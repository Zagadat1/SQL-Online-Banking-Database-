CREATE DATABASE OnlineBankingDB;
GO

USE OnlineBankingDB;
GO

-- TABLE 1: Customer
CREATE TABLE Customer (
    CustomerID      INT             IDENTITY(1,1)   PRIMARY KEY,
    FirstName       NVARCHAR(50)    NOT NULL,
    LastName        NVARCHAR(50)    NOT NULL,
    Address         NVARCHAR(255)   NOT NULL,
    DateOfBirth     DATE            NOT NULL,
    Username        NVARCHAR(50)    NOT NULL        UNIQUE,
    PasswordHash    NVARCHAR(255)   NOT NULL,
    Email           NVARCHAR(100)   NULL,
    Phone           NVARCHAR(20)    NULL,
    IsActive        BIT             NOT NULL        DEFAULT 1,
    ClosureDate     DATE            NULL
);
GO

-- TABLE 2: Account
CREATE TABLE Account (
    AccountID           INT             IDENTITY(1,1)   PRIMARY KEY,
    CustomerID          INT             NOT NULL,
    AccountName         NVARCHAR(100)   NOT NULL,
    AccountType         NVARCHAR(20)    NOT NULL,
    OpeningDate         DATE            NOT NULL,
    Status              NVARCHAR(10)    NOT NULL        DEFAULT 'Active',
    ClosedFrozenDate    DATE            NULL,
    ReferenceNumber     NVARCHAR(50)    NULL,

    CONSTRAINT FK_Account_Customer
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),

    CONSTRAINT CHK_AccountType
        CHECK (AccountType IN ('Savings', 'Checking', 'Loan', 'Credit Card', 'Investment')),

    CONSTRAINT CHK_AccountStatus
        CHECK (Status IN ('Active', 'Dormant', 'Closed', 'Frozen'))
);
GO

-- Filtered unique index: allows multiple NULLs but enforces uniqueness where value exists
CREATE UNIQUE INDEX UX_Account_ReferenceNumber
    ON Account(ReferenceNumber)
    WHERE ReferenceNumber IS NOT NULL;
GO

-- TABLE 3: Transaction
CREATE TABLE [Transaction] (
    TransactionID       INT             IDENTITY(1,1)   PRIMARY KEY,
    CustomerID          INT             NOT NULL,
    AccountID           INT             NOT NULL,
    Amount              DECIMAL(18,2)   NOT NULL,
    TransactionDate     DATETIME2       NOT NULL        DEFAULT SYSUTCDATETIME(),
    DueDate             DATE            NULL,
    CompletionDate      DATETIME2       NULL,

    CONSTRAINT FK_Transaction_Customer
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),

    CONSTRAINT FK_Transaction_Account
        FOREIGN KEY (AccountID) REFERENCES Account(AccountID),

    CONSTRAINT CHK_Amount
        CHECK (Amount > 0)
);
GO

-- TABLE 4: OverdueFee
CREATE TABLE OverdueFee (
    OverdueFeeID    INT             IDENTITY(1,1)   PRIMARY KEY,
    TransactionID   INT             NOT NULL,
    CustomerID      INT             NOT NULL,
    FeeAmount       DECIMAL(18,2)   NOT NULL,
    DaysOverdue     INT             NOT NULL,
    TotalOwed       DECIMAL(18,2)   NOT NULL,
    TotalRepaid     DECIMAL(18,2)   NOT NULL        DEFAULT 0.00,
    FeeDate         DATE            NOT NULL        DEFAULT CAST(GETDATE() AS DATE),

    CONSTRAINT FK_OverdueFee_Transaction
        FOREIGN KEY (TransactionID) REFERENCES [Transaction](TransactionID),

    CONSTRAINT FK_OverdueFee_Customer
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),

    CONSTRAINT CHK_FeeAmount
        CHECK (FeeAmount >= 0),

    CONSTRAINT CHK_TotalRepaid
        CHECK (TotalRepaid >= 0)
);
GO

-- TABLE 5: Repayment
CREATE TABLE Repayment (
    RepaymentID     INT             IDENTITY(1,1)   PRIMARY KEY,
    OverdueFeeID    INT             NOT NULL,
    CustomerID      INT             NOT NULL,
    RepaymentDate   DATETIME2       NOT NULL        DEFAULT SYSUTCDATETIME(),
    Amount          DECIMAL(18,2)   NOT NULL,
    PaymentMethod   NVARCHAR(20)    NOT NULL,

    CONSTRAINT FK_Repayment_OverdueFee
        FOREIGN KEY (OverdueFeeID) REFERENCES OverdueFee(OverdueFeeID),

    CONSTRAINT FK_Repayment_Customer
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),

    CONSTRAINT CHK_RepaymentAmount
        CHECK (Amount > 0),

    CONSTRAINT CHK_PaymentMethod
        CHECK (PaymentMethod IN ('Bank Transfer', 'Card', 'Cash'))
);
GO

-- POPULATE CUSTOMERS TABLE
INSERT INTO Customer (FirstName, LastName, Address, DateOfBirth, Username, PasswordHash, Email, Phone, IsActive, ClosureDate)
VALUES
('James',   'Harrison', '12 Baker Street, London, E1 4AA',      '1985-03-15', 'jharrison', 'hashed_pw_001', 'james.harrison@email.com', '07911123456', 1, NULL),
('Sophie',  'Clarke',   '45 Oak Avenue, Manchester, M2 3BB',    '1990-07-22', 'sclarke',   'hashed_pw_002', 'sophie.clarke@email.com',  '07922234567', 1, NULL),
('Daniel',  'Murphy',   '8 Pine Road, Birmingham, B3 1CC',      '1978-11-08', 'dmurphy',   'hashed_pw_003', NULL,                       '07933345678', 1, NULL),
('Emily',   'Watson',   '33 Elm Close, Leeds, LS4 2DD',         '1995-05-30', 'ewatson',   'hashed_pw_004', 'emily.watson@email.com',   NULL,          1, NULL),
('Michael', 'Thompson', '77 Maple Lane, Bristol, BS5 3EE',      '1982-09-14', 'mthompson', 'hashed_pw_005', 'michael.t@email.com',      '07955567890', 1, NULL),
('Laura',   'Bennett',  '19 Cedar Way, Edinburgh, EH1 4FF',     '1993-01-25', 'lbennett',  'hashed_pw_006', 'laura.bennett@email.com',  '07966678901', 1, NULL),
('Robert',  'Jenkins',  '55 Birch Street, Cardiff, CF10 5GG',   '1970-06-18', 'rjenkins',  'hashed_pw_007', NULL,                       NULL,          1, NULL),
('Olivia',  'Price',    '21 Willow Drive, Nottingham, NG7 6HH', '1988-12-03', 'oprice',    'hashed_pw_008', 'olivia.price@email.com',   '07988890123', 1, NULL),
('Thomas',  'Evans',    '64 Ash Court, Liverpool, L1 7II',      '1975-04-11', 'tevans',    'hashed_pw_009', 'thomas.evans@email.com',   '07999901234', 0, '2024-11-15'),
('Chloe',   'Nguyen',   '3 Chestnut Row, Sheffield, S1 8JJ',    '1999-08-27', 'cnguyen',   'hashed_pw_010', 'chloe.nguyen@email.com',   '07900012345', 1, NULL);
GO

-- POPULATE ACCOUNTS TABLE
INSERT INTO Account (CustomerID, AccountName, AccountType, OpeningDate, Status, ClosedFrozenDate, ReferenceNumber)
VALUES
(1,  'James Personal Savings',      'Savings',     '2020-01-10', 'Active',  NULL,         NULL),
(1,  'James Home Loan',             'Loan',         '2021-06-01', 'Active',  NULL,         'LN-2021-001'),
(2,  'Sophie Current Account',      'Checking',     '2019-03-22', 'Active',  NULL,         NULL),
(2,  'Sophie Credit Card',          'Credit Card',  '2022-08-15', 'Active',  NULL,         NULL),
(3,  'Daniel Investment Portfolio', 'Investment',   '2018-11-05', 'Active',  NULL,         NULL),
(4,  'Emily Savings Account',       'Savings',      '2021-02-28', 'Dormant', NULL,         NULL),
(5,  'Michael Car Loan',            'Loan',         '2022-03-10', 'Active',  NULL,         'LN-2022-002'),
(6,  'Laura Checking Account',      'Checking',     '2020-07-19', 'Active',  NULL,         NULL),
(7,  'Robert Credit Card',          'Credit Card',  '2019-09-30', 'Frozen',  '2024-06-01', NULL),
(8,  'Olivia Home Loan',            'Loan',         '2023-01-14', 'Active',  NULL,         'LN-2023-003'),
(9,  'Thomas Old Savings',          'Savings',      '2015-05-20', 'Closed',  '2024-11-15', NULL),
(10, 'Chloe Student Account',       'Checking',     '2023-09-01', 'Active',  NULL,         NULL);
GO

-- POPULATE TRANSACTIONS TABLE
INSERT INTO [Transaction] (CustomerID, AccountID, Amount, TransactionDate, DueDate, CompletionDate)
VALUES
(1,  2,  1500.00, '2024-10-01 09:00:00', '2024-10-15', '2024-10-14 10:00:00'),
(1,  2,  1500.00, '2024-11-01 09:00:00', '2024-11-15', '2024-11-20 10:00:00'),
(2,  4,   200.00, '2024-10-05 11:00:00', '2024-10-20', '2024-10-19 09:00:00'),
(2,  4,   200.00, '2024-11-05 11:00:00', '2024-11-20', NULL),
(3,  5,  5000.00, '2024-09-15 14:00:00', NULL,          '2024-09-16 10:00:00'),
(4,  6,   100.00, '2024-10-10 08:00:00', '2024-10-25', '2024-11-05 09:00:00'),
(5,  7,   800.00, '2024-10-20 10:00:00', '2024-11-05', '2024-11-04 11:00:00'),
(5,  7,   800.00, '2024-11-20 10:00:00', '2024-12-05', NULL),
(6,  8,   300.00, '2024-11-01 13:00:00', '2024-11-28', '2024-11-27 14:00:00'),
(8,  10, 2000.00, '2024-10-15 09:00:00', '2024-11-15', '2024-11-20 10:00:00'),
(8,  10, 2000.00, '2024-11-15 09:00:00', '2024-12-15', NULL),
(10, 12,  150.00, '2024-11-25 16:00:00', NULL,          '2024-11-25 16:30:00');
GO

-- POPULATE OVERDUE FEES TABLE
INSERT INTO OverdueFee (TransactionID, CustomerID, FeeAmount, DaysOverdue, TotalOwed, TotalRepaid, FeeDate)
VALUES
(2,  1, 25.00,  5,  25.00, 25.00, '2024-11-21'),
(6,  4, 50.00, 11,  50.00, 20.00, '2024-11-06'),
(10, 8, 75.00,  5,  75.00,  0.00, '2024-11-21'),
(2,  1, 15.00,  3,  15.00, 15.00, '2024-11-24'),
(6,  4, 30.00,  6,  30.00,  5.00, '2024-11-12'),
(10, 8, 40.00,  8,  40.00,  0.00, '2024-11-29'),
(4,  2, 20.00,  4,  20.00,  8.00, '2024-11-25');
GO

-- POPULATE REPAYMENTS TABLE
INSERT INTO Repayment (OverdueFeeID, CustomerID, RepaymentDate, Amount, PaymentMethod)
VALUES
(1, 1, '2024-11-22 10:00:00', 25.00, 'Bank Transfer'),
(2, 4, '2024-11-10 09:00:00', 20.00, 'Card'),
(3, 8, '2024-11-22 11:00:00',  0.01, 'Cash'),
(4, 1, '2024-11-25 14:00:00', 15.00, 'Bank Transfer'),
(5, 4, '2024-11-15 10:00:00',  5.00, 'Card'),
(7, 2, '2024-11-26 09:00:00',  8.00, 'Bank Transfer'),
(1, 1, '2024-11-23 08:00:00',  0.01, 'Cash'),
(2, 4, '2024-11-20 15:00:00',  0.01, 'Card'),
(3, 8, '2024-11-28 12:00:00',  0.01, 'Bank Transfer');
GO

-- SP: Search bank accounts/products by name
-- Returns results sorted by most recently opened first
-- =============================================
CREATE PROCEDURE usp_SearchAccountByName
    @AccountName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.AccountID,
        a.AccountName,
        a.AccountType,
        a.OpeningDate,
        a.Status,
        a.ReferenceNumber,
        c.FirstName + ' ' + c.LastName   AS CustomerName
    FROM Account a
    INNER JOIN Customer c ON a.CustomerID = c.CustomerID
    WHERE a.AccountName LIKE '%' + @AccountName + '%'
    ORDER BY a.OpeningDate DESC;
END;
GO

-- SP: Return all pending loan or credit payments
-- due within 5 days of the current system date
-- =============================================
CREATE PROCEDURE usp_GetPaymentsDueSoon
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.TransactionID,
        c.FirstName + ' ' + c.LastName       AS CustomerName,
        a.AccountName,
        a.AccountType,
        t.Amount,
        t.DueDate,
        DATEDIFF(DAY, CAST(GETDATE() AS DATE), t.DueDate) AS DaysUntilDue
    FROM [Transaction] t
    INNER JOIN Customer c ON t.CustomerID = c.CustomerID
    INNER JOIN Account  a ON t.AccountID  = a.AccountID
    WHERE
        t.CompletionDate IS NULL
        AND t.DueDate IS NOT NULL
        AND a.AccountType IN ('Loan', 'Credit Card')
        AND DATEDIFF(DAY, CAST(GETDATE() AS DATE), t.DueDate) < 5
        AND DATEDIFF(DAY, CAST(GETDATE() AS DATE), t.DueDate) >= 0
    ORDER BY t.DueDate ASC;
END;
GO

-- SP: Insert a new bank customer
-- =============================================
CREATE PROCEDURE usp_InsertCustomer
    @FirstName      NVARCHAR(50),
    @LastName       NVARCHAR(50),
    @Address        NVARCHAR(255),
    @DateOfBirth    DATE,
    @Username       NVARCHAR(50),
    @PasswordHash   NVARCHAR(255),
    @Email          NVARCHAR(100) = NULL,
    @Phone          NVARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if username already exists
    IF EXISTS (SELECT 1 FROM Customer WHERE Username = @Username)
    BEGIN
        RAISERROR('Username already exists. Please choose a different username.', 16, 1);
        RETURN;
    END

    INSERT INTO Customer (FirstName, LastName, Address, DateOfBirth, Username, PasswordHash, Email, Phone, IsActive, ClosureDate)
    VALUES (@FirstName, @LastName, @Address, @DateOfBirth, @Username, @PasswordHash, @Email, @Phone, 1, NULL);

    -- Return the newly created CustomerID
    SELECT SCOPE_IDENTITY() AS NewCustomerID;
END;
GO

-- SP: Update details for an existing customer
-- =============================================
CREATE PROCEDURE usp_UpdateCustomer
    @CustomerID     INT,
    @FirstName      NVARCHAR(50)    = NULL,
    @LastName       NVARCHAR(50)    = NULL,
    @Address        NVARCHAR(255)   = NULL,
    @Email          NVARCHAR(100)   = NULL,
    @Phone          NVARCHAR(20)    = NULL,
    @IsActive       BIT             = NULL,
    @ClosureDate    DATE            = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Check customer exists
    IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID)
    BEGIN
        RAISERROR('Customer not found. Please check the CustomerID.', 16, 1);
        RETURN;
    END

    UPDATE Customer
    SET
        FirstName   = ISNULL(@FirstName,    FirstName),
        LastName    = ISNULL(@LastName,     LastName),
        Address     = ISNULL(@Address,      Address),
        Email       = ISNULL(@Email,        Email),
        Phone       = ISNULL(@Phone,        Phone),
        IsActive    = ISNULL(@IsActive,     IsActive),
        ClosureDate = ISNULL(@ClosureDate,  ClosureDate)
    WHERE CustomerID = @CustomerID;

    -- Return updated record
    SELECT
        CustomerID, FirstName, LastName,
        Address, Email, Phone,
        IsActive, ClosureDate
    FROM Customer
    WHERE CustomerID = @CustomerID;
END;
GO

-- VIEW: All transactions including overdue fees
-- Shows all past and current transactions with
-- any associated overdue fees per requirement 3
-- =============================================
CREATE VIEW vw_TransactionsWithOverdueFees
AS
SELECT
    t.TransactionID,
    c.CustomerID,
    c.FirstName + ' ' + c.LastName         AS CustomerName,
    a.AccountID,
    a.AccountName,
    a.AccountType,
    t.Amount                                AS TransactionAmount,
    t.TransactionDate,
    t.DueDate,
    t.CompletionDate,
    CASE
        WHEN t.CompletionDate IS NULL THEN 'Pending'
        WHEN t.CompletionDate > t.DueDate  THEN 'Completed Late'
        ELSE 'Completed On Time'
    END                                     AS TransactionStatus,
    o.OverdueFeeID,
    o.FeeAmount,
    o.DaysOverdue,
    o.TotalOwed,
    o.TotalRepaid,
    o.TotalOwed - o.TotalRepaid             AS OutstandingBalance,
    o.FeeDate,
    CASE
        WHEN o.OverdueFeeID IS NULL THEN 'No Fee'
        WHEN o.TotalOwed - o.TotalRepaid <= 0 THEN 'Fully Repaid'
        WHEN o.TotalRepaid > 0 THEN 'Partially Repaid'
        ELSE 'Unpaid'
    END                                     AS FeeStatus
FROM [Transaction] t
INNER JOIN Customer c ON t.CustomerID = c.CustomerID
INNER JOIN Account  a ON t.AccountID  = a.AccountID
LEFT JOIN  OverdueFee o ON t.TransactionID = o.TransactionID
GO

-- VIEW: Customers who paid less than 50% of
-- their total overdue fees, with count
-- Satisfies requirement 5
-- =============================================
CREATE VIEW vw_CustomersUnder50PctRepayment
AS
SELECT
    c.CustomerID,
    c.FirstName + ' ' + c.LastName         AS CustomerName,
    c.Email,
    c.Phone,
    SUM(o.TotalOwed)                        AS TotalFeesOwed,
    SUM(o.TotalRepaid)                      AS TotalFeesRepaid,
    SUM(o.TotalOwed) - SUM(o.TotalRepaid)   AS TotalOutstanding,
    CAST(
        CASE
            WHEN SUM(o.TotalOwed) = 0 THEN 0
            ELSE (SUM(o.TotalRepaid) / SUM(o.TotalOwed)) * 100
        END
    AS DECIMAL(5,2))                        AS RepaymentPercentage
FROM Customer c
INNER JOIN OverdueFee o ON c.CustomerID = o.CustomerID
GROUP BY
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.Email,
    c.Phone
HAVING
    CASE
        WHEN SUM(o.TotalOwed) = 0 THEN 0
        ELSE (SUM(o.TotalRepaid) / SUM(o.TotalOwed)) * 100
    END < 50;
GO


-- Query the view and include total count
SELECT
    *,
    COUNT(*) OVER () AS TotalCustomersUnder50Pct
FROM vw_CustomersUnder50PctRepayment
ORDER BY RepaymentPercentage ASC;


-- See all transactions with fee information
SELECT * FROM vw_TransactionsWithOverdueFees
ORDER BY TransactionDate DESC;

-- Filter to only transactions that have overdue fees
SELECT * FROM vw_TransactionsWithOverdueFees
WHERE OverdueFeeID IS NOT NULL
ORDER BY TransactionDate DESC;

-- Filter to only pending transactions
SELECT * FROM vw_TransactionsWithOverdueFees
WHERE TransactionStatus = 'Pending'
ORDER BY DueDate ASC;


-- TRIGGER: Auto-close Loan or Credit Card account
-- when final scheduled payment is completed
-- Fires on UPDATE of Transaction table
-- =============================================
CREATE TRIGGER trg_AutoCloseAccountOnFinalPayment
ON [Transaction]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Only proceed if CompletionDate was just set (changed from NULL to a value)
    -- 'inserted' holds the new row state, 'deleted' holds the old row state
    IF NOT EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN deleted d ON i.TransactionID = d.TransactionID
        WHERE d.CompletionDate IS NULL
          AND i.CompletionDate IS NOT NULL
    )
    BEGIN
        RETURN; -- No completion happened, exit trigger
    END

    -- Find accounts affected by this update
    -- where the account type is Loan or Credit Card
    -- and there are no remaining pending transactions
    DECLARE @AccountsToClose TABLE (AccountID INT);

    INSERT INTO @AccountsToClose (AccountID)
    SELECT DISTINCT i.AccountID
    FROM inserted i
    INNER JOIN deleted d   ON i.TransactionID = d.TransactionID
    INNER JOIN Account  a  ON i.AccountID     = a.AccountID
    WHERE
        -- Payment was just completed in this update
        d.CompletionDate IS NULL
        AND i.CompletionDate IS NOT NULL
        -- Account must be Loan or Credit Card
        AND a.AccountType IN ('Loan', 'Credit Card')
        -- Account must currently be Active
        AND a.Status = 'Active'
        -- No other pending transactions exist for this account
        AND NOT EXISTS (
            SELECT 1
            FROM [Transaction] t
            WHERE t.AccountID = i.AccountID
              AND t.CompletionDate IS NULL
              AND t.TransactionID <> i.TransactionID
        );

    -- Close all qualifying accounts
    UPDATE Account
    SET
        Status           = 'Closed',
        ClosedFrozenDate = CAST(GETDATE() AS DATE)
    WHERE AccountID IN (SELECT AccountID FROM @AccountsToClose);

    -- Confirmation message showing which accounts were closed
    IF @@ROWCOUNT > 0
    BEGIN
        PRINT 'Trigger fired: One or more Loan/Credit Card accounts have been automatically closed.';
    END
END;
GO

-- Testing the Trigger

-- BEFORE: Check account 7 (Michael Car Loan) status
SELECT AccountID, AccountName, Status, ClosedFrozenDate
FROM Account
WHERE AccountID = 7;

-- Complete the final pending transaction on Michael's Car Loan (TransactionID = 8)
UPDATE [Transaction]
SET CompletionDate = SYSUTCDATETIME()
WHERE TransactionID = 8;

-- AFTER: Trigger should have auto-closed account 7
SELECT AccountID, AccountName, Status, ClosedFrozenDate
FROM Account
WHERE AccountID = 7;


-- SP: Monthly Transaction Summary Report
-- Returns transaction counts, amounts and
-- overdue fee totals grouped by account type
-- for a specified month and year
-- =============================================
CREATE PROCEDURE usp_MonthlyTransactionSummary
    @Month  INT,
    @Year   INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate month input
    IF @Month < 1 OR @Month > 12
    BEGIN
        RAISERROR('Invalid month. Please enter a value between 1 and 12.', 16, 1);
        RETURN;
    END

    -- Validate year input
    IF @Year < 2000 OR @Year > YEAR(GETDATE())
    BEGIN
        RAISERROR('Invalid year. Please enter a year between 2000 and the current year.', 16, 1);
        RETURN;
    END

    SELECT
        a.AccountType,
        COUNT(t.TransactionID)                          AS TotalTransactions,
        SUM(t.Amount)                                   AS TotalTransactionAmount,
        SUM(CASE
                WHEN t.CompletionDate IS NULL THEN 1
                ELSE 0
            END)                                        AS PendingTransactions,
        SUM(CASE
                WHEN t.CompletionDate IS NOT NULL
                 AND t.CompletionDate > t.DueDate THEN 1
                ELSE 0
            END)                                        AS LateTransactions,
        ISNULL(SUM(o.FeeAmount), 0)                     AS TotalOverdueFees,
        ISNULL(SUM(o.TotalRepaid), 0)                   AS TotalFeesRepaid,
        ISNULL(SUM(o.TotalOwed - o.TotalRepaid), 0)     AS TotalFeesOutstanding
    FROM [Transaction] t
    INNER JOIN Account    a ON t.AccountID    = a.AccountID
    LEFT JOIN  OverdueFee o ON t.TransactionID = o.TransactionID
    WHERE
        MONTH(t.TransactionDate) = @Month
        AND YEAR(t.TransactionDate)  = @Year
    GROUP BY
        a.AccountType
    ORDER BY
        TotalTransactionAmount DESC;

    -- Also return the overall monthly totals as a summary row
    SELECT
        COUNT(t.TransactionID)          AS GrandTotalTransactions,
        SUM(t.Amount)                   AS GrandTotalAmount,
        ISNULL(SUM(o.FeeAmount), 0)     AS GrandTotalFees,
        ISNULL(SUM(o.TotalRepaid), 0)   AS GrandTotalRepaid,
        DATENAME(MONTH, DATEFROMPARTS(@Year, @Month, 1))
            + ' ' + CAST(@Year AS NVARCHAR(4)) AS ReportPeriod
    FROM [Transaction] t
    LEFT JOIN OverdueFee o ON t.TransactionID = o.TransactionID
    WHERE
        MONTH(t.TransactionDate) = @Month
        AND YEAR(t.TransactionDate)  = @Year;
END;
GO

-- This is how to call it 

-- Get summary for November 2024
EXEC usp_MonthlyTransactionSummary @Month = 11, @Year = 2024;

-- Get summary for October 2024
EXEC usp_MonthlyTransactionSummary @Month = 10, @Year = 2024;

-- UDF: Calculate total outstanding overdue
-- balance for a given customer
-- =============================================
CREATE FUNCTION fn_GetCustomerOutstandingBalance
(
    @CustomerID INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @OutstandingBalance DECIMAL(18,2);

    SELECT @OutstandingBalance = ISNULL(SUM(TotalOwed - TotalRepaid), 0)
    FROM OverdueFee
    WHERE CustomerID = @CustomerID;

    RETURN @OutstandingBalance;
END;
GO


-- VIEW: Customer Account Health Dashboard
-- Summarises each customer's account portfolio,
-- transaction history and overdue fee position
-- =============================================
CREATE VIEW vw_CustomerHealthDashboard
AS
SELECT
    c.CustomerID,
    c.FirstName + ' ' + c.LastName             AS CustomerName,
    c.Email,
    c.Phone,
    c.IsActive,
    c.ClosureDate,

    -- Account summary
    COUNT(DISTINCT a.AccountID)                 AS TotalAccounts,
    SUM(CASE
            WHEN a.Status = 'Active'  THEN 1 ELSE 0
        END)                                    AS ActiveAccounts,
    SUM(CASE
            WHEN a.Status = 'Frozen'  THEN 1 ELSE 0
        END)                                    AS FrozenAccounts,
    SUM(CASE
            WHEN a.Status = 'Closed'  THEN 1 ELSE 0
        END)                                    AS ClosedAccounts,
    SUM(CASE
            WHEN a.Status = 'Dormant' THEN 1 ELSE 0
        END)                                    AS DormantAccounts,

    -- Transaction summary
    COUNT(DISTINCT t.TransactionID)             AS TotalTransactions,
    ISNULL(SUM(t.Amount), 0)                    AS TotalTransactionValue,
    SUM(CASE
            WHEN t.CompletionDate IS NULL
             AND t.DueDate IS NOT NULL THEN 1
            ELSE 0
        END)                                    AS PendingPayments,

    -- Overdue fee summary using scalar UDF
    dbo.fn_GetCustomerOutstandingBalance(c.CustomerID) AS TotalOutstandingFees,

    -- Risk flag
    CASE
        WHEN dbo.fn_GetCustomerOutstandingBalance(c.CustomerID) > 100  THEN 'High Risk'
        WHEN dbo.fn_GetCustomerOutstandingBalance(c.CustomerID) > 0    THEN 'Medium Risk'
        ELSE 'Low Risk'
    END                                         AS RiskFlag

FROM Customer c
LEFT JOIN Account     a ON c.CustomerID = a.CustomerID
LEFT JOIN [Transaction] t ON c.CustomerID = t.CustomerID
GROUP BY
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.Email,
    c.Phone,
    c.IsActive,
    c.ClosureDate;
GO

-- This is how to query the dashboard 
-- View all customers with their health summary
SELECT * FROM vw_CustomerHealthDashboard
ORDER BY TotalOutstandingFees DESC;

-- View only high risk customers
SELECT * FROM vw_CustomerHealthDashboard
WHERE RiskFlag = 'High Risk';

-- View a specific customer
SELECT * FROM vw_CustomerHealthDashboard
WHERE CustomerID = 8;

-- TESTING ALL DATABASE OBJECTS

-- =============================================
-- TEST 1a: Search for 'Loan' accounts
-- Expected: Returns all loan accounts,
-- most recently opened first
-- =============================================
EXEC usp_SearchAccountByName @AccountName = 'Loan';

-- =============================================
-- TEST 1b: Search for 'Credit' accounts
-- Expected: Returns Sophie Credit Card
-- and Robert Credit Card
-- =============================================
EXEC usp_SearchAccountByName @AccountName = 'Credit';

-- =============================================
-- TEST 1c: Search for a specific customer name
-- Expected: Returns James Personal Savings
-- and James Home Loan
-- =============================================
EXEC usp_SearchAccountByName @AccountName = 'James';

-- =============================================
-- TEST 1d: Search for something that doesnt exist
-- Expected: Returns empty result set
-- =============================================
EXEC usp_SearchAccountByName @AccountName = 'Mortgage';





-- =============================================
-- Insert test transaction due in 3 days
-- =============================================
INSERT INTO [Transaction] (CustomerID, AccountID, Amount, TransactionDate, DueDate, CompletionDate)
VALUES (2, 4, 350.00, GETDATE(), CAST(DATEADD(DAY, 3, GETDATE()) AS DATE), NULL);
GO

INSERT INTO [Transaction] (CustomerID, AccountID, Amount, TransactionDate, DueDate, CompletionDate)
VALUES (5, 7, 800.00, GETDATE(), CAST(DATEADD(DAY, 1, GETDATE()) AS DATE), NULL);
GO

-- =============================================
-- TEST 2: Get payments due within 5 days
-- Expected: Returns both test transactions
-- above, ordered by most urgent first
-- =============================================
EXEC usp_GetPaymentsDueSoon;

-- Suppress harmless NULL aggregate warnings
SET ANSI_WARNINGS OFF;
GO
-- =============================================
-- TEST 3a: Insert a valid new customer
-- Expected: Success, returns new CustomerID
-- =============================================
EXEC usp_InsertCustomer
    @FirstName    = 'Nathan',
    @LastName     = 'Brooks',
    @Address      = '88 Poplar Street, Leicester, LE1 2KK',
    @DateOfBirth  = '1991-04-17',
    @Username     = 'nbrooks',
    @PasswordHash = 'hashed_pw_011',
    @Email        = 'nathan.brooks@email.com',
    @Phone        = '07911999888';

-- =============================================
-- TEST 3b: Insert with optional fields omitted
-- Expected: Success, Email and Phone are NULL
-- =============================================
EXEC usp_InsertCustomer
    @FirstName    = 'Grace',
    @LastName     = 'Kelly',
    @Address      = '12 Rosewood Lane, Oxford, OX1 3PP',
    @DateOfBirth  = '1998-09-05',
    @Username     = 'gkelly',
    @PasswordHash = 'hashed_pw_012';

-- =============================================
-- TEST 3c: Try to insert duplicate username
-- Expected: Error message returned
-- =============================================
EXEC usp_InsertCustomer
    @FirstName    = 'Fake',
    @LastName     = 'User',
    @Address      = '1 Test Street, London',
    @DateOfBirth  = '2000-01-01',
    @Username     = 'jharrison',
    @PasswordHash = 'hashed_pw_999';

-- Verify all new customers inserted correctly
SELECT CustomerID, FirstName, LastName, Username, Email, Phone
FROM Customer
WHERE Username IN ('nbrooks', 'gkelly');


-- =============================================
-- BEFORE: Check current state of CustomerID 1
-- =============================================
SELECT CustomerID, FirstName, LastName, Address, Email, Phone
FROM Customer
WHERE CustomerID = 1;

-- =============================================
-- TEST 4a: Update email and phone only
-- Expected: Only Email and Phone change,
-- all other fields remain the same
-- =============================================
EXEC usp_UpdateCustomer
    @CustomerID = 1,
    @Email      = 'james.updated@email.com',
    @Phone      = '07911000000';

-- =============================================
-- TEST 4b: Update address only
-- Expected: Only Address changes
-- =============================================
EXEC usp_UpdateCustomer
    @CustomerID = 3,
    @Address    = '99 New Road, Birmingham, B1 9ZZ';

-- =============================================
-- TEST 4c: Close a customer account
-- Expected: IsActive set to 0, ClosureDate set
-- =============================================
EXEC usp_UpdateCustomer
    @CustomerID  = 6,
    @IsActive    = 0,
    @ClosureDate = '2024-12-01';

-- =============================================
-- TEST 4d: Try to update non-existent customer
-- Expected: Error message returned
-- =============================================
EXEC usp_UpdateCustomer
    @CustomerID = 9999,
    @Email      = 'nobody@email.com';


    -- =============================================
-- TEST 5a: View all transactions with fee info
-- Expected: 12 rows, LEFT JOIN means
-- transactions without fees show NULL fee cols
-- =============================================
SELECT *
FROM vw_TransactionsWithOverdueFees
ORDER BY TransactionDate DESC;

-- =============================================
-- TEST 5b: Only transactions WITH overdue fees
-- Expected: Returns 7 rows matching
-- our OverdueFee inserts
-- =============================================
SELECT *
FROM vw_TransactionsWithOverdueFees
WHERE OverdueFeeID IS NOT NULL
ORDER BY FeeDate DESC;

-- =============================================
-- TEST 5c: Only pending transactions
-- Expected: Returns pending transactions
-- with NULL CompletionDate
-- =============================================
SELECT
    TransactionID,
    CustomerName,
    AccountName,
    TransactionAmount,
    DueDate,
    TransactionStatus
FROM vw_TransactionsWithOverdueFees
WHERE TransactionStatus = 'Pending'
ORDER BY DueDate ASC;

-- =============================================
-- TEST 5d: Transactions with unpaid fees
-- Expected: Olivia Price fees show as Unpaid
-- =============================================
SELECT
    TransactionID,
    CustomerName,
    AccountName,
    FeeAmount,
    OutstandingBalance,
    FeeStatus
FROM vw_TransactionsWithOverdueFees
WHERE FeeStatus = 'Unpaid'
ORDER BY OutstandingBalance DESC;


-- =============================================
-- TEST 6: Customers who paid less than 50%
-- Expected: Emily Watson, Olivia Price,
-- Sophie Clarke — with count of 3
-- =============================================
SELECT
    *,
    COUNT(*) OVER () AS TotalCustomersUnder50Pct
FROM vw_CustomersUnder50PctRepayment
ORDER BY RepaymentPercentage ASC;


-- =============================================
-- BEFORE STATE: Check Michael Car Loan
-- AccountID = 7, should be Active

UPDATE Account
SET Status = 'Active', ClosedFrozenDate = NULL
WHERE AccountID = 7;

UPDATE [Transaction]
SET CompletionDate = NULL
WHERE TransactionID = 8;

SELECT AccountID, AccountName, AccountType, Status, ClosedFrozenDate
FROM Account
WHERE AccountID = 7;

-- Also confirm pending transactions on account 7
SELECT TransactionID, AccountID, Amount, DueDate, CompletionDate
FROM [Transaction]
WHERE AccountID = 7;

-- =============================================
-- ACTION: Complete the final pending
-- transaction on Michael's Car Loan
-- TransactionID = 8 is the pending one
-- =============================================
UPDATE [Transaction]
SET CompletionDate = SYSUTCDATETIME()
WHERE TransactionID = 8;
GO

-- =============================================
-- AFTER STATE: Account 7 should now be Closed
-- ClosedFrozenDate should be set to today
-- =============================================
SELECT AccountID, AccountName, AccountType, Status, ClosedFrozenDate
FROM Account
WHERE AccountID = 7;

-- Verify the transaction was completed
SELECT TransactionID, AccountID, Amount, DueDate, CompletionDate
FROM [Transaction]
WHERE AccountID = 7;


-- =============================================
-- TRIGGER TEST 2: Verify trigger does NOT fire
-- when pending transactions still remain
-- Complete only ONE of Olivia's transactions
-- Account 10 has TransactionIDs 10 and 11
-- =============================================

-- BEFORE
SELECT AccountID, AccountName, Status FROM Account WHERE AccountID = 10;

-- Complete only transaction 10 (transaction 11 still pending)
UPDATE [Transaction]
SET CompletionDate = SYSUTCDATETIME()
WHERE TransactionID = 10;

-- AFTER: Account should still be Active
-- because transaction 11 is still pending
SELECT AccountID, AccountName, Status FROM Account WHERE AccountID = 10;


-- =============================================
-- TEST 8a: Monthly Transaction Summary
-- for November 2024
-- =============================================
EXEC usp_MonthlyTransactionSummary @Month = 11, @Year = 2024;

-- =============================================
-- TEST 8b: Monthly Transaction Summary
-- for October 2024
-- =============================================
EXEC usp_MonthlyTransactionSummary @Month = 10, @Year = 2024;

-- =============================================
-- TEST 8c: Invalid month input
-- Expected: Error message
-- =============================================
EXEC usp_MonthlyTransactionSummary @Month = 13, @Year = 2024;

-- =============================================
-- TEST 8d: Scalar UDF — Get outstanding
-- balance for specific customers
-- =============================================
SELECT dbo.fn_GetCustomerOutstandingBalance(1) AS JamesOutstanding;   -- Expected: 0.00
SELECT dbo.fn_GetCustomerOutstandingBalance(4) AS EmilyOutstanding;   -- Expected: 55.00
SELECT dbo.fn_GetCustomerOutstandingBalance(8) AS OliviaOutstanding;  -- Expected: 114.98

-- =============================================
-- TEST 8e: Customer Health Dashboard
-- =============================================

-- All customers ordered by risk
SELECT * FROM vw_CustomerHealthDashboard
ORDER BY TotalOutstandingFees DESC;

-- High risk customers only
SELECT CustomerID, CustomerName, TotalOutstandingFees, RiskFlag
FROM vw_CustomerHealthDashboard
WHERE RiskFlag = 'High Risk';

-- Specific customer lookup
SELECT * FROM vw_CustomerHealthDashboard
WHERE CustomerID = 8;


