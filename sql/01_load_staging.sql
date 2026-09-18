-- ============================================================================
-- Script: 01_load_staging.sql
-- Giai doan: Giai doan 2 — Ha tang & Staging
-- Muc dich: Tao database Staging_InsuranceRaw, tao cac bang staging khop voi
--           cau truc CSV goc (khong transform), va nap du lieu bang BULK INSERT.
-- Tham chieu: docs/specs/implementation-guide.md (Giai doan 2, Muc 3, 4, 5, 6)
--
-- Input mong doi:
--   - File CSV tho tu SUSEP (du lieu thi truong bao hiem Brazil ~8.3M rows) trong data/raw/
--   - File CSV tho tu Porto Seguro Safe Driver Prediction (~1.5M rows) trong data/raw/
--
-- Output mong doi:
--   - Database Staging_InsuranceRaw duoc khoi tao
--   - Cac bang staging: stg_susep_raw, stg_portoseguro_raw, stg_risk_predictions
--   - Toan bo dong du lieu duoc nap day du qua BULK INSERT
--   - Log so dong nap duoc doi chieu khop voi so dong file CSV goc
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Tao Database Staging_InsuranceRaw (neu chua ton tai)
-- ----------------------------------------------------------------------------
-- TODO: Kiem tra va tao database Staging_InsuranceRaw
/*
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'Staging_InsuranceRaw')
BEGIN
    CREATE DATABASE Staging_InsuranceRaw;
END
GO

USE Staging_InsuranceRaw;
GO
*/

-- ----------------------------------------------------------------------------
-- 2. DDL: Tao bang Staging cho nguon SUSEP
-- ----------------------------------------------------------------------------
-- TODO: Dinh nghia bang stg_susep_raw khop voi schema file CSV goc
/*
DROP TABLE IF EXISTS dbo.stg_susep_raw;
CREATE TABLE dbo.stg_susep_raw (
    -- TODO: Dinh nghia cac cot tuong ung voi bo du lieu SUSEP
    -- Vi du: company_id, company_name, product_code, region_code, date_ref, premium_amt, claims_amt, etc.
);
GO
*/

-- ----------------------------------------------------------------------------
-- 3. DDL: Tao bang Staging cho nguon Porto Seguro (~1.5M dong)
-- ----------------------------------------------------------------------------
-- TODO: Dinh nghia bang stg_portoseguro_raw khop voi schema file CSV goc
/*
DROP TABLE IF EXISTS dbo.stg_portoseguro_raw;
CREATE TABLE dbo.stg_portoseguro_raw (
    -- TODO: Dinh nghia cac cot tuong ung voi bo du lieu Porto Seguro (id, target, ps_ind_*, ps_reg_*, ps_car_*, ps_calc_*)
);
GO
*/

-- ----------------------------------------------------------------------------
-- 4. BULK INSERT nap du lieu tu CSV tho
-- ----------------------------------------------------------------------------
-- TODO: Thuc hien BULK INSERT tu file CSV da chuan hoa encoding/delimiter vao staging
/*
BULK INSERT dbo.stg_susep_raw
FROM '/var/opt/mssql/raw_data/susep_data.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

BULK INSERT dbo.stg_portoseguro_raw
FROM '/var/opt/mssql/raw_data/porto_seguro_data.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO
*/

-- ----------------------------------------------------------------------------
-- 5. Kiem tra va doi chieu so luong dong (Row Count Reconciliation)
-- ----------------------------------------------------------------------------
-- TODO: Doi chieu row count staging = row count file CSV goc
/*
SELECT 'stg_susep_raw' AS TableName, COUNT(1) AS TotalRows FROM dbo.stg_susep_raw;
SELECT 'stg_portoseguro_raw' AS TableName, COUNT(1) AS TotalRows FROM dbo.stg_portoseguro_raw;
GO
*/
