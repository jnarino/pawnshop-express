-- 008_store_transaction.sql
-- Store transactions: header + tenders + line items

-------------------------------
-- store_transaction_type
-------------------------------
CREATE TABLE IF NOT EXISTS store_transaction_type (
  id SMALLINT PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,        -- e.g., 'RETAIL_SALE'
  legacy_code TEXT UNIQUE,          -- original PawnMaster code: 'SS','PPP', etc.
  name TEXT NOT NULL,
  cash_dir SMALLINT NOT NULL DEFAULT 0 CHECK (cash_dir IN (-1,0,1)),
  active BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO store_transaction_type (id, code, legacy_code, name, cash_dir) VALUES
  (1,  'RETAIL_SALE',             'SS',  'Retail sale',               +1),
  (2,  'LAYAWAY_DEPOSIT',         'SL',  'Layaway deposit',           +1),
  (3,  'PAWN_PAYMENT',            'PPP', 'Pawn payment',              +1),
  (4,  'PAWN_REDEMPTION_PAYMENT', 'PPU', 'Pawn redemption payment',   +1),
  (5,  'PAWN_DISBURSEMENT',       'P',   'Pawn (cash out)',           -1),
  (6,  'BUY_OUTRIGHT',            'B',   'Buy (cash out)',            -1),
  (7,  'BUY_REVERSAL',            'BV',  'Voided buy (reverse)',      +1),
  (8,  'CASH_FROM_BANK',          'MZ',  'Cash from bank/main',       +1),
  (9,  'CASH_TO_MAIN',            'MO',  'Cash to main',              -1),
  (10, 'BANK_DEPOSIT',            'MA',  'Bank deposit / to bank',    -1),
  (11, 'CASH_DRAWER_BALANCING',   'MB',  'Main balancing entry',       0),
  (12, 'OTHER_NON_CASH',          'T',   'Commission/other (no cash)', 0),
  (13, 'PAWN_DEFAULTED',          'PD',  'Defaulted (no cash)',        0),
  (14, 'PAWN_REVERSAL',           'PV',  'Voided pawn (reverse)',     +1)
ON CONFLICT (id) DO NOTHING;

-------------------------------
-- tender_type
-------------------------------
CREATE TABLE IF NOT EXISTS tender_type (
  id SMALLINT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  legacy_code TEXT UNIQUE,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO tender_type(id, name, legacy_code) VALUES
  (1, 'CASH',             '1001'),
  (2, 'AMERICAN EXPRESS', '35001'),
  (3, 'DEBIT',            '36001'),
  (4, 'DISCOVER',         '37001'),
  (5, 'MASTER CARD',      '38001'),
  (6, 'VISA',             '39001'),
  (7, 'CHECK',            '287001'),
  (8, 'CASH PASS',        '1186001')
ON CONFLICT (id) DO NOTHING;

-------------------------------
-- store_transaction (header)
-------------------------------
CREATE TABLE IF NOT EXISTS store_transaction (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- legacy keys for traceability
  legacy_acct_pk BIGINT,
  legacy_ticketnum TEXT,
  legacy_cus_fk TEXT,
  legacy_usr_fk TEXT,

  customer_id UUID REFERENCES customer(id) ON DELETE SET NULL,
  clerk_user_id UUID REFERENCES app_user(id) ON DELETE SET NULL,

  type_id SMALLINT NOT NULL REFERENCES store_transaction_type(id),

  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  amount NUMERIC(12,2),
  tax_sales NUMERIC(12,2),
  tax_exempt_used        BOOLEAN NOT NULL DEFAULT FALSE,
  tax_exempt_certificate TEXT,
  state_tax NUMERIC(12,2),
  tender_change NUMERIC(12,2),

  gun_proc_fee NUMERIC(12,2),

  note TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_store_tx_time     ON store_transaction(occurred_at);
CREATE INDEX IF NOT EXISTS idx_store_tx_type_id  ON store_transaction(type_id);
CREATE INDEX IF NOT EXISTS idx_store_tx_customer ON store_transaction(customer_id);

-- assumes set_updated_at() already exists from previous migration
DROP TRIGGER IF EXISTS trg_store_tx_updated ON store_transaction;
CREATE TRIGGER trg_store_tx_updated
BEFORE UPDATE ON store_transaction
FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

-------------------------------
-- store_transaction_tender
-------------------------------
CREATE TABLE IF NOT EXISTS store_transaction_tender (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_transaction_id UUID NOT NULL REFERENCES store_transaction(id) ON DELETE CASCADE,
  sequence SMALLINT NOT NULL DEFAULT 1,
  tender_type_id SMALLINT NOT NULL REFERENCES tender_type(id),
  amount NUMERIC(12,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_store_tx_tender_tx   ON store_transaction_tender(store_transaction_id);
CREATE INDEX IF NOT EXISTS idx_store_tx_tender_type ON store_transaction_tender(tender_type_id);

-------------------------------
-- store_transaction_item
-------------------------------
CREATE TABLE IF NOT EXISTS store_transaction_item (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_transaction_id UUID NOT NULL REFERENCES store_transaction(id) ON DELETE CASCADE,
  sequence SMALLINT NOT NULL DEFAULT 1,
  inventory_item_id UUID REFERENCES inventory_item(id) ON DELETE SET NULL,

  description TEXT,
  quantity NUMERIC(12,2) NOT NULL DEFAULT 1,
  line_amount NUMERIC(12,2),
  line_cost NUMERIC(12,2),
  tax_exempt BOOLEAN,
  county_tax_exempt BOOLEAN,
  returned BOOLEAN,
  status TEXT,

  -- legacy linkage
  legacy_sitem_pk BIGINT,
  legacy_items_pk BIGINT,
  legacy_items_guid TEXT,
  legacy_invnum TEXT,
  legacy_vendor_pk BIGINT,
  legacy_from_customer_pk BIGINT,
  legacy_cflag INT,
  legacy_sit_id TEXT,
  legacy_sales_loc TEXT,
  legacy_last_updated_usr TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_store_tx_item_tx        ON store_transaction_item(store_transaction_id);
CREATE INDEX IF NOT EXISTS idx_store_tx_item_inventory ON store_transaction_item(inventory_item_id);
