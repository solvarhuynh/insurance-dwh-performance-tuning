-- ============================================================================
-- Script: 05_sp_fact_premium.sql
-- Giai doan: Giai doan 4 — ETL bang T-SQL voi Incremental Load & Audit Log
--            (Phan 4c: Stored Procedures chinh cho Fact Table)
-- Muc dich: Dinh nghia Stored Procedure sp_Load_FactPremium:
--           - Doc CDC net changes tu Staging (SUSEP Premium data)
--           - Join voi cac bang Dimension (Dim_Customer, Dim_Policy, Dim_Date, Dim_Region)
--             de lay Surrogate Key tuong ung
--           - Thuc hien MERGE UPSERT vao bang Fact_Premium
--           - Ghi log thuc thi vao ETL_Audit_Log, dam bao idempotent
-- Tham chieu: implementation-guide.md (Giai doan 4, Muc 5, 6, 9, 10)
--
-- Input mong doi:
--   - CDC net changes tu bang staging phi bao hiem (SUSEP)
--   - Cac bang Dimension da duoc nap day du surrogate keys
--   - BatchId tu Airflow / execution context
--
-- Output mong doi:
--   - Bang Fact_Premium duoc nạp/cập nhật dữ liệu phí bảo hiểm và số hợp đồng
--   - Khong phat sinh ban ghi mo coi (orphan records)
--   - Ghi nhan trang thai 'SUCCESS' va so dong anh huong vao ETL_Audit_Log
-- ============================================================================

USE DWH_Insurance;
GO

-- ----------------------------------------------------------------------------
-- Stored Procedure: sp_Load_FactPremium
-- ----------------------------------------------------------------------------
-- TODO: Cai dat sp_Load_FactPremium voi Lookup Surrogate Keys, MERGE va Audit Log
/*
CREATE OR ALTER PROCEDURE dbo.sp_Load_FactPremium
    @BatchId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @BatchId IS NULL SET @BatchId = NEWID();
    DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();
    DECLARE @RowsAffected INT = 0;
    DECLARE @LogId BIGINT;

    INSERT INTO dbo.ETL_Audit_Log (BatchId, ProcedureName, StartTime, Status)
    VALUES (@BatchId, 'sp_Load_FactPremium', @StartTime, 'RUNNING');
    SET @LogId = SCOPE_IDENTITY();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- TODO: Trich xuat du lieu tu CDC staging va lookup surrogate keys
        /*
        WITH StagingData AS (
            SELECT 
                s.PolicyNumber,
                s.CustomerId,
                s.DateRef,
                s.RegionCode,
                s.PremiumAmount
            FROM Staging_InsuranceRaw.dbo.stg_susep_raw s
            -- TODO: Thay the bang cdc.fn_cdc_get_net_changes_...
        ),
        TransformedFact AS (
            SELECT 
                ISNULL(c.CustomerKey, -1) AS CustomerKey,
                ISNULL(p.PolicyKey, -1)   AS PolicyKey,
                ISNULL(d.DateKey, -1)     AS DateKey,
                ISNULL(r.RegionKey, -1)   AS RegionKey,
                stg.PremiumAmount,
                1 AS PolicyCount
            FROM StagingData stg
            LEFT JOIN dbo.Dim_Customer c ON stg.CustomerId = c.CustomerId AND c.Is_Current = 1
            LEFT JOIN dbo.Dim_Policy p   ON stg.PolicyNumber = p.PolicyNumber
            LEFT JOIN dbo.Dim_Date d     ON CONVERT(INT, FORMAT(stg.DateRef, 'yyyyMMdd')) = d.DateKey
            LEFT JOIN dbo.Dim_Region r   ON stg.RegionCode = r.RegionCode
        )
        MERGE dbo.Fact_Premium AS Target
        USING TransformedFact AS Source
        ON  Target.CustomerKey = Source.CustomerKey
        AND Target.PolicyKey   = Source.PolicyKey
        AND Target.DateKey     = Source.DateKey
        AND Target.RegionKey   = Source.RegionKey
        WHEN MATCHED THEN
            UPDATE SET 
                Target.PremiumAmount = Source.PremiumAmount,
                Target.PolicyCount   = Source.PolicyCount
        WHEN NOT MATCHED THEN
            INSERT (CustomerKey, PolicyKey, DateKey, RegionKey, PremiumAmount, PolicyCount)
            VALUES (Source.CustomerKey, Source.PolicyKey, Source.DateKey, Source.RegionKey, Source.PremiumAmount, Source.PolicyCount);
        */

        SET @RowsAffected = @@ROWCOUNT;
        COMMIT TRANSACTION;

        UPDATE dbo.ETL_Audit_Log
        SET EndTime = SYSUTCDATETIME(), RowsAffected = @RowsAffected, Status = 'SUCCESS'
        WHERE LogId = @LogId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        UPDATE dbo.ETL_Audit_Log
        SET EndTime = SYSUTCDATETIME(), Status = 'FAILED', ErrorMessage = ERROR_MESSAGE()
        WHERE LogId = @LogId;
        THROW;
    END CATCH
END
GO
*/

