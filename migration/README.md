# PawnMaster Database Migration

Complete migration solution for migrating PawnMaster data from SQL Server backup to PostgreSQL.

## Overview

This project handles the complete migration process in two phases:

1. **Backup to SQL Server**: Restore PawnMaster backup file to SQL Server (Docker)
2. **SQL Server to PostgreSQL**: Migrate all data from SQL Server to PostgreSQL with schema transformation

## Project Structure

```
migration/
├── README.md                      # This file
├── backup-to-sql-server/          # Phase 1: Restore backup
│   ├── docker-compose.yml         # SQL Server container config
│   ├── data/                      # SQL Server database files (auto-generated)
│   ├── backup/                    # Place your .dat backup file here
│   ├── scripts/                   # Restore scripts
│   ├── setup.sh                   # Automated setup script
│   └── verify.sh                  # Verification script
└── sql-server-to-postgresql/      # Phase 2: Data migration
    ├── .env.example               # Environment variables template
    ├── requirements.txt           # Python dependencies
    ├── customer_map.json          # Generated customer ID mapping
    ├── lookup_map.json            # Generated lookup ID mapping
    └── scripts/                   # Migration scripts
        ├── config.py              # Database configuration
        ├── migrate_all.py         # Main migration orchestrator
        ├── migrate_lookup.py      # Attribute types/values
        ├── migrate_customers.py
        ├── migrate_categories.py
        ├── migrate_inventory.py
        ├── migrate_pawn.py
        └── migrate_gunlog.py
```

## Prerequisites

- **Docker Desktop**: Installed and running
- **Python 3.9+**: For migration scripts
- **Disk Space**: At least 10GB free
- **PawnMaster Backup**: `.dat` backup file from PawnMaster

> **⚠️ IMPORTANT: Files Excluded from Git**
> 
> The following files are **automatically excluded** from version control (see `.gitignore`):
> - `backup-to-sql-server/data/` - SQL Server database files (2.2GB, auto-generated)
> - `backup-to-sql-server/backup/*.dat` - Backup files (2GB+, contains sensitive data)
> - `backup-to-sql-server/backup/*.zip` - Backup archives (1.8GB+)
> - `backup-to-sql-server/backup/POLICE.EXP` - Backup archives
> - `sql-server-to-postgresql/*.json` - ID mapping files (3MB, auto-generated)
> - `sql-server-to-postgresql/.env` - Database credentials (sensitive)
> 
> **What IS committed to Git:**
> - All Python migration scripts
> - `docker-compose.yml`
> - `requirements.txt`
> - `.env.example` (template only)
> - Documentation (README.md)
> - Shell scripts (setup.sh, verify.sh)

---

## Phase 1: Backup to SQL Server

### 1.1 Setup

1. **Start Docker Desktop**
   - Open Docker Desktop from Applications
   - Wait until status shows "Docker Desktop is running"

2. **Place Backup File**
   ```bash
   # Copy your backup file to the backup folder
   cp /path/to/pmDATAbak.dat backup-to-sql-server/backup/
   ```

3. **Start SQL Server Container**
   ```bash
   cd backup-to-sql-server
   docker-compose up -d
   ```
   
   Wait ~30 seconds for SQL Server to fully start.

### 1.2 Restore Database

```bash
docker exec -it pawnshop_sql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrong!Passw0rd' \
  -C -i /var/opt/mssql/scripts/restore.sql
```

### 1.3 Verify Restore

```bash
./verify.sh
```

**Connection Details:**
- Host: `localhost`
- Port: `1433`
- Username: `sa`
- Password: `YourStrong!Passw0rd`
- Database: `PawnMaster_v2`

### 1.4 Sample Queries

```sql
-- Check customer count
SELECT COUNT(*) FROM [PawnMaster_v2].[dbo].[cust];

-- Check items count
SELECT COUNT(*) FROM [PawnMaster_v2].[dbo].[items];

-- Check pawn tickets
SELECT COUNT(*) FROM [PawnMaster_v2].[dbo].[pawn];
```

---

## Phase 2: SQL Server to PostgreSQL

### 2.1 Prerequisites

Ensure Phase 1 is complete and SQL Server container is running.

### 2.2 Configure Environment

Create `.env` file in project root:

```ini
# SQL Server (Source)
SQLSERVER_HOST=localhost
SQLSERVER_PORT=1433
SQLSERVER_USER=sa
SQLSERVER_PASSWORD=YourStrong!Passw0rd
SQLSERVER_DB=PawnMaster_v2

# PostgreSQL (Target)
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_postgres_password
POSTGRES_DB=pawnshop
```

### 2.3 Install Python Dependencies

```bash
cd sql-server-to-postgresql
pip install -r requirements.txt
```

**Required packages:**
- `pymssql` - SQL Server connector
- `psycopg2` - PostgreSQL connector
- `python-dotenv` - Environment variables
- `tqdm` - Progress bars

### 2.4 Prepare PostgreSQL Database

Run the initial schema migration in your PostgreSQL database:

```bash
# From parent directory (pawnshop-express)
cat src/infrastructure/db/migrations/0001_11072025_initial.sql | \
  psql -U postgres -d pawnshop
```

### 2.5 Run Migration

```bash
cd sql-server-to-postgresql
python3 scripts/migrate_all.py
```

### 2.6 Migration Phases

The migration runs in the following order:

1. **Lookup Data** (`migrate_lookup.py`)
   - Migrates `Lookup_B` → `item_attribute_type` (22 types)
   - Migrates `Lookup_C` → `item_attribute_value` (1,560 values)
   - Generates `lookup_map.json` for reference

2. **Customers** (`migrate_customers_v2.py`)
   - Migrates `dbo.cust` → `customer` (~55,000 records)
   - Includes hair_color, eye_color from lookups
   - Generates `customer_map.json`

3. **Categories** (`migrate_categories_v2.py`)
   - Migrates `Level1-5` → `inventory_category` (~14,600 records)
   - Builds hierarchical structure with `parent_id`

4. **Inventory Items** (`migrate_inventory_v2.py`)
   - Migrates `dbo.items` → `inventory_item` (~112,000 records)
   - Joins with `Detail_J` (jewelry), `Detail_G` (firearms), `stones`
   - Populates JSONB `attributes` and `extra` fields

5. **Pawn Tickets** (`migrate_pawn_v2.py`)
   - Migrates `dbo.pawn` → `pawn_ticket` (~142,000 records)
   - Links to customers and items

6. **Gun Log** (`migrate_gunlog_v2.py`)
   - Migrates `dbo.gunlog` → `gunlog` (~4,000 records)

### 2.7 Monitor Progress

The script shows real-time progress:

```
🚀 Starting Lookup Migration...
✅ Migrated 22 attribute types
✅ Migrated 1560 attribute values

👥 PHASE 2: Customers
🚀 Starting Customer Migration...
100%|██████████| 55123/55123 [00:15<00:00, 3500.45it/s]
✅ Customer Migration Completed!

📦 PHASE 3: Inventory Items
...
```

---

## Schema Highlights

### Key Features

✅ **Single Attribute System**: All dropdowns use `item_attribute_type` → `item_attribute_value`  
✅ **Hierarchical Categories**: Up to 5 levels with `parent_id` and `ltree` path  
✅ **JSONB Attributes**: Flexible storage for jewelry/firearm-specific data  
✅ **Customer Colors**: Hair/eye colors stored as TEXT (no FK joins)  
✅ **Bin Location & Storage Fee**: Added to inventory items  

### New Tables

- `item_attribute_type` - Attribute categories (Metal, Karat, Action, etc.)
- `item_attribute_value` - Dropdown values (Gold, 14K, Bolt, etc.)

### Updated Tables

- `customer` - Added `hair_color`, `eye_color` TEXT columns
- `inventory_item` - Added `bin_location`, `storage_fee`, JSONB `attributes` and `extra`

### Removed Tables

- `color` and `color_group` - Replaced by attribute system

---

## Querying the Data

### Get Dropdown Options

```sql
-- Get all attribute types
SELECT id, name FROM item_attribute_type ORDER BY name;

-- Get values for a specific type (e.g., Metal)
SELECT v.value 
FROM item_attribute_value v
JOIN item_attribute_type t ON v.attribute_type_id = t.id
WHERE t.name = 'METAL'
ORDER BY v.value;
```

### Category Hierarchy

```sql
-- Get main types (Level 1)
SELECT id, name FROM inventory_category 
WHERE parent_id IS NULL 
ORDER BY name;

-- Get sublevels for a type
SELECT id, name FROM inventory_category 
WHERE parent_id = :type_id 
ORDER BY name;

-- Get full hierarchy for an item
SELECT 
  parent.name as type,
  child.name as sublevel
FROM inventory_category child
LEFT JOIN inventory_category parent ON child.parent_id = parent.id
WHERE child.id = :category_id;
```

### Inventory with Attributes

```sql
-- Find jewelry items
SELECT * FROM inventory_item 
WHERE attributes->>'Metal' = 'GOLD';

-- Find items with stones
SELECT * FROM inventory_item 
WHERE extra->'stones' IS NOT NULL;

-- Find firearms by caliber
SELECT * FROM inventory_item 
WHERE attributes->>'Caliber' = '.308';
```

---

## Troubleshooting

### Phase 1 Issues

**Docker daemon not running**
- Start Docker Desktop and wait for it to be ready

**Container won't start**
```bash
docker-compose logs
```

**Restore fails**
```bash
# Check SQL Server logs
docker logs pawnshop_sql

# Verify backup file exists
ls -lh backup/pmDATAbak.dat
```

### Phase 2 Issues

**Connection Failed**
- Verify `.env` credentials
- Ensure both Docker containers are running
- Test connections manually

**Migration Errors**
- Check that Phase 1 completed successfully
- Verify PostgreSQL schema is created
- Review error messages in console output

**Data Validation**
```sql
-- Check record counts
SELECT 'Customers:', COUNT(*) FROM customer;
SELECT 'Items:', COUNT(*) FROM inventory_item;
SELECT 'Tickets:', COUNT(*) FROM pawn_ticket;
```

---

## Cleanup

### Stop Containers

```bash
# Stop SQL Server
cd backup-to-sql-server
docker-compose down

# Stop PostgreSQL (if using Docker)
docker-compose down
```

### Remove All Data

```bash
# WARNING: This deletes everything
docker-compose down -v
rm -rf data/
```

---

## Migration Results

Expected final counts:
- **Customers**: ~55,123
- **Categories**: ~14,658
- **Inventory Items**: ~112,271
- **Pawn Tickets**: ~141,958
- **Gun Log**: ~4,039
- **Attribute Types**: 22
- **Attribute Values**: 1,560

---

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review migration logs
3. Verify source data in SQL Server
4. Check PostgreSQL schema matches expectations
