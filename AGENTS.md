# AGENTS.md — ForgeFlow (ai-native-sdlc-platform)

> Control plane for AI-native SDLC. Connects tools, runs event-triggered workflows with human gates. Repo is greenfield (only this file as of 2026-10-01) — TDDs below are the only source of truth until manifests land.

- TDDs: [ForgeFlow Technical Design Document](https://app.notion.com/p/ForgeFlow-Technical-Design-Document-3ec095e172b6804cb5c5ea4516a4919d), [AI-Native SDLC Orchestration Platform](https://app.notion.com/p/AI-Native-SDLC-Orchestration-Platform-3ec095e172b680d3a92be4d10b88d90f)

## Do / do not build

- `Connect existing tools. Compose a workflow. Let events execute it. Keep humans in control.` Workflow is configuration (YAML), not code.
- Owns: project/workflow catalog + versions, run/step state projection, event routing, plugin/connection/AI-provider config, approvals, artifact *references*, audit metadata, RBAC.
- Does NOT own — reuse, never rebuild: issue tracking (Redmine), git hosting (GitLab/GitHub), CI/CD, AI coding runtime (OpenCode/Factory/Claude/Codex), workflow engine (n8n default, Temporal optional), broker, docs/KB, vector DB/RAG, secret manager, monitoring, K8s.
- No dev/test/lint commands in repo or TDDs yet. Do not assume npm/maven/gradle. When stack lands, record exact install/dev/single-test/lint/typecheck order here.

## Proposed stack (from TDD §55 — not in repo yet, replaceable)

- Frontend `React + TypeScript`, backend `Spring Boot`, DB `PostgreSQL`, workflows `n8n` (Temporal only for durable/long-running/retries/timers/compensation), AI via adapters (`OpenCodeExecutor, FactoryExecutor, ...`), tool protocol `MCP`, events `webhooks + n8n`, auth `OIDC/OAuth2`, notify `Slack`, artifacts `Git / S3 / MinIO`.

## Rules agents get wrong

- Never run AI/shell in ForgeFlow server. Delegate via `Docker / remote worker / K8s Job / OpenCode env / Factory Droid Computer`.
- Plugins only via `n8n | MCP | HTTP/REST`. Shape: `Plugin { Metadata, Connection, Triggers, Actions, Permissions }`. No provider-specific logic in core; swap providers without changing workflow.
- Workflow immutable once run starts — runs pin version (run on v2 stays on v2 after v3 exists).
- Idempotency mandatory: `eventId / idempotencyKey`. Duplicate webhook (e.g. `Event #456`) must not start a 2nd run.
- Approvals are first-class: `PENDING, APPROVED, REJECTED, CHANGES_REQUESTED, EXPIRED`. Run: `RUNNING, WAITING_APPROVAL, FAILED, COMPLETED, CANCELLED`. Step: `PENDING, RUNNING, WAITING, SUCCESS, FAILED, SKIPPED, CANCELLED`.
- Artifacts + secrets are references only: artifact ` {id, type, runId, stepId, version, location, metadata}` in Git/S3/MinIO/etc; secrets as `vault://…` refs. Never store large blobs in Postgres.
- Least privilege per plugin/agent/step + audit (who/what/when/workflow/step/plugin/result). AI steps get minimum tools only.
- MVP scope is one chain only: `Redmine webhook → BA → approval → Architect → approval → Developer → QA → approval → GitLab MR`. Step types: `trigger, agent, action, approval, condition, parallel, wait, notification`.
- REST prefix `/api/` (e.g. `POST /api/workflows/{id}/runs`, `GET /api/runs/{id}`, `POST /api/approvals/{id}/approve|reject`, `POST /api/events`, `POST /api/webhooks/{webhookId}`). No auth/pagination schema decided — check TDDs before adding.

## Working rules

- Read repo root + manifests before changing; prefer executable config over prose. Smallest change; don't introduce monorepo tooling/deps without direction.
- Never commit secrets. Ask before destructive ops.
