[**English**](README.md) | [**فارسی**](README_fa.md)
---
# **🛒 Online Shoppers Purchase Intention — Data Engineering & ML Project**

![Python](https://img.shields.io/badge/Python-3.10+-blue?logo=python)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)
![Made with Jupyter](https://img.shields.io/badge/Made%20with-Jupyter-orange?logo=jupyter)



## 📘 Project Overview

This project is a complete data analytics and machine learning pipeline built around the Online Shoppers Intention dataset
 from the UCI Machine Learning Repository.
The goal of this project is to predict whether a visitor will make a purchase during their session, based on their browsing behavior and session attributes.


----------------------
The workflow includes:

Data ingestion and cleaning in PostgreSQL

ETL and normalization into dimensional tables

Statistical analysis and data preprocessing

Machine learning model (Random Forest) in Python

Data visualization and insights with Power BI

## 🧩 Project Structure
<br>📂 OnlineShoppersIntention
<br>├── [**OnlineShoppersIntention.sql**](OnlineShoppersIntention.sql)
<br>├── [**OnlineShoppersIntention_ml.ipynb**](OnlineShoppersIntention_ml.ipynb)
<br>├── [**OnlineShoppersIntention.pbix**](OnlineShoppersIntention.pbix)
<br>├── data/online_shoppers_intention.csv
<br>└── README.md                       


-----------------------

⚙️ Step-by-Step Workflow
-

1️⃣ Data Source

Dataset: UCI ML Repository – Online Shoppers Intention

Format: CSV

Size: 12,330 rows × 18 features

2️⃣ Database & ETL (PostgreSQL)

Created normalized tables:

dim_month, dim_visitor_type, dim_weekend, dim_revenue

fact_online_shoppers

Used a robust ETL process to:

Clean inconsistent month names (e.g. “Sept”, “Sep.”, etc.)

Normalize boolean fields (Weekend, Revenue)

Standardize visitor types (Returning_Visitor, New_Visitor)

Script includes diagnostic queries for validation and integrity checks.

📄 File: OnlineShoppersIntention.sql

3️⃣ Statistical Analysis & ML Model (Python)

Loaded the cleaned PostgreSQL data using psycopg2 and pandas

Performed exploratory data analysis (EDA)

Encoded categorical variables and handled missing values

Trained a Random Forest Classifier to predict Revenue (purchase intent)

Evaluated model performance using:

Accuracy

Precision / Recall

ROC-AUC Score

Saved the notebook: OnlineShoppersIntention.ipynb

4️⃣ Visualization (Power BI)

Connected Power BI directly to PostgreSQL for live data refresh

Designed an interactive dashboard featuring:

Visitor behavior trends

Purchase conversion rates

Traffic type performance

Regional insights

Final dashboard file: PowerBI_Dashboard.pbix


-----------------------------------
🧠 Tools & Technologies
-
Category	Tools
Database	PostgreSQL, pgAdmin
Language	Python 3.x
Libraries	pandas, scikit-learn, matplotlib, seaborn
Visualization	Power BI
Environment	Jupyter Notebook
Source	UCI ML Repository
🚀 How to Run Locally
Prerequisites

PostgreSQL 14+

Python 3.9+

Power BI Desktop

Installed Python packages:

pip install pandas scikit-learn psycopg2 matplotlib seaborn

Steps

Clone this repository:

git clone https://github.com/<your-username>/OnlineShoppersIntention.git
cd OnlineShoppersIntention


Run the SQL script in pgAdmin to create tables and load data:
-

\i OnlineShoppersIntention.sql


Open and run the Jupyter Notebook to train and test the ML model:

jupyter notebook OnlineShoppersIntention.ipynb

Open the Power BI file (PowerBI_Dashboard.pbix) and connect it to your PostgreSQL instance.
---------------------------------------
📊 Results

Model Accuracy: ~100% (Random Forest)

Key Insights:

Returning visitors have a higher purchase conversion rate.

Weekend sessions are more likely to result in a purchase.

Specific traffic sources contribute more to conversions.

🧾 References

UCI Machine Learning Repository — Online Shoppers Intention Data Set (Root File)

scikit-learn Documentation

PostgreSQL Official Docs
--------------------------------------
👤 Author

[Omid Jabari]
📧 jabbariomid7@gmail.com
🌐 https://github.com/ChiefOmid
