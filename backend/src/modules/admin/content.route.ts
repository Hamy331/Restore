import express, { Router } from 'express';
import { randomUUID } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { prisma } from '../../lib/prisma.js';
import { AuthRequest, verifyToken, authorizeRoles } from '../../middlewares/auth.middleware.js';
import { AppError } from '../../errors/app-error.js';
import { imageExtension } from '../listings/listing.route.js';
import { audit, choice, normalizeKnowledge, object, page, text } from './admin.service.js';
import { withQuotaTransaction } from '../stores/store.service.js';

const router = Router();
const handler = (fn:(req:AuthRequest)=>Promise<unknown>)=>async(req:AuthRequest,res:import('express').Response,next:import('express').NextFunction)=>{
  try{res.json({success:true,data:await fn(req)});}catch(error){next(error);}
};
const folder=path.join(process.cwd(),'uploads','admin');
router.post('/media',verifyToken,authorizeRoles('ADMIN'),express.raw({type:()=>true,limit:'5mb'}),handler(async req=>{
  const extension=imageExtension(req.headers['content-type']?.split(';')[0],req.body);
  const filename=`${randomUUID()}.${extension}`;
  await mkdir(folder,{recursive:true});await writeFile(path.join(folder,filename),req.body,{flag:'wx'});
  return {url:`/api/v1/content/media/${filename}`};
}));
router.get('/media/:filename',(req:AuthRequest,res,next)=>req.headers.authorization?verifyToken(req,res,next):next(),async(req:AuthRequest,res,next)=>{
  try{
    const filename=String(req.params.filename);
    if(!/^[0-9a-f-]{36}\.(jpg|png|webp)$/.test(filename))throw new AppError(404,'IMAGE_NOT_FOUND','Không có ảnh.');
    if(req.user?.role!=='ADMIN'&&!await prisma.blogPost.findFirst({where:{status:'PUBLISHED',coverUrl:`/api/v1/content/media/${filename}`},select:{id:true}}))throw new AppError(404,'IMAGE_NOT_FOUND','Không có ảnh.');
    const data=await readFile(path.join(folder,filename));res.setHeader('Cache-Control','private, no-store');res.setHeader('X-Content-Type-Options','nosniff');res.type(path.extname(filename)).send(data);
  }catch(error){next((error as NodeJS.ErrnoException).code==='ENOENT'?new AppError(404,'IMAGE_NOT_FOUND','Không có ảnh.'):error);}
});
router.get('/posts',handler(async req=>({items:await prisma.blogPost.findMany({where:{status:'PUBLISHED'},skip:(page(req.query.page)-1)*20,take:20,orderBy:[{createdAt:'desc'},{id:'desc'}],select:{id:true,slug:true,title:true,category:true,coverUrl:true,createdAt:true}})})));
router.get('/posts/:slug',handler(async req=>{
  const post=await prisma.blogPost.findFirst({where:{slug:String(req.params.slug),status:'PUBLISHED'}});
  if(!post)throw new AppError(404,'POST_NOT_FOUND','Không tìm thấy bài viết.');
  const listings=await prisma.listing.findMany({where:{id:{in:post.listingIds},status:'AVAILABLE',owner:{status:'ACTIVE'}},select:{id:true,title:true,price:true,images:true}});
  return {...post,listings};
}));
router.get('/knowledge/search',handler(async req=>{
  const q=normalizeKnowledge(text(req.query.q,'q',2,100));
  // ponytail: lexical retrieval, not a generative LLM; replace with embeddings when an AI provider is configured.
  const documents=await prisma.knowledgeDocument.findMany({where:{active:true,indexedText:{not:null},AND:q.split(/\s+/).slice(0,10).map(token=>({indexedText:{contains:token}}))},take:5,select:{id:true,title:true,content:true,syncedAt:true}});
  return {mode:'lexical',documents};
}));
router.post('/knowledge/upload',verifyToken,authorizeRoles('ADMIN'),express.text({type:['text/plain','text/markdown'],limit:'100kb'}),handler(req=>{
  const title=text(req.query.title,'title',3,160),content=text(req.body,'content',10,100000);
  if(content.includes('\u0000'))throw new AppError(400,'INVALID_DOCUMENT','Chỉ nhận văn bản UTF-8 (.txt, .md).');
  return withQuotaTransaction(async tx=>{const doc=await tx.knowledgeDocument.create({data:{title,content,active:true}});await audit(tx,req.user!.userId,'UPLOAD','KNOWLEDGE',doc.id,title);return doc;});
}));
router.post('/reports',verifyToken,authorizeRoles('USER'),handler(req=>{
  const body=object(req.body,['targetType','targetId','reason','evidence']);
  const targetType=choice(body.targetType,['LISTING','USER']),targetId=text(body.targetId,'targetId',1,100),reason=text(body.reason,'reason',5,300),evidence=text(body.evidence,'evidence',5,4000);
  return withQuotaTransaction(async tx=>{
    const target=targetType==='USER'?await tx.user.findFirst({where:{id:targetId,role:'USER'}}):await tx.listing.findFirst({where:{id:targetId,status:'AVAILABLE'}});
    if(!target)throw new AppError(404,'TARGET_NOT_FOUND','Đối tượng không tồn tại.');
    if(targetId===req.user!.userId||targetType==='LISTING'&&(target as {ownerId?:string}).ownerId===req.user!.userId)throw new AppError(400,'INVALID_REPORT','Không tự báo cáo mình.');
    if(await tx.violationReport.findFirst({where:{reporterId:req.user!.userId,targetType,targetId,status:'OPEN'}}))throw new AppError(409,'REPORT_EXISTS','Bạn đã có báo cáo đang chờ xử lý.');
    return tx.violationReport.create({data:{reporterId:req.user!.userId,targetType,targetId,reason,evidence}});
  });
}));
router.get('/reports/mine',verifyToken,authorizeRoles('USER'),handler(req=>prisma.violationReport.findMany({where:{reporterId:req.user!.userId},skip:(page(req.query.page)-1)*20,take:20,orderBy:{createdAt:'desc'}})));
router.get('/tickets',verifyToken,authorizeRoles('USER'),handler(req=>prisma.supportTicket.findMany({where:{userId:req.user!.userId},skip:(page(req.query.page)-1)*20,take:20,orderBy:{updatedAt:'desc'},include:{messages:{orderBy:{createdAt:'asc'}}}})));
router.post('/tickets',verifyToken,authorizeRoles('USER'),handler(req=>{
  const body=object(req.body,['subject','content']);return prisma.supportTicket.create({data:{userId:req.user!.userId,subject:text(body.subject,'subject',5,160),messages:{create:{authorId:req.user!.userId,isAdmin:false,content:text(body.content,'content',5,4000)}}}});
}));
router.post('/tickets/:id/reply',verifyToken,authorizeRoles('USER'),handler(req=>{
  const body=object(req.body,['content']);const content=text(body.content,'content',1,4000);
  return withQuotaTransaction(async tx=>{
    const ticket=await tx.supportTicket.findFirst({where:{id:String(req.params.id),userId:req.user!.userId,status:'OPEN'}});
    if(!ticket)throw new AppError(404,'TICKET_NOT_FOUND','Không tìm thấy yêu cầu đang mở của bạn.');
    await tx.supportTicket.update({where:{id:ticket.id},data:{updatedAt:new Date()}});
    return tx.supportMessage.create({data:{ticketId:ticket.id,authorId:req.user!.userId,isAdmin:false,content}});
  });
}));
export default router;
