# COVID-19 Database Analysis Project

## 📌 Overview

The **COVID-19 Database Analysis Project** is a PostgreSQL-based database project designed to store, manage, and analyze COVID-19 data at both global and Indian state levels.

The project uses **PostgreSQL** as the database management system and **pgAdmin** as the database administration and query tool.

The project focuses on practical SQL concepts such as:

- Database and table creation
- Primary Keys and Foreign Keys
- Joins
- Aggregate Functions
- GROUP BY
- Common Table Expressions (CTEs)
- Stored Procedures
- User-Defined Functions (UDFs)
- Views
- Indexes
- Date-based analysis
- COVID-19 case analysis
- Vaccination analysis
- Indian state-wise analysis

---

## 🛠️ Technologies Used

| Technology | Purpose |
|------------|---------|
| PostgreSQL | Database Management System |
| pgAdmin | Database administration and SQL execution |
| SQL | Data manipulation and analysis |
| PL/pgSQL | Stored Procedures and User-Defined Functions |
| CSV | Source data format |
| Git | Version control |
| GitHub | Repository hosting |

---

# 📂 Project Structure

```text
COVID_DB_Project/
│
├── schema/
│   └── Covid_schema.sql
│		load_data.sql
├── data/
│   ├── countries.csv
│   ├── states.csv
│   ├── districts.csv
│   ├── covid_case_stats.csv
│   ├── vaccination.csv
│   ├── testing.csv
│   ├── global_covid_stats.csv
│   └── mumbai_case_stats.csv
│
├── sql/
│   ├── solutions.sql
│
└── README.md