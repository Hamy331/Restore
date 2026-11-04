import { WARD_BOUNDARIES } from './location.boundaries.js';
import type { Coordinates } from './catalog.type.js';

/** Một phường đã giải mã: bbox [minLon, minLat, maxLon, maxLat] và các vòng [lon, lat][] */
type WardShape = { code: string; bbox: readonly number[]; rings: Float64Array[] };

let shapes: WardShape[] | undefined;

/** Giải mã polyline (độ chính xác 1e-5) thành mảng phẳng [lon0, lat0, lon1, lat1, ...] */
function decode(encoded: string) {
  const out: number[] = [];
  let index = 0, lat = 0, lon = 0;
  const next = () => {
    let result = 0, shift = 0, byte: number;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    return result & 1 ? ~(result >> 1) : result >> 1;
  };
  while (index < encoded.length) {
    lat += next();
    lon += next();
    out.push(lon / 1e5, lat / 1e5);
  }
  return Float64Array.from(out);
}

/** Giải mã ranh giới một lần, lần gọi đầu (khoảng 380 nghìn điểm) */
function wardShapes() {
  shapes ??= Object.entries(WARD_BOUNDARIES).map(([code, [bbox, rings]]) => ({ code, bbox, rings: rings.map(decode) }));
  return shapes;
}

/** Điểm trong polygon (quy tắc chẵn lẻ trên mọi vòng, nên lỗ thủng được tính đúng) */
function contains(shape: WardShape, x: number, y: number) {
  let inside = false;
  for (const ring of shape.rings) {
    for (let i = 0, j = ring.length - 2; i < ring.length; j = i, i += 2) {
      const xi = ring[i]!, yi = ring[i + 1]!, xj = ring[j]!, yj = ring[j + 1]!;
      if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
    }
  }
  return inside;
}

/** Mã phường có ranh giới chứa điểm GPS, undefined nếu không phường nào chứa */
export function wardCodeAt(point: Coordinates) {
  const { longitude: x, latitude: y } = point;
  return wardShapes().find((shape) => {
    const [minX, minY, maxX, maxY] = shape.bbox as [number, number, number, number];
    return x >= minX && x <= maxX && y >= minY && y <= maxY && contains(shape, x, y);
  })?.code;
}
