-- App user session table: non-expiring sessions, only revoked explicitly
CREATE TABLE IF NOT EXISTS app_user_session (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at   TIMESTAMPTZ,
  refresh_token_hash TEXT UNIQUE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_app_user_session_user_id
  ON app_user_session(user_id);

CREATE INDEX IF NOT EXISTS idx_app_user_session_refresh_token_hash
  ON app_user_session(refresh_token_hash);
