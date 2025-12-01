-- Basic seed data for inventory categories focusing on Jewelry and FIREARM
-- This enables the autocomplete functionality in the inventory item form

-- Function to make insertions idempotent
CREATE OR REPLACE FUNCTION insert_category(
  p_name TEXT,
  p_code TEXT,
  p_parent_code TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_parent_id UUID;
  v_id UUID;
BEGIN
  -- Find parent ID if provided
  IF p_parent_code IS NOT NULL THEN
    SELECT id INTO v_parent_id
    FROM inventory_category
    WHERE code = p_parent_code;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Parent category with code % not found', p_parent_code;
    END IF;
  END IF;

  -- Try to find existing category
  SELECT id INTO v_id
  FROM inventory_category
  WHERE code = p_code
    AND (
      (p_parent_code IS NULL AND parent_id IS NULL) OR
      (parent_id = v_parent_id)
    );

  -- Insert if not found
  IF NOT FOUND THEN
    INSERT INTO inventory_category (name, code, parent_id)
    VALUES (p_name, p_code, v_parent_id)
    RETURNING id INTO v_id;
  END IF;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Top-level categories
SELECT insert_category('JEWELRY', 'JEWELRY');
SELECT insert_category('FIREARM', 'FIREARM');

-- Jewelry subcategories
SELECT insert_category('RING', 'RING', 'JEWELRY');
SELECT insert_category('NECKLACE', 'NECKLACE', 'JEWELRY');
SELECT insert_category('BRACELET', 'BRACELET', 'JEWELRY');
SELECT insert_category('EARRINGS', 'EARRINGS', 'JEWELRY');
SELECT insert_category('PENDANT', 'PENDANT', 'JEWELRY');
SELECT insert_category('WATCH', 'WATCH', 'JEWELRY');
SELECT insert_category('CHAIN', 'CHAIN', 'JEWELRY');
SELECT insert_category('ANKLET', 'ANKLET', 'JEWELRY');
SELECT insert_category('BROOCH', 'BROOCH', 'JEWELRY');
SELECT insert_category('CUFFLINKS', 'CUFFLINKS', 'JEWELRY');
SELECT insert_category('CHARM', 'CHARM', 'JEWELRY');

-- Jewelry brands (under various subcategories)
-- Watch brands
SELECT insert_category('ROLEX', 'ROLEX', 'WATCH');
SELECT insert_category('OMEGA', 'OMEGA', 'WATCH');
SELECT insert_category('TAG HEUER', 'TAG-HEUER', 'WATCH');
SELECT insert_category('SEIKO', 'SEIKO', 'WATCH');
SELECT insert_category('CITIZEN', 'CITIZEN', 'WATCH');
SELECT insert_category('BULOVA', 'BULOVA', 'WATCH');
SELECT insert_category('TISSOT', 'TISSOT', 'WATCH');
SELECT insert_category('CASIO', 'CASIO', 'WATCH');
SELECT insert_category('MOVADO', 'MOVADO', 'WATCH');
SELECT insert_category('LONGINES', 'LONGINES', 'WATCH');

-- Luxury jewelry brands (can appear under multiple categories)
SELECT insert_category('NONE', 'NONE', 'RING');
SELECT insert_category('TIFFANY & CO', 'TIFFANY', 'RING');
SELECT insert_category('CARTIER', 'CARTIER', 'RING');
SELECT insert_category('DAVID YURMAN', 'DAVID-YURMAN', 'RING');
SELECT insert_category('PANDORA', 'PANDORA', 'RING');
SELECT insert_category('KAY JEWELERS', 'KAY', 'RING');
SELECT insert_category('ZALES', 'ZALES', 'RING');
SELECT insert_category('SWAROVSKI', 'SWAROVSKI', 'RING');

SELECT insert_category('TIFFANY & CO', 'TIFFANY', 'NECKLACE');
SELECT insert_category('CARTIER', 'CARTIER', 'NECKLACE');
SELECT insert_category('DAVID YURMAN', 'DAVID-YURMAN', 'NECKLACE');
SELECT insert_category('PANDORA', 'PANDORA', 'NECKLACE');

SELECT insert_category('TIFFANY & CO', 'TIFFANY', 'BRACELET');
SELECT insert_category('CARTIER', 'CARTIER', 'BRACELET');
SELECT insert_category('DAVID YURMAN', 'DAVID-YURMAN', 'BRACELET');
SELECT insert_category('PANDORA', 'PANDORA', 'BRACELET');

-- FIREARM subcategories
SELECT insert_category('HANDGUN', 'HANDGUN', 'FIREARM');
SELECT insert_category('RIFLE', 'RIFLE', 'FIREARM');
SELECT insert_category('SHOTGUN', 'SHOTGUN', 'FIREARM');
SELECT insert_category('AIRGUN', 'AIRGUN', 'FIREARM');
SELECT insert_category('BLACK POWDER', 'BLACK-POWDER', 'FIREARM');

-- Firearm brands
SELECT insert_category('SMITH & WESSON', 'SMITH-WESSON', 'HANDGUN');
SELECT insert_category('GLOCK', 'GLOCK', 'HANDGUN');
SELECT insert_category('SIG SAUER', 'SIG-SAUER', 'HANDGUN');
SELECT insert_category('RUGER', 'RUGER', 'HANDGUN');
SELECT insert_category('COLT', 'COLT', 'HANDGUN');
SELECT insert_category('BERETTA', 'BERETTA', 'HANDGUN');
SELECT insert_category('SPRINGFIELD', 'SPRINGFIELD', 'HANDGUN');
SELECT insert_category('KIMBER', 'KIMBER', 'HANDGUN');
SELECT insert_category('TAURUS', 'TAURUS', 'HANDGUN');
SELECT insert_category('WALTHER', 'WALTHER', 'HANDGUN');

SELECT insert_category('REMINGTON', 'REMINGTON', 'RIFLE');
SELECT insert_category('WINCHESTER', 'WINCHESTER', 'RIFLE');
SELECT insert_category('SAVAGE ARMS', 'SAVAGE', 'RIFLE');
SELECT insert_category('RUGER', 'RUGER', 'RIFLE');
SELECT insert_category('BROWNING', 'BROWNING', 'RIFLE');
SELECT insert_category('MARLIN', 'MARLIN', 'RIFLE');
SELECT insert_category('MOSSBERG', 'MOSSBERG', 'RIFLE');

SELECT insert_category('REMINGTON', 'REMINGTON', 'SHOTGUN');
SELECT insert_category('MOSSBERG', 'MOSSBERG', 'SHOTGUN');
SELECT insert_category('WINCHESTER', 'WINCHESTER', 'SHOTGUN');
SELECT insert_category('BENELLI', 'BENELLI', 'SHOTGUN');
SELECT insert_category('BROWNING', 'BROWNING', 'SHOTGUN');
SELECT insert_category('BERETTA', 'BERETTA', 'SHOTGUN');
SELECT insert_category('SAVAGE ARMS', 'SAVAGE', 'SHOTGUN');

-- Add common jewelry styles for chains, necklace, and bracelet
-- Chain styles
SELECT insert_category('ROPE', 'ROPE', 'CHAIN');
SELECT insert_category('ROLO', 'ROLO', 'CHAIN');
SELECT insert_category('CURB', 'CURB', 'CHAIN');
SELECT insert_category('CUBAN', 'CUBAN', 'CHAIN');
SELECT insert_category('BOX', 'BOX', 'CHAIN');
SELECT insert_category('SNAKE', 'SNAKE', 'CHAIN');
SELECT insert_category('FIGARO', 'FIGARO', 'CHAIN');
SELECT insert_category('MARINER', 'MARINER', 'CHAIN');
SELECT insert_category('HERRINGBONE', 'HERRINGBONE', 'CHAIN');
SELECT insert_category('WHEAT', 'WHEAT', 'CHAIN');
SELECT insert_category('SINGAPORE', 'SINGAPORE', 'CHAIN');
SELECT insert_category('SPIGA', 'SPIGA', 'CHAIN');
SELECT insert_category('BALL', 'BALL', 'CHAIN');
SELECT insert_category('CABLE', 'CABLE', 'CHAIN');
SELECT insert_category('BYZANTINE', 'BYZANTINE', 'CHAIN');
SELECT insert_category('OMEGA', 'OMEGA', 'CHAIN');

-- Ring styles
SELECT insert_category('SOLITAIRE', 'SOLITAIRE', 'RING');
SELECT insert_category('THREE STONE', 'THREE-STONE', 'RING');
SELECT insert_category('HALO', 'HALO', 'RING');
SELECT insert_category('BAND', 'BAND', 'RING');
SELECT insert_category('ENGAGEMENT', 'ENGAGEMENT', 'RING');
SELECT insert_category('SIGNET', 'SIGNET', 'RING');
SELECT insert_category('CLUSTER', 'CLUSTER', 'RING');
SELECT insert_category('COCKTAIL', 'COCKTAIL', 'RING');
SELECT insert_category('ETERNITY BAND', 'ETERNITY-BAND', 'RING');
SELECT insert_category('STACKABLE', 'STACKABLE', 'RING');

-- Bracelet styles
SELECT insert_category('TENNIS BRACELET', 'TENNIS-BRACELET', 'BRACELET');
SELECT insert_category('BANGLE', 'BANGLE', 'BRACELET');
SELECT insert_category('ROPE BRACELET', 'ROPE', 'BRACELET');
SELECT insert_category('CUBAN LINK', 'CUBAN-LINK', 'BRACELET');
SELECT insert_category('CURB LINK', 'CURB-LINK', 'BRACELET');
SELECT insert_category('S LINK', 'S-LINK', 'BRACELET');
SELECT insert_category('ID BRACELET', 'ID-BRACELET', 'BRACELET');

-- Necklace styles
SELECT insert_category('CHOKER', 'CHOKER', 'NECKLACE');
SELECT insert_category('LARIAT', 'LARIAT', 'NECKLACE');
SELECT insert_category('ROPE LINK', 'ROPE-LINK', 'NECKLACE');
SELECT insert_category('CUBAN LINK', 'CUBAN-LINK', 'NECKLACE');
SELECT insert_category('CURB LINK', 'CURB-LINK', 'NECKLACE');

-- Earring styles
SELECT insert_category('STUD EARRING', 'STUD', 'EARRINGS');
SELECT insert_category('HOOP EARRING', 'HOOP', 'EARRINGS');
SELECT insert_category('DROP EARRING', 'DROP', 'EARRINGS');
SELECT insert_category('DANGLE EARRING', 'DANGLE', 'EARRINGS');
SELECT insert_category('CHANDELIER EARRING', 'CHANDELIER', 'EARRINGS');
SELECT insert_category('HUGGIE EARRING', 'HUGGIE', 'EARRINGS');
SELECT insert_category('CLUSTER EARRING', 'CLUSTER-EARRING', 'EARRINGS');
SELECT insert_category('JACKET EARRING', 'JACKET', 'EARRINGS');

