-- ============================================================================
-- Script: 02_enable_cdc.sql
-- Giai doan: Giai doan 4 — ETL bang T-SQL voi Incremental Load & Audit Log
--            (Phan 4a: Incremental Load bang Change Data Capture - CDC)
-- Muc dich: Bat SQL Server CDC tren database Staging_InsuranceRaw va cac bang
--           staging, tao bang ETL_Watermark de theo doi LSN/timestamp cho
--           incremental load.
-- Tham chieu: implementation-guide.md (Giai doan 4, Muc 1, 2, 3)
--
-- Input mong doi:
--   - Database Staging_InsuranceRaw va cac bang staging da tao tu Giai doan 2
--   - SQL Server Agent dang chay de phuc vu cac CDC capture/cleanup jobs
--
-- Output mong doi:
--   - CDC duoc kich hoat tren database Staging_InsuranceRaw
--   - CDC capture instances duoc bat tren tung bang staging
--   - Bang ETL_Watermark luu thong tin watermark (LSN/timestamp) sau moi batch
-- ============================================================================

USE Staging_InsuranceRaw;
GO

-- ----------------------------------------------------------------------------
-- 1. Kich hoat CDC tren cap do Database
-- ----------------------------------------------------------------------------
-- TODO: Bat CDC tren database Staging_InsuranceRaw
/*
IF (SELECT is_cdc_enabled FROM sys.databases WHERE name = 'Staging_InsuranceRaw') = 0
BEGIN
    EXEC sys.sp_cdc_enable_db;
END
GO
*/

-- ----------------------------------------------------------------------------
-- 2. Kich hoat CDC tren tung bang Staging
-- ----------------------------------------------------------------------------
-- TODO: Bat CDC tren bang stg_susep_raw va stg_prudential_raw
/*
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'stg_susep_raw' AND is_tracked_by_cdc = 0)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'dbo',
        @source_name   = N'stg_susep_raw',
        @role_name     = NULL,
        @supports_net_changes = 1;
END
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'stg_prudential_raw' AND is_tracked_by_cdc = 0)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'dbo',
        @source_name   = N'stg_prudential_raw',
        @role_name     = NULL,
        @supports_net_changes = 1;
END
GO
*/

-- ----------------------------------------------------------------------------
-- 3. DDL: Tao bang ETL_Watermark luu vet LSN/Timestamp cho Incremental Load
-- ----------------------------------------------------------------------------
-- TODO: Dinh nghia bang ETL_Watermark
/*
DROP TABLE IF EXISTS dbo.ETL_Watermark;
CREATE TABLE dbo.ETL_Watermark (
    SourceTableName NVARCHAR(128) NOT NULL PRIMARY KEY,
    LastProcessedLSN BINARY(10) NULL,
    LastProcessedTime DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- Khoi tao watermark ban dau
INSERT INTO dbo.ETL_Watermark (SourceTableName, LastProcessedLSN, LastProcessedTime)
VALUES 
    ('stg_susep_raw', sys.fn_cdc_get_min_lsn('dbo_stg_susep_raw'), SYSUTCDATETIME()),
    ('stg_prudential_raw', sys.fn_cdc_get_min_lsn('dbo_stg_prudential_raw'), SYSUTCDATETIME());
GO
*/

