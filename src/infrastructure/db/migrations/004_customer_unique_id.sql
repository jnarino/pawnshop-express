-- Prevent two customers from having the same ID document
-- (type + number + state combination must be unique)

CREATE UNIQUE INDEX customer_unique_id_document
ON customer (id_type, id_number, id_state)
WHERE id_type IS NOT NULL
  AND id_number IS NOT NULL
  AND id_state IS NOT NULL;
