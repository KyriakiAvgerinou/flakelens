-- ci_runs: stores GitHub Actions CI runs.
CREATE TABLE IF NOT EXISTS ci_runs (
    id BIGSERIAL PRIMARY KEY,
    -- Where the CI run comes from...
    source TEXT NOT NULL DEFAULT 'manual'
        CHECK (source IN ('manual', 'github_actions')),
    github_run_id BIGINT UNIQUE,
    repository TEXT,
    branch TEXT,
    commit_sha TEXT,
    workflow_name TEXT,
    status TEXT NOT NULL DEFAULT 'unknown'
        CHECK (status IN ('passed', 'failed', 'cancelled', 'timed_out', 'unknown')),
    -- The CI run started at...
    started_at TIMESTAMPTZ,
    -- ... and finished at...
    finished_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),  -- the timestamp of the record
    updated_at TIMESTAMPTZ,

    CONSTRAINT ci_run_finished_after_started
        CHECK (
            started_at IS NULL
            OR finished_at IS NULL
            OR finished_at >= started_at
        )
);

-- ci_run_logs: stores the CI run log file metadata.
CREATE TABLE IF NOT EXISTS ci_run_logs (
    id BIGSERIAL PRIMARY KEY,
    -- The CI run the log file belongs to.
    ci_run_id BIGINT NOT NULL
        REFERENCES ci_runs(id)
        ON DELETE CASCADE,
    original_file_name TEXT,
    -- The relative path where the log file is stored,
    -- under data/logs.
    storage_path TEXT NOT NULL UNIQUE,
    -- The SHA-256 hash of the log file content.
    content_sha256 TEXT NOT NULL,
    -- The size of the log file in bytes.
    size_bytes BIGINT NOT NULL
        CHECK (size_bytes >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- test_failures: stores the structured failures
-- extracted from the CI log files by FlakeLens.
CREATE TABLE IF NOT EXISTS test_failures (
    id BIGSERIAL PRIMARY KEY,
    -- Because failures-per-run queries will be common,
    -- we also add ci_run_id, even though we already have ci_run_log_id.
    ci_run_id BIGINT NOT NULL
        REFERENCES ci_runs(id)
        ON DELETE CASCADE,
    -- The log file this failure was extracted from.
    ci_run_log_id BIGINT NOT NULL
        REFERENCES ci_run_logs(id)
        ON DELETE CASCADE,
    test_name TEXT,
    test_file_path TEXT,  -- the test file where the failure was reported
    line_number INTEGER  -- the line where the failure was reported
        CHECK (line_number IS NULL OR line_number > 0),
    message TEXT NOT NULL,
    -- This is a simplified version of the error message
    -- that will help us later recognize failures of the same type.
    fingerprint TEXT NOT NULL,  -- pattern of the failure
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add indexes.

-- to show the latest CI runs first...
CREATE INDEX IF NOT EXISTS idx_ci_runs_created_at
ON ci_runs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ci_runs_repository_branch_created_at
ON ci_runs(repository, branch, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ci_runs_status
ON ci_runs(status);

CREATE INDEX IF NOT EXISTS idx_ci_run_logs_ci_run_id
ON ci_run_logs(ci_run_id);

CREATE INDEX IF NOT EXISTS idx_test_failures_ci_run_id
ON test_failures(ci_run_id);

CREATE INDEX IF NOT EXISTS idx_test_failures_ci_run_log_id
ON test_failures(ci_run_log_id);

CREATE INDEX IF NOT EXISTS idx_test_failures_fingerprint
ON test_failures(fingerprint);

CREATE INDEX IF NOT EXISTS idx_test_failures_test_name_created_at
ON test_failures(test_name, created_at DESC);
