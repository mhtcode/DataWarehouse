import json
import subprocess
import sys
import os

CONFIG_PATH = os.path.join('Scripts', 'config.json')
MAKE_DB_SCRIPT = os.path.join('Scripts', 'makeDB.py')

def print_welcome():
    print("="*60)
    print("        Welcome to Your Automated Datawarehouse Manager")
    print("="*60)
    print("Browse and run any part of your pipeline from the menu tree!")
    print("="*60)

def run_make_db(mode, sub_path=None):
    # Pass the sub_path (list of keys) to makeDB.py for partial execution
    cmd = [sys.executable, MAKE_DB_SCRIPT, mode]
    if sub_path:
        cmd += sub_path  # Each subkey as an argument
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
            try:
                choice = int(choice)
                if 1 <= choice <= len(keys):
                    # Step into the next level
                    path.append(keys[choice-1])
                    return navigate_menu(config, path)
                elif choice == len(keys)+1:
                    # Run all under this node
                    print(">>> Running:", ' '.join([MAKE_DB_SCRIPT, 'make'] + path))
                    run_make_db("make", path)
                    input("Press Enter to continue...")
                elif path and choice == len(keys)+2:
                    # Back
                    path.pop()
                    return
                elif choice == len(keys)+extra:
                    # Exit
                    print("Exiting. Have a nice day!")
                    sys.exit(0)
                else:
                    print("Invalid input.")
                    input("Press Enter to continue...")
            except Exception:
                print("Invalid input.")
                input("Press Enter to continue...")
        elif isinstance(current, list):
            # At a list of files, show each file, plus "run all" and back
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
            try:
                choice = int(choice)
                if 1 <= choice <= len(current):
                    # Run a single file
                    print(f">>> Running only: {current[choice-1]}")
                    run_make_db("make", path + [str(choice-1)])
                    input("Press Enter to continue...")
                elif choice == len(current)+1:
                    # Run all
                    print(">>> Running all under this node")
                    run_make_db("make", path)
                    input("Press Enter to continue...")
                elif path and choice == len(current)+2:
                    # Back
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
        print("3. Exit")
        choice = input("Choose: ").strip()
        if choice == "1":
            config = load_config()
            navigate_menu(config["make"])
        elif choice == "2":
            run_clean()
        elif choice == "3":
            print("Exiting. Have a nice day!")
            break
        else:
            print("Invalid input. Try again.")

if __name__ == "__main__":
    print_welcome()
    main_menu()
