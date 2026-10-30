import { prisma } from './prisma.js';

// Conditional updates cannot accidentally lift a ban applied after the expiry scan.
export async function releaseExpiredSuspensions(userId?: string) {
  return prisma.$transaction(async tx=>{
    const expired=await tx.user.findMany({where:{...(userId?{id:userId}:{}),status:'SUSPENDED',suspendedUntil:{lte:new Date()}},select:{id:true},take:100});
    let count=0;
    for(const user of expired){
      const changed=await tx.user.updateMany({where:{id:user.id,status:'SUSPENDED',suspendedUntil:{lte:new Date()}},data:{status:'ACTIVE',suspendedUntil:null}});
      if(changed.count){count++;await tx.adminAudit.create({data:{actorId:'SYSTEM',action:'SUSPENSION_EXPIRED',targetType:'USER',targetId:user.id,reason:'Hết thời hạn đình chỉ',before:{status:'SUSPENDED'},after:{status:'ACTIVE'}}});}
    }
    return {count};
  });
}
