# Assistant foundation

Backend provider and conversation storage only. This release does not mount assistant routes, start indexing jobs or enable the chatbot UI.

Configure server-only `AI_ENABLED` and `GEMINI_API_KEY`; optional model settings are in `.env.example`. The provider supports bounded text/tool responses, native SSE parsing and validated 768-dimensional embeddings. Missing configuration fails explicitly. Sensitive strings are redacted before provider calls and persistence.

Storage checks authenticated ownership, serializes quotas, leases one in-flight request per conversation, and commits completed turns with their response. Retries reuse a request ID and identical redacted input. Limits: 20 accepted attempts per ten minutes, 100 per UTC day, five completed requests per ten seconds across conversations. Accepted failed attempts count; busy/foreign conversations are rejected first.

Apply `20261108000000_ai_assistant` using migration deploy and generate the Prisma client before building. No reset or seed is required. The original migration also reserves action and knowledge-chunk tables for compatibility with databases where it was already deployed. No draft-creation capability or retrieval pipeline is exposed. Later migrations are outside this release.

Verification: build, unit tests and Prisma schema validation. Tests use mocked provider responses and isolated transaction adapters, with no live Gemini or database calls. API wiring, search/RAG, orchestration, state/slot filling and Flutter integration follow separately.
