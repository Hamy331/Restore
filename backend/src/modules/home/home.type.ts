/** Khoảng cách tối đa (km) từ GPS tới tâm phường gần nhất để coi là cùng khu vực */
export const MAX_AREA_DISTANCE_KM = 30;

/** Khu vực mặc định khi không xác định được tỉnh/thành */
export const NATIONWIDE_AREA = { code: null, name: 'Toàn quốc' } as const;
