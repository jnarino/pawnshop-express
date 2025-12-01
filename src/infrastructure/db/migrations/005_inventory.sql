-- 005_inventory.sql
-- Inventory categories, status, and inventory_item table

-- =========================================
-- Extensions / helper functions
-- =========================================

-- ltree for hierarchical inventory_category.path
CREATE EXTENSION IF NOT EXISTS ltree;

-- Shared updated_at trigger function (safe to redefine if it already exists)
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Inventory category path helper
CREATE OR REPLACE FUNCTION inventory_category_set_path()
RETURNS TRIGGER AS $$
DECLARE
  parent_path ltree;
BEGIN
  IF NEW.parent_id IS NULL THEN
    NEW.path := replace(NEW.code, '-', '_')::ltree;
  ELSE
    SELECT path INTO parent_path FROM inventory_category WHERE id = NEW.parent_id;
    NEW.path := parent_path || replace(NEW.code, '-', '_')::ltree;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- Inventory categories (hierarchy)
-- =========================================

CREATE TABLE IF NOT EXISTS inventory_category (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  parent_id UUID REFERENCES inventory_category(id) ON DELETE CASCADE,
  path LTREE,
  depth INT GENERATED ALWAYS AS (nlevel(path)) STORED,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT inventory_category_unique_sibling UNIQUE (parent_id, name),
  CONSTRAINT inventory_category_code_sibling   UNIQUE (parent_id, code)
);

-- updated_at trigger
DROP TRIGGER IF EXISTS trg_inventory_category_updated ON inventory_category;
CREATE TRIGGER trg_inventory_category_updated
BEFORE UPDATE ON inventory_category
FOR EACH ROW
EXECUTE PROCEDURE set_updated_at();

-- path management triggers
DROP TRIGGER IF EXISTS trg_inventory_category_path_ins ON inventory_category;
CREATE TRIGGER trg_inventory_category_path_ins
BEFORE INSERT ON inventory_category
FOR EACH ROW
EXECUTE PROCEDURE inventory_category_set_path();

DROP TRIGGER IF EXISTS trg_inventory_category_path_upd ON inventory_category;
CREATE TRIGGER trg_inventory_category_path_upd
BEFORE UPDATE OF parent_id, code ON inventory_category
FOR EACH ROW
EXECUTE PROCEDURE inventory_category_set_path();

CREATE INDEX IF NOT EXISTS inventory_category_path_gist
  ON inventory_category USING GIST (path);
CREATE INDEX IF NOT EXISTS inventory_category_parent_idx
  ON inventory_category(parent_id);


-- =========================================
-- Inventory status lookup
-- =========================================

CREATE TABLE IF NOT EXISTS inventory_status (
  code TEXT PRIMARY KEY,     -- 'B','C','D','H','I','J','L','O','P','S','T','U','V'
  description TEXT,
  is_terminal BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order INT NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_inventory_status_updated ON inventory_status;
CREATE TRIGGER trg_inventory_status_updated
BEFORE UPDATE ON inventory_status
FOR EACH ROW
EXECUTE PROCEDURE set_updated_at();

INSERT INTO inventory_status(code, description, sort_order)
VALUES
  ('B', NULL, 10),
  ('C', NULL, 20),
  ('D', NULL, 30),
  ('H', NULL, 40),
  ('I', 'In inventory (default)', 50),
  ('J', NULL, 60),
  ('L', NULL, 70),
  ('O', NULL, 80),
  ('P', NULL, 90),
  ('S', NULL, 100),
  ('T', NULL, 110),
  ('U', NULL, 120),
  ('V', NULL, 130)
ON CONFLICT DO NOTHING;

-- =========================================
-- Inventory items
-- =========================================

CREATE TABLE IF NOT EXISTS inventory_item (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Classification
  category_id UUID NOT NULL REFERENCES inventory_category(id) ON DELETE RESTRICT,
  status TEXT NOT NULL DEFAULT 'I' REFERENCES inventory_status(code),

  -- Descriptive
  brand TEXT,
  model TEXT,
  serial_number TEXT,
  color_id UUID REFERENCES color(id) ON DELETE SET NULL,
  item_condition TEXT,
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),

  -- Pricing
  price_amount NUMERIC(12,2),
  resale NUMERIC(12,2),
  min_resale NUMERIC(12,2),
  item_replace NUMERIC(12,2),

  owner_mark TEXT,
  item_description TEXT,

  -- JSON payloads for extra attributes (firearms/jewelry, etc.)
  extra JSONB NOT NULL DEFAULT '{}'::jsonb,
  attributes JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- Legacy linkages
  legacy_inventory_number TEXT,       -- INVNUM
  legacy_item_guid TEXT,              -- Items_ID
  legacy_category_description TEXT,   -- Composite
  legacy_brand_color_description TEXT,-- Composite2

  -- Store-visible number (unique)
  inventory_number TEXT UNIQUE,

  last_updated_user_id UUID REFERENCES app_user(id) ON DELETE SET NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Partial unique index for serial_number (only when present)
CREATE UNIQUE INDEX IF NOT EXISTS inventory_item_serial_unique
  ON inventory_item(serial_number)
  WHERE serial_number IS NOT NULL;

CREATE INDEX IF NOT EXISTS inventory_item_category_idx
  ON inventory_item(category_id);

CREATE INDEX IF NOT EXISTS inventory_item_status_idx
  ON inventory_item(status);

CREATE INDEX IF NOT EXISTS inventory_item_brand_model_idx
  ON inventory_item(brand, model);

-- updated_at trigger
DROP TRIGGER IF EXISTS trg_inventory_item_updated ON inventory_item;
CREATE TRIGGER trg_inventory_item_updated
BEFORE UPDATE ON inventory_item
FOR EACH ROW
EXECUTE PROCEDURE set_updated_at();
