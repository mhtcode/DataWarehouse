import os
import pyodbc
import json
import random
from faker import Faker
from tqdm import tqdm
from collections import defaultdict
import logging
from datetime import datetime

faker = Faker()

# --- Date Range Constants ---
DATE_START = datetime(2009, 3, 20)
DATE_END = datetime(2015, 1, 1)

# --- Path and Logging Setup ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(BASE_DIR, 'fillingTables.log')
CONFIG_FILE = os.path.join(BASE_DIR, 'config.json')

logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger()

# --- DB Connection ---
DB_CONFIG = {
    'driver': 'ODBC Driver 18 for SQL Server',
    'server': 'localhost',
    'database': 'DB2_Project',
    'trusted_connection': 'yes',
    'trust_server_certificate': 'yes',
}
conn_str = (
    f"DRIVER={DB_CONFIG['driver']};"
    f"SERVER={DB_CONFIG['server']};"
    f"DATABASE={DB_CONFIG['database']};"
    f"Trusted_Connection={DB_CONFIG['trusted_connection']};"
    f"TrustServerCertificate={DB_CONFIG['trust_server_certificate']};"
)
conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

# --- Helpers to fetch schema, FKs, etc. ---
def get_table_schema(table_name):
    cursor.execute("""
        SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, COLUMN_DEFAULT, IS_NULLABLE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA='Source' AND TABLE_NAME=?
        ORDER BY ORDINAL_POSITION
    """, table_name)
    return cursor.fetchall()

def get_primary_key(table_name):
    cursor.execute("""
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
        JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
            ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
        WHERE tc.TABLE_SCHEMA='Source' AND tc.TABLE_NAME=? AND tc.CONSTRAINT_TYPE='PRIMARY KEY'
    """, table_name)
    row = cursor.fetchone()
    return row[0] if row else None

def get_foreign_keys(table_name):
    cursor.execute("""
        SELECT kcu.COLUMN_NAME, ccu.TABLE_NAME AS REF_TABLE
        FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
        JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
          ON kcu.CONSTRAINT_CATALOG = rc.CONSTRAINT_CATALOG
         AND kcu.CONSTRAINT_SCHEMA = rc.CONSTRAINT_SCHEMA
         AND kcu.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
        JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu
          ON ccu.CONSTRAINT_CATALOG = rc.UNIQUE_CONSTRAINT_CATALOG
         AND ccu.CONSTRAINT_SCHEMA = rc.UNIQUE_CONSTRAINT_SCHEMA
         AND ccu.CONSTRAINT_NAME = rc.UNIQUE_CONSTRAINT_NAME
        WHERE kcu.TABLE_SCHEMA='Source' AND kcu.TABLE_NAME=?
    """, table_name)
    return {row[0]: row[1] for row in cursor.fetchall()}

# --- Context-Aware Data Generation ---
id_pools = defaultdict(list)

def generate_value(col, dtype, maxlen, fks):
    col_low = col.lower()
    # Foreign key
    if col in fks:
        ref_table = fks[col]
        if id_pools[ref_table]:
            return random.choice(id_pools[ref_table])
        else:
            return None
    # Integers
    if dtype in ('int', 'bigint', 'smallint'):
        if "age" in col_low:
            return random.randint(18, 80)
        if "year" in col_low:
            return random.randint(2009, 2015)
        return random.randint(1, 2_000_000)
    # Decimals
    if dtype.startswith('decimal') or dtype == 'money':
        if "rate" in col_low:
            return round(random.uniform(0.01, 0.10), 6)
        if "tax" in col_low or "price" in col_low or "amount" in col_low or "cost" in col_low:
            return round(random.uniform(10, 5000), 2)
        return round(random.uniform(1, 99999), 2)
    # Bits
    if dtype == 'bit':
        return random.choice([0, 1])
    # Text/Varchars
    if dtype in ('varchar', 'nvarchar', 'char', 'nchar'):
        if "email" in col_low:
            val = faker.email()
        elif "phone" in col_low or "mobile" in col_low:
            val = faker.phone_number()
        elif "name" in col_low and "user" not in col_low and "airline" not in col_low and "airport" not in col_low:
            val = faker.name()
        elif "address" in col_low:
            val = faker.street_address()
        elif col_low == "city":
            val = faker.city()
        elif col_low == "country":
            val = faker.country()
        elif "postal" in col_low or "zip" in col_low:
            val = faker.postcode()
        elif "desc" in col_low:
            val = faker.text(max_nb_chars=(maxlen or 50))
        elif "passport" in col_low:
            val = faker.unique.bothify(text="??#######")
        elif "gender" in col_low:
            val = random.choice(["Male", "Female"])
        elif "website" in col_low:
            val = faker.url()
        elif "iata" in col_low:
            val = faker.unique.bothify(text="??#")
        elif "manager" in col_low:
            val = faker.name()
        elif "role" in col_low:
            val = random.choice(['Manager', 'Pilot', 'Attendant', 'Technician', 'Customer'])
        elif "model" in col_low:
            val = random.choice(['A320', 'B737', 'B777', 'A350'])
        elif "type" in col_low:
            val = random.choice(['Economy', 'Business', 'First', 'Cargo'])
        elif "code" in col_low:
            val = faker.unique.bothify(text="??#")
        elif "category" in col_low:
            val = random.choice(['Economy', 'Business', 'Technical', 'Premium'])
        elif "manufacturer" in col_low:
            val = faker.company()
        elif "partnumber" in col_low:
            val = faker.unique.bothify(text="P#######")
        elif "currency" in col_low:
            val = random.choice(['USD', 'EUR', 'GBP', 'IRR'])
        else:
            val = faker.word()
        return val[:maxlen] if maxlen else val
    # Dates
    if dtype == 'date':
        return faker.date_between_dates(date_start=DATE_START, date_end=DATE_END)
    if dtype == 'datetime':
        return faker.date_time_between_dates(datetime_start=DATE_START, datetime_end=DATE_END)
    return None

def fill_table(table_name, n_records):
    schema = get_table_schema(table_name)
    pk = get_primary_key(table_name)
    fks = get_foreign_keys(table_name)
    colnames = [col for col, dtype, maxlen, default, isnull in schema]
    pk_index = colnames.index(pk) if pk else None

    print(f"\nFilling {table_name}: {n_records} records.")
    logger.info(f"Filling {table_name}: {n_records} records.")

    for i in tqdm(range(n_records)):
        vals = []
        for idx, (col, dtype, maxlen, default, isnull) in enumerate(schema):
            if pk and idx == pk_index:
                vals.append(i + 1)  # manual incremental PK
                continue
            v = generate_value(col, dtype, maxlen, fks)
            vals.append(v)
        colnames_str = ", ".join(f"[{c}]" for c in colnames)
        qmarks = ", ".join(['?'] * len(colnames))
        sql = f"INSERT INTO [Source].[{table_name}] ({colnames_str}) VALUES ({qmarks})"
        try:
            cursor.execute(sql, vals)
            if pk:
                id_pools[table_name].append(vals[pk_index])
            if i % 100 == 0:
                conn.commit()
        except Exception as e:
            logger.error(f"Error in {table_name}: {e}")
            print(f"Error in {table_name}: {e}")
    conn.commit()
    logger.info(f"Completed filling {table_name}.")

# --- Dependency Resolver ---
def resolve_order(config):
    ordered = []
    seen = set()
    def visit(tbl):
        name = tbl['name']
        if name in seen: return
        for dep in tbl.get('depends_on', []):
            dep_tbl = next(t for t in config['tables'] if t['name'] == dep)
            visit(dep_tbl)
        ordered.append(tbl)
        seen.add(name)
    for tbl in config['tables']:
        visit(tbl)
    return ordered

# --- Main Routine ---
if __name__ == "__main__":
    with open(CONFIG_FILE) as f:
        config = json.load(f)
    for tbl in resolve_order(config):
        fill_table(tbl['name'], tbl['records'])
    print("\nAll done.")
    logger.info("All done.")
