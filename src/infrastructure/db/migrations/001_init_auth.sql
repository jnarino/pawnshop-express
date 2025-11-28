-- Roles / Users / Auth
CREATE TABLE IF NOT EXISTS role (
  id   SMALLINT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL
);

INSERT INTO role (id, name) VALUES
  (1, 'admin'),
  (2, 'manager'),
  (3, 'sales_associate')
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS app_user (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  first_name TEXT NOT NULL,
  middle_name TEXT,
  last_name TEXT NOT NULL,
  street_address TEXT,
  suite_number TEXT,
  city TEXT,
  state_us TEXT,
  zip_code TEXT,
  phone_number TEXT,
  ss_number TEXT,
  birth_date DATE,
  starting_date DATE NOT NULL DEFAULT CURRENT_DATE,
  terminated_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  role_id SMALLINT NOT NULL REFERENCES role(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_app_user_username
  ON app_user(username);
