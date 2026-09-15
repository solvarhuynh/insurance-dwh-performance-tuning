-- ============================================================================
-- Script: 03_sp_dim_customer_scd2.sql
-- Giai doan: Giai doan 4 — ETL bang T-SQL voi Incremental Load & Audit Log
--            (Phan 4b: Audit Log & Idempotency, Phan 4c: Stored Procedures chinh)
-- Muc dich: Tao bang ETL_Audit_Log va Stored Procedure sp_Load_DimCustomer
--           thuc hien incremental load theo SCD Type 2 (Start_Date, End_Date,
--           Is_Current) tu CDC net changes, ghi audit log, dam bao tinh idempotent.
-- Tham chieu: implementation-guide.md (Giai doan 4, Muc 4, 5, 6, 7)
--
-- Input mong doi:
--   - CDC net changes tu bang stg_prudential_raw tren Staging_InsuranceRaw
--   - Biet duoc moc LSN tu ETL_Watermark
--
-- Output mong doi:
--   - Bang ETL_Audit_Log duoc tao de ghi log thuc thi ETL
--   - Dim_Customer duoc cap nhat theo chuan SCD Type 2 (dong cu: Is_Current=0, End_Date; dong moi: Is_Current=1, End_Date=NULL)
--   - Log thuc thi duoc ghi vao ETL_Audit_Log (status = 'SUCCESS' hoac 'FAILED')
--   - Dam bao tinh idempotent: chay lai cung batch khong nhan doi du lieu
-- ============================================================================

USE DWH_Insurance;
GO

-- ----------------------------------------------------------------------------
-- 1. DDL: Bang ETL_Audit_Log
-- ----------------------------------------------------------------------------
-- TODO: Dinh nghia bang ETL_Audit_Log dung chung cho toan bo pipeline
/*
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ETL_Audit_Log')
BEGIN
    CREATE TABLE dbo.ETL_Audit_Log (
        LogId BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        BatchId UNIQUEIDENTIFIER NOT NULL,
        ProcedureName NVARCHAR(128) NOT NULL,
        StartTime DATETIME2 NOT NULL,
        EndTime DATETIME2 NULL,
        RowsAffected INT NULL,
        Status NVARCHAR(20) NOT NULL,            -- 'RUNNING', 'SUCCESS', 'FAILED'
        ErrorMessage NVARCHAR(MAX) NULL
    );
END
GO
*/

-- ----------------------------------------------------------------------------
-- 2. Stored Procedure: sp_Load_DimCustomer (SCD Type 2)
-- ----------------------------------------------------------------------------
-- TODO: Cai dat sp_Load_DimCustomer voi TRY...CATCH, MERGE, Audit Log
/*
CREATE OR ALTER PROCEDURE dbo.sp_Load_DimCustomer
    @BatchId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @BatchId IS NULL
        SET @BatchId = NEWID();

    DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();
    DECLARE @RowsAffected INT = 0;
    DECLARE @LogId BIGINT;

    -- Ghi log bat dau
    INSERT INTO dbo.ETL_Audit_Log (BatchId, ProcedureName, StartTime, Status)
    VALUES (@BatchId, 'sp_Load_DimCustomer', @StartTime, 'RUNNING');
    SET @LogId = SCOPE_IDENTITY();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- TODO: Lay CDC net changes tu Staging_InsuranceRaw.cdc.fn_cdc_get_net_changes_dbo_stg_prudential_raw
        -- TODO: Ap dung logic SCD Type 2:
        --       Buoc 1: Dong cu co thay doi thuoc tinh -> Update End_Date = @StartTime, Is_Current = 0
        --       Buoc 2: Insert ban ghi moi hoac dong cap nhat voi Start_Date = @StartTime, End_Date = NULL, Is_Current = 1

        /*
        -- Vi du stub MERGE SCD Type 2:
        MERGE dbo.Dim_Customer AS Target
        USING (...) AS Source
        ON Target.CustomerId = Source.Id AND Target.Is_Current = 1
        WHEN MATCHED AND (Target.Age <> Source.Ins_Age OR Target.BMI <> Source.BMI ...)
            THEN UPDATE SET Target.End_Date = @StartTime, Target.Is_Current = 0;

        INSERT INTO dbo.Dim_Customer (CustomerId, Age, BMI, RiskLevel, Start_Date, End_Date, Is_Current)
        SELECT ...;
        */

        SET @RowsAffected = @@ROWCOUNT;

        -- TODO: Cap nhat ETL_Watermark sang LSN moi nhat

        COMMIT TRANSACTION;

        -- Ghi log thanh cong
        UPDATE dbo.ETL_Audit_Log
        SET EndTime = SYSUTCDATETIME(),
            RowsAffected = @RowsAffected,
            Status = 'SUCCESS'
        WHERE LogId = @LogId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Ghi log that bai
        UPDATE dbo.ETL_Audit_Log
        SET EndTime = SYSUTCDATETIME(),
            Status = 'FAILED',
            ErrorMessage = ERROR_MESSAGE()
        WHERE LogId = @LogId;

        THROW;
    END CATCH
END
GO
*/

