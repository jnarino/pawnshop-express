CREATE TABLE IF NOT EXISTS color_group (
  code TEXT PRIMARY KEY, 
  -- 'GENERIC_ITEM','FIREARM','JEWELRY_METAL_TONE','JEWELRY_STONE_COLOR','PERSON_HAIR','PERSON_EYE'
  name TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS color (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid (), 
  group_code TEXT NOT NULL REFERENCES color_group (code) ON DELETE RESTRICT, 
  slug TEXT NOT NULL, 
  -- e.g., 'YELLOW','WHITE','BLACK'
  name TEXT NOT NULL, 
  -- display label
  legacy_code TEXT, 
  sort_order INT NOT NULL DEFAULT 0, 
  active BOOLEAN NOT NULL DEFAULT TRUE, 
  UNIQUE (group_code, slug)
);
CREATE INDEX IF NOT EXISTS idx_color_group ON color (group_code);
CREATE TABLE IF NOT EXISTS customer (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), 
  -- Legacy linkage
  old_customer_pk TEXT, 
  old_customer_id TEXT, 
  -- Person
  first_name TEXT NOT NULL, 
  middle_name TEXT, 
  last_name TEXT NOT NULL, 
  street_address TEXT, 
  suite_number TEXT, 
  city TEXT, 
  state_us TEXT, 
  zip_code TEXT, 
  phone_number TEXT, 
  height TEXT, 
  weight TEXT, 
  hair_color_id UUID REFERENCES color (id) ON DELETE 
  SET 
    NULL, 
    eye_color_id UUID REFERENCES color (id) ON DELETE 
  SET 
    NULL, 
    race TEXT, 
    sex TEXT, 
    marks TEXT, 
    date_of_birth DATE, 
    birth_city TEXT, 
    birth_state TEXT, 
    birth_country TEXT, 
    -- Identification
    id_type TEXT, 
    id_number TEXT, 
    id_expiration DATE, 
    id_issue_date DATE, 
    ss_number TEXT, 
    id_address TEXT, 
    id_suite_number TEXT, 
    id_city TEXT, 
    id_state TEXT, 
    id_zip TEXT, 
    -- Employer
    employer_name TEXT, 
    employer_address TEXT, 
    employer_suite_number TEXT, 
    employer_city TEXT, 
    employer_state TEXT, 
    employer_zip TEXT, 
    employer_phone_number TEXT, 
    -- Misc / compliance
    description TEXT, 
    ffl_number TEXT, 
    locked BOOLEAN DEFAULT FALSE, 
    tax_id TEXT, 
    cell_phone TEXT, 
    email TEXT, 
    entered_at TIMESTAMPTZ, 
    military BOOLEAN DEFAULT FALSE, 
    ffl_expire_date DATE, 
    tax_exempt BOOLEAN DEFAULT FALSE, 
    tax_exempt_certificate TEXT, 
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), 
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS customer_name_idx ON customer (last_name, first_name);
CREATE INDEX IF NOT EXISTS customer_dob_idx ON customer (date_of_birth);
