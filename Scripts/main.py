import json
import subprocess
import sys
import os
import re

CONFIG_PATH = os.path.join('Scripts', 'config.json')
MAKE_DB_SCRIPT = os.path.join('Scripts', 'makeDB.py')

def fix_bulk_insert_path():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    csv_path = os.path.abspath(os.path.join(script_dir, '..', 'Files', 'Date1.CSV'))
    sql_path = os.path.abspath(os.path.join(script_dir, '..', 'Datawarehouse', 'Dimensions', 'Initial_Date_Dim.sql'))
    if not os.path.isfile(csv_path):
        print(f"ERROR: {csv_path} does not exist! Bulk insert path not updated.")
        return
    if not os.path.isfile(sql_path):
        print(f"ERROR: {sql_path} does not exist! Bulk insert path not updated.")
        return
    with open(sql_path, 'r', encoding='utf-8') as f:
        sql = f.read()
    pattern = r"FROM\s+'[^']*Date1\.CSV'"
    replacement = f"FROM '{csv_path.replace(os.sep, '\\\\')}'"
    new_sql = re.sub(pattern, replacement, sql)
    with open(sql_path, 'w', encoding='utf-8') as f:
        f.write(new_sql)
    print(f"BULK INSERT path updated in {sql_path}.")

def print_welcome():
    print("=" * 70)
    print("Project Topic:")
    print('  Modeling a comprehensive "flight reservation and loyalty system"')
    print("Supervisor: Prof. Alireza Basiri")
    print("=" * 70)
    print("Project Overview")
    print("  This project demonstrates a fully automated pipeline for building,")
    print("  populating, and managing a multi-layered data warehouse environment")
    print("  for the airline/flight reservation domain using SQL Server and Python.")
    print()
    print("  The solution covers:")
    print("   - Source System: OLTP-style operational tables")
    print("   - Staging Area: ETL/ELT processing and integration")
    print("   - Data Warehouse: Star schema, facts, and dimensions for analytics")
    print("=" * 70)

def print_help():
    print("\n" + "=" * 60)
    print("SCRIPT HELP & USAGE")
    print("=" * 60)
    print("This tool allows you to manage and automate all steps of your BI data pipeline.")
    print()
    print("1. Browse and run steps from your config.json tree:")
    print("   - Explore the data pipeline structure defined in config.json.")
    print("   - You can execute all, or only selected, ETL steps or scripts.")
    print("   - Select '[Run all under this node]' at any point to run all scripts in a section.")
    print()
    print("2. Clean Project (drop all tables):")
    print("   - Runs a cleanup of the entire database (Source, Staging, and Data Warehouse).")
    print()
    print("3. Exit: Safely exit the automation menu.")
    print()
    print("All execution and error logs are available in Scripts/makeDB.log for troubleshooting and monitoring.")
    print("=" * 60)

def run_make_db(mode, sub_path=None):
    cmd = [sys.executable, MAKE_DB_SCRIPT, mode]
    if sub_path:
        cmd += sub_path
    result = subprocess.run(cmd)
    return result.returncode == 0

def load_config():
    with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
        return json.load(f)

def navigate_menu(config, path=[]):
    current = config
    for key in path:
        current = current[key]
    while True:
        os.system('cls' if os.name == 'nt' else 'clear')
        print(f"\nCurrent path: {'/'.join(path) if path else '(root)'}")
        print("Type 'help' to see script usage instructions.\n")
        if isinstance(current, dict):
            keys = list(current.keys())
            for idx, k in enumerate(keys, 1):
                print(f"{idx}. {k}")
            print(f"{len(keys)+1}. [Run all under this node]")
            if path:
                print(f"{len(keys)+2}. [Back]")
                print(f"{len(keys)+3}. [Exit]")
                extra = 3
            else:
                print(f"{len(keys)+2}. [Exit]")
                extra = 2
            choice = input("Choose: ").strip()
            if choice.lower() == 'help':
                print_help()
                input("Press Enter to continue...")
                continue
            try:
                choice = int(choice)
                if 1 <= choice <= len(keys):
                    path.append(keys[choice-1])
                    return navigate_menu(config, path)
                elif choice == len(keys)+1:
                    print(">>> Running:", ' '.join([MAKE_DB_SCRIPT, 'make'] + path))
                    run_make_db("make", path)
                    input("Press Enter to continue...")
                elif path and choice == len(keys)+2:
                    path.pop()
                    return
                elif choice == len(keys)+extra:
                    print("Exiting. Have a nice day!")
                    sys.exit(0)
                else:
                    print("Invalid input.")
                    input("Press Enter to continue...")
            except Exception:
                print("Invalid input.")
                input("Press Enter to continue...")
        elif isinstance(current, list):
            for idx, fname in enumerate(current, 1):
                print(f"{idx}. {fname}")
            print(f"{len(current)+1}. [Run all under this node]")
            if path:
                print(f"{len(current)+2}. [Back]")
                print(f"{len(current)+3}. [Exit]")
                extra = 3
            else:
                print(f"{len(current)+2}. [Exit]")
                extra = 2
            choice = input("Choose: ").strip()
            if choice.lower() == 'help':
                print_help()
                input("Press Enter to continue...")
                continue
            try:
                choice = int(choice)
                if 1 <= choice <= len(current):
                    print(f">>> Running only: {current[choice-1]}")
                    run_make_db("make", path + [str(choice-1)])
                    input("Press Enter to continue...")
                elif choice == len(current)+1:
                    print(">>> Running all under this node")
                    run_make_db("make", path)
                    input("Press Enter to continue...")
                elif path and choice == len(current)+2:
                    path.pop()
                    return
                elif choice == len(current)+extra:
                    print("Exiting. Have a nice day!")
                    sys.exit(0)
                else:
                    print("Invalid input.")
                    input("Press Enter to continue...")
            except Exception:
                print("Invalid input.")
                input("Press Enter to continue...")

def run_clean():
    print("\nCleaning (dropping) all DB tables ...")
    result = subprocess.run([sys.executable, MAKE_DB_SCRIPT, "clean"])
    if result.returncode == 0:
        print("All tables dropped successfully!\n")
    else:
        print("There was an error in cleaning the DB!\n")
    input("Press Enter to continue...")

def main_menu():
    while True:
        print("\n=== MAIN MENU ===")
        print("1. Browse and run steps from your config.json tree")
        print("2. Clean Project (drop all tables)")
        print("3. Help")
        print("4. Exit")
        choice = input("Choose: ").strip()
        if choice.lower() == "help" or choice == "3":
            print_help()
            input("Press Enter to continue...")
        elif choice == "1":
            config = load_config()
            navigate_menu(config["make"])
        elif choice == "2":
            run_clean()
        elif choice == "4":
            print("Exiting. Have a nice day!")
            break
        else:
            print("Invalid input. Try again.")

if __name__ == "__main__":
    fix_bulk_insert_path()
    print_welcome()
    main_menu()
