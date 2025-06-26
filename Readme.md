# DB2 Project: Data Warehouse Automation

**Project Topic:**  
Modeling a comprehensive ...  
*(replace with your actual topic, e.g., "flight reservation and loyalty system")*  
**Supervisor:** Prof. Alireza Basiri

---

## Project Overview

This project demonstrates a full automation pipeline for building, populating, and managing a multi-layered data warehouse environment for the ... domain using SQL Server and Python. The solution covers:

- **Source System:** OLTP-style operational tables
- **Staging Area:** ETL/ELT processing and integration
- **Data Warehouse:** Star schema, facts, and dimensions for analytics

The entire process is automated with Python scripts, menu-based navigation, and detailed logging for performance and troubleshooting.

---

## Project Structure

├── Datawarehouse/
│ ├── Dimensions/
│ └── Facts/
├── Files/
├── Scripts/
│ ├── main.py
│ └── makeDB.py
├── Source/
├── Staging Area/
└── Scripts/config.json



- **Datawarehouse/**: Schema, dimension, and fact creation scripts
- **Source/**: Scripts for source/operational tables and test data
- **Staging Area/**: Scripts for staging schema and ETL logic
- **Scripts/**: Python automation scripts and config

---

## Getting Started

### Prerequisites

- **Python 3.9+** (recommended: 3.11+)
- **SQL Server** (tested with SQL Server 2019+)
- **ODBC Driver 18 for SQL Server**
- Python packages (install with pip):

    ```bash
    pip install pyodbc
    ```

### SQL Server Setup

- Ensure your SQL Server instance is running and accessible.
- Windows Authentication is supported by default.
- Update the `DB_CONFIG` dictionary in `makeDB.py` if your server/database is different.

---

## How to Run

### 1. **Set Up Files**

- Ensure all SQL scripts are present in the correct folders.
- Check and edit `Scripts/config.json` if you wish to change the script execution order.

### 2. **Launch the Menu**

From the project root directory:

```bash
python Scripts/main.py

3. Menu Options
Browse and Run
Navigate the config tree to run any part (source, staging, datawarehouse, etc.)

Clean Project
Drops all tables in all layers to reset your environment.

Exit
Quits the tool.

4. Logs
All steps and SQL script durations are logged in Scripts/makeDB.log.

How It Works
Pipeline structure and run order are defined in config.json.

The menu allows you to:

Browse and execute any pipeline section or the full workflow.

Run all scripts under any node with one click.

Each script is executed in order, with run time recorded for each step.

Customization
Add or Remove Steps:
Edit Scripts/config.json and adjust the folder structure as needed.

Change Database Connection:
Edit the DB_CONFIG dictionary in makeDB.py to match your SQL Server setup.

Contact
For any questions, contact the project owner or
Supervisor: Prof. Alireza Basiri

Enjoy your automated data warehouse build!