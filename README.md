# ForgeFlow — AI-Native SDLC Orchestration Platform

> `Connect existing tools. Compose a workflow. Let events execute it. Keep humans in control.`
> Workflow is configuration (YAML), not code.

ForgeFlow is the **control plane** for AI-native software delivery. It connects
existing tools, runs event-triggered workflows, and keeps humans in control via
first-class approvals. It does **not** re-implement issue tracking, git hosting,
CI/CD, AI runtimes, or workflow engines — it orchestrates them.

## What ForgeFlow owns / does not own

**Owns:** project/workflow catalog + immutable versions, run/step state
projection, event routing, plugin/connection/AI-provider config, approvals,
artifact *references*, audit metadata, RBAC.

**Reuses, never rebuilds:** Redmine (issues), GitLab/GitHub (git), CI/CD
(GitLab CI/Actions), AI coding runtime (OpenCode/Factory/Claude/Codex via
adapters), workflow engine (**n8n** default, Temporal optional for
durable/long-running/retries/timers/compensation), broker, docs/KB, vector
DB/RAG, secret manager, monitoring, K8s.

Rule: **never run AI/shell in ForgeFlow server.** Delegate via
`Docker / remote worker / K8s Job / OpenCode env / Factory Droid Computer`.

## Proposed stack

Frontend `React + TypeScript`, backend `Spring Boot`, DB `PostgreSQL`
(metadata only — no blobs), workflows `n8n`, AI via adapters
(`OpenCodeExecutor, FactoryExecutor, ...`), tool protocol `MCP`, events
`webhooks + n8n`, auth `OIDC/OAuth2`, notify `Slack`, artifacts `Git / S3 / MinIO`,
secrets as `vault://…` refs.

No install/dev/test/lint commands are pinned yet. See `AGENTS.md` — when the
stack lands, record the exact order there. `backend/README.md` and
`frontend/README.md` are placeholders until then.

## MVP — one chain only

```text
Redmine webhook (issue.status_changed → ready_for_development)
 → BA agent (opencode) → approval (product_owner)
 → Architect agent (factory) → approval (tech_lead)
 → Developer agent (opencode)
 → QA agent (opencode) → approval (qa_lead)
 → GitLab create_merge_request (+ CI)
```

Executable definition: [`workflows/mvp-feature-development.yaml`](workflows/mvp-feature-development.yaml).
Success = 12 steps run without code change: connect Redmine/GitLab/AI →
create workflow → event → start → agent → wait approval → resume → next
agent → MR → full history.

Step types (MVP): `trigger, agent, action, approval, condition, parallel, wait, notification`.

## Repo layout (init)

```text
workflows/  executable workflow YAML (config, not code) + version pinning
plugins/    plugin manifests — n8n | MCP | HTTP/REST only, no provider logic in core
api/        REST contract (prefix /api/) — OpenAPI stub, source of truth for routes
db/         PostgreSQL DDL — metadata only, artifacts/secrets are references
schemas/    JSON Schema + canonical event example (idempotency via eventId)
docs/       pointers to TDDs, no duplicated prose
frontend/   placeholder (React+TS when stack lands)
backend/    placeholder (Spring Boot when stack lands)
```

## Key invariants (enforced from day one)

- **Workflow immutable once run starts** — runs pin version (run on v2 stays on v2 after v3 exists).
- **Idempotency mandatory** — `eventId / idempotencyKey`. Duplicate webhook
  (e.g. `Event #456`) must not start a 2nd run. See
  [`schemas/event.example.json`](schemas/event.example.json).
- **Approvals first-class:** `PENDING, APPROVED, REJECTED, CHANGES_REQUESTED, EXPIRED`.
  Run: `RUNNING, WAITING_APPROVAL, FAILED, COMPLETED, CANCELLED`.
  Step: `PENDING, RUNNING, WAITING, SUCCESS, FAILED, SKIPPED, CANCELLED`.
- **Artifacts + secrets are references only:** artifact
  `{id, type, runId, stepId, version, location, metadata}` in Git/S3/MinIO;
  secrets as `vault://…`. Never store large blobs in Postgres.
- **Least privilege** per plugin/agent/step + audit
  (`who/what/when/workflow/step/plugin/result`). AI steps get minimum tools only.
- **Plugins only via `n8n | MCP | HTTP/REST`.** Shape:
  `Plugin { Metadata, Connection, Triggers, Actions, Permissions }`.

## REST (prefix `/api/`)

See [`api/openapi.yaml`](api/openapi.yaml) for the contract stub:

- `POST /api/workflows/{id}/runs`, `GET /api/runs/{id}`, `POST /api/runs/{id}/cancel`
- `POST /api/approvals/{id}/approve|reject`, `GET /api/approvals`
- `POST /api/events`, `POST /api/webhooks/{webhookId}`
- `GET /api/plugins`, `POST /api/plugins/{id}/connect`, `GET /api/artifacts/{id}`

No auth/pagination schema decided — check TDDs before adding.

## Design docs (source of truth)

- [ForgeFlow Technical Design Document](https://app.notion.com/p/ForgeFlow-Technical-Design-Document-3ec095e172b6804cb5c5ea4516a4919d)
- [AI-Native SDLC Orchestration Platform](https://app.notion.com/p/AI-Native-SDLC-Orchestration-Platform-3ec095e172b680d3a92be4d10b88d90f)

Further detail: [`docs/architecture.md`](docs/architecture.md).
