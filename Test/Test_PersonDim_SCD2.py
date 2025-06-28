import pyodbc
import logging
import sys
import os
import random
import string

# --------------- CONFIG ----------------
DB_CONFIG = {
    'driver': 'ODBC Driver 18 for SQL Server',
    'server': 'localhost',
    'database': 'DB2_Project',
    'trusted_connection': 'yes',
    'trust_server_certificate': 'yes',
}

SA_ETL_FILE = os.path.join("Staging Area", "ETL_Passenger.sql")
DW_ETL_FILE = os.path.join("Datawarehouse", "Dimensions", "ETL_Person_Dim.sql")
LOG_FILE = os.path.join("Test", "scd2_passenger_test.log")

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

def random_passport():
    return ''.join(random.choices(string.ascii_uppercase, k=2)) + \
           ''.join(random.choices(string.digits, k=6)) + \
           random.choice(string.ascii_uppercase)

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
        passenger_id = 1

        # 1. Show before
        print("Step 1: Check before state in Source and DW.")
        sa_pass_rows = log_and_print(
            "Source.Passenger BEFORE Update",
            cursor,
            f"SELECT PassengerID, PersonID, PassportNumber FROM Source.Passenger WHERE PassengerID = {passenger_id}"
        )
        dim_rows_before = log_and_print(
            "DW.DimPerson BEFORE Update",
            cursor,
            f"""SELECT * FROM DW.DimPerson
                WHERE PersonID = (SELECT PersonID FROM Source.Passenger WHERE PassengerID = {passenger_id})
                ORDER BY EffectiveFrom DESC"""
        )

        if not sa_pass_rows:
            print(f"❌ No row with PassengerID={passenger_id} in Source.Passenger. Aborting test.")
            return

        # 2. Update Source
        new_passport = random_passport()
        print(f"\nStep 2: Updating Source.PassengerID={passenger_id} to PassportNumber={new_passport}")
        cursor.execute(
            "UPDATE Source.Passenger SET PassportNumber = ? WHERE PassengerID = ?",
            new_passport, passenger_id
        )
        conn.commit()
        print("✅ Source.Passenger updated.")

        # 3. Run SA ETL
        print(f"\nStep 3: Running SA ETL: {SA_ETL_FILE}")
        run_sql_file(cursor, SA_ETL_FILE)
        cursor.execute("EXEC [SA].[ETL_Passenger]")  # <<< Actually run the ETL
        conn.commit()
        print("✅ SA ETL executed.")

        # 4. Check SA updated
        sa_pass_rows_after = log_and_print(
            "Source.Passenger AFTER Update",
            cursor,
            f"SELECT PassengerID, PersonID, PassportNumber FROM Source.Passenger WHERE PassengerID = {passenger_id}"
        )
        sa_rows = log_and_print(
            "SA.Passenger AFTER SA ETL",
            cursor,
            f"SELECT PassengerID, PersonID, PassportNumber FROM SA.Passenger WHERE PassengerID = {passenger_id}"
        )
        sa_passport_ok = any(r['PassportNumber'] == new_passport for r in sa_rows)
        if sa_passport_ok:
            print("✅ SA updated with new passport.")
        else:
            print("❌ SA was NOT updated correctly.")

        # 5. Run DW ETL
        print(f"\nStep 4: Running DW ETL: {DW_ETL_FILE}")
        run_sql_file(cursor, DW_ETL_FILE)
        cursor.execute("EXEC [DW].[ETL_Person_Dim]")  # <<< Actually run the ETL
        conn.commit()
        print("✅ DW ETL executed.")

        # 6. Check DW updated
        dim_rows = log_and_print(
            "DW.DimPerson AFTER DW ETL",
            cursor,
            f"""SELECT * FROM DW.DimPerson
                WHERE PersonID = (SELECT PersonID FROM Source.Passenger WHERE PassengerID = {passenger_id})
                ORDER BY EffectiveFrom DESC"""
        )

        # 7. Assert SCD2: Must have exactly one current row, and at least one expired
        current_count = sum(1 for r in dim_rows if r['PassportNumberIsCurrent'] == 1)
        expired_count = sum(1 for r in dim_rows if r['PassportNumberIsCurrent'] == 0)
        new_pass_ok = any(r['PassportNumberIsCurrent'] == 1 and r['PassportNumber'] == new_passport for r in dim_rows)
        if current_count == 1 and expired_count >= 1 and new_pass_ok:
            print("✅ SCD Type 2 update PASSED: One current, at least one expired, and current row has the new passport number.")
        else:
            print(f"❌ SCD Type 2 update FAILED: current={current_count}, expired={expired_count}, current_pass_ok={new_pass_ok}")

        cursor.close()
        conn.close()

    except Exception as e:
        logging.error(f"Test failed: {e}")
        print(f"Test failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
