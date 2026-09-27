# Online Banking Database (SQL Server)
A relational database design for an online banking platform, built as part of my MSc Data Science coursework. The project covers the full design and implementation of a system to manage customers, accounts/products, transactions, overdue fees, and repayments.

Overview

The brief was to design a normalised (3NF) SQL Server database for an online bank, including:

Customer records (personal details, login credentials, contact info)
Bank accounts/products (Savings, Checking, Loan, Credit Card, Investment)
Transactions, including due dates and completion status
Overdue fee tracking and partial/full repayments
Database Design
Normalised to Third Normal Form (3NF) to reduce redundancy and maintain data integrity
Primary/foreign key relationships enforce referential integrity across Customer, Account, Transaction, OverdueFee, and Repayment tables
CHECK constraints enforce valid account types/statuses, payment methods, and positive amounts
A filtered unique index on the loan/credit reference number allows multiple NULLs while still enforcing uniqueness where a reference number is present
Database Objects

The script (sql/database-script.sql) includes:

Stored Procedures

usp_SearchAccountByName — search accounts/products by name, sorted by most recently opened
usp_GetPaymentsDueSoon — returns loan/credit payments due within 5 days
usp_InsertCustomer — inserts a new customer, with duplicate-username validation
usp_UpdateCustomer — partial customer updates (only supplied fields change)
usp_MonthlyTransactionSummary — monthly transaction and overdue-fee summary grouped by account type, with input validation

Views

vw_TransactionsWithOverdueFees — all transactions with any associated overdue fees and computed status columns
vw_CustomersUnder50PctRepayment — customers who have repaid less than 50% of their overdue fees, with a running count
vw_CustomerHealthDashboard — per-customer account/transaction summary with an overdue-fee risk flag

Function

fn_GetCustomerOutstandingBalance — scalar UDF calculating a customer's total outstanding overdue balance

Trigger

trg_AutoCloseAccountOnFinalPayment — automatically closes a Loan/Credit Card account once its final pending transaction is completed, verified with both a positive test and a negative test (confirms it does not fire while another transaction is still pending)
How to Run
Clone this repository
Open sql/database-script.sql in SQL Server Management Studio (SSMS)
Execute against a new or existing SQL Server instance
Skills Demonstrated
Relational database design and normalisation (3NF)
T-SQL (DDL/DML, stored procedures, functions, triggers, views)
Data integrity via constraints, filtered indexes, and referential relationships
Query writing with joins, subqueries, CASE expressions, and window functions
