import { listReasons } from '../repositories/report.repository.js';

/** Shared catalog for the listing form and admin filters. No catalog management endpoints. */
export const list = async (all = false) => ({ items: await listReasons(all) });
