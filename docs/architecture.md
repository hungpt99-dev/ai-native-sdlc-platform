# Architecture (init pointer — TDDs are source of truth)

- [ForgeFlow Technical Design Document](https://app.notion.com/p/ForgeFlow-Technical-Design-Document-3ec095e172b6804cb5c5ea4516a4919d)
- [AI-Native SDLC Orchestration Platform](https://app.notion.com/p/AI-Native-SDLC-Orchestration-Platform-3ec095e172b680d3a92be4d10b88d90f)

Layers: `L1 ForgeFlow (UI/config/approvals/view)` → `L2 n8n/Temporal` →
`L3 OpenCode/Factory/GitLab/Redmine/etc`.

MVP reuses: `n8n, OpenCode/Factory, MCP, Redmine, GitLab, GitLab CI, Slack, Postgres`.
P2 adds `GitHub/Jira/Slack/Factory/Claude/Codex, conditions/parallel/retry/timeout/versioning/templates`.
P3 adds `Temporal, SDK, knowledge/RAG, security/incident, cost/eval, RBAC`.
P4 adds `marketplace, governance, analytics`.

Tables: `users, organizations, teams, projects, workflows, workflow_versions,
workflow_runs, step_runs, plugins, plugin_connections, ai_providers, approvals,
artifacts, audit_logs` — see [`../db/schema.sql`](../db/schema.sql).
