# Feed API

Apply with `npx prisma migrate deploy` then `npx prisma generate` from backend.
No existing tables are reset. Tables use RLS without public policies; Express must use a privileged backend database connection.

Images go through `modules/media` and `services/storage.service.ts` like listing photos: `STORAGE_DRIVER=disk` (default, `uploads/`) or `supabase` (private bucket `SUPABASE_STORAGE_BUCKET`, default `media`). Feed photos use area `feeds`, avatars use `avatars`; files are named `<userId>_<uuid>.<ext>` and served by `GET /api/v1/media/<area>/<name>`. Posts only accept `imageUrl` values under `/api/v1/media/feeds/`.

All routes require Bearer authentication and use `{success:true,data:...}`.
- GET /api/v1/feeds: tab=for-you|following, limit=1..50 (default 20), cursor opaque. Newest first, createdAt + id descending. Returns {items,nextCursor}.
- POST /api/v1/feeds: {text,imageUrl?,listingId?}. Text <=2000 characters; text or uploaded image required. Returns created post, HTTP 201.
- PUT/DELETE /api/v1/feeds/:id/like: returns {likedByMe,likeCount}; duplicate PUT does not duplicate likes.
- GET /api/v1/feeds/:id/comments: limit/cursor; oldest first, createdAt + id ascending. Returns {items,nextCursor}.
- POST /api/v1/feeds/:id/comments: {text}, nonempty <=2000. Returns created comment, HTTP 201.
- PUT/DELETE /api/v1/feed-comments/:id/like: returns {likedByMe,likeCount}.
- DELETE /api/v1/feeds/:id: author only (403 otherwise). GET /api/v1/feeds also accepts authorId=<uuid>.
- POST /api/v1/media/images?purpose=feed|avatar: raw JPEG/PNG/WebP bytes, Content-Type image/jpeg|image/png|image/webp, <=5MB. Returns {imageUrl} (relative `/api/v1/media/...` path), HTTP 201. GET /api/v1/media/:area/:name returns the file without auth.

Feed items contain id,text,imageUrl,createdAt,author:{id,fullName,avatarUrl},isMine,isFollowingAuthor,likedByMe,likeCount,commentCount,listing:{id,title,price,imageUrl}|null.
Comment items contain id,postId,text,createdAt,author,likedByMe,likeCount.
Posts/comments from non-ACTIVE authors are excluded. Missing/unavailable posts/comments return 404. Listing cards become null when listing is unavailable or seller inactive. Follow uses existing /users/:id/follow endpoints.

Validation and authentication tests do not use a database. Database persistence/concurrency and the Supabase storage driver require a configured isolated integration environment.
