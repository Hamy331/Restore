# ReStore AI

## Conversation state and slot filling (2026-11-18)

Deploy additive migration `20261118000000_ai_conversation_state`, regenerate Prisma client and restart backend before using this revision. No reset is needed. This workspace change does not apply migrations to the configured database.

Versioned, bounded state belongs to each AiConversation and commits with its response under the existing lease. Missing/invalid legacy state starts empty; historical messages remain available, but old constraints are not guessed. Retries return the original committed reply. Failed tools, canceled requests and failed commits do not advance state.

Shared dialogue rules support every active category, loading category names and attribute keys/labels from database metadata. Explicit slot corrections replace old values; null removes constraints; attribute updates merge by key. Product switches clear incompatible old constraints. A pending budget question understands short amounts and unlimited/search-now responses. Ordinal choices use the last displayed result order; cheaper requests re-read the selected listing's current price. Switching to quota/policy preserves shopping slots; “tiếp tục tìm” resumes them.

Obvious noise is handled locally. Consecutive unclear turns escalate from clarification to examples and then optional `suggestions` (three quick choices); meaningful input resets the count. Existing rate/ownership limits remain in force. Flutter renders suggestions only on the latest response and uses the normal message endpoint.

Unambiguous contextual replies use deterministic rules without model inference. More complex needs use one schema-validated Gemini JSON extraction with untrusted data and allowed category metadata. Shopping searches then return factual server records directly; details/comparison show actual recorded fields without inferred specifications. Price, brand and category remain exact filters. Other preferences (including area/condition/attributes) are bounded semantic query terms, not guaranteed structured matches; the response explains this limitation. Approved policy/quota prose retains the existing grounding path.

Run dialogue and persistence unit tests plus existing backend/Flutter checks. Real model extraction and natural-language relevance still require live evaluation before rollout. No live model calls or production database migrations are part of the unit suite.

Operational collectors can subscribe to Node's diagnostics channel `restore.ai.dialogue`: completed/failed outcome, elapsed milliseconds, extraction call count, intent, pending question, unclear count and result count. Events contain no user IDs, message bodies, secrets or raw errors; no metrics storage/dashboard is enabled automatically. Cached replays do not repeat a completed event. Existing provider/tool round and timeout limits still apply; the extraction shares the overall 60-second deadline.

## Modules

- `assistant`: authenticated conversations, Gemini function calling, schemas, tool execution, quotas (read-only tools).
- `rag`: document ingestion, chunking, embedding, indexing, retrieval, ranking and source context. Each stage has its own service file.

The assistant sends a separate system instruction, server-owned conversation history and the latest user message to Gemini. Gemini requests allowlisted tools; the server validates arguments and injects the authenticated user ID. Results are returned as function responses, preserving Gemini call IDs and thought signatures. The final answer is plain text; listing cards and source excerpts come from server records.

## Configuration

After deploying `20261108000000_ai_assistant` and `20261108010000_qdrant_rag` to the intended database, configure backend `.env`:

```dotenv
AI_ENABLED=true
GEMINI_API_KEY=<server-side-key>
GEMINI_MODEL=gemini-3.5-flash-lite
GEMINI_EMBEDDING_MODEL=gemini-embedding-2
QDRANT_URL=https://<cluster>.<region>.cloud.qdrant.io:6333
QDRANT_API_KEY=<cluster-read-write-key>
QDRANT_COLLECTION=restore_knowledge_dev_v1
```

Restart the backend. No key is sent to Flutter. Disabled or missing configuration returns `503 AI_NOT_CONFIGURED`, never sample answers.

Use the Qdrant Cloud **Cluster Endpoint** and **Cluster API key**, not a dashboard URL or Cloud account management key. A hostname without a port defaults to the REST port 6333. Only HTTPS Qdrant Cloud endpoints are accepted; there is no local/SQL vector fallback. Use separate collections for dev and production. Collection setup checks 768-dimensional Cosine vectors and creates keyword indexes for the filtering fields; it never recreates an incompatible existing collection.

## Routes (under /api/v1)

| Method | Route | Access |
| --- | --- | --- |
| POST | `/ai/assistant/conversations/:uuid/messages` | User, own conversation |
| GET | `/ai/assistant/conversations` | User, latest 30 own conversations with completed turns |
| GET | `/ai/assistant/conversations/:uuid` | User, own last 10 turns |
| DELETE | `/ai/assistant/conversations/:uuid` | User, own idle conversation |
| POST | `/ai/rag/documents/:id/index` | Content admin |
| GET | `/ai/rag/documents/:id/index` | Content admin, indexing state |
| POST | `/ai/rag/cleanup` | Content admin, retry queued vector deletion |

Send body: `{ "requestId": "<uuid>", "message": "Tìm Samsung dưới 5 triệu" }`. The client generates the conversation UUID. Retries reuse the same request ID and input. Confirm/index bodies are `{}`; edited proposal bodies are rejected. A proposal expires after 10 minutes. Confirmation and draft quota enforcement share one serializable transaction.

## Knowledge workflow

1. Admin creates or updates a KnowledgeDocument using the existing knowledge administration.
2. Admin runs its existing content-index action. Only active, indexed documents are eligible.
3. Call `POST /ai/rag/documents/:id/index` with an admin access token. This creates 768-dimensional embeddings for up to 40 overlapping chunks in Qdrant Cloud. PostgreSQL keeps source text, point IDs and document versions, not new vectors.
4. Query retrieval runs two independent Qdrant prefetches: Gemini dense cosine search and sparse keyword search (`lexical_v1`, local log-TF weights with Qdrant IDF). Vietnamese accents/case are normalized; digits/model codes are retained. Qdrant merges both lists with reciprocal rank fusion (RRF). This is true dense+sparse hybrid retrieval, not keyword reranking of dense candidates. The keyword scorer is TF-IDF, not BM25.
5. Every returned point ID is validated against current, active, indexed PostgreSQL documents before selecting up to five excerpts by fusion rank. Remote payload text is never trusted as source text. The 0.55 cutoff applies only to the dense branch; RRF scores must not be filtered as cosine scores.

Editing, deactivating or deleting a source immediately excludes its old chunks on the next retrieval. Reindex after content/model/tokenizer changes. In-flight answers use the source snapshot read at retrieval time. Each prefetch keeps 200 candidates; at most 200 fused hits are validated in pages of 40. A stale index that prevents finding current candidates returns an explicit error. Thresholds and retrieval quality still need evaluation on a larger approved corpus.

Existing dense collections are upgraded additively with `PUT /collections/:collection/vectors/lexical_v1` (Qdrant 1.18+; verified on Cloud 1.19.2). No collection is deleted. Reindex existing documents to populate their sparse vectors; until then their dense vectors remain available. Token IDs use deterministic 32-bit hashes, with a small collision risk; IDF statistics are collection-wide. Keep dev/prod collections separate. This change covers knowledge retrieval only; listing search continues through the existing listing service and SQL filters.

### Starter knowledge

`backend/knowledge/bootstrap.json` contains three code-derived guides (draft publishing, live quota/unsupported credit actions, product search). They are explicitly labeled starter guides, not an official pricing or credit policy. Review and revise through knowledge administration when business rules change.

From `backend`, `npm run ai:knowledge:bootstrap` previews the manifest without database writes. `npm run ai:knowledge:bootstrap -- --apply --verify` creates missing documents on the configured database, records system audit provenance, indexes them and verifies each expected source ranks first. It does not overwrite edited documents or reactivate disabled ones. Re-running can reindex identical documents. `--verify` alone is read-only apart from provider inference. Never use the general demo seed to populate this knowledge base.

Indexing holds a per-document lease, uploads a new generation with `wait=true`, then publishes its SQL metadata transactionally after rechecking the source version. Failed uploads never replace the current generation. Deleting SQL chunks (including document cascade deletion) queues point IDs in the `AiVectorDeletion` outbox via a database trigger. Successful indexing drains a batch; the backend also runs cleanup every five minutes while AI is enabled. The admin cleanup endpoint can drain further batches while `remaining > 0`. An ambiguous database outage can leave unreferenced vectors; they are not used for answers, but may require later reconciliation. The old SQL embedding column is retained for an additive migration, with empty arrays on new records; reindex existing documents before retiring legacy data.

## Limits and guardrails

- 2,000 input characters, recent complete turns within 24,000 serialized characters, four model rounds, six tool calls, 60-second model/tool deadline.
- 20 accepted attempts per user per 10-minute window; 100 per UTC calendar day. Database transactions enforce counters across instances. Failed attempts count; completed retries do not.
- At most five completed requests in the preceding ten seconds across the user's conversations. Noisy/local refusals also count; rapid requests return 429 before provider inference. Local clarification/refusal still checks ownership, lease and quota, then persists a safe reply without invoking Gemini.
- Read tools expose available listings owned by active users, limited public details, the caller's quota and eligible documents. No arbitrary SQL, external URL fetch, admin tools, money movement or publish tool.
AI does not create or save listing drafts. Users create drafts through the existing listing flow.
- Prompt injection instructions in content cannot grant new tools or identity. The prompt also restricts scope and unsupported claims, but answer correctness still needs live evaluation.
- Input rules handle obvious keyboard noise/repetition/emoji, unrelated writing requests, direct injection and requests for another account. They clarify vague phone/laptop shopping and preserve contextual follow-ups. Unknown words, short product codes and typos are not automatically blocked.
- Current question (and recent context for short follow-ups) determines the required tools. A factual answer without fresh successful evidence, including empty retrieval, becomes an insufficient-data response. Model tool names, arguments and scope are checked before execution; retrieved instructions cannot add tools or user identity.
- Final answers pass exact amount/number, listing-ID, URL and source-ID checks. Policy answers require `[nguồn:id]` citations. A second Gemini request, with no tools, checks all claims against current tool results; it gets up to ten seconds within the existing overall deadline. Invalid/unsupported/unavailable verdicts fall back to returned listing fields, quota values or source excerpts. This adds up to one inference request per factual answer, not another quota-counted user turn. Model verification and heuristic injection screening reduce risk, not guarantee semantic correctness.
- Common secrets, configured backend credentials, labeled OTP/identity/account details, email and Vietnamese phone patterns are redacted before storage and provider calls; historical API responses are sanitized on read. Arbitrary unlabeled private prose is not reliably detected. Logs omit query strings and raw exception objects. Previously stored database content is not retroactively migrated.
- Flutter opens a fresh conversation on entry. The history button reopens a saved conversation with its last 10 turns. Starting over preserves the previous conversation. DELETE removes an idle conversation.
- Do not log chat bodies, API keys or upstream error bodies. Existing request logs contain method/path/status only.

## Verification

`npm run build`, `npm test`, `npm run test:api` (only with disposable local `TEST_DATABASE_URL`), and Flutter analyze/tests.

With `AI_LIVE_EVAL=true`, `npm run ai:qdrant:check` initializes the configured collection if needed, obtains one real Gemini embedding, upserts/searches a uniquely tagged smoke point and removes that exact point in `finally`. It does not read or write application database records. Failed cleanup reports the point ID for later removal.

`npm run ai:rag:eval` tests real embedding/indexing/retrieval and inactive-source exclusion. It also requires `AI_LIVE_EVAL=true` and `TEST_DATABASE_URL` restricted to a seeded disposable **local** PostgreSQL database. Source text never enters Supabase; test Cloud vectors and local source records are removed afterward. `npm run ai:qdrant:check` also verifies independent keyword recovery with a deliberately opposite dense vector and exclusion of an unrelated query; test points are removed afterward.

`AI_LIVE_EVAL=true npm run ai:eval` is an explicit paid evaluation against configured Gemini. In PowerShell set `$env:AI_LIVE_EVAL='true'` and `$env:AI_ENABLED='true'` first. Seven Vietnamese cases cover tool choice, VND amounts, follow-up context, quota, policy retrieval, read-only listing assistance and injection/unsupported credit actions. `AI_EVAL_INTERVAL_MS` spaces provider requests (default 20 seconds) to avoid exhausting low development quotas. Tools use test fixtures; no production DB reads or writes. This is not a full RAG benchmark: evaluate retrieval against real approved documents and manually review citation support, latency and token costs before rollout.

Not included: image understanding/upload, credit/payment integration, Redis, automatic conversation retention. Vector storage is Qdrant Cloud, as requested; pgvector is no longer planned.

## Listing hybrid search

Deploy migration `20261108020000_ai_listing_search` before starting the new backend. `search_listings` now searches a separate Qdrant collection using the same dense+sparse RRF pipeline. Set `QDRANT_LISTING_COLLECTION` or use the default `<QDRANT_COLLECTION>_listings`; it must differ from the knowledge collection. Semantic query, VND price range, category and brand are separate tool arguments. Price/category filters run in Qdrant and are rechecked in SQL; brand is checked against the current attribute (title fallback only when no brand attribute exists). Only AVAILABLE listings owned by ACTIVE accounts may be returned.

`npm run ai:listings:index -- --all` indexes the pending public catalog. The backend job then checks every `AI_LISTING_INDEX_INTERVAL_MS` (default 60000), up to `AI_LISTING_INDEX_BATCH_SIZE` items per batch (default 10). Set these in the environment to fit embedding quotas. Indexing is asynchronous: a new/changed listing may be absent until the next successful batch. Search returns a bounded candidate set, not a total catalog count. There is no fabricated fallback when the provider is unavailable.

SQL keeps the current point ID and source hash. Triggers invalidate/queue old vectors when searchable listing fields change, and on deletion; view-count updates do not re-embed unchanged content. The indexer rechecks the source in a serializable transaction after Qdrant acknowledges writes. Search rechecks SQL visibility, filters and hash, so stale cloud hits cannot expose hidden/changed/deleted listings. Background cleanup removes queued vectors. Concurrent indexers may duplicate embedding work but only SQL-published points are eligible. A database outage at ambiguous commit can leave unreferenced cloud points requiring reconciliation.

Code is split into listing-source helpers, listing-index repository, vector adapter, index service, search service and a scheduled job. Shared technical search bounds live in `ai.config.ts`; business prices and quotas come from SQL. Search text does not include the location/account objects. Public listing descriptions themselves remain untrusted model input.

`AI_LIVE_EVAL=true npm run ai:listings:check` checks real public listing retrieval with exact SQL filters, then a real streamed Gemini tool roundtrip. It creates no user conversation or draft. Local API tests separately cover stale price, brand/category, banned owners, hidden/deleted listings, unchanged-view indexing and failed writes. These are correctness checks; they do not replace a larger natural-language relevance benchmark.

## Streaming

POST `/ai/assistant/conversations/:id/messages/stream` accepts the same message/request ID as the JSON endpoint. SSE data frames contain `status` and `reset`, then either `done` with the checked, committed reply or `error` with a safe message. Unverified text deltas are buffered on the backend and are never sent to the client. Status names are server-controlled; the UI maps them through English/Vietnamese localization.

Gemini uses its native `streamGenerateContent` SSE endpoint; its text is held until validation finishes. Source/listing cards and the approved answer are delivered in `done`, after the response transaction commits. A partial or interrupted answer is discarded by Flutter and can be retried with the same request ID. A committed replay returns `done` without calling Gemini or consuming quota again. Client disconnect cancels in-flight provider work; model/tool budgets and ownership checks are retained.

Flutter uses Dio with the existing token refresh interceptors. A conditional Fetch adapter handles only the AI SSE route on web; other requests keep their existing adapter. This avoids XMLHttpRequest buffering. Native platforms use the normal Dio stream adapter. Proxies must allow streamed responses without buffering; the endpoint sends `X-Accel-Buffering: no` and no-cache headers.

Provider references: [function calling](https://ai.google.dev/gemini-api/docs/function-calling), [embeddings](https://ai.google.dev/gemini-api/docs/embeddings), [Gemini 3.5 Flash-Lite](https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite).
