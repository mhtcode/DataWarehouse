import json
import pyodbc
import time
import logging
import sys
import os

DB_CONFIG = {
    'driver': 'ODBC Driver 18 for SQL Server',
    'server': 'localhost',
    'database': 'DB2_Project',
    'trusted_connection': 'yes',
    'trust_server_certificate': 'yes',
}

LOG_FILE = os.path.join('Scripts', 'makeDB.log')
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
    batches = re.split(r'(?im)^\s*GO\s*$', sql)
    for batch in batches:
        batch = batch.strip()
        if batch:
            try:
                cursor.execute(batch)
            except Exception as e:
                logging.error(f"Error in batch from {file_path}:\n{batch[:150]}...\nError: {e}")
                raise
    cursor.commit()

def resolve_node(node, prefix=[]):
    # Recursively resolve all scripts under node, with their paths
    results = []
    if isinstance(node, str):
        results.append(node)
    elif isinstance(node, list):
        for item in node:
            results.extend(resolve_node(item, prefix))
    elif isinstance(node, dict):
        for k, v in node.items():
            results.extend(resolve_node(v, prefix + [k]))
    return results

def run_node(node):
    scripts = resolve_node(node)
    try:
        conn = get_connection()
        cursor = conn.cursor()
        total_start = time.time()
        for script in scripts:
            start = time.time()
            logging.info(f"Running: {script}")
            try:
                run_sql_file(cursor, script)
                elapsed = time.time() - start
                logging.info(f"Completed: {script} in {elapsed:.2f}s")
            except Exception as e:
                logging.error(f"Error in {script}: {e}")
                raise
        cursor.close()
        conn.close()
        total_elapsed = time.time() - total_start
        logging.info(f"Completed {len(scripts)} scripts in {total_elapsed:.2f}s")
    except Exception as e:
        logging.error(f"Failed to run scripts: {e}")

def main():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[logging.FileHandler(LOG_FILE), logging.StreamHandler()]
    )
    if len(sys.argv) >= 2:
        mode = sys.argv[1].lower()
        with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
            config = json.load(f)
        if mode == "clean":
            node = config['clean']
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
        elif mode == "make":
            node = config['make']
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
        else:
            print("Usage: python makeDB.py [make|clean] [optional_path ...]")
    else:
        print("Usage: python makeDB.py [make|clean] [optional_path ...]")

if __name__ == "__main__":
    main()
