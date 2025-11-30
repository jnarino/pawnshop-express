-- Prevent two customers from having the same ID document
-- (type + number + state combination must be unique)

CREATE UNIQUE INDEX IF NOT EXISTS customer_unique_id_document
ON customer (
  COALESCE(id_type, ''),
  COALESCE(id_number, ''),
  COALESCE(id_state, '')
);
