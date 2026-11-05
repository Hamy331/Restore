import { Response, NextFunction } from 'express';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import * as service from '../services/feed.service.js';

export async function listPosts(r: AuthRequest, res: Response, next: NextFunction) {
  try {
    const data = await service.listPosts(r.user!.userId, r.query);
    res.status(200).json({ success: true, data });
  } catch (error) { next(error); }
}

export async function createPost(r: AuthRequest, res: Response, next: NextFunction) {
  try {
    const data = await service.createPost(r.user!.userId, r.body);
    res.status(201).json({ success: true, data });
  } catch (error) { next(error); }
}

export async function deletePost(r: AuthRequest, res: Response, next: NextFunction) {
  try {
    const data = await service.deletePost(r.user!.userId, r.params.id as string);
    res.status(200).json({ success: true, data });
  } catch (error) { next(error); }
}

export async function listComments(r: AuthRequest, res: Response, next: NextFunction) {
  try {
    const data = await service.listComments(r.user!.userId, r.params.id as string, r.query);
    res.status(200).json({ success: true, data });
  } catch (error) { next(error); }
}

export async function createComment(r: AuthRequest, res: Response, next: NextFunction) {
  try {
    const data = await service.createComment(r.user!.userId, r.params.id as string, r.body);
    res.status(201).json({ success: true, data });
  } catch (error) { next(error); }
}

export async function likePost(r: AuthRequest, res: Response, next: NextFunction) {
  try {
    const data = await service.likePost(r.user!.userId, r.params.id as string, true);
    res.status(200).json({ success: true, data });
  } catch (error) { next(error); }
}

export async function unlikePost(r: AuthRequest, res: Response, next: NextFunction) {
  try {
    const data = await service.likePost(r.user!.userId, r.params.id as string, false);
    res.status(200).json({ success: true, data });
  } catch (error) { next(error); }
}

export async function likeComment(r: AuthRequest, res: Response, next: NextFunction) {
  try {
    const data = await service.likeComment(r.user!.userId, r.params.id as string, true);
    res.status(200).json({ success: true, data });
  } catch (error) { next(error); }
}

export async function unlikeComment(r: AuthRequest, res: Response, next: NextFunction) {
  try {
    const data = await service.likeComment(r.user!.userId, r.params.id as string, false);
    res.status(200).json({ success: true, data });
  } catch (error) { next(error); }
}
