import express, { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { requirePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import { knowledgeSearchQuery, knowledgeUploadBody, knowledgeUploadQuery } from '../content.validator.js';
import * as knowledgeController from '../controllers/knowledge.controller.js';

/** Tài liệu kiến thức (trợ lý tra cứu), gắn tại /api/v1/content */
const knowledgeRouter = Router();

/**
 * Tìm tối đa 5 tài liệu chứa đủ các từ khóa (không phân biệt dấu)
 *
 * Query params:
 *  - q: string (2-100)
 *
 * Trả về: { mode: 'lexical', documents: [{ id, title, content, syncedAt }] }
 */
knowledgeRouter.get('/knowledge/search', validate({ query: knowledgeSearchQuery }), knowledgeController.search);

/**
 * Tải lên tài liệu văn bản, ghi AdminAudit
 *
 * Header: Content-Type: text/plain | text/markdown (tối đa 100 KB), body là nội dung
 *
 * Query params:
 *  - title: string (3-160)
 */
knowledgeRouter.post(
  '/knowledge/upload',
  requirePermission(PERMISSION.CONTENT_MANAGE),
  express.text({ type: ['text/plain', 'text/markdown'], limit: '100kb' }),
  validate({ query: knowledgeUploadQuery, body: knowledgeUploadBody }),
  knowledgeController.upload,
);

export default knowledgeRouter;
