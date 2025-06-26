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

```text
.
├── Datawarehouse/
│   ├── Dimensions/
│   └── Facts/
├── Files/
├── Scripts/
│   ├── main.py
│   ├── makeDB.py
│   └── config.json
├── Source/
├── Staging Area/
