import pyodbc
import logging
import sys
import os
import random

# --------------- CONFIG ----------------
DB_CONFIG = {
    'driver': 'ODBC Driver 18 for SQL Server',
    'server': 'localhost',
    'database': 'DB2_Project',
    'trusted_connection': 'yes',
    'trust_server_certificate': 'yes',
}

SA_ETL_FILE = os.path.join("Staging Area", "ETL_LoyaltyTier.sql")
DW_ETL_FILE = os.path.join("Datawarehouse", "Dimensions", "ETL_LoyaltyTier_Dim.sql")
LOG_FILE = os.path.join("Test", "scd2_loyaltytier_test.log")

# ------------ UTILITIES ---------------
def get_connection():
    conn_str = (
        f"DRIVER={{{DB_CONFIG['driver']}}};"
        f"SERVER={DB_CONFIG['server']};"
        f"DATABASE={DB_CONFIG['database']};"
        f"Trusted_Connection={DB_CONFIG['trusted_connection']};"
        f"TrustServerCertificate={DB_CONFIG['trust_server_certificate']};"
    )
    return pyodbc.connect(conn_str)

def run_sql_file(cursor, file_path):
    import re
    with open(file_path, 'r', encoding='utf-8') as f:
        sql = f.read()
    batches = re.split(r'(?im)^\s*GO\s*$', sql)
    for batch in batches:
        batch = batch.strip()
        if batch:
            try:
                cursor.execute(batch)
            except Exception as e:
                logging.error(f"Error in batch from {file_path}:\n{batch[:150]}...\nError: {e}")
                print(f"Error in batch from {file_path}:\n{batch[:150]}...\nError: {e}")
                raise
    cursor.commit()

def log_and_print(title, cursor, sql):
    print(f"\n--- {title} ---")
    logging.info(f"--- {title} ---")
    cursor.execute(sql)
    columns = [column[0] for column in cursor.description]
    rows = cursor.fetchall()
    if not rows:
        print("(no rows)")
        logging.info("(no rows)")
    result = []
    for row in rows:
        d = dict(zip(columns, row))
        print(d)
        logging.info(d)
        result.append(d)
    print("--- End ---\n")
    logging.info("--- End ---\n")
    return result

# ------------ MAIN TEST ---------------
def main():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[logging.FileHandler(LOG_FILE), logging.StreamHandler()]
    )
    try:
        conn = get_connection()
        cursor = conn.cursor()
        loyalty_tier_id = 2   # <--- Change as needed

        # 1. Show before
        print("Step 1: Check before state in Source, SA, and DW.")
        src_rows = log_and_print(
            "Source.LoyaltyTier BEFORE Update",
            cursor,
            f"SELECT * FROM Source.LoyaltyTier WHERE LoyaltyTierID = {loyalty_tier_id}"
        )
        sa_rows = log_and_print(
            "SA.LoyaltyTier BEFORE Update",
            cursor,
            f"SELECT * FROM SA.LoyaltyTier WHERE LoyaltyTierID = {loyalty_tier_id}"
        )
        dim_rows_before = log_and_print(
            "DW.DimLoyaltyTier BEFORE Update",
            cursor,
            f"""SELECT * FROM DW.DimLoyaltyTier
                WHERE LoyaltyTierID = {loyalty_tier_id}
                ORDER BY EffectiveFrom DESC"""
        )
        if not src_rows:
            print(f"❌ No row with LoyaltyTierID={loyalty_tier_id} in Source.LoyaltyTier. Aborting test.")
            return

        # 2. Update Source (simulate SCD2 change)
        old_minpoints = src_rows[0]['MinPoints']
        new_minpoints = old_minpoints + random.randint(1000, 9999)
        print(f"\nStep 2: Updating Source.LoyaltyTierID={loyalty_tier_id} MinPoints: {old_minpoints} -> {new_minpoints}")
        cursor.execute(
            "UPDATE Source.LoyaltyTier SET MinPoints = ? WHERE LoyaltyTierID = ?",
            new_minpoints, loyalty_tier_id
        )
        conn.commit()
        print("✅ Source.LoyaltyTier updated.")

        # 3. Run SA ETL
        print(f"\nStep 3: Running SA ETL: {SA_ETL_FILE}")
        run_sql_file(cursor, SA_ETL_FILE)
        cursor.execute("EXEC [SA].[ETL_LoyaltyTier]")
        conn.commit()
        print("✅ SA ETL executed.")

        # 4. Check SA updated
        sa_rows_after = log_and_print(
            "SA.LoyaltyTier AFTER SA ETL",
            cursor,
            f"SELECT * FROM SA.LoyaltyTier WHERE LoyaltyTierID = {loyalty_tier_id}"
        )
        sa_ok = any(r['MinPoints'] == new_minpoints for r in sa_rows_after)
        if sa_ok:
            print("✅ SA.LoyaltyTier updated with new MinPoints.")
        else:
            print("❌ SA.LoyaltyTier was NOT updated correctly.")

        # 5. Run DW ETL
        print(f"\nStep 4: Running DW ETL: {DW_ETL_FILE}")
        run_sql_file(cursor, DW_ETL_FILE)
        cursor.execute("EXEC [DW].[ETL_LoyaltyTier_Dim]")
        conn.commit()
        print("✅ DW ETL executed.")

        # 6. Check DW updated
        dim_rows = log_and_print(
            "DW.DimLoyaltyTier AFTER DW ETL",
            cursor,
            f"""SELECT * FROM DW.DimLoyaltyTier
                WHERE LoyaltyTierID = {loyalty_tier_id}
                ORDER BY EffectiveFrom DESC"""
        )
        # 7. Assert SCD2: one current row, at least one expired, current row has new MinPoints
        current_rows = [r for r in dim_rows if r['MinPointsIsCurrent'] == 1]
        expired_rows = [r for r in dim_rows if r['MinPointsIsCurrent'] == 0]
        new_val_ok = any(r['MinPointsIsCurrent'] == 1 and r['MinPoints'] == new_minpoints for r in dim_rows)
        if len(current_rows) == 1 and len(expired_rows) >= 1 and new_val_ok:
            print("✅ SCD2 update PASSED: One current, at least one expired, and current row has the new MinPoints.")
        else:
            print(f"❌ SCD2 update FAILED: current={len(current_rows)}, expired={len(expired_rows)}, current_has_new={new_val_ok}")

        cursor.close()
        conn.close()
    except Exception as e:
        logging.error(f"Test failed: {e}")
        print(f"Test failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
