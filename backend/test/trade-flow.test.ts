import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Prisma } from '@prisma/client';
import { prisma } from '../src/lib/prisma.js';
import { changeTrade, submitReview } from '../src/modules/chat/services/trade.service.js';

test('only the selected buyer confirms receipt and both participants can review', async t => {
  const listing = { id:'phone', title:'Phone', images:[], price:500, ownerId:'seller', status:'AVAILABLE', allowSale:true };
  type Trade = {conversationId:string; sellerId:string; buyerId:string; confirmedAt?:Date};
  let trade:Trade|null = null;
  const reviews: {authorId:string; recipientId:string; fromSeller:boolean}[] = [];
  const messages:string[] = [];
  const tx = {
    $queryRaw:async()=>[],
    conversationMember:{findFirst:async()=>null,updateMany:async()=>({})},
    conversation:{
      findFirst:async({where}:any)=>{
        const members=['seller',where.id==='chat2'?'buyer2':'buyer'];
        return members.includes(where.members.some.userId)?{listingId:'phone',members:members.map(userId=>({userId}))}:null;
      },
      updateMany:async()=>({})
    },
    listing:{findUniqueOrThrow:async()=>listing,update:async({data}:any)=>Object.assign(listing,data)},
    listingTrade:{findUnique:async()=>trade,create:async({data}:any)=>trade=data,
      delete:async()=>trade=null,update:async({data}:any)=>Object.assign(trade!,data)},
    listingRevision:{findUnique:async()=>null},
    message:{create:async({data}:any)=>messages.push(data.text)}
  };
  t.mock.method(prisma,'$transaction',async(run:any)=>run(tx));
  // Prisma delegates expose operations via a proxy, rather than own methods.
  Object.assign(prisma.listingTrade,{findUnique:async()=>trade});
  Object.assign(prisma.tradeReview,{
    create:async({data}:any)=>{
      if(reviews.some(r=>r.authorId===data.authorId)) {
        throw new Prisma.PrismaClientKnownRequestError('duplicate',{code:'P2002',clientVersion:'test'});
      }
      reviews.push(data);
    },
    findUnique:async({where}:any)=>reviews.find(r=>r.authorId===where.conversationId_authorId.authorId)
  });
  const rate=(id:string)=>submitReview(id,'chat',{stars:4,comment:'Good'});
  await assert.rejects(changeTrade('buyer','chat','sell'),{statusCode:403});
  await assert.rejects(changeTrade('buyer','chat','receive'),{statusCode:409});
  await changeTrade('seller','chat','sell');
  await changeTrade('seller','chat','sell');
  assert.equal(messages.length,1);
  await assert.rejects(changeTrade('seller','chat2','sell'),{statusCode:409});
  await assert.rejects(rate('buyer'),{statusCode:409});
  await assert.rejects(changeTrade('seller','chat','receive'),{statusCode:403});
  await changeTrade('buyer','chat','cancel');
  await changeTrade('seller','chat','sell');
  await changeTrade('buyer','chat','receive');
  await changeTrade('buyer','chat','receive');
  assert.equal(listing.status,'SOLD');
  assert.equal(messages.length,4);
  await assert.rejects(changeTrade('seller','chat','cancel'),{statusCode:409});
  await assert.rejects(rate('stranger'),{statusCode:403});
  await assert.rejects(submitReview('buyer','chat',{stars:6}),{statusCode:422});
  await Promise.all([rate('buyer'),rate('seller')]);
  await rate('buyer');
  await assert.rejects(submitReview('buyer','chat',{stars:2}),{statusCode:409});
  assert.deepEqual(reviews.map(r=>[r.authorId,r.recipientId,r.fromSeller]).sort(),[['buyer','seller',false],['seller','buyer',true]]);
});
