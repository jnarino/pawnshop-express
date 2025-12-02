-- 007_pawn_ticket.sql
-- Basic pawn ticket schema + control number helper

-------------------------
-- Pawn transaction type
-------------------------
CREATE TABLE IF NOT EXISTS pawn_transaction_type (
  code TEXT PRIMARY KEY,      -- 'PAWN' | 'PURCHASE'
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_pawn_transaction_type_updated ON pawn_transaction_type;
CREATE TRIGGER trg_pawn_transaction_type_updated
BEFORE UPDATE ON pawn_transaction_type
FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

INSERT INTO pawn_transaction_type (code, description, sort_order) VALUES
  ('PAWN', 'Collateralized loan (pawn)', 10),
  ('PURCHASE', 'Outright purchase', 20)
ON CONFLICT (code) DO NOTHING;

-------------------------
-- Pawn ticket
-------------------------
CREATE TABLE IF NOT EXISTS pawn_ticket (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  control_number TEXT NOT NULL,
  transaction_type TEXT NOT NULL REFERENCES pawn_transaction_type(code),
  customer_id UUID NOT NULL REFERENCES customer(id) ON DELETE RESTRICT,

  amount_financed NUMERIC(12,2),
  purchase_trade_value NUMERIC(12,2),

  transaction_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  maturity_date TIMESTAMPTZ NOT NULL,
  default_date TIMESTAMPTZ NOT NULL,

  pawn_status TEXT NOT NULL DEFAULT 'active'
    CHECK (pawn_status IN (
      'active',
      'redeemed',
      'defaulted',
      'police hold',
      'confiscation',
      'voided'
    )),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS pawn_ticket_customer_idx
  ON pawn_ticket(customer_id);

CREATE INDEX IF NOT EXISTS pawn_ticket_control_num_idx
  ON pawn_ticket(control_number);

CREATE INDEX IF NOT EXISTS pawn_ticket_status_idx
  ON pawn_ticket(pawn_status);

CREATE INDEX IF NOT EXISTS pawn_ticket_transaction_idx
  ON pawn_ticket(transaction_date);

DROP TRIGGER IF EXISTS pawn_ticket_updated ON pawn_ticket;
CREATE TRIGGER pawn_ticket_updated
BEFORE UPDATE ON pawn_ticket
FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

-------------------------
-- Pawn ticket item link
-------------------------
CREATE TABLE IF NOT EXISTS pawn_ticket_item (
  pawn_ticket_id UUID REFERENCES pawn_ticket(id) ON DELETE CASCADE,
  inventory_item_id UUID REFERENCES inventory_item(id) ON DELETE RESTRICT,
  PRIMARY KEY (pawn_ticket_id, inventory_item_id)
);

-------------------------
-- App settings + control number generator
-------------------------
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by UUID REFERENCES app_user(id) ON DELETE SET NULL
);

INSERT INTO app_settings (key, value, description)
VALUES ('pawn_ticket_control_number_next', '100001', 'Next control number for pawn tickets')
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION get_next_control_number()
RETURNS TEXT AS $$
DECLARE
  next_num TEXT;
BEGIN
  UPDATE app_settings
  SET value = (value::INTEGER + 1)::TEXT,
      updated_at = NOW()
  WHERE key = 'pawn_ticket_control_number_next'
  RETURNING (value::INTEGER - 1)::TEXT INTO next_num;

  RETURN next_num;
END;
$$ LANGUAGE plpgsql;
