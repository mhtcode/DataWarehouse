import json
import pyodbc
import time
import logging
import sys
import os
import subprocess

DB_CONFIG = {
    'driver': 'ODBC Driver 18 for SQL Server',
    'server': 'localhost',
    'database': 'DB2_Project',
    'trusted_connection': 'yes',
    'trust_server_certificate': 'yes',
}

LOG_FILE    = os.path.join('Scripts', 'makeDB.log')
CONFIG_FILE = os.path.join('Scripts', 'config.json')

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
    # split on GO lines
    batches = re.split(r'(?im)^\s*GO\s*$', sql)
    for batch in batches:
        batch = batch.strip()
        if not batch:
            continue
        try:
            cursor.execute(batch)
        except Exception as e:
            logging.error(f"Error in batch from {file_path}:\n{batch[:150]}...\nError: {e}")
            raise
    cursor.commit()

def resolve_node(node):
    """Flatten dictionary / list into a list of file‐paths."""
    results = []
    if isinstance(node, str):
        results.append(node)
    elif isinstance(node, list):
        for item in node:
            results.extend(resolve_node(item))
    elif isinstance(node, dict):
        for v in node.values():
            results.extend(resolve_node(v))
    return results

def run_node(node):
    scripts = resolve_node(node)
    conn = get_connection()
    cursor = conn.cursor()
    total_start = time.time()

    for script in scripts:
        logging.info(f"Running: {script}")
        start = time.time()
        try:
            if script.lower().endswith('.py'):
                # run Python loader
                subprocess.run([sys.executable, script], check=True)
            else:
                # run SQL
                run_sql_file(cursor, script)
            elapsed = time.time() - start
            logging.info(f"Completed: {script} in {elapsed:.2f}s")
        except Exception as e:
            logging.error(f"Error running {script}: {e}")
            cursor.close()
            conn.close()
            sys.exit(1)

    cursor.close()
    conn.close()
    total_elapsed = time.time() - total_start
    logging.info(f"All {len(scripts)} scripts completed in {total_elapsed:.2f}s")

def main():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[logging.FileHandler(LOG_FILE), logging.StreamHandler()]
    )

    if len(sys.argv) < 2 or sys.argv[1].lower() not in ('make', 'clean'):
        print("Usage: python makeDB.py [make|clean] [optional_path ...]")
        sys.exit(1)

    mode = sys.argv[1].lower()
    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        config = json.load(f)

    node = config.get(mode, {})
    # drill down any extra path args
    for arg in sys.argv[2:]:
        if isinstance(node, dict) and arg in node:
            node = node[arg]
        else:
            try:
                idx = int(arg)
                if isinstance(node, list) and 0 <= idx < len(node):
                    node = node[idx]
                else:
                    raise
            except:
                logging.error(f"Invalid path argument: {arg}")
                sys.exit(1)

    run_node(node)

if __name__ == "__main__":
    main()
