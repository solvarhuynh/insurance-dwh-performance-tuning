-- ============================================================================
-- Script: 08_sp_load_risk_predictions.sql
-- Giai doan: Machine Learning & DWH Integration (Lop Du doan Rui ro)
-- Muc dich: Dinh nghia Stored Procedure sp_Load_CustomerRiskPredictions:
--           - Doc ket qua du doan rui ro tu bang staging / file du doan ML
--           - Lookup Surrogate Keys (CustomerKey, DateKey) tu DWH
--           - Thuc hien MERGE UPSERT vao bang Fact_Customer_Risk_Prediction
--           - Ghi log thuc thi vao ETL_Audit_Log, dam bao tinh idempotent
-- Tham chieu: docs/specs/implementation-guide.md
--
-- Input mong doi:
--   - Bang staging stg_risk_predictions (chua CustomerId, DateRef, PredictedProbability, RiskCategory, ModelVersion)
--   - BatchId tu Airflow / execution context
--
-- Output mong doi:
--   - Bang Fact_Customer_Risk_Prediction duoc cap nhat day du diem rui ro du doan
--   - Ghi nhan trang thai 'SUCCESS' va so dong anh huong vao ETL_Audit_Log
-- ============================================================================

USE DWH_Insurance;
GO

-- ----------------------------------------------------------------------------
-- Stored Procedure: sp_Load_CustomerRiskPredictions
-- ----------------------------------------------------------------------------
-- TODO: Cai dat sp_Load_CustomerRiskPredictions voi Lookup Surrogate Keys, MERGE va Audit Log
/*
CREATE OR ALTER PROCEDURE dbo.sp_Load_CustomerRiskPredictions
    @BatchId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @BatchId IS NULL SET @BatchId = NEWID();
    DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();
    DECLARE @RowsAffected INT = 0;
    DECLARE @LogId BIGINT;

    INSERT INTO dbo.ETL_Audit_Log (BatchId, ProcedureName, StartTime, Status)
    VALUES (@BatchId, 'sp_Load_CustomerRiskPredictions', @StartTime, 'RUNNING');
    SET @LogId = SCOPE_IDENTITY();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- TODO: MERGE ket qua scoring tu bang staging vao Fact_Customer_Risk_Prediction
        /*
        MERGE dbo.Fact_Customer_Risk_Prediction AS Target
        USING (
            SELECT 
                c.CustomerKey,
                d.DateKey,
                stg.PredictedClaimProbability,
                stg.RiskCategory,
                stg.ModelVersion
            FROM Staging_InsuranceRaw.dbo.stg_risk_predictions stg
            INNER JOIN dbo.Dim_Customer c ON stg.CustomerId = c.CustomerId AND c.Is_Current = 1
            INNER JOIN dbo.Dim_Date d     ON CONVERT(INT, FORMAT(stg.PredictionDate, 'yyyyMMdd')) = d.DateKey
        ) AS Source
        ON Target.CustomerKey = Source.CustomerKey AND Target.DateKey = Source.DateKey
        WHEN MATCHED THEN
            UPDATE SET 
                Target.PredictedClaimProbability = Source.PredictedClaimProbability,
                Target.RiskCategory              = Source.RiskCategory,
                Target.ModelVersion              = Source.ModelVersion,
                Target.UpdatedDate               = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN
            INSERT (CustomerKey, DateKey, PredictedClaimProbability, RiskCategory, ModelVersion, CreatedDate)
            VALUES (Source.CustomerKey, Source.DateKey, Source.PredictedClaimProbability, Source.RiskCategory, Source.ModelVersion, SYSUTCDATETIME());
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
