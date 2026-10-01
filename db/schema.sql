-- ForgeFlow DDL (init) — PostgreSQL, metadata only.
-- Artifacts/secrets are REFERENCES (location / vault://), never blobs.
-- Enums match AGENTS.md so later code can rely on them.

CREATE TABLE organizations (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE users (
  id UUID PRIMARY KEY,
  org_id UUID REFERENCES organizations(id),
  email TEXT NOT NULL UNIQUE
);

CREATE TABLE teams (
  id UUID PRIMARY KEY,
  org_id UUID REFERENCES organizations(id),
  name TEXT NOT NULL
);

CREATE TABLE projects (
  id UUID PRIMARY KEY,
  org_id UUID REFERENCES organizations(id),
  name TEXT NOT NULL,
  repository TEXT  -- e.g. gitlab://payment-service (ref only)
);

CREATE TABLE workflows (
  id UUID PRIMARY KEY,
  project_id UUID REFERENCES projects(id),
  name TEXT NOT NULL
);

-- Immutable versions: runs pin version_id; never mutate a version with runs.
CREATE TABLE workflow_versions (
  id UUID PRIMARY KEY,
  workflow_id UUID REFERENCES workflows(id),
  version INT NOT NULL,
  definition TEXT NOT NULL,  -- workflow YAML snapshot (immutable once runs exist)
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (workflow_id, version)
);

CREATE TABLE workflow_runs (
  id UUID PRIMARY KEY,
  workflow_id UUID REFERENCES workflows(id),
  version_id UUID REFERENCES workflow_versions(id),
  status TEXT NOT NULL CHECK (status IN ('RUNNING','WAITING_APPROVAL','FAILED','COMPLETED','CANCELLED')),
  current_step TEXT,
  event_id TEXT,          -- idempotency: duplicate Event #456 must not start 2nd run
  idempotency_key TEXT UNIQUE,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE step_runs (
  id UUID PRIMARY KEY,
  run_id UUID REFERENCES workflow_runs(id),
  step_id TEXT NOT NULL,  -- e.g. ba, ba-approval, architect
  type TEXT NOT NULL CHECK (type IN ('trigger','agent','action','approval','condition','parallel','wait','notification')),
  status TEXT NOT NULL CHECK (status IN ('PENDING','RUNNING','WAITING','SUCCESS','FAILED','SKIPPED','CANCELLED')),
  started_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE plugins (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,  -- redmine, gitlab, opencode, factory, slack
  transport TEXT NOT NULL CHECK (transport IN ('n8n','mcp','http')),
  metadata JSONB NOT NULL DEFAULT '{}'
);

CREATE TABLE plugin_connections (
  id UUID PRIMARY KEY,
  plugin_id UUID REFERENCES plugins(id),
  project_id UUID REFERENCES projects(id),
  secret_ref TEXT NOT NULL,  -- vault://… only
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ai_providers (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,  -- opencode, factory, ...
  adapter TEXT NOT NULL,      -- OpenCodeExecutor, FactoryExecutor, ...
  secret_ref TEXT NOT NULL
);

CREATE TABLE approvals (
  id UUID PRIMARY KEY,
  run_id UUID REFERENCES workflow_runs(id),
  step_id TEXT NOT NULL,
  approver_role TEXT NOT NULL,  -- product_owner, tech_lead, qa_lead
  status TEXT NOT NULL CHECK (status IN ('PENDING','APPROVED','REJECTED','CHANGES_REQUESTED','EXPIRED')),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ
);

-- Reference only: location -> Git/S3/MinIO (artifact:// or https:// …).
CREATE TABLE artifacts (
  id UUID PRIMARY KEY,
  run_id UUID REFERENCES workflow_runs(id),
  step_id TEXT NOT NULL,
  type TEXT NOT NULL,   -- Requirement, Design, API Spec, Plan, Code/PR, Test Report, ...
  version INT NOT NULL DEFAULT 1,
  location TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'
);

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY,
  run_id UUID REFERENCES workflow_runs(id),
  who TEXT NOT NULL,
  what TEXT NOT NULL,
  step_id TEXT,
  plugin TEXT,
  result TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
