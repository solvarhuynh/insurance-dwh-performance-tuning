-- ============================================================================
-- Migration: V1__create_dwh_schema.sql
-- Giai doan: Giai doan 3 — Thiet ke Data Warehouse & Schema Migration
-- Cong cu: Flyway / DbUp (version-controlled migration)
-- Muc dich: Tao database DWH_Insurance va toan bo bang Fact/Dim theo kien truc
--           Star Schema, bao gom Primary Key, Foreign Key, Business Key va Surrogate Key.
-- Tham chieu: docs/specs/implementation-guide.md
--
-- Danh sach cac bang trong Star Schema:
--   1. Dim_Date: Bang chieu thoi gian chuan (ngay, thang, quy, nam)
--   2. Dim_Region: Bang chieu dia ly / bang / khu vuc (tu nguon SUSEP)
--   3. Dim_Policy: Bang chieu loai san pham bao hiem, dac diem hop dong
--   4. Dim_Customer: Bang chieu khach hang ap dung SCD Type 2 (tu nguon Porto Seguro ~1.5M dong)
--   5. Fact_Premium: Bang su kien thu phi bao hiem (gia tri phi, so hop dong)
--   6. Fact_Claims: Bang su kien boi thuong bao hiem (gia tri boi thuong, so vu claim)
--   7. Fact_Customer_Risk_Prediction: Bang su kien luu diem du doan rui ro tu Machine Learning
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Tao Database DWH_Insurance (neu duoc phep boi migration tool)
-- ----------------------------------------------------------------------------
-- TODO: Khoi tao database DWH_Insurance neu chua co
/*
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DWH_Insurance')
BEGIN
    CREATE DATABASE DWH_Insurance;
END
GO

USE DWH_Insurance;
GO
*/

-- ----------------------------------------------------------------------------
-- 2. DDL: Dim_Date
-- ----------------------------------------------------------------------------
-- TODO: Dinh nghia bang Dim_Date
/*
CREATE TABLE dbo.Dim_Date (
    DateKey INT NOT NULL PRIMARY KEY,            -- YYYYMMDD
    FullDate DATE NOT NULL,
    DayNumberOfWeek TINYINT NOT NULL,
    DayName NVARCHAR(20) NOT NULL,
    DayNumberOfMonth TINYINT NOT NULL,
    DayNumberOfYear SMALLINT NOT NULL,
    MonthNumberOfYear TINYINT NOT NULL,
    MonthName NVARCHAR(20) NOT NULL,
    Quarter TINYINT NOT NULL,
    CalendarYear INT NOT NULL
);
GO
*/

-- ----------------------------------------------------------------------------
-- 3. DDL: Dim_Region
-- ----------------------------------------------------------------------------
-- TODO: Dinh nghia bang Dim_Region (Surrogate Key: RegionKey, Business Key: RegionCode/StateCode)
/*
CREATE TABLE dbo.Dim_Region (
    RegionKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    RegionCode NVARCHAR(20) NOT NULL,            -- Business Key
    RegionName NVARCHAR(100) NULL,
    StateCode NVARCHAR(10) NULL,
    CountryName NVARCHAR(50) DEFAULT 'Brazil'
);
GO
*/

-- ----------------------------------------------------------------------------
-- 4. DDL: Dim_Policy
-- ----------------------------------------------------------------------------
-- TODO: Dinh nghia bang Dim_Policy (Surrogate Key: PolicyKey, Business Key: PolicyTypeCode/ProductCode)
/*
CREATE TABLE dbo.Dim_Policy (
    PolicyKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PolicyNumber NVARCHAR(50) NOT NULL,          -- Business Key
    PolicyTypeCode NVARCHAR(50) NULL,
    PolicyTypeName NVARCHAR(100) NULL,
    CoverageCategory NVARCHAR(100) NULL,
    RiskCategory NVARCHAR(50) NULL
);
GO
*/

-- ----------------------------------------------------------------------------
-- 5. DDL: Dim_Customer (SCD Type 2)
-- ----------------------------------------------------------------------------
-- TODO: Dinh nghia bang Dim_Customer ap dung SCD Type 2 (nguon Porto Seguro ~1.5M dong)
/*
CREATE TABLE dbo.Dim_Customer (
    CustomerKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,  -- Surrogate Key
    CustomerId INT NOT NULL,                             -- Business Key (Id tu Porto Seguro)
    IndGroupCategory NVARCHAR(50) NULL,                  -- Nhom dac trung ca nhan (ps_ind_*)
    CarCategory NVARCHAR(50) NULL,                       -- Nhom dac trung xe (ps_car_*)
    CalcScore DECIMAL(10,4) NULL,                        -- Chi so rui ro tinh toan (ps_calc_*)
    -- Cac cot SCD Type 2:
    Start_Date DATETIME2 NOT NULL,
    End_Date DATETIME2 NULL,
    Is_Current BIT NOT NULL DEFAULT 1
);
GO
CREATE INDEX IX_Dim_Customer_BusinessKey ON dbo.Dim_Customer (CustomerId, Is_Current);
GO
*/

-- ----------------------------------------------------------------------------
-- 6. DDL: Fact_Premium
-- ----------------------------------------------------------------------------
-- TODO: Dinh nghia bang Fact_Premium voi Foreign Keys toi cac Dim
/*
CREATE TABLE dbo.Fact_Premium (
    PremiumFactKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerKey INT NOT NULL,
    PolicyKey INT NOT NULL,
    DateKey INT NOT NULL,
    RegionKey INT NOT NULL,
    -- Measures
    PremiumAmount DECIMAL(18,2) NOT NULL,
    PolicyCount INT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Fact_Premium_Customer FOREIGN KEY (CustomerKey) REFERENCES dbo.Dim_Customer(CustomerKey),
    CONSTRAINT FK_Fact_Premium_Policy FOREIGN KEY (PolicyKey) REFERENCES dbo.Dim_Policy(PolicyKey),
    CONSTRAINT FK_Fact_Premium_Date FOREIGN KEY (DateKey) REFERENCES dbo.Dim_Date(DateKey),
    CONSTRAINT FK_Fact_Premium_Region FOREIGN KEY (RegionKey) REFERENCES dbo.Dim_Region(RegionKey)
);
GO
*/

-- ----------------------------------------------------------------------------
-- 7. DDL: Fact_Claims
-- ----------------------------------------------------------------------------
-- TODO: Dinh nghia bang Fact_Claims voi Foreign Keys toi cac Dim
/*
CREATE TABLE dbo.Fact_Claims (
    ClaimFactKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerKey INT NOT NULL,
    PolicyKey INT NOT NULL,
    DateKey INT NOT NULL,
    RegionKey INT NOT NULL,
    -- Measures
    ClaimAmount DECIMAL(18,2) NOT NULL,
    ClaimCount INT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Fact_Claims_Customer FOREIGN KEY (CustomerKey) REFERENCES dbo.Dim_Customer(CustomerKey),
    CONSTRAINT FK_Fact_Claims_Policy FOREIGN KEY (PolicyKey) REFERENCES dbo.Dim_Policy(PolicyKey),
    CONSTRAINT FK_Fact_Claims_Date FOREIGN KEY (DateKey) REFERENCES dbo.Dim_Date(DateKey),
    CONSTRAINT FK_Fact_Claims_Region FOREIGN KEY (RegionKey) REFERENCES dbo.Dim_Region(RegionKey)
);
GO
*/

-- ----------------------------------------------------------------------------
-- 8. DDL: Fact_Customer_Risk_Prediction (Ket qua Machine Learning)
-- ----------------------------------------------------------------------------
-- TODO: Dinh nghia bang Fact_Customer_Risk_Prediction
/*
CREATE TABLE dbo.Fact_Customer_Risk_Prediction (
    PredictionFactKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerKey INT NOT NULL,
    DateKey INT NOT NULL,
    -- ML Output Measures & Labels
    PredictedClaimProbability DECIMAL(6,4) NOT NULL,    -- Xac suat tu 0.0000 den 1.0000
    RiskCategory NVARCHAR(20) NOT NULL,                 -- 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    ModelVersion NVARCHAR(50) NOT NULL,
    CreatedDate DATETIME2 DEFAULT SYSUTCDATETIME(),
    UpdatedDate DATETIME2 DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Fact_RiskPred_Customer FOREIGN KEY (CustomerKey) REFERENCES dbo.Dim_Customer(CustomerKey),
    CONSTRAINT FK_Fact_RiskPred_Date FOREIGN KEY (DateKey) REFERENCES dbo.Dim_Date(DateKey)
);
GO
CREATE INDEX IX_Fact_RiskPred_Customer ON dbo.Fact_Customer_Risk_Prediction (CustomerKey, DateKey);
GO
*/
