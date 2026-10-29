import { Router } from 'express';
import { ListingStatus, ListingCondition, Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { AuthRequest, verifyToken, authorizeRoles } from '../../middlewares/auth.middleware.js';
import { withQuotaTransaction } from '../stores/store.service.js';
import { AppError } from '../../errors/app-error.js';
import { audit, boolean, changed, choice, integer, moderate, object, page, sanction, text, userFields, version, normalizeKnowledge } from './admin.service.js';

const router = Router();
router.use(verifyToken, authorizeRoles('ADMIN'));
const actor = (req: AuthRequest) => req.user!.userId;
const route = (fn: (req: AuthRequest) => Promise<unknown>) => async (req: AuthRequest, res: import('express').Response, next: import('express').NextFunction) => {
  try { res.json({success:true,data:await fn(req)}); } catch (error) { next(error); }
};
const listingFields = {id:true,title:true,description:true,price:true,status:true,images:true,reviewReason:true,updatedAt:true,categoryId:true,ownerId:true,condition:true,owner:{select:{id:true,fullName:true}},category:{select:{id:true,name:true}}} as const;
router.get('/me', route(req => prisma.user.findUniqueOrThrow({where:{id:actor(req)},select:userFields})));
router.get('/dashboard', route(async () => {
  const [pendingListings,openReports,activeUsers,activeListings,pendingStores,pendingPromotions,revenue,logs] = await Promise.all([
    prisma.listing.count({where:{status:'PENDING'}}), prisma.violationReport.count({where:{status:'OPEN'}}),
    prisma.user.count({where:{role:'USER',status:'ACTIVE'}}),prisma.listing.count({where:{status:'AVAILABLE'}}),
    prisma.storeOrder.count({where:{status:'PENDING'}}),prisma.promotionOrder.count({where:{status:'PENDING'}}),
    prisma.promotionOrder.aggregate({where:{status:'CONFIRMED'},_sum:{amount:true}}),prisma.adminAudit.findMany({take:10,orderBy:[{createdAt:'desc'},{id:'desc'}]}),
  ]);
  return {pendingListings,openReports,activeUsers,activeListings,pendingStores,pendingPromotions,promotionRevenue:revenue._sum.amount??'0',logs};
}));
router.get('/listings',route(req => {
  const where: Prisma.ListingWhereInput = { ...(req.query.status ? {status:choice(req.query.status,Object.values(ListingStatus))} : {}),
    ...(req.query.q ? {title:{contains:text(req.query.q,'q',1,100),mode:'insensitive'}} : {})};
  const current=page(req.query.page);
  return prisma.$transaction(async tx => ({items:await tx.listing.findMany({where,select:listingFields,orderBy:[{updatedAt:'desc'},{id:'desc'}],skip:(current-1)*25,take:25}),total:await tx.listing.count({where}),page:current}));
}));
router.post('/listings/:id/decision',route(req => {
  const body=object(req.body,['action','reason','updatedAt']);
  const action=choice(body.action,['APPROVE','REJECT','REQUEST_CHANGES','REMOVE']);
  const reason=text(body.reason,'reason',action==='APPROVE'?0:5,300);
  const expected=version(body.updatedAt);
  return withQuotaTransaction(async tx => {await moderate(tx,actor(req),String(req.params.id),action,reason,expected);return {updated:true};});
}));
router.get('/users',route(req => {
  const where:Prisma.UserWhereInput={role:'USER',...(req.query.q ? {OR:[{fullName:{contains:text(req.query.q,'q',1,100),mode:'insensitive'}},{email:{contains:String(req.query.q),mode:'insensitive'}}]}:{})};
  const current=page(req.query.page);
  return prisma.$transaction(async tx => ({items:await tx.user.findMany({where,select:userFields,take:25,skip:(current-1)*25,orderBy:[{createdAt:'desc'},{id:'desc'}]}),total:await tx.user.count({where}),page:current}));
}));
router.post('/users/:id/action',route(req => {
  const body=object(req.body,['action','reason','days','updatedAt']);
  const action=choice(body.action,['WARN','SUSPEND','BAN','RESTORE']);
  const reason=text(body.reason,'reason',5,300), days=integer(body.days??7,1,365), expected=version(body.updatedAt);
  return withQuotaTransaction(async tx => {await sanction(tx,actor(req),String(req.params.id),action,reason,days,expected);return {updated:true};});
}));
router.get('/reports',route(req => {
  const current=page(req.query.page), where:Prisma.ViolationReportWhereInput=req.query.status?{status:choice(req.query.status,['OPEN','RESOLVED','DISMISSED'] as const)}:{};
  return prisma.$transaction(async tx=>({items:await tx.violationReport.findMany({where,skip:(current-1)*25,take:25,orderBy:[{createdAt:'desc'},{id:'desc'}]}),total:await tx.violationReport.count({where}),page:current}));
}));
router.post('/reports/:id/resolve',route(req => {
  const body=object(req.body,['action','reason','days','updatedAt','targetUpdatedAt']);
  const action=choice(body.action,['DISMISS','KEEP','REMOVE','WARN','SUSPEND','BAN']);
  const reason=text(body.reason,'reason',5,300), expected=version(body.updatedAt);
  return withQuotaTransaction(async tx=>{
    const report=await tx.violationReport.findUniqueOrThrow({where:{id:String(req.params.id)}});
    if(report.status!=='OPEN') throw new AppError(409,'REPORT_CLOSED','Báo cáo đã được xử lý.');
    if(report.targetType==='LISTING' && !['DISMISS','KEEP','REMOVE'].includes(action) || report.targetType==='USER' && !['DISMISS','WARN','SUSPEND','BAN'].includes(action)) throw new AppError(400,'INVALID_DECISION','Hành động không phù hợp đối tượng.');
    if(action==='REMOVE') await moderate(tx,actor(req),report.targetId,'REMOVE',reason,version(body.targetUpdatedAt));
    if(['WARN','SUSPEND','BAN'].includes(action)) await sanction(tx,actor(req),report.targetId,action,reason,integer(body.days??7,1,365),version(body.targetUpdatedAt));
    const result=await tx.violationReport.updateMany({where:{id:report.id,status:'OPEN',updatedAt:expected},data:{status:action==='DISMISS'?'DISMISSED':'RESOLVED',decision:action,resolution:reason}});
    changed(result.count);await audit(tx,actor(req),action,'REPORT',report.id,reason);return {updated:true};
  });
}));
router.get('/reports/:id/target',route(async req=>{
  const report=await prisma.violationReport.findUniqueOrThrow({where:{id:String(req.params.id)}});
  return report.targetType==='USER'?prisma.user.findUnique({where:{id:report.targetId},select:userFields}):prisma.listing.findUnique({where:{id:report.targetId},select:listingFields});
}));
router.get('/catalog',route(async()=>({categories:await prisma.category.findMany({orderBy:{name:'asc'}}),conditions:await prisma.conditionPolicy.findMany({orderBy:{condition:'asc'}})})));
router.post('/categories',route(req=>{
  const body=object(req.body,['id','name','description','active']);
  const name=text(body.name,'name',2,100), id=text(body.id,'id',2,80),description=text(body.description,'description',0,500),active=boolean(body.active);
  if(!/^[a-z0-9-]+$/.test(id)) throw new AppError(400,'INVALID_ID','Mã danh mục chỉ gồm chữ thường, số và dấu gạch ngang.');
  return withQuotaTransaction(async tx=>{if(await tx.category.findFirst({where:{name:{equals:name,mode:'insensitive'}}})) throw new AppError(409,'DUPLICATE_CATEGORY','Tên danh mục đã tồn tại.');
    const item=await tx.category.create({data:{id,name,active,metadata:{name,description,attributes:[]}}});await audit(tx,actor(req),'CREATE','CATEGORY',id,name);return item;});
}));
router.put('/categories/:id',route(req=>{
  const body=object(req.body,['name','description','active']); const name=text(body.name,'name',2,100),description=text(body.description,'description',0,500),active=boolean(body.active);
  return withQuotaTransaction(async tx=>{const id=String(req.params.id),old=await tx.category.findUniqueOrThrow({where:{id}});
    if(await tx.category.findFirst({where:{id:{not:id},name:{equals:name,mode:'insensitive'}}}))throw new AppError(409,'DUPLICATE_CATEGORY','Tên danh mục đã tồn tại.');
    const item=await tx.category.update({where:{id},data:{name,active,metadata:{...(old.metadata as Prisma.JsonObject),name,description}}});await audit(tx,actor(req),'UPDATE','CATEGORY',id,name,old,item);return item;});
}));
router.put('/conditions/:condition',route(req=>{
  const condition=choice(req.params.condition,Object.values(ListingCondition)),body=object(req.body,['name','active']);
  return withQuotaTransaction(async tx=>{const item=await tx.conditionPolicy.upsert({where:{condition},create:{condition,name:text(body.name,'name',2,100),active:boolean(body.active)},update:{name:text(body.name,'name',2,100),active:boolean(body.active)}});await audit(tx,actor(req),'UPDATE','CONDITION',condition,item.name);return item;});
}));
router.get('/posts',route(req=>{
  const current=page(req.query.page);
  return prisma.$transaction(async tx=>({items:await tx.blogPost.findMany({skip:(current-1)*25,take:25,orderBy:[{updatedAt:'desc'},{id:'desc'}]}),total:await tx.blogPost.count(),page:current}));
}));
const savePost=route(req=>{
  const body=object(req.body,['title','slug','category','content','coverUrl','listingIds','status','updatedAt']);
  const title=text(body.title,'title',5,160),slug=text(body.slug,'slug',3,160),category=text(body.category,'category',2,100),content=text(body.content,'content',20,50000);
  if(!/^[a-z0-9-]+$/.test(slug))throw new AppError(400,'INVALID_SLUG','Slug chỉ gồm chữ thường, số, dấu gạch ngang.');
  const status=choice(body.status,['DRAFT','PUBLISHED','HIDDEN','ARCHIVED']);
  const coverUrl=body.coverUrl?text(body.coverUrl,'coverUrl',1,300):null;
  if(coverUrl&&!/^\/api\/v1\/content\/media\/[0-9a-f-]{36}\.(jpg|png|webp)$/.test(coverUrl))throw new AppError(400,'INVALID_COVER','Chọn ảnh bìa đã tải lên hệ thống.');
  if(!Array.isArray(body.listingIds)||body.listingIds.length>10||body.listingIds.some(v=>typeof v!=='string'||v.length>100))throw new AppError(400,'INVALID_LISTINGS','Tối đa 10 tin liên quan.');
  const listingIds=[...new Set(body.listingIds as string[])];
  return withQuotaTransaction(async tx=>{
    if(await tx.listing.count({where:{id:{in:listingIds},status:'AVAILABLE',owner:{status:'ACTIVE'}}})!==listingIds.length)throw new AppError(400,'INVALID_LISTINGS','Tin liên quan phải đang hiển thị.');
    const data={title,slug,category,content,coverUrl,listingIds,status};
    if(req.params.id){const id=String(req.params.id);changed((await tx.blogPost.updateMany({where:{id,updatedAt:version(body.updatedAt)},data})).count);await audit(tx,actor(req),'UPDATE','POST',id,title);return tx.blogPost.findUniqueOrThrow({where:{id}});}
    const item=await tx.blogPost.create({data});await audit(tx,actor(req),'CREATE','POST',item.id,title);return item;
  });
});
router.post('/posts',savePost);router.put('/posts/:id',savePost);
router.get('/tickets',route(req=>{const current=page(req.query.page);return prisma.$transaction(async tx=>({items:await tx.supportTicket.findMany({skip:(current-1)*25,take:25,orderBy:[{updatedAt:'desc'},{id:'desc'}],include:{messages:{orderBy:{createdAt:'asc'}}}}),total:await tx.supportTicket.count(),page:current}));}));
router.post('/tickets/:id/reply',route(req=>{
  const body=object(req.body,['content','updatedAt']); const content=text(body.content,'content',1,4000),expected=version(body.updatedAt);
  return withQuotaTransaction(async tx=>{const id=String(req.params.id);changed((await tx.supportTicket.updateMany({where:{id,status:'OPEN',updatedAt:expected},data:{updatedAt:new Date()}})).count);const message=await tx.supportMessage.create({data:{ticketId:id,authorId:actor(req),isAdmin:true,content}});await audit(tx,actor(req),'REPLY','TICKET',id,'Phản hồi hỗ trợ');return message;});
}));
router.post('/tickets/:id/status',route(req=>{
  const body=object(req.body,['status','updatedAt']),status=choice(body.status,['OPEN','RESOLVED']);
  return withQuotaTransaction(async tx=>{const id=String(req.params.id);changed((await tx.supportTicket.updateMany({where:{id,updatedAt:version(body.updatedAt)},data:{status}})).count);await audit(tx,actor(req),status,'TICKET',id,'Cập nhật trạng thái hỗ trợ');return {updated:true};});
}));
router.get('/knowledge',route(req=>{const current=page(req.query.page);return prisma.$transaction(async tx=>({items:await tx.knowledgeDocument.findMany({skip:(current-1)*25,take:25,orderBy:[{updatedAt:'desc'},{id:'desc'}]}),total:await tx.knowledgeDocument.count(),page:current}));}));
router.post('/knowledge/catalog-sync',route(req=>withQuotaTransaction(async tx=>{
  const categories=await tx.category.findMany({where:{active:true},orderBy:{id:'asc'},select:{id:true,name:true,metadata:true}});
  const content=categories.map(item=>`${item.id}: ${item.name}\n${JSON.stringify(item.metadata)}`).join('\n\n');
  const data={title:'Danh mục và thuộc tính sản phẩm',content,indexedText:normalizeKnowledge(content),syncedAt:new Date(),active:true};
  const item=await tx.knowledgeDocument.upsert({where:{id:'system-catalog'},create:{id:'system-catalog',...data},update:data});
  await audit(tx,actor(req),'CATALOG_SYNC','KNOWLEDGE',item.id,`Đồng bộ ${categories.length} danh mục từ database`);
  return {categories:categories.length,syncedAt:item.syncedAt};
})));
const saveKnowledge=route(req=>{
  const body=object(req.body,['title','content','active','updatedAt']);const data={title:text(body.title,'title',3,160),content:text(body.content,'content',10,100000),active:boolean(body.active),indexedText:null,syncedAt:null};
  return withQuotaTransaction(async tx=>{if(req.params.id){const id=String(req.params.id);changed((await tx.knowledgeDocument.updateMany({where:{id,updatedAt:version(body.updatedAt)},data})).count);await audit(tx,actor(req),'UPDATE','KNOWLEDGE',id,data.title);return tx.knowledgeDocument.findUniqueOrThrow({where:{id}});}const item=await tx.knowledgeDocument.create({data});await audit(tx,actor(req),'CREATE','KNOWLEDGE',item.id,item.title);return item;});
});
router.post('/knowledge',saveKnowledge);router.put('/knowledge/:id',saveKnowledge);
router.post('/knowledge/:id/sync',route(req=>{
  const body=object(req.body,['updatedAt']);return withQuotaTransaction(async tx=>{const id=String(req.params.id),doc=await tx.knowledgeDocument.findUniqueOrThrow({where:{id}});changed((await tx.knowledgeDocument.updateMany({where:{id,updatedAt:version(body.updatedAt)},data:{indexedText:normalizeKnowledge(doc.title+'\n'+doc.content),syncedAt:new Date()}})).count);await audit(tx,actor(req),'INDEX','KNOWLEDGE',id,'Lập chỉ mục tìm kiếm nội dung');return {indexed:true};});
}));
router.delete('/knowledge/:id',route(req=>{
  const body=object(req.body,['updatedAt']);return withQuotaTransaction(async tx=>{const id=String(req.params.id);changed((await tx.knowledgeDocument.deleteMany({where:{id,updatedAt:version(body.updatedAt)}})).count);await audit(tx,actor(req),'DELETE','KNOWLEDGE',id,'Xóa tài liệu và chỉ mục');return {deleted:true};});
}));
router.get('/audit',route(req=>{const current=page(req.query.page);return prisma.$transaction(async tx=>({items:await tx.adminAudit.findMany({skip:(current-1)*25,take:25,orderBy:[{createdAt:'desc'},{id:'desc'}]}),total:await tx.adminAudit.count(),page:current}));}));
router.get('/store-packages',route(()=>prisma.storePackage.findMany({orderBy:{priorityLevel:'asc'}})));
router.get('/store-orders',route(req=>{
  const current=page(req.query.page),where:Prisma.StoreOrderWhereInput=req.query.status?{status:choice(req.query.status,['PENDING','CONFIRMED','REJECTED'] as const)}:{};
  return prisma.$transaction(async tx=>({items:await tx.storeOrder.findMany({where,take:25,skip:(current-1)*25,orderBy:[{createdAt:'desc'},{id:'desc'}],include:{user:{select:{fullName:true,email:true}},package:true,category:true}}),total:await tx.storeOrder.count({where}),page:current}));
}));
router.get('/promotion-orders',route(req=>{
  const current=page(req.query.page),where:Prisma.PromotionOrderWhereInput=req.query.status?{status:choice(req.query.status,['PENDING','CONFIRMED','REJECTED'] as const)}:{};
  return prisma.$transaction(async tx=>({items:await tx.promotionOrder.findMany({where,take:25,skip:(current-1)*25,orderBy:[{createdAt:'desc'},{id:'desc'}],include:{user:{select:{fullName:true,email:true}},package:true,listing:{select:{id:true,title:true}}}}),total:await tx.promotionOrder.count({where}),page:current}));
}));
router.put('/store-packages/:id',route(req=>{
  const body=object(req.body,['name','monthlyPrice','dailyListingLimit','activeListingLimit','monthlyPromotionQuota','priorityLevel']);const name=text(body.name,'name',3,80),monthlyPrice=text(body.monthlyPrice,'monthlyPrice',1,12);
  if(!/^(0|[1-9]\d{0,11})$/.test(monthlyPrice))throw new AppError(400,'INVALID_PRICE','Giá không hợp lệ.');
  const data={name,monthlyPrice,dailyListingLimit:integer(body.dailyListingLimit,1,10000),activeListingLimit:integer(body.activeListingLimit,1,100000),monthlyPromotionQuota:integer(body.monthlyPromotionQuota,0,10000),priorityLevel:integer(body.priorityLevel,0,10)};
  return withQuotaTransaction(async tx=>{const id=String(req.params.id),old=await tx.storePackage.findUniqueOrThrow({where:{id}});if(old.tier==='PERSONAL' && (monthlyPrice!=='0'||data.priorityLevel!==0||data.monthlyPromotionQuota!==0))throw new AppError(400,'INVALID_PERSONAL_PACKAGE','Gói cá nhân phải miễn phí, không có ưu tiên hoặc quảng cáo kèm gói.');const item=await tx.storePackage.update({where:{id},data});await audit(tx,actor(req),'UPDATE','STORE_PACKAGE',id,name,old,item);return item;});
}));
export default router;
