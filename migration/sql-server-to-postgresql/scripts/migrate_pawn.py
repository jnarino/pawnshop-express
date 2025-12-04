import pymssql
import psycopg2
from psycopg2.extras import execute_values
import json
import uuid
import os
from tqdm import tqdm
from datetime import datetime, timedelta
from config import SQLSERVER_CONFIG, POSTGRES_CONFIG

def safe_str(value):
    """Safely convert value to string and strip, handling None and non-strings"""
    if value is None:
        return None
    return str(value).strip() if value else None

def migrate_pawn_tickets():
    print("🚀 Starting Pawn Ticket Migration...")
    
    # Load Customer Map
    try:
        with open('customer_map.json', 'r') as f:
            customer_map = json.load(f)
    except FileNotFoundError:
        print("❌ customer_map.json not found. Run migrate_customers_v2.py first.")
        return
    
    try:
        mssql_conn = pymssql.connect(**SQLSERVER_CONFIG)
        mssql_cursor = mssql_conn.cursor(as_dict=True)
        
        pg_conn = psycopg2.connect(**POSTGRES_CONFIG)
        pg_cursor = pg_conn.cursor()
        
        # Get default rate plan
        pg_cursor.execute("SELECT id FROM rate_plan LIMIT 1")
        default_rate_plan = pg_cursor.fetchone()
        default_rate_plan_id = str(default_rate_plan[0]) if default_rate_plan else None
        
        # Fetch pawn tickets
        print("Fetching pawn tickets from SQL Server...")
        mssql_cursor.execute("""
            SELECT * FROM dbo.pawn 
            WHERE DATEIN > '1980-01-01'
            ORDER BY DATEIN
        """)
        
        tickets = mssql_cursor.fetchall()
        print(f"Found {len(tickets)} pawn tickets to migrate")
        
        batch_size = 1000
        batch_data = []
        errors = 0
        
        print("Migrating...")
        for row in tqdm(tickets):
            try:
                # Use source UUID if available
                ticket_id = str(row['PWN_id']) if row.get('PWN_id') else str(uuid.uuid4())
                
                # Map customer
                customer_pk = str(row.get('CUS_FK'))
                customer_id = customer_map.get(customer_pk)
                
                if not customer_id:
                    # Skip if customer not found
                    errors += 1
                    if errors < 10:
                        print(f"  Warning: Customer {customer_pk} not found for ticket {row.get('TICKETNUM')}")
                    continue
                
                # Status mapping
                status_map = {
                    'U': 'active',      # Unredeemed
                    'I': 'active',      # Active
                    'A': 'active',      # Active
                    '0': 'active',
                    '1': 'active',
                    'D': 'defaulted',   # Defaulted
                    'R': 'redeemed',    # Redeemed
                    'V': 'voided',      # Voided
                    'P': 'police hold', # Police Hold
                    'C': 'confiscation' # Confiscation
                }
                pawn_status = status_map.get(safe_str(row.get('STATUS')), 'active')
                
                # Transaction type
                transaction_type = 'PAWN'  # Default to PAWN
                
                # Financial fields - use PawnAMT not AMOUNT
                amount_financed = float(row.get('PawnAMT', 0)) if row.get('PawnAMT') else 0.0
                
                # Skip if missing critical financial data for PAWN
                if amount_financed == 0:
                    # User requested to change 0 amount to 0.01 instead of skipping
                    amount_financed = 0.01
                    # errors += 1
                    # if errors < 10:
                    #     print(f"  Warning: Skipping ticket {row.get('TICKETNUM')} - missing pawn amount")
                    # continue
                
                # Calculate finance charge (25% of pawn amount, minimum $3)
                finance_charge = max(amount_financed * 0.25, 3.00)
                
                # Calculate total of payments
                total_of_payments = amount_financed + finance_charge
                
                # Dates
                transaction_date = row.get('DATEIN')  # Date pawn was made
                maturity_date = row.get('CHARGEDATE')  # When next charge is due
                default_date = row.get('DATEOUT')  # Default/due date
                
                # If no maturity/default dates, calculate them
                if transaction_date:
                    if not maturity_date:
                        maturity_date = transaction_date + timedelta(days=30)
                    if not default_date:
                        default_date = transaction_date + timedelta(days=60)
                
                # APR and periodic rate (estimate if not provided)
                periodic_rate = 0.25  # 25% default
                apr = 300.00  # 300% APR default
                
                batch_data.append((
                    ticket_id,
                    safe_str(row.get('TICKETNUM')),
                    transaction_type,
                    customer_id,
                    amount_financed,
                    finance_charge,
                    periodic_rate,
                    total_of_payments,
                    apr,
                    None,  # purchase_trade_value
                    transaction_date,
                    maturity_date,
                    default_date,
                    default_rate_plan_id,
                    None,  # paid_through_date
                    None,  # next_charge_date
                    0.00,  # interest_credit
                    None,  # last_payment_at
                    None,  # last_activity_at
                    None,  # default_marked_at
                    None,  # default_marked_by
                    None,  # default_reason
                    pawn_status
                ))
                
                if len(batch_data) >= batch_size:
                    try:
                        _insert_batch(pg_cursor, batch_data)
                        pg_conn.commit()
                    except Exception as e:
                        pg_conn.rollback()
                        errors += len(batch_data)
                        if errors < 100:
                            print(f"  Batch error: {e}")
                    batch_data = []
                    
            except Exception as e:
                errors += 1
                if errors < 10:
                    print(f"  Error processing ticket {row.get('TICKETNUM')}: {e}")
        
        # Insert remaining
        if batch_data:
            try:
                _insert_batch(pg_cursor, batch_data)
                pg_conn.commit()
            except Exception as e:
                pg_conn.rollback()
                errors += len(batch_data)
                print(f"  Final batch error: {e}")
        
        print(f"\n✅ Pawn Ticket Migration Completed!")
        print(f"   Migrated: {len(tickets) - errors}")
        print(f"   Errors: {errors}")
        
    except Exception as e:
        pg_conn.rollback()
        print(f"❌ Migration Failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if 'mssql_conn' in locals(): mssql_conn.close()
        if 'pg_conn' in locals(): pg_conn.close()

def _insert_batch(cursor, data):
    sql = """
        INSERT INTO pawn_ticket (
            id, control_number, transaction_type, customer_id,
            amount_financed, finance_charge, periodic_rate, total_of_payments, apr,
            purchase_trade_value,
            transaction_date, maturity_date, default_date,
            rate_plan_id, paid_through_date, next_charge_date, interest_credit,
            last_payment_at, last_activity_at,
            default_marked_at, default_marked_by, default_reason,
            pawn_status
        ) VALUES %s
        ON CONFLICT (id) DO NOTHING
    """
    execute_values(cursor, sql, data)

if __name__ == "__main__":
    migrate_pawn_tickets()
