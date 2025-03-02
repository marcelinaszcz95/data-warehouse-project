# 🏛️Data Warehouse Project


Welcome to the **Data Warehouse** repository! 

The project is about developing a **multi-level data warehouse** using **SQL Server** to consolidate and structure data from ERP and CRM systems. It involves implementing **ETL processes**, **data cleaning**, and **data modeling** to transform raw data into a well-organized, analysis-ready format in the Gold layer. This structured data enables efficient querying and supports downstream analytical use cases.

---

## 📐Data Architecture

The data architecture of this project is based on the Medallion Model, consisting of three layers: Bronze, Silver, and Gold.

- **Bronze Layer**: Stores the raw, unmodified data directly from the source systems, imported from CSV files into the SQL Server database.
- **Silver Layer**: Focuses on data cleansing, standardization, and normalization to make the data ready for analysis.
- **Gold Layer**: Contains business-ready data organized in a star schema, optimized for reporting and analytical purposes.

## 🔍Project Summary

This project encompasses the following key elements:

- **Data Architecture:** Building a contemporary data warehouse with the Medallion Architecture, incorporating Bronze, Silver, and Gold layers.
- **ETL Pipelines:** Extracting, transforming, and loading data from source systems into the data warehouse.
- **Data Modeling:** Crafting fact and dimension tables that are optimized for efficient analytical querying.
- **Analytics & Reporting:** Developing SQL-based reports and interactive dashboards to provide actionable insights (future).

## 🛠️Project Requirements

### 🧱Building the Data Warehouse (Data Engineering)
Create a modern data warehouse using SQL Server to aggregate sales data, facilitating analytical reporting and data-driven decision-making.

#### Specifications

- **Data Sources**: Import data from two distinct systems (ERP and CRM) provided in CSV format.
- **Data Quality**: Perform data cleaning to address and resolve any quality issues before analysis.
- **Integration**: Merge both data sources into a unified, user-friendly data model optimized for analytical queries.
- **Scope**: Focus exclusively on the most recent dataset; historical data processing is not needed.
- **Documentation**: Provide comprehensive documentation of the data model to assist business stakeholders and analytics teams.
---

#### Objective
Develop SQL-based analytics to deliver detailed insights into:
- **Customer Behavior**
- **Product Performance**
- **Sales Trends**

These insights empower stakeholders with key busines metrics, enabling strategic decision-making.

---

## License 

This project is licensed under the [Apache 2.0](LICENSE). 

