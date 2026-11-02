import type { Unit } from './catalog.type.js';

/*
 * Đơn vị hành chính (mẫu): tỉnh/thành và phường/xã có tọa độ tâm.
 * Dữ liệu tĩnh, đọc lúc chạy (không lưu DB). Phủ toàn quốc sẽ thay file này.
 */

export const PROVINCES: readonly Unit[] = [
  {
    "code": "79",
    "name": "TP. Hồ Chí Minh",
    "level": "province"
  },
  {
    "code": "01",
    "name": "TP. Hà Nội",
    "level": "province"
  },
  {
    "code": "48",
    "name": "TP. Đà Nẵng",
    "level": "province"
  },
  {
    "code": "31",
    "name": "TP. Hải Phòng",
    "level": "province"
  },
  {
    "code": "92",
    "name": "TP. Cần Thơ",
    "level": "province"
  },
  {
    "code": "46",
    "name": "TP. Huế",
    "level": "province"
  }
];

/** Phường/xã theo mã tỉnh */
export const WARDS: Readonly<Record<string, readonly Unit[]>> = {
  "79": [
    {
      "code": "79-SG",
      "name": "Phường Sài Gòn",
      "level": "ward",
      "parentCode": "79",
      "center": {
        "latitude": 10.7769,
        "longitude": 106.7009
      }
    },
    {
      "code": "79-BT",
      "name": "Phường Bến Thành",
      "level": "ward",
      "parentCode": "79",
      "center": {
        "latitude": 10.7725,
        "longitude": 106.698
      }
    },
    {
      "code": "79-TD",
      "name": "Phường Tân Định",
      "level": "ward",
      "parentCode": "79",
      "center": {
        "latitude": 10.7905,
        "longitude": 106.6897
      }
    },
    {
      "code": "79-BC",
      "name": "Phường Bàn Cờ",
      "level": "ward",
      "parentCode": "79",
      "center": {
        "latitude": 10.77,
        "longitude": 106.68
      }
    },
    {
      "code": "79-XH",
      "name": "Phường Xuân Hòa",
      "level": "ward",
      "parentCode": "79",
      "center": {
        "latitude": 10.779,
        "longitude": 106.689
      }
    },
    {
      "code": "79-GV",
      "name": "Phường Gò Vấp",
      "level": "ward",
      "parentCode": "79",
      "center": {
        "latitude": 10.8387,
        "longitude": 106.6653
      }
    },
    {
      "code": "79-AK",
      "name": "Phường An Khánh",
      "level": "ward",
      "parentCode": "79",
      "center": {
        "latitude": 10.788,
        "longitude": 106.731
      }
    },
    {
      "code": "79-THD",
      "name": "Phường Thủ Đức",
      "level": "ward",
      "parentCode": "79",
      "center": {
        "latitude": 10.8494,
        "longitude": 106.7537
      }
    }
  ],
  "01": [
    {
      "code": "01-HK",
      "name": "Phường Hoàn Kiếm",
      "level": "ward",
      "parentCode": "01",
      "center": {
        "latitude": 21.0285,
        "longitude": 105.8542
      }
    },
    {
      "code": "01-CN",
      "name": "Phường Cửa Nam",
      "level": "ward",
      "parentCode": "01",
      "center": {
        "latitude": 21.0245,
        "longitude": 105.8412
      }
    },
    {
      "code": "01-BD",
      "name": "Phường Ba Đình",
      "level": "ward",
      "parentCode": "01",
      "center": {
        "latitude": 21.0368,
        "longitude": 105.8346
      }
    },
    {
      "code": "01-NH",
      "name": "Phường Ngọc Hà",
      "level": "ward",
      "parentCode": "01",
      "center": {
        "latitude": 21.039,
        "longitude": 105.82
      }
    },
    {
      "code": "01-DD",
      "name": "Phường Đống Đa",
      "level": "ward",
      "parentCode": "01",
      "center": {
        "latitude": 21.018,
        "longitude": 105.829
      }
    },
    {
      "code": "01-CG",
      "name": "Phường Cầu Giấy",
      "level": "ward",
      "parentCode": "01",
      "center": {
        "latitude": 21.0333,
        "longitude": 105.794
      }
    },
    {
      "code": "01-HBT",
      "name": "Phường Hai Bà Trưng",
      "level": "ward",
      "parentCode": "01",
      "center": {
        "latitude": 21.009,
        "longitude": 105.858
      }
    }
  ],
  "48": [
    {
      "code": "48-HC",
      "name": "Phường Hải Châu",
      "level": "ward",
      "parentCode": "48",
      "center": {
        "latitude": 16.06,
        "longitude": 108.22
      }
    },
    {
      "code": "48-HCU",
      "name": "Phường Hòa Cường",
      "level": "ward",
      "parentCode": "48",
      "center": {
        "latitude": 16.04,
        "longitude": 108.22
      }
    },
    {
      "code": "48-TK",
      "name": "Phường Thanh Khê",
      "level": "ward",
      "parentCode": "48",
      "center": {
        "latitude": 16.067,
        "longitude": 108.19
      }
    },
    {
      "code": "48-ST",
      "name": "Phường Sơn Trà",
      "level": "ward",
      "parentCode": "48",
      "center": {
        "latitude": 16.086,
        "longitude": 108.244
      }
    },
    {
      "code": "48-NHS",
      "name": "Phường Ngũ Hành Sơn",
      "level": "ward",
      "parentCode": "48",
      "center": {
        "latitude": 16.001,
        "longitude": 108.256
      }
    }
  ],
  "31": [
    {
      "code": "31-HB",
      "name": "Phường Hồng Bàng",
      "level": "ward",
      "parentCode": "31",
      "center": {
        "latitude": 20.865,
        "longitude": 106.683
      }
    },
    {
      "code": "31-LC",
      "name": "Phường Lê Chân",
      "level": "ward",
      "parentCode": "31",
      "center": {
        "latitude": 20.85,
        "longitude": 106.68
      }
    },
    {
      "code": "31-NQ",
      "name": "Phường Ngô Quyền",
      "level": "ward",
      "parentCode": "31",
      "center": {
        "latitude": 20.86,
        "longitude": 106.7
      }
    }
  ],
  "92": [
    {
      "code": "92-NK",
      "name": "Phường Ninh Kiều",
      "level": "ward",
      "parentCode": "92",
      "center": {
        "latitude": 10.034,
        "longitude": 105.788
      }
    },
    {
      "code": "92-CK",
      "name": "Phường Cái Khế",
      "level": "ward",
      "parentCode": "92",
      "center": {
        "latitude": 10.045,
        "longitude": 105.785
      }
    },
    {
      "code": "92-BTH",
      "name": "Phường Bình Thủy",
      "level": "ward",
      "parentCode": "92",
      "center": {
        "latitude": 10.07,
        "longitude": 105.75
      }
    }
  ],
  "46": [
    {
      "code": "46-PX",
      "name": "Phường Phú Xuân",
      "level": "ward",
      "parentCode": "46",
      "center": {
        "latitude": 16.47,
        "longitude": 107.58
      }
    },
    {
      "code": "46-TH",
      "name": "Phường Thuận Hóa",
      "level": "ward",
      "parentCode": "46",
      "center": {
        "latitude": 16.46,
        "longitude": 107.59
      }
    }
  ]
};
