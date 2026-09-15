-- ============================================================================
-- Script: 07_data_quality_checks.sql
-- Giai doan: Giai doan 5 — Data Quality Framework
-- Muc dich: Dinh nghia bo kiem dinh chat luong du lieu tu dong tren DWH:
--           - Tao bang DQ_Check_Log luu ket qua kiem tra
--           - Cai dat Stored Procedure sp_Run_DataQualityChecks voi cac rule:
--             + Not Null tren cac khoa bat buoc (PK, FK)
--             + Unique tren Business Key cua cac Dim
--             + Referential Integrity (khong co ban ghi orphan trong Fact)
--             + Range/Value validation (so tien phi/boi thuong >= 0, ngay hop ly)
--           - Bao loi (THROW) neu co critical check that bai de Airflow dung pipeline
-- Tham chieu: implementation-guide.md (Giai doan 5, Muc 1, 2, 3, 4)
--
-- Input mong doi:
--   - Cac bang trong DWH_Insurance sau khi da nap du lieu o Giai doan 4
--
-- Output mong doi:
--   - Bang DQ_Check_Log ghi nhan chi tiet cac check da chay (pass/fail, so dong loi)
--   - Throw error neu check critical bi fail de Airflow biet va trigger failure callback
-- ============================================================================

USE DWH_Insurance;
GO

-- ----------------------------------------------------------------------------
-- 1. DDL: Bang DQ_Check_Log
-- ----------------------------------------------------------------------------
-- TODO: Dinh nghia bang DQ_Check_Log
/*
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DQ_Check_Log')
BEGIN
    CREATE TABLE dbo.DQ_Check_Log (
        CheckLogId BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CheckName NVARCHAR(128) NOT NULL,
        RunTime DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        TableName NVARCHAR(128) NOT NULL,
        RowsChecked INT NOT NULL,
        RowsFailed INT NOT NULL,
        Status NVARCHAR(20) NOT NULL,            -- 'PASSED', 'FAILED', 'WARNING'
        ErrorMessage NVARCHAR(MAX) NULL
    );
END
GO
*/

-- ----------------------------------------------------------------------------
-- 2. Stored Procedure: sp_Run_DataQualityChecks
-- ----------------------------------------------------------------------------
-- TODO: Cai dat sp_Run_DataQualityChecks kiem tra toan bo rule va ghi vao DQ_Check_Log
/*
CREATE OR ALTER PROCEDURE dbo.sp_Run_DataQualityChecks
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CriticalErrors INT = 0;
    DECLARE @Now DATETIME2 = SYSUTCDATETIME();

    -- Rule 1: Not Null tren khoa Fact_Premium
    -- TODO: Kiem tra cac cot CustomerKey, PolicyKey, DateKey, RegionKey khong duoc NULL

    -- Rule 2: Not Null tren khoa Fact_Claims
    -- TODO: Kiem tra cac cot CustomerKey, PolicyKey, DateKey, RegionKey khong duoc NULL

    -- Rule 3: Referential Integrity - Fact_Premium toi Dim_Customer
    /*
    DECLARE @OrphanPremiumCustomer INT;
    SELECT @OrphanPremiumCustomer = COUNT(1)
    FROM dbo.Fact_Premium f
    LEFT JOIN dbo.Dim_Customer c ON f.CustomerKey = c.CustomerKey
    WHERE c.CustomerKey IS NULL;

    INSERT INTO dbo.DQ_Check_Log (CheckName, RunTime, TableName, RowsChecked, RowsFailed, Status)
    VALUES ('RI_FactPremium_DimCustomer', @Now, 'Fact_Premium', (SELECT COUNT(1) FROM dbo.Fact_Premium), @OrphanPremiumCustomer,
            CASE WHEN @OrphanPremiumCustomer = 0 THEN 'PASSED' ELSE 'FAILED' END);

    IF @OrphanPremiumCustomer > 0 SET @CriticalErrors = @CriticalErrors + 1;
    */

    -- Rule 4: Referential Integrity - Fact_Claims toi Dim_Policy
    -- TODO: Kiem tra ban ghi orphan tu Fact_Claims sang Dim_Policy

    -- Rule 5: Value Validation - So tien phi va boi thuong khong am
    /*
    DECLARE @NegativePremiums INT;
    SELECT @NegativePremiums = COUNT(1) FROM dbo.Fact_Premium WHERE PremiumAmount < 0;

    INSERT INTO dbo.DQ_Check_Log (CheckName, RunTime, TableName, RowsChecked, RowsFailed, Status)
    VALUES ('Value_PremiumNonNegative', @Now, 'Fact_Premium', (SELECT COUNT(1) FROM dbo.Fact_Premium), @NegativePremiums,
            CASE WHEN @NegativePremiums = 0 THEN 'PASSED' ELSE 'FAILED' END);

    IF @NegativePremiums > 0 SET @CriticalErrors = @CriticalErrors + 1;
    */

    -- Rule 6: Unique check tren Business Key cua Dim_Customer (Is_Current = 1)
    -- TODO: Dam bao moi CustomerId chi co duy nhat 1 ban ghi Is_Current = 1

    -- Kiem tra tong the va canh bao ngat pipeline Airflow neu can
    IF @CriticalErrors > 0
    BEGIN
        DECLARE @Msg NVARCHAR(200) = CONCAT('Data Quality Check that bai: Phat hien ', @CriticalErrors, ' critical rule(s) khong dat.');
        RAISERROR(@Msg, 16, 1);
        RETURN 1;
    END

    PRINT 'Tat ca cac buoc Data Quality Check deu dat yeu cau.';
    RETURN 0;
END
GO
*/

