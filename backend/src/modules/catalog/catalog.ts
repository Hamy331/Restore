import { readFileSync } from 'node:fs';
import { Router } from 'express';
import { prisma } from '../../lib/prisma.js';
import { AppError } from '../../errors/app-error.js';

export type Unit = { code: string; name: string; level: string; parentCode?: string;
  center?: { latitude: number; longitude: number } };
// The initial administrative coverage is the sample already used by the UI.
export const catalog = JSON.parse(readFileSync(new URL('./catalog.json', import.meta.url), 'utf8')) as {
  categories: {id:string}[]; provinces: Unit[]; wards: Record<string, Unit[]> };

export function coordinates(latitude: unknown, longitude: unknown) {
  if (typeof latitude !== 'number' || typeof longitude !== 'number' || !Number.isFinite(latitude) ||
    !Number.isFinite(longitude) || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    throw new AppError(400, 'INVALID_LOCATION', 'Tọa độ không hợp lệ.', 'location');
  }
  return { latitude, longitude };
}

export function listingLocation(value: unknown) {
  if (value == null) return null;
  if (typeof value !== 'object' || Array.isArray(value)) throw new AppError(400, 'INVALID_LOCATION', 'Địa chỉ không hợp lệ.', 'location');
  const body = value as Record<string, unknown>;
  if (Object.keys(body).some((key) => !['provinceCode','wardCode','streetAddress','latitude','longitude','geoSource'].includes(key))) {
    throw new AppError(400, 'INVALID_LOCATION', 'Địa chỉ chứa trường không được hỗ trợ.', 'location');
  }
  const province = catalog.provinces.find((unit) => unit.code === body.provinceCode);
  const ward = province && catalog.wards[province.code]?.find((unit) => unit.code === body.wardCode);
  const streetAddress = body.streetAddress ?? '';
  if (!province || !ward || typeof streetAddress !== 'string' || streetAddress.trim().length > 200 ||
    !['device','ward_center'].includes(String(body.geoSource ?? 'ward_center'))) {
    throw new AppError(400, 'INVALID_LOCATION', 'Tỉnh/phường hoặc địa chỉ không hợp lệ.', 'location');
  }
  const hasPoint = body.latitude != null || body.longitude != null;
  const point = hasPoint ? coordinates(body.latitude, body.longitude) : ward.center;
  return { provinceCode: province.code, wardCode: ward.code, province, ward,
    streetAddress: streetAddress.trim(), ...point,
    geoSource: hasPoint && body.geoSource === 'device' ? 'device' : 'ward_center' };
}

export function publicLocation(value: unknown) {
  if (!value || typeof value !== 'object') return null;
  const location = value as ReturnType<typeof listingLocation>;
  if (!location) return null;
  return { provinceCode: location.provinceCode, wardCode: location.wardCode,
    province: location.province, ward: location.ward, ...location.ward.center, geoSource: 'ward_center' };
}

export function distanceKm(a: {latitude: number; longitude: number}, b: {latitude: number; longitude: number}) {
  const rad = Math.PI / 180;
  const dLat = (b.latitude-a.latitude)*rad, dLon = (b.longitude-a.longitude)*rad;
  const h = Math.sin(dLat/2)**2 + Math.cos(a.latitude*rad)*Math.cos(b.latitude*rad)*Math.sin(dLon/2)**2;
  return 6371 * 2 * Math.asin(Math.sqrt(Math.min(1,h)));
}

export const catalogRouter = Router();
catalogRouter.get('/categories', async (_req, res, next) => {
  try {
    const categories = await prisma.category.findMany({ orderBy: { name: 'asc' } });
    const order=new Map(catalog.categories.map((item,index)=>[item.id,index]));
    categories.sort((a,b)=>(order.get(a.id)??Number.MAX_SAFE_INTEGER)-(order.get(b.id)??Number.MAX_SAFE_INTEGER));
    res.json({ success: true, data: categories.map((category) => {
      const metadata = category.metadata as Record<string, unknown>;
      return { ...metadata, id: category.id, name: metadata.name ?? category.name,
        description: metadata.description ?? '', attributes: metadata.attributes ?? [] };
    }) });
  } catch (error) { next(error); }
});
catalogRouter.get('/locations/provinces', (_req, res) => res.json({ success: true, data: catalog.provinces, coverage: 'sample' }));
catalogRouter.get('/locations/provinces/:code/wards', (req, res, next) => {
  const wards = catalog.wards[req.params.code];
  if (!wards) return next(new AppError(404, 'LOCATION_NOT_FOUND', 'Chưa có dữ liệu địa chỉ cho tỉnh này.'));
  res.json({ success: true, data: wards, coverage: 'sample' });
});
catalogRouter.get('/locations/reverse-geocode', (req, res, next) => {
  try {
    if(typeof req.query.latitude!=='string' || typeof req.query.longitude!=='string' || !req.query.latitude.trim() || !req.query.longitude.trim()) throw new AppError(400,'INVALID_LOCATION','Cần đủ tọa độ GPS.','location');
    const point = coordinates(Number(req.query.latitude), Number(req.query.longitude));
    const wards = Object.values(catalog.wards).flat().filter((unit) => unit.center);
    const ward = wards.sort((a,b) => distanceKm(point,a.center!)-distanceKm(point,b.center!))[0];
    if (!ward || distanceKm(point,ward.center!) > 30) throw new AppError(404, 'LOCATION_NOT_FOUND', 'GPS nằm ngoài vùng dữ liệu địa chỉ.');
    res.json({ success: true, data: { province: catalog.provinces.find((unit) => unit.code === ward.parentCode), ward }, coverage: 'sample' });
  } catch (error) { next(error); }
});
catalogRouter.get('/home/area', (_req, res) => res.json({ success: true, data: { name: 'Toàn quốc' } }));
catalogRouter.get('/home/banners', (_req, res) => res.json({ success: true, data: [] }));
