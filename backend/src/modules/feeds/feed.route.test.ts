import http from 'node:http';
import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import { input, page } from './feed.input.js';
import { feedRouter } from './feed.route.js';
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
 const {setPostLike}=await import('./feed.route.js');const values=new Set<string>();
 const db={createMany:async({data,skipDuplicates}:any)=>{assert.equal(skipDuplicates,true);for(const x of data)values.add(x.postId+':'+x.userId);},deleteMany:async({where}:any)=>{values.delete(where.postId+':'+where.userId);},count:async()=>values.size};
 await Promise.all(Array.from({length:10},()=>setPostLike('post','user',true,db as never)));
 assert.equal(values.size,1);
 await setPostLike('post','user',false,db as never);await setPostLike('post','user',false,db as never);assert.equal(values.size,0);
});
test('pagination only emits cursor when more rows exist, retaining tied IDs',async()=>{
 const {slice}=await import('./feed.route.js');const createdAt=new Date('2026-11-03');
 const result=slice([{id:'b',createdAt},{id:'a',createdAt}],1);
 assert.equal(result.items[0]?.id,'b');assert.equal(JSON.parse(Buffer.from(result.nextCursor!,'base64url').toString()).id,'b');
 assert.equal(slice([{id:'a',createdAt}],1).nextCursor,null);
});

test('missing or unavailable posts return 404 without database writes',async()=>{
 const {prisma}=await import('../../lib/prisma.js');const {post}=await import('./feed.route.js');
 const original=prisma.feedPost.findFirst;
 try {
  prisma.feedPost.findFirst=(async(args:unknown)=>{assert.deepEqual(args,{where:{id:'12345678-1234-1234-1234-123456789012',author:{status:'ACTIVE'}}});return null;}) as typeof original;
  await assert.rejects(post('12345678-1234-1234-1234-123456789012'),{code:'POST_NOT_FOUND'});
 }finally{prisma.feedPost.findFirst=original;}
});

test('following feed is constrained to the authenticated follower',async()=>{
 const {followingFilter}=await import('./feed.route.js');
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
 const {followPage}=await import('../users/users.service.js');
 assert.equal(followPage(undefined),1);assert.equal(followPage('3'),3);
 for(const v of ['0','-1','1.5','x'])assert.throws(()=>followPage(v));
});
