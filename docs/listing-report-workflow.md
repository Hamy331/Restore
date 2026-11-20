# Listing reports

The listing detail action opens a scrollable sheet with single-choice reasons loaded from the
ReportReason database catalog, phone and email. There is no description field, guidance paragraph
or privacy paragraph in the form. Contact values start from the signed-in profile and can be
edited for this report. They are not written back to the profile. The form uses Vietnamese/English
localization, fits all eight reasons and both fields on screen without vertical scrolling,
keeps contact fields and the submit action visible while typing, prevents repeated taps while submitting,
retains entries after errors and closes immediately when the user chooses to close (no discard confirmation).

## API and moderation

`POST /api/v1/content/reports` accepts `targetType: LISTING`, `targetId`, `reasonCode`, `evidence`,
`contactPhone` and `contactEmail`. Server-owned reason labels are persisted for existing admin clients.
Contacts are validated and normalized. Existing free-text requests from older clients and feed reports
retain their validation rules; contact fields require the structured listing format.

The existing authenticated serializable report transaction prevents self-reports and a second OPEN
report by the same reporter against the same target. An uncertain network result is not reported as
success; resubmission can return REPORT_EXISTS if the earlier request committed.

Admin report details display the supplied contacts. Report lookup remains limited to its reporter
or authorized moderation staff. A report does not automatically remove a listing. Existing review
decisions are KEEP, REMOVE and DISMISS; moderation and report resolution remain transactional and
version checked. A damage report is not an order/refund request.

## Deployment

Apply additive migrations `20261118010000_report_contact_fields` and
`20261118020000_report_reason_catalog` and `20261118030000_report_form_without_description`
to the intended database, then run
`prisma generate` and restart the backend before releasing the updated form. Review all pending
migrations first. This change does not deploy migrations to the shared database.

The three new nullable columns keep existing reports readable. Existing content API snapshots include
null fields for legacy reports. New API assertions cover structured submission, duplicate rejection and
reporter isolation. Run database integration tests only with a disposable local TEST_DATABASE_URL.

## Admin grouping and shared reasons

`GET /admin/report-groups` aggregates matching reports by (targetType, targetId) before pagination.
It returns counts, reason summaries, oldest/latest timestamps, listing titles, total groups and a
server-owned `asOf` timestamp. Reports on deleted targets remain accessible. Users and feed posts
are separate target types even when their identifiers equal a listing ID.

Both `/admin/report-groups` and `/admin/reports` accept status, targetType, targetId, reasonCode,
uncategorized, minWaitHours, maxWaitHours, sort, page and limit. Wait bounds are inclusive and only
apply to OPEN reports. Group drill-down reuses the server `asOf` so time boundaries and newly
arriving reports do not change the matching set between the group query and its details. Refresh
gets a new timestamp. Counts explicitly represent reports matching the current filters.

`GET /content/reports/reasons` returns active reasons; `GET /admin/report-reasons` supplies filters.
The agreed eight reasons are stored once in the database. Each reason has stable
code, Vietnamese/English labels, guidance, description requirement, order and active state.
The migration seeds exactly the eight agreed choices; application code does not duplicate their codes.
There is no admin catalog editor or create/update endpoint. Historical report labels are preserved.

Submission rechecks the active reason inside the report transaction. Structured listing reports
accept empty evidence for every reason, matching the form that contains no description input.
If choices change while a form is open, Flutter reloads them and keeps the contact entries.
If the catalog is unavailable or empty, the form does not invent fallback choices.

## Follow-up ideas (not implemented here)

- Add a user report history with receipt ID, status, resolution and an in-app outcome notification.
- Add private screenshot evidence with upload limits, access checks and deletion/retention rules.
- Add a per-account submission rate limit across different targets and operational monitoring.
- Preserve a bounded listing snapshot when submitted, so edits do not remove moderation context.
- Add follow-up questions through support tickets for incomplete reports; avoid collecting contact
  details in public comments or exposing a reporter's identity to the reported seller.
- Evaluate abuse signals and appeals before introducing any automatic sanctions; report volume alone
  must not be treated as proof of a violation.
