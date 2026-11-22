/*
 * Chuyển tin của 10 danh mục cũ (phones, electronics, vehicles, fashion, appliances, pets, furniture, books,
 * sports, other) sang cây danh mục 2 cấp (prisma/seed/categories.ts).
 * Dùng cho seed demo/shop (dữ liệu mẫu viết theo danh mục cũ).
 *
 * Danh mục con lấy từ thuộc tính "loại" cũ (device_type, vehicle_type...) và từ khoá trong tiêu đề.
 * Thuộc tính được đổi sang key/giá trị mới; giá trị không hợp lệ với danh mục con mới thì bỏ.
 */
import { effectiveMetadata } from '../../src/modules/catalog/category-tree.js';
import { CATEGORIES } from './categories.js';

type Attributes = Record<string, unknown>;
type Option = { value: string; label?: { vi: string; en: string } };
type Attribute = { key: string; type: string; required?: boolean; options?: Option[]; min?: number; max?: number; maxLength?: number };
type Sub = { id: string; attributes: Attribute[] };

export type LegacyListing = { categoryId: string | null; title: string; attributes: Attributes };
export type MappedListing = {
  categoryId: string; subcategoryId: string; attributes: Attributes;
  /** Thuộc tính cũ bị bỏ vì không còn trong danh mục con mới / giá trị không hợp lệ */
  dropped: string[];
  /** Thuộc tính bắt buộc của danh mục con mới mà tin chưa có (người bán bổ sung khi sửa tin) */
  missing: string[];
};

/** Danh mục cũ → danh mục cha mới (cho gói cửa hàng, cảnh báo tin, danh mục của shop) */
export const LEGACY_PARENT: Record<string, string> = {
  phones: 'electronics', electronics: 'electronics', vehicles: 'vehicles', fashion: 'fashion', appliances: 'appliances',
  pets: 'pets', furniture: 'furniture', books: 'hobbies', sports: 'hobbies', other: 'hobbies',
};

/** Chữ thường, bỏ dấu tiếng Việt, để so từ khoá */
const fold = (input: unknown) => String(input ?? '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
  .replace(/đ/g, 'd');

/** Giá trị đầu tiên có từ khoá xuất hiện trong [text]; rules: [giá trị, ...từ khoá không dấu] */
const guess = (text: string, rules: [string, ...string[]][], fallback?: string) =>
  rules.find(([, ...words]) => words.some((word) => text.includes(word)))?.[0] ?? fallback;

const parentOf = (id: string) => CATEGORIES.find((item) => item.id === id)!;

/** Thuộc tính hiệu lực của danh mục con (cùng quy tắc gộp với lúc đăng tin) */
function schemaOf(categoryId: string, subcategoryId: string): Attribute[] {
  const parent = parentOf(categoryId);
  if (!(parent.subcategories as Sub[]).some((item) => item.id === subcategoryId)) {
    throw new Error(`Không có danh mục con ${categoryId}/${subcategoryId}`);
  }
  return (effectiveMetadata(parent, subcategoryId).attributes ?? []) as Attribute[];
}

/** Giá trị select khớp lựa chọn (theo value hoặc nhãn, không phân biệt dấu/hoa thường) */
function matchOption(attribute: Attribute, value: unknown): string | undefined {
  if (typeof value !== 'string' || !value.trim()) return undefined;
  const target = fold(value.trim());
  const options = attribute.options ?? [];
  return options.find((option) => fold(option.value) === target)?.value
    ?? options.find((option) => option.label && (fold(option.label.vi) === target || fold(option.label.en) === target))?.value
    ?? options.find((option) => option.value !== 'other' && option.label && target.includes(fold(option.label.vi)))?.value;
}

/** Giữ các giá trị hợp lệ với schema mới; select không khớp mà có "other" thì thành other */
function clean(values: Attributes, schema: Attribute[], dropped: string[]) {
  const result: Attributes = {};
  for (const [key, value] of Object.entries(values)) {
    if (value == null || value === '') continue;
    const attribute = schema.find((item) => item.key === key);
    if (!attribute) { dropped.push(key); continue; }
    let next: unknown;
    if (attribute.type === 'select') {
      next = matchOption(attribute, value) ?? (attribute.options?.some((option) => option.value === 'other') ? 'other' : undefined);
    } else if (attribute.type === 'number') {
      const number = typeof value === 'number' ? value : Number(value);
      next = Number.isFinite(number) && (attribute.min == null || number >= attribute.min) &&
        (attribute.max == null || number <= attribute.max) ? number : undefined;
    } else if (attribute.type === 'boolean') {
      next = typeof value === 'boolean' ? value : undefined;
    } else {
      next = typeof value === 'string' ? value.trim().slice(0, attribute.maxLength ?? 200) : undefined;
    }
    if (next === undefined) dropped.push(key); else result[key] = next;
  }
  return result;
}

const bucket = (value: unknown, steps: [number, string][], last: string) => {
  const number = typeof value === 'number' ? value : Number(String(value ?? '').replace(/[^\d.]/g, ''));
  if (!Number.isFinite(number) || number <= 0) return undefined;
  return steps.find(([limit]) => number < limit)?.[1] ?? last;
};

/** Danh mục con + thuộc tính đổi tên cho từng danh mục cũ */
function route(old: string, attributes: Attributes, title: string): { categoryId: string; subcategoryId: string; extra: Attributes; remove: string[] } {
  const a = attributes;
  const go = (categoryId: string, subcategoryId: string, extra: Attributes = {}, remove: string[] = []) =>
    ({ categoryId, subcategoryId, extra, remove });
  switch (old) {
    case 'phones':
      if (title.includes('op lung') || title.includes('cuong luc') || title.includes('cu sac') || title.includes('cap sac')) {
        return go('electronics', 'phu-kien', { accessory_type: 'phone' }, ['storage', 'color', 'origin', 'battery_health']);
      }
      return go('electronics', 'dien-thoai');
    case 'electronics': {
      const type = a.device_type;
      if (type === 'laptop') return go('electronics', 'laptop', {}, ['device_type']);
      if (type === 'tablet') return go('electronics', 'may-tinh-bang', {}, ['device_type']);
      if (type === 'camera') {
        return go('electronics', 'may-anh', { camera_type: guess(title, [['lens', 'ong kinh', 'lens'], ['camcorder', 'may quay']], 'camera') }, ['device_type']);
      }
      if (type === 'smartwatch') {
        return go('electronics', 'thiet-bi-deo', { wearable_type: guess(title, [['band', 'vong tay', 'band']], 'smartwatch') }, ['device_type']);
      }
      if (type === 'gaming') {
        return go('hobbies', 'thiet-bi-game', {
          game_item: guess(title, [['controller', 'tay cam', 'controller'], ['game', 'dia game', 'bang game', 'the game']], 'console'),
          platform: guess(title, [['playstation', 'ps4', 'ps5', 'playstation'], ['xbox', 'xbox'], ['nintendo', 'nintendo', 'switch']]),
        }, ['device_type']);
      }
      if (type === 'audio' || type === 'tv') {
        if (type === 'tv' && title.includes('man hinh')) return go('electronics', 'phu-kien', { accessory_type: 'computer' }, ['device_type']);
        return go('electronics', 'tivi-am-thanh', {
          av_type: type === 'tv' ? 'tv' : guess(title, [['headphone', 'tai nghe', 'airpods', 'headphone'], ['speaker', 'loa'],
            ['amplifier', 'amply'], ['karaoke', 'karaoke'], ['microphone', 'micro']], 'other'),
        }, ['device_type']);
      }
      return go('electronics', 'phu-kien', {
        accessory_type: guess(title, [['computer', 'ban phim', 'chuot', 'man hinh', 'keyboard', 'mouse', 'webcam', 'usb'],
          ['phone', 'op lung', 'sac', 'cap ', 'cuong luc']], 'other'),
      }, ['device_type']);
    }
    case 'vehicles': {
      const type = a.vehicle_type;
      const engine = { engine_size: bucket(a.engine_cc, [[50, 'lt50'], [100, '50_100'], [175, '100_175']], 'gt175') };
      if (type === 'car') return go('vehicles', 'o-to', {}, ['vehicle_type', 'engine_cc']);
      if (type === 'bicycle' || (type === 'ebike' && title.includes('xe dap'))) {
        return go('vehicles', 'xe-dap', { bicycle_type: type === 'ebike' ? 'electric' :
          guess(title, [['kids', 'tre em'], ['sport', 'the thao', 'dia hinh', 'road', 'mtb', 'fixed']], 'city') },
        ['vehicle_type', 'engine_cc', 'year', 'mileage', 'has_papers', 'model']);
      }
      if (type === 'parts') {
        return go('vehicles', 'phu-tung-xe', { part_type: guess(title, [['car', 'o to'], ['motorbike', 'xe may'], ['bicycle', 'xe dap'],
          ['truck', 'xe tai']], 'other') }, ['vehicle_type', 'engine_cc', 'year', 'mileage', 'has_papers', 'model']);
      }
      return go('vehicles', 'xe-may', {
        bike_type: type === 'ebike' ? 'electric' : guess(`${title} ${fold(a.model)}`, [
          ['scooter', 'vision', 'air blade', 'lead', ' sh', 'sh ', 'vespa', 'liberty', 'grande', 'janus', 'nvx', 'pcx', 'click', 'tay ga'],
          ['clutch', 'exciter', 'winner', 'raider', 'satria', 'moto', 'cbr', 'z1000', 'ducati', 'tay con'],
          ['manual', 'wave', 'sirius', 'future', 'jupiter', 'dream', 'blade', 'xe so']]),
        ...engine,
      }, ['vehicle_type', 'engine_cc']);
    }
    case 'fashion': {
      const sub = ({ clothes: 'quan-ao', shoes: 'giay-dep', bags: 'tui-xach', accessories: 'phu-kien-thoi-trang', watch: 'dong-ho' } as
        Record<string, string>)[String(a.product_type)] ?? guess(title, [['nuoc-hoa', 'nuoc hoa'], ['dong-ho', 'dong ho'],
        ['giay-dep', 'giay', 'dep', 'sneaker'], ['tui-xach', 'tui', 'balo', 'vi ']], 'quan-ao')!;
      return go('fashion', sub, {}, ['product_type']);
    }
    case 'appliances': {
      const type = a.appliance_type;
      const volume = bucket(a.capacity, [[150, 'lt150'], [300, '150_300'], [400, '300_400'], [500, '400_500']], 'gte500');
      if (type === 'fridge') return go('appliances', 'tu-lanh', { volume }, ['appliance_type', 'capacity', 'power']);
      if (type === 'washer') return go('appliances', 'may-giat', {}, ['appliance_type', 'capacity', 'power']);
      if (type === 'air_conditioner') return go('appliances', 'may-lanh', {}, ['appliance_type', 'capacity', 'power']);
      if (title.includes('tivi') || title.includes(' tv ')) {
        return go('electronics', 'tivi-am-thanh', { av_type: 'tv' }, ['appliance_type', 'capacity', 'power']);
      }
      if (type === 'water_heater') {
        return go('furniture', 'thiet-bi-ve-sinh', { product_type: 'water_heater' }, ['appliance_type', 'capacity', 'power', 'warranty']);
      }
      if (title.includes('hut bui')) {
        return go('furniture', 'thiet-bi-ve-sinh', { product_type: 'vacuum' }, ['appliance_type', 'capacity', 'power', 'warranty']);
      }
      if (title.includes('quat')) {
        return go('furniture', 'quat', { product_type: guess(title, [['ceiling', 'tran'], ['wall', 'treo tuong'], ['cooler', 'dieu hoa', 'hoi nuoc'],
          ['mini', 'mini', 'sac'], ['box', 'hop'], ['stand', 'dung']], 'other') }, ['appliance_type', 'capacity', 'power', 'warranty']);
      }
      const kitchen = guess(title, [['rice_cooker', 'noi com'], ['air_fryer', 'chien khong dau'], ['microwave', 'vi song'],
        ['oven', 'lo nuong'], ['cooktop', 'bep tu', 'bep dien', 'bep hong ngoai'], ['gas_stove', 'bep gas'], ['blender', 'may xay'],
        ['coffee', 'ca phe', 'cafe', 'espresso'], ['kettle', 'am sieu toc', 'binh dun'], ['water_purifier', 'loc nuoc'], ['hood', 'hut mui']]);
      if (type === 'kitchen' || kitchen) {
        return go('furniture', 'bep-do-dien', { product_type: kitchen ?? 'other' }, ['appliance_type', 'capacity', 'power']);
      }
      return go('furniture', 'gia-dung-khac', {}, ['appliance_type', 'capacity', 'power', 'warranty']);
    }
    case 'pets': {
      const ageGroup = (() => {
        const months = Number(a.age_months);
        if (!Number.isFinite(months) || a.age_months == null || a.age_months === '') return undefined;
        return months < 3 ? 'young' : months < 12 ? 'junior' : 'adult';
      })();
      const common = { age_group: ageGroup };
      const remove = ['pet_type', 'age_months'];
      if (a.pet_type === 'dog') return go('pets', 'cho', common, remove);
      if (a.pet_type === 'cat') return go('pets', 'meo', common, remove);
      if (a.pet_type === 'bird') return go('pets', 'chim', { age_group: ageGroup === 'young' ? 'young' : ageGroup && 'adult' }, remove);
      if (a.pet_type === 'fish') return go('pets', 'thu-cung-khac', { pet_kind: 'fish' }, [...remove, 'breed', 'pet_gender', 'vaccinated']);
      return go('pets', 'phu-kien-thuc-an', { supply_type: guess(title, [['food', 'thuc an', 'hat ', 'pate'], ['cage', 'long', 'chuong', 'be ca']],
        'accessory') }, [...remove, 'breed', 'pet_gender', 'vaccinated']);
    }
    case 'furniture': {
      const type = a.home_type;
      const remove = ['home_type'];
      if (type === 'lighting') {
        return go('furniture', 'den', { product_type: guess(title, [['chandelier', 'chum'], ['pendant', 'den tha'], ['ceiling', 'op tran'],
          ['desk', 'den ban'], ['night', 'den ngu'], ['outdoor', 'ngoai troi'], ['flashlight', 'den pin']], 'decor') }, [...remove, 'material', 'dimensions']);
      }
      if (type === 'kitchenware') {
        return go('furniture', 'dung-cu-bep', { product_type: guess(title, [['pan', 'chao'], ['pot', 'noi'], ['knife', 'dao', 'thot', 'keo'],
          ['dish', 'chen', 'bat', 'dia'], ['glass', 'ly', 'coc'], ['flask', 'giu nhiet'], ['container', 'hop dung']], 'other') },
        [...remove, 'material', 'dimensions']);
      }
      if (type === 'decor') {
        return go('furniture', 'cay-canh-trang-tri', { product_type: guess(title, [['pot', 'chau'], ['indoor_plant', 'cay']], 'indoor_decor') },
          [...remove, 'material', 'dimensions']);
      }
      if (type === 'bedding' || title.includes('giuong') || title.includes('nem')) {
        return go('furniture', 'giuong-nem', { product_type: guess(title, [['mattress', 'nem'], ['bed', 'giuong'], ['pillow', 'goi']], 'bedding') },
          [...remove, 'material', 'dimensions']);
      }
      // So trên chữ còn dấu: bỏ dấu thì "đá" (kính, đá) và "da" (da thuộc) trùng nhau
      const material = guess(String(a.material ?? '').toLowerCase(), [['wood', 'gỗ'], ['plastic', 'nhựa'],
        ['metal', 'sắt', 'inox', 'thép', 'kim loại'], ['glass', 'kính', 'đá'], ['leather', 'da'], ['fabric', 'vải', 'nỉ', 'nệm'],
        ['rattan', 'mây', 'tre']], a.material ? 'other' : undefined);
      if (title.includes('tu ') || title.includes('ke ') || title.startsWith('tu') || title.startsWith('ke')) {
        return go('furniture', 'tu-ke', { material, product_type: guess(title, [['wardrobe', 'quan ao'], ['shoe', 'giay'], ['book', 'sach'],
          ['tv', 'tivi'], ['kitchen', 'bep'], ['bedside', 'dau giuong'], ['display', 'trung bay']], 'other') }, remove);
      }
      return go('furniture', 'ban-ghe', { material, product_type: guess(title, [['sofa', 'sofa'], ['office_chair', 'ghe van phong', 'ghe xoay'],
        ['massage_chair', 'massage'], ['dining_table', 'ban an'], ['desk', 'ban lam viec', 'ban hoc', 'ban may tinh'],
        ['coffee_table', 'ban tra', 'ban cafe', 'ban ca phe', 'ban sofa'], ['stool', 'ghe dau'], ['chair', 'ghe']], 'other') }, remove);
    }
    case 'books':
      if (a.genre === 'stationery') return go('office', 'do-dung-van-phong', { item_type: 'stationery' }, ['genre', 'author', 'quantity']);
      return go('hobbies', 'sach');
    case 'sports':
      if (title.includes('xe dap')) {
        return go('vehicles', 'xe-dap', { bicycle_type: 'sport' }, ['sport_type', 'size']);
      }
      return go('hobbies', 'the-thao-da-ngoai', {
        sport_type: guess(`${title} ${fold(a.sport_type)}`, [['badminton', 'cau long'], ['football', 'bong da', 'giay da bong'],
          ['racket', 'tennis', 'pickleball'], ['swimming', 'boi'], ['golf', 'golf'], ['camping', 'cam trai', 'da ngoai', 'leu', 'trekking'],
          ['fishing', 'cau ca', 'can cau'], ['martial', 'vo ', 'boxing'], ['gym', 'gym', 'ta ', 'yoga', 'fitness', 'chay bo']], 'other'),
      });
    default:
      if (title.includes('may film') || title.includes('may anh')) return go('electronics', 'may-anh', { camera_type: 'camera' });
      if (title.includes('dong ho')) return go('fashion', 'dong-ho');
      if (title.includes('may in')) return go('office', 'do-dung-van-phong', { item_type: 'printer' });
      if (title.includes('dia than') || title.includes('loa ') || title.includes('tai nghe')) {
        return go('electronics', 'tivi-am-thanh', { av_type: 'other' });
      }
      if (title.includes('dan ') || title.includes('guitar') || title.includes('piano')) {
        return go('hobbies', 'nhac-cu', { instrument_type: guess(title, [['guitar', 'guitar'], ['piano', 'piano', 'organ'], ['ukulele', 'ukulele']], 'other') });
      }
      return go('hobbies', 'so-thich-khac');
  }
}

/** Danh mục cha + con và thuộc tính mới cho một tin của danh mục cũ */
export function mapLegacyListing(listing: LegacyListing): MappedListing {
  const old = listing.categoryId ?? 'other';
  const title = ` ${fold(listing.title)} `;
  const { categoryId, subcategoryId, extra, remove } = route(old, listing.attributes ?? {}, title);
  const schema = schemaOf(categoryId, subcategoryId);
  const dropped: string[] = [];
  const source: Attributes = { ...listing.attributes };
  for (const key of remove) delete source[key];
  const attributes = clean({ ...source, ...extra }, schema, dropped);
  const missing = schema.filter((item) => item.required && item.type !== 'boolean' && attributes[item.key] == null).map((item) => item.key);
  return { categoryId, subcategoryId, attributes, dropped, missing };
}
