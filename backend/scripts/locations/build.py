"""Sinh dữ liệu tỉnh/phường (34 tỉnh, 3.321 phường/xã) cho backend từ
thanglequoc/vietnamese-provinces-database (elasticsearch/provinces-gis-part-*.ndjson, MIT).
Dùng: python3 scripts/locations/build.py <thư mục chứa gis1..5.ndjson> src/modules/catalog
Tải: https://raw.githubusercontent.com/ThangLeQuoc/vietnamese-provinces-database/master/elasticsearch/provinces-gis-part-0{1..5}.ndjson"""
import json, sys, os, math

src, out = sys.argv[1], sys.argv[2]
TOL = float(os.environ.get('TOL', '0.0006'))

def dp(pts, tol):
    if len(pts) < 3: return pts
    keep = [False]*len(pts); keep[0]=keep[-1]=True
    stack=[(0,len(pts)-1)]
    while stack:
        a,b=stack.pop()
        ax,ay=pts[a]; bx,by=pts[b]; dx,dy=bx-ax,by-ay; L=dx*dx+dy*dy
        best,idx=-1,-1
        for i in range(a+1,b):
            px,py=pts[i]
            if L==0: d=(px-ax)**2+(py-ay)**2
            else:
                t=max(0,min(1,((px-ax)*dx+(py-ay)*dy)/L)); d=(px-ax-t*dx)**2+(py-ay-t*dy)**2
            if d>best: best,idx=d,i
        if best>tol*tol: keep[idx]=True; stack+= [(a,idx),(idx,b)]
    return [p for p,k in zip(pts,keep) if k]

def enc_num(v):
    v = ~(v<<1) if v<0 else (v<<1)
    s=''
    while v>=0x20: s+=chr((0x20|(v&0x1f))+63); v>>=5
    return s+chr(v+63)

def encode(pts):
    s=''; plat=plon=0
    for lon,lat in pts:
        la,lo=round(lat*1e5),round(lon*1e5)
        s+=enc_num(la-plat)+enc_num(lo-plon); plat,plon=la,lo
    return s

def ring_area_centroid(r):
    a=cx=cy=0
    for (x1,y1),(x2,y2) in zip(r,r[1:]+r[:1]):
        c=x1*y2-x2*y1; a+=c; cx+=(x1+x2)*c; cy+=(y1+y2)*c
    if a==0: return 0,r[0]
    return a/2,(cx/(3*a),cy/(3*a))

def inside(pt, rings):
    x,y=pt; c=False
    for r in rings:
        for (x1,y1),(x2,y2) in zip(r,r[1:]+r[:1]):
            if (y1>y)!=(y2>y) and x<(x2-x1)*(y-y1)/(y2-y1)+x1: c=not c
    return c

def center_of(geom, fallback):
    polys=geom['coordinates'] if geom['type']=='MultiPolygon' else [geom['coordinates']]
    best=max(polys,key=lambda p: abs(ring_area_centroid([tuple(q) for q in p[0]])[0]))
    rings=[[tuple(q) for q in r] for r in best]
    _,c=ring_area_centroid(rings[0])
    if inside(c,rings): return c
    fb=(fallback['lon'],fallback['lat'])
    if inside(fb,rings): return fb
    # quét ngang qua tâm bbox, lấy trung điểm đoạn trong dài nhất
    xs=[p[0] for p in rings[0]]; ys=[p[1] for p in rings[0]]
    y=(min(ys)+max(ys))/2; cuts=[]
    for r in rings:
        for (x1,y1),(x2,y2) in zip(r,r[1:]+r[:1]):
            if (y1>y)!=(y2>y): cuts.append(x1+(y-y1)*(x2-x1)/(y2-y1))
    cuts.sort(); seg=max(zip(cuts[::2],cuts[1::2]),key=lambda s:s[1]-s[0])
    return ((seg[0]+seg[1])/2,y)

provinces=[]; wards={}; shapes={}
for i in range(1,6):
    for line in open(os.path.join(src,f'gis{i}.ndjson'),encoding='utf8'):
        d=json.loads(line)
        if 'index' in d: continue
        provinces.append(d)
provinces.sort(key=lambda p:p['Code'])
r6=lambda v: round(v,6)
P=[]; W={}; B={}; npts=0
for p in provinces:
    P.append({'code':p['Code'],'name':p['FullName'],'shortName':p['Name'],'level':'province'})
    ws=[]
    for w in sorted(p['Wards'],key=lambda w:w['Code']):
        g=w['GIS']; c=center_of(g['Geometry'],g['Center'])
        ws.append({'code':w['Code'],'name':w['FullName'],'shortName':w['Name'],'level':'ward','parentCode':p['Code'],
                   'center':{'latitude':r6(c[1]),'longitude':r6(c[0])}})
        bb=g['BoundingBox']
        polys=g['Geometry']['coordinates'] if g['Geometry']['type']=='MultiPolygon' else [g['Geometry']['coordinates']]
        enc=[]
        for poly in polys:
            for ring in poly:
                s=dp([tuple(q) for q in ring[:-1]] if ring[0]==ring[-1] else [tuple(q) for q in ring],TOL)
                if len(s)>=3: enc.append(encode(s)); npts+=len(s)
        B[w['Code']]=[[r6(bb['MinLongitude']),r6(bb['MinLatitude']),r6(bb['MaxLongitude']),r6(bb['MaxLatitude'])],enc]
    W[p['Code']]=ws
os.makedirs(out,exist_ok=True)
hdr="/*\n * Tự sinh bởi scripts/locations/build.py, không sửa tay.\n * Nguồn: thanglequoc/vietnamese-provinces-database v5.2.0 (MIT), theo 39/2026/QH16 và 388/NQ-UBTVQH16.\n"
with open(os.path.join(out,'location.units.ts'),'w',encoding='utf8') as f:
    f.write(hdr+' */\n'+"import type { Unit } from './catalog.type.js';\n\n")
    f.write('/** 34 tỉnh/thành, theo mã */\nexport const PROVINCES: readonly Unit[] = '+json.dumps(P,ensure_ascii=False,separators=(',',':'))+';\n\n')
    f.write('/** Phường/xã/đặc khu theo mã tỉnh, kèm tâm (điểm nằm trong ranh giới) */\nexport const WARDS: Readonly<Record<string, readonly Unit[]>> = '+json.dumps(W,ensure_ascii=False,separators=(',',':'))+';\n')
with open(os.path.join(out,'location.boundaries.ts'),'w',encoding='utf8') as f:
    f.write(hdr+f' * Ranh giới phường/xã đã đơn giản hóa (Douglas-Peucker {TOL} độ), mã hóa polyline (1e-5), [lon,lat].\n */\n')
    f.write('/** Mã phường -> [bbox [minLon, minLat, maxLon, maxLat], các vòng polygon đã mã hóa] */\n')
    f.write('export const WARD_BOUNDARIES: Readonly<Record<string, readonly [readonly number[], readonly string[]]>> = '+json.dumps(B,ensure_ascii=False,separators=(',',':'))+';\n')
print(len(P),sum(len(v) for v in W.values()),'points',npts)
