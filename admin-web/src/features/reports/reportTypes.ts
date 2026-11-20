export type ReasonConfig = {
  code: string;
  labelVi: string;
  labelEn: string;
  requiresDescription: boolean;
  guidanceVi: string | null;
  guidanceEn: string | null;
  active: boolean;
  sortOrder: number;
  updatedAt: string;
};

export type ReportGroup = {
  targetType: 'LISTING' | 'USER' | 'FEED_POST';
  targetId: string;
  reportCount: number;
  oldestAt: string;
  latestAt: string;
  reasons: { code: string | null; label: string; count: number }[];
  listing: { id: string; title: string; status: string } | null;
};

export type GroupPage = {
  items: ReportGroup[]; total: number; reportCount: number; page: number; limit: number; asOf: string;
};
