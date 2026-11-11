# 🎵 Chinook Data Warehouse (OLTP to OLAP Star Schema)

![MySQL](https://img.shields.io/badge/MySQL-8.0+-005C84?style=for-the-badge&logo=mysql&logoColor=white)
![Data Warehousing](https://img.shields.io/badge/Data_Warehousing-Kimball_Model-FF6F00?style=for-the-badge&logo=databricks&logoColor=white)
![Power BI](https://img.shields.io/badge/BI_Ready-Power_BI_%7C_Tableau-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Status](https://img.shields.io/badge/Status-Completed-2EA44F?style=for-the-badge)

> **📌 Suggested GitHub Repository Name:** `chinook-olap-data-warehouse`  
> **📝 Suggested GitHub Description:** `End-to-end Kimball Star Schema Data Warehouse implementation migrating the Chinook OLTP music store database into an analytical OLAP environment using MySQL & BI Views.`

---

## 📖 Project Overview

**MusicRhythm Corp.** (based on the classic **Chinook Digital Media Store** dataset) operates on a normalized transactional database (**OLTP**) optimized for day-to-day operations. However, running complex business intelligence queries and multi-dimensional sales reporting directly on an OLTP schema causes performance bottlenecks.

This project designs and implements a **Kimball-style Star Schema Data Warehouse (`chinook_dw`)** in MySQL, transforming raw transactional records into an analytics-ready **OLAP** environment complete with denormalized dimensions, audit tracking, composite fact granularity, and a unified Business Intelligence Data Mart view.

---

## 🏗️ Data Warehouse Architecture (Star Schema)

The data warehouse follows a **3-Dimension + 1-Fact** Star Schema architecture designed specifically for **Sales Analytics**:

```text
                    +-------------------+
                    |     Track_Dim     |
                    |-------------------|
                    | PK TrackId        |
                    |    TrackName      |
                    |    AlbumTitle     |
                    |    ArtistName     |
                    |    GenreName      |
                    |    CreateDate     |
                    |    UpdateDate     |
                    +---------+---------+
                              |
                              | (1:N)
                              v
+-------------------+   +-------------------+   +-------------------+
|   Customer_Dim    |   |   Invoice_Fact    |   |     Date_Dim      |
|-------------------|   |-------------------|   |-------------------|
| PK CustomerId     |-->| PK,FK InvoiceId   |<--| PK DateKey        |
|    FirstName      |   | PK,FK TrackId     |   |    Day            |
|    LastName       |   | FK    CustomerId  |   |    Month          |
|    Company        |   | FK    SaleDateID  |   |    MonthName      |
|    City / Country |   |       Quantity    |   |    Quarter        |
|    CreateDate     |   |       TotalAmount |   |    Year           |
|    UpdateDate     |   +-------------------+   +-------------------+
+-------------------+
```

---

## 🗂️ Schema Breakdown

### 1. Fact Table
* **`Invoice_Fact`**: Captures every individual track sale event.
  * **Granularity:** Invoice Line Item level (`InvoiceId` + `TrackId`).
  * **Composite Primary Key:** `(InvoiceId, TrackId)`
  * **Foreign Keys:** `CustomerId`, `TrackId`, `SaleDateID`
  * **Calculated Measures:** `Quantity`, `TotalAmount` ($\text{UnitPrice} \times \text{Quantity}$)

### 2. Dimension Tables
* **`Customer_Dim`** *(SCD Type 1)*: Stores customer demographics and location details (`City`, `State`, `Country`, `PostalCode`) along with automated audit timestamps (`CreateDate`, `UpdateDate`).
* **`Track_Dim`** *(Denormalized)*: Merges `Track`, `Album`, `Artist`, and `Genre` tables from the OLTP source into a single flat dimension for fast query performance, including audit timestamps (`CreateDate`, `UpdateDate`).
* **`Date_Dim`**: Calendar dimension extracted from transaction timestamps supporting time-series rollups (`Day`, `Month`, `MonthName`, `Quarter`, `Year`).

### 3. BI Reporting Layer
* **`Chinook_Datamart` (SQL View)**: A pre-joined, flattened analytical view combining `Invoice_Fact` with all three dimensions via `LEFT JOIN`. Designed for plug-and-play consumption in **Power BI** or **Tableau**.

---

## 🛠️ Tech Stack & Tools

* **Database Engine:** MySQL 8.0+
* **Modeling & ERD:** MySQL Workbench (Reverse Engineering)
* **ETL / Transformations:** Pure SQL (DDL, DML, Views, Joins)
* **BI Visualization:** Power BI Desktop / Tableau

---

## 📂 Repository Structure

```text
├── chinook_dw_solution.sql   # Complete DDL & ETL script (Schema, Tables, Constraints, View)
├── ER_DIAGRAM.png            # Reverse-engineered Star Schema ERD from MySQL Workbench
└── README.md                 # Project documentation and architecture overview
```

---

## 🚀 How to Run This Project

1. **Prerequisites:** Ensure you have **MySQL Server** and **MySQL Workbench** installed, with the source `Chinook_oltp` database loaded.
2. **Clone the Repository:**
   ```bash
   git clone https://github.com/yourusername/chinook-olap-data-warehouse.git
   cd chinook-olap-data-warehouse
   ```
3. **Execute the ETL Script:**
   * Open `chinook_dw_solution.sql` in MySQL Workbench.
   * Run the entire script (`Ctrl + Shift + Enter`) to create the `chinook_dw` database, populate dimensions and facts, and generate the `Chinook_Datamart` view.
4. **Verify Data Mart:**
   ```sql
   SELECT * FROM chinook_dw.Chinook_Datamart LIMIT 10;
   ```
5. **Connect to Power BI:**
   * Open Power BI Desktop $\rightarrow$ **Get Data** $\rightarrow$ **MySQL Database**.
   * Connect to `localhost` and select `chinook_dw` to load the Star Schema or `Chinook_Datamart` view.

---

## 📊 Key Analytical Use Cases Supported

* 💰 **Revenue & Sales Trends:** Analyze `TotalAmount` across years, quarters, and months using `Date_Dim`.
* 🎸 **Genre & Artist Performance:** Identify top-selling music genres, albums, and artists without multi-table joins via `Track_Dim`.
* 🌍 **Geographic Customer Insights:** Track sales distribution by country and city using `Customer_Dim`.

---

## 👩‍💻 Author

**Alishba Naeem**  
*Data Engineering & Business Intelligence Project*