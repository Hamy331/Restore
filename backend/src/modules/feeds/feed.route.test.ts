import http from 'node:http';
import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import { input, page } from './feed.validator.js';
import { feedRouter } from './routes/feed.route.js';

test('feed auth protects registered routes and leaves unknown paths to 404', async () => {
  const app = express();
  app.use(feedRouter);
  app.use((_req, res) => { res.sendStatus(404); });
  const server = http.createServer(app);
  await new Promise<void>(resolve => server.listen(0, '127.0.0.1', resolve));
  const baseUrl = `http://127.0.0.1:${(server.address() as {port:number}).port}`;
  try {
    assert.equal((await fetch(`${baseUrl}/feeds`)).status, 401);
    assert.equal((await fetch(`${baseUrl}/missing-api`)).status, 404);
  } finally {
    server.closeAllConnections();
    await new Promise<void>(resolve => server.close(() => resolve()));
  }
});
test('rejects empty, oversized, spoofed and local image posts',()=>{
 assert.equal(input({text:' hello '}).text,'hello');
 for(const b of [{text:' '},{text:'a'.repeat(2001)},{text:'ok',authorId:'other'},{imageUrl:'blob:local'}])assert.throws(()=>input(b));
 assert.throws(()=>input({text:' '},true));
});
test('validates cursor timestamp, tie-breaking ID and limits',()=>{
 const c={id:'12345678-1234-1234-1234-123456789012',createdAt:'2026-11-03T00:00:00.000Z'};
 const p=page({cursor:Buffer.from(JSON.stringify(c)).toString('base64url'),limit:'2'});
 assert.equal(p.after?.id,c.id);assert.equal(p.after?.createdAt.toISOString(),c.createdAt);
 for(const q of [{limit:0},{limit:51},{limit:1.5},{cursor:'invalid'}])assert.throws(()=>page(q));
});
test('requires authentication before accessing data',async()=>{
 const {verifyToken}=await import('../../middlewares/auth.middleware.js');
 let status=0, payload:unknown;
 await verifyToken({headers:{}} as never,{status:(code:number)=>{status=code;return {json:(body:unknown)=>{payload=body;}}}} as never,()=>{throw Error('must not continue');});
 assert.equal(status,401);assert.equal((payload as {code:string}).code,'AUTH_REQUIRED');
});

test('post likes are idempotent with duplicate concurrent requests',async()=>{
 const {setPostLike}=await import('./services/feed.service.js');const values=new Set<string>();
 const db={createMany:async({data,skipDuplicates}:any)=>{assert.equal(skipDuplicates,true);for(const x of data)values.add(x.postId+':'+x.userId);},deleteMany:async({where}:any)=>{values.delete(where.postId+':'+where.userId);},count:async()=>values.size};
 await Promise.all(Array.from({length:10},()=>setPostLike('post','user',true,db as never)));
 assert.equal(values.size,1);
 await setPostLike('post','user',false,db as never);await setPostLike('post','user',false,db as never);assert.equal(values.size,0);
});
test('pagination only emits cursor when more rows exist, retaining tied IDs',async()=>{
 const {slice}=await import('./services/feed.service.js');const createdAt=new Date('2026-11-03');
 const result=slice([{id:'b',createdAt},{id:'a',createdAt}],1);
 assert.equal(result.items[0]?.id,'b');assert.equal(JSON.parse(Buffer.from(result.nextCursor!,'base64url').toString()).id,'b');
 assert.equal(slice([{id:'a',createdAt}],1).nextCursor,null);
});

test('missing or unavailable posts return 404 without database writes',async()=>{
 const {prisma}=await import('../../lib/prisma.js');const {post}=await import('./services/feed.service.js');
 const original=prisma.feedPost.findFirst;
 try {
  prisma.feedPost.findFirst=(async(args:unknown)=>{assert.deepEqual(args,{where:{id:'12345678-1234-1234-1234-123456789012',author:{status:'ACTIVE'}}});return null;}) as typeof original;
  await assert.rejects(post('12345678-1234-1234-1234-123456789012'),{code:'POST_NOT_FOUND'});
 }finally{prisma.feedPost.findFirst=original;}
});

test('following feed is constrained to the authenticated follower',async()=>{
 const {followingFilter}=await import('./services/feed.service.js');
 assert.deepEqual(followingFilter('current-user'),{author:{status:'ACTIVE',followers:{some:{followerId:'current-user'}}}});
});

test('only the author can delete a post',async()=>{
 const {prisma}=await import('../../lib/prisma.js');
 const postId='12345678-1234-1234-1234-123456789012';
 const findFirst=prisma.feedPost.findFirst,remove=prisma.feedPost.delete;let deleted=0;
 prisma.feedPost.findFirst=(async()=>({id:postId,authorId:'author'})) as never;
 prisma.feedPost.delete=(async()=>{deleted++;}) as never;
 const app=express();app.use((req,_res,next)=>{(req as never as {user:object}).user={userId:req.headers['x-user'],role:'USER'};next();});
 const route=(feedRouter.stack as {route?:{path:string;methods:Record<string,boolean>;stack:{handle:express.RequestHandler}[]}}[]).find(l=>l.route?.path==='/feeds/:id'&&l.route.methods.delete)!.route!;
 app.delete('/feeds/:id',route.stack.at(-1)!.handle);
 app.use((e:{statusCode?:number;code?:string},_q:express.Request,s:express.Response,_n:express.NextFunction)=>{s.status(e.statusCode??500).json({code:e.code});});
 const server=http.createServer(app).listen(0);
 try{
  const port=(server.address() as {port:number}).port;
  const call=(user:string)=>fetch(`http://127.0.0.1:${port}/feeds/${postId}`,{method:'DELETE',headers:{'x-user':user}});
  assert.equal((await call('someone-else')).status,403);assert.equal(deleted,0);
  assert.equal((await call('author')).status,200);assert.equal(deleted,1);
 }finally{server.close();prisma.feedPost.findFirst=findFirst;prisma.feedPost.delete=remove;}
});
test('follow list pagination rejects invalid pages',async()=>{
 const {followPage}=await import('../users/services/profile.service.js');
 assert.equal(followPage(undefined),1);assert.equal(followPage('3'),3);
 for(const v of ['0','-1','1.5','x'])assert.throws(()=>followPage(v));
});

test('media uploads go to their own area and are named after the uploader',async()=>{
 const {mkdtemp,rm}=await import('node:fs/promises');const {tmpdir}=await import('node:os');const path=await import('node:path');
 const {uploadMedia,readMedia,isMediaUrl,mediaPurpose}=await import('../media/media.service.js');
 const root=await mkdtemp(path.join(tmpdir(),'media-'));const saved={driver:process.env.STORAGE_DRIVER,root:process.env.STORAGE_DISK_ROOT};
 process.env.STORAGE_DRIVER='disk';process.env.STORAGE_DISK_ROOT=root;
 try{
  const user='12345678-1234-1234-1234-123456789012';
  const feed=await uploadMedia(user,'feed',Buffer.from([255,216,255,0]));
  const avatar=await uploadMedia(user,mediaPurpose('avatar'),Buffer.from([137,80,78,71,13,10,26,10,0]));
  assert.match(feed,new RegExp(`^/api/v1/media/feeds/${user}_[0-9a-f-]{36}\.jpg$`));
  assert.match(avatar,/^\/api\/v1\/media\/avatars\/.+\.png$/);
  assert.ok(isMediaUrl(feed,'feed'));assert.ok(!isMediaUrl(feed,'avatar'));assert.ok(!isMediaUrl('https://evil.example/a.jpg','feed'));
  const [area,name]=feed.split('/').slice(-2);
  assert.equal((await readMedia(area!,name!)).contentType,'image/jpeg');
  await assert.rejects(readMedia('listings',name!),{code:'MEDIA_NOT_FOUND'});
  await assert.rejects(uploadMedia(user,'feed',Buffer.from('not an image')),{code:'INVALID_IMAGE'});
  assert.throws(()=>mediaPurpose('listing'),{code:'INVALID_PURPOSE'});
 }finally{
  for(const [k,v] of [['STORAGE_DRIVER',saved.driver],['STORAGE_DISK_ROOT',saved.root]] as const){if(v===undefined)delete process.env[k];else process.env[k]=v;}
  await rm(root,{recursive:true,force:true});
 }
});
test('posts only accept images uploaded to the feeds area',()=>{
 const ok='/api/v1/media/feeds/12345678-1234-1234-1234-123456789012_12345678-1234-1234-1234-123456789012.jpg';
 assert.equal(input({imageUrl:ok}).imageUrl,ok);
 for(const imageUrl of [ok.replace('/feeds/','/avatars/'),'https://evil.example/a.jpg','/api/v1/media/feeds/../x.jpg'])assert.throws(()=>input({imageUrl}),{code:'INVALID_IMAGE'});
});

test('comments accept uploaded images and reply IDs while rejecting invalid payloads', () => {
  const parentId = '12345678-1234-1234-1234-123456789012';
  const imageUrl = `/api/v1/media/feeds/${parentId}_${parentId}.jpg`;
  const comment = input({ imageUrl, parentId }, true);
  assert.equal(comment.imageUrl, imageUrl);
  assert.equal(comment.parentId, parentId);
  assert.equal(comment.text, '');
  for (const body of [{ text: '' }, { text: 'Hi', parentId: 'invalid' }, { imageUrl: 'blob:local' }, { text: 'Hi', listingId: parentId }]) {
    assert.throws(() => input(body, true));
  }
});
