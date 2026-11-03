# Feed API

Apply with `npx prisma migrate deploy` then `npx prisma generate` from backend.
No existing tables are reset. Tables use RLS without public policies; Express must use a privileged backend database connection.

Set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET in backend environment. Upload responds 503 when missing. Existing listing uploads are local and tied to listing IDs, so feed uploads use Cloudinary separately.

All routes require Bearer authentication and use `{success:true,data:...}`.
- GET /api/v1/feeds: tab=for-you|following, limit=1..50 (default 20), cursor opaque. Newest first, createdAt + id descending. Returns {items,nextCursor}.
- POST /api/v1/feeds: {text,imageUrl?,listingId?}. Text <=2000 characters; text or uploaded image required. Returns created post, HTTP 201.
- PUT/DELETE /api/v1/feeds/:id/like: returns {likedByMe,likeCount}; duplicate PUT does not duplicate likes.
- GET /api/v1/feeds/:id/comments: limit/cursor; oldest first, createdAt + id ascending. Returns {items,nextCursor}.
- POST /api/v1/feeds/:id/comments: {text}, nonempty <=2000. Returns created comment, HTTP 201.
- PUT/DELETE /api/v1/feed-comments/:id/like: returns {likedByMe,likeCount}.
- POST /api/v1/media/images: raw JPEG/PNG/WebP bytes, Content-Type image/jpeg|image/png|image/webp, <=5MB. Returns {imageUrl}, HTTP 201.

Feed items contain id,text,imageUrl,createdAt,author:{id,fullName,avatarUrl},isMine,isFollowingAuthor,likedByMe,likeCount,commentCount,listing:{id,title,price,imageUrl}|null.
Comment items contain id,postId,text,createdAt,author,likedByMe,likeCount.
Posts/comments from non-ACTIVE authors are excluded. Missing/unavailable posts/comments return 404. Listing cards become null when listing is unavailable or seller inactive. Follow uses existing /users/:id/follow endpoints.

Validation and authentication tests do not use a database. Database persistence/concurrency and Cloudinary require a configured isolated integration environment.
