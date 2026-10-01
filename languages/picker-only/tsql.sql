-- ── Comments ──
-- T-SQL (SQL Server): warehouse inventory. Detects as SQL; pick T-SQL in the language picker.
/* Block comment
   /* T-SQL block comments nest */
   still inside. */
-- TODO: partition dbo.Movements by month
-- FIXME: usp_Reorder double counts reserved stock

USE [Warehouse];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET DATEFORMAT ymd;
GO

-- ── Schemas and tables ──
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'inv')
    EXEC (N'CREATE SCHEMA inv AUTHORIZATION dbo');
GO

CREATE TABLE inv.[Warehouses] (
    [WarehouseId]  INT IDENTITY(1, 1) NOT NULL CONSTRAINT [PK_Warehouses] PRIMARY KEY CLUSTERED,
    [Code]         NVARCHAR(8)      NOT NULL CONSTRAINT [UQ_Warehouses_Code] UNIQUE,
    [Name]         NVARCHAR(120)    NOT NULL,
    [Region]       NCHAR(2)         NOT NULL CONSTRAINT [DF_Warehouses_Region] DEFAULT (N'EU'),
    [Capacity]     INT              NULL CONSTRAINT [CK_Warehouses_Capacity] CHECK ([Capacity] > 0),
    [OpenedOn]     DATE             NULL,
    [Location]     GEOGRAPHY        NULL,
    [RowVersion]   ROWVERSION,
    [CreatedAt]    DATETIME2(3)     NOT NULL DEFAULT SYSUTCDATETIME(),
    [Guid]         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    [Active]       BIT              NOT NULL DEFAULT 1,
    [Notes]        NVARCHAR(MAX)    NULL,
    [Photo]        VARBINARY(MAX)   NULL,
    [Config]       XML              NULL,
    [Price]        MONEY            NULL,
    [Ratio]        DECIMAL(9, 4)    NULL,
    [Weight]       FLOAT(53)        NULL,
    [Small]        SMALLINT         NULL,
    [Tiny]         TINYINT          NULL,
    [Big]          BIGINT           NULL,
    [Computed]     AS ([Capacity] * 2) PERSISTED,
    [ValidFrom]    DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    [ValidTo]      DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = inv.[WarehousesHistory]));
GO

CREATE TABLE inv.[Stock] (
    [WarehouseId] INT NOT NULL REFERENCES inv.[Warehouses]([WarehouseId]) ON DELETE CASCADE,
    [Sku]         NVARCHAR(20) NOT NULL,
    [Qty]         INT NOT NULL DEFAULT 0,
    [Reserved]    INT NOT NULL DEFAULT 0,
    CONSTRAINT [PK_Stock] PRIMARY KEY ([WarehouseId], [Sku]),
    CONSTRAINT [CK_Stock_Reserved] CHECK ([Reserved] <= [Qty])
);
GO

CREATE TYPE inv.SkuList AS TABLE (Sku NVARCHAR(20) NOT NULL PRIMARY KEY);
GO

CREATE SEQUENCE inv.OrderNumbers AS BIGINT START WITH 1000 INCREMENT BY 1 CACHE 50;
GO

-- ── Indexes, views, synonyms ──
CREATE NONCLUSTERED INDEX [IX_Stock_Low] ON inv.[Stock] ([Qty]) INCLUDE ([Reserved]) WHERE [Qty] < 25 WITH (FILLFACTOR = 90, ONLINE = OFF);
CREATE UNIQUE CLUSTERED INDEX [IX_Warehouses_Name] ON inv.[Warehouses] ([Name]) WITH (DROP_EXISTING = OFF);
CREATE FULLTEXT CATALOG [InventoryCatalog];
GO

CREATE OR ALTER VIEW inv.LowStock
WITH SCHEMABINDING
AS
    SELECT s.[WarehouseId], s.[Sku], s.[Qty]
    FROM inv.[Stock] AS s
    WHERE s.[Qty] <= 25;
GO

CREATE SYNONYM dbo.Stock FOR inv.[Stock];
GO

-- ── Functions ──
CREATE OR ALTER FUNCTION inv.Available (@Qty INT, @Reserved INT)
RETURNS INT
WITH SCHEMABINDING
AS
BEGIN
    RETURN @Qty - ISNULL(@Reserved, 0);
END;
GO

CREATE OR ALTER FUNCTION inv.LowFor (@WarehouseId INT)
RETURNS TABLE
AS
RETURN (SELECT [Sku], [Qty] FROM inv.[Stock] WHERE [WarehouseId] = @WarehouseId AND [Qty] <= 25);
GO

CREATE OR ALTER FUNCTION inv.SkuParts (@Sku NVARCHAR(20))
RETURNS @Parts TABLE (Prefix NVARCHAR(3), Number INT)
AS
BEGIN
    INSERT INTO @Parts VALUES (LEFT(@Sku, 3), CAST(SUBSTRING(@Sku, 5, 10) AS INT));
    RETURN;
END;
GO

-- ── Stored procedure ──
CREATE OR ALTER PROCEDURE inv.usp_Reorder
    @WarehouseId INT,
    @Threshold   INT = 25,
    @Skus        inv.SkuList READONLY,
    @Count       INT OUTPUT,
    @Verbose     BIT = 0
WITH EXECUTE AS OWNER, RECOMPILE
AS
BEGIN
    SET NOCOUNT ON;

    -- ── Variables, literals ──
    DECLARE @Low TABLE (Sku NVARCHAR(20), Qty INT);
    DECLARE @Now DATETIME2 = SYSUTCDATETIME(),
            @Msg NVARCHAR(200),
            @Num INT = 42,
            @Hex VARBINARY(4) = 0xDEADBEEF,
            @Float FLOAT = 1.5E-3,
            @Money MONEY = $12.50,
            @Unicode NVARCHAR(50) = N'Zürich ✓ it''s fine',
            @Guid UNIQUEIDENTIFIER = '6F9619FF-8B86-D011-B42D-00C04FC964FF',
            @Date DATE = '2026-09-24',
            @Cursor CURSOR;
    SET @Msg = CONCAT('reorder for ', @WarehouseId, ' at ', FORMAT(@Now, 'yyyy-MM-dd HH:mm'));
    SELECT @Count = 0, @Num += 1, @Num -= 1, @Num *= 2, @Num /= 2, @Num %= 7;
    SELECT @Num &= 3, @Num |= 4, @Num ^= 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ── CTE with window functions ──
        ;WITH Recent AS (
            SELECT o.[Number], o.[Total], o.[Status],
                   ROW_NUMBER() OVER (PARTITION BY o.[Status] ORDER BY o.[PlacedAt] DESC) AS rn,
                   RANK() OVER (ORDER BY o.[Total] DESC) AS rk,
                   LAG(o.[Total], 1, 0) OVER (ORDER BY o.[PlacedAt]) AS PrevTotal,
                   SUM(o.[Total]) OVER (ORDER BY o.[PlacedAt] ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Running
            FROM dbo.[Orders] AS o WITH (NOLOCK, INDEX(IX_Orders_PlacedAt))
            WHERE o.[PlacedAt] >= DATEADD(DAY, -7, SYSUTCDATETIME())
        )
        SELECT TOP (10) PERCENT WITH TIES [Number], [Total], [Status]
        FROM Recent
        WHERE rn <= 3
        ORDER BY [Total] DESC
        OPTION (MAXDOP 1, RECOMPILE);

        -- ── Recursive CTE ──
        ;WITH Tree AS (
            SELECT c.CategoryId, c.ParentId, 0 AS Depth FROM dbo.Categories c WHERE c.ParentId IS NULL
            UNION ALL
            SELECT c.CategoryId, c.ParentId, t.Depth + 1
            FROM dbo.Categories c INNER JOIN Tree t ON c.ParentId = t.CategoryId
        )
        SELECT * FROM Tree OPTION (MAXRECURSION 50);

        -- ── Inserts, outputs, merge ──
        INSERT INTO @Low (Sku, Qty)
        SELECT [Sku], [Qty] FROM inv.[Stock] WHERE [Qty] <= @Threshold AND [WarehouseId] = @WarehouseId;
        SET @Count = @@ROWCOUNT;

        INSERT INTO inv.[Stock] ([WarehouseId], [Sku], [Qty])
        OUTPUT INSERTED.[Sku], INSERTED.[Qty] INTO @Low (Sku, Qty)
        SELECT @WarehouseId, Sku, 100 FROM @Skus;

        MERGE inv.[Stock] AS target
        USING (SELECT Sku FROM @Skus) AS source ON target.Sku = source.Sku AND target.WarehouseId = @WarehouseId
        WHEN MATCHED THEN UPDATE SET target.Qty += 10
        WHEN NOT MATCHED BY TARGET THEN INSERT (WarehouseId, Sku, Qty) VALUES (@WarehouseId, source.Sku, 10)
        WHEN NOT MATCHED BY SOURCE AND target.WarehouseId = @WarehouseId THEN DELETE
        OUTPUT $action, INSERTED.Sku, DELETED.Sku;

        UPDATE s SET s.Qty = s.Qty - 1
        OUTPUT DELETED.Qty AS OldQty, INSERTED.Qty AS NewQty
        FROM inv.[Stock] AS s
        WHERE s.Sku = N'ABC-1';

        DELETE TOP (100) FROM dbo.AuditLog WHERE LoggedAt < DATEADD(YEAR, -1, GETDATE());
        TRUNCATE TABLE #scratch;

        -- ── Control flow ──
        IF @@ROWCOUNT > 0
            PRINT CONCAT('reorder ', (SELECT COUNT(*) FROM @Low), ' skus');
        ELSE IF @Verbose = 1
        BEGIN
            PRINT 'nothing to reorder';
        END
        ELSE
            PRINT 'quiet';

        DECLARE @i INT = 0;
        WHILE @i < 3
        BEGIN
            SET @i += 1;
            IF @i = 2 CONTINUE;
            IF @i > 5 BREAK;
            RAISERROR('pass %d', 0, 1, @i) WITH NOWAIT;
        END

        SELECT CASE WHEN @Count = 0 THEN 'none' WHEN @Count < 5 THEN 'few' ELSE 'many' END AS Bucket,
               IIF(@Count > 0, 'yes', 'no') AS Any,
               CHOOSE(2, 'a', 'b', 'c') AS Picked,
               COALESCE(NULL, @Msg) AS Msg,
               NULLIF(@Num, 0) AS Nz,
               TRY_CAST('12' AS INT) AS Parsed,
               TRY_CONVERT(DATE, '2026-09-24', 23) AS ParsedDate,
               CONVERT(VARCHAR(10), GETDATE(), 120) AS IsoDate,
               EOMONTH(GETDATE()) AS MonthEnd,
               DATEDIFF(DAY, '2026-01-01', @Date) AS Days,
               DATEPART(YEAR, @Date) AS Yr,
               STRING_AGG([Sku], ', ') WITHIN GROUP (ORDER BY [Sku]) AS SkuList,
               JSON_VALUE(N'{"a":1}', '$.a') AS JsonA,
               @@VERSION AS Ver, @@SERVERNAME AS Srv, @@IDENTITY AS LastId, SCOPE_IDENTITY() AS Scope,
               OBJECT_ID(N'inv.Stock') AS ObjId, DB_NAME() AS Db, SUSER_SNAME() AS Login,
               LEN(@Msg) AS L, UPPER(@Msg) AS U, REPLACE(@Msg, 'a', 'b') AS R, STUFF(@Msg, 1, 1, 'X') AS S
        FROM @Low;

        SELECT * FROM OPENJSON(N'[{"sku":"ABC-1"}]') WITH (sku NVARCHAR(20) '$.sku');
        SELECT p.Sku, x.Qty FROM inv.Stock AS p CROSS APPLY inv.LowFor(p.WarehouseId) AS x;
        SELECT * FROM inv.Stock PIVOT (SUM(Qty) FOR WarehouseId IN ([1], [2], [3])) AS pvt;
        SELECT * FROM inv.Stock UNPIVOT (Qty FOR Col IN (Reserved)) AS u;
        SELECT * INTO #copy FROM inv.Stock;
        SELECT Sku FROM inv.Stock EXCEPT SELECT Sku FROM inv.LowStock INTERSECT SELECT Sku FROM inv.Stock;
        SELECT * FROM inv.Stock FOR SYSTEM_TIME AS OF '2026-01-01';
        SELECT TOP 5 * FROM inv.Stock ORDER BY Qty OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
        SELECT * FROM inv.Stock FOR XML PATH('item'), ROOT('items');
        SELECT * FROM inv.Stock FOR JSON AUTO;
        SELECT GROUPING(WarehouseId) AS g, WarehouseId, SUM(Qty) FROM inv.Stock GROUP BY ROLLUP (WarehouseId);
        SELECT WarehouseId, SUM(Qty) FROM inv.Stock GROUP BY CUBE (WarehouseId) HAVING SUM(Qty) > 0;
        SELECT WarehouseId, SUM(Qty) FROM inv.Stock GROUP BY GROUPING SETS ((WarehouseId), ());

        -- ── Cursors ──
        DECLARE sku_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT Sku FROM @Low;
        DECLARE @sku NVARCHAR(20);
        OPEN sku_cursor;
        FETCH NEXT FROM sku_cursor INTO @sku;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            FETCH NEXT FROM sku_cursor INTO @sku;
        END
        CLOSE sku_cursor;
        DEALLOCATE sku_cursor;

        -- ── Dynamic SQL ──
        DECLARE @sql NVARCHAR(MAX) = N'SELECT COUNT(*) FROM inv.Stock WHERE WarehouseId = @id';
        EXEC sp_executesql @sql, N'@id INT', @id = @WarehouseId;
        EXEC (@sql);
        EXECUTE inv.usp_Reorder @WarehouseId = 1, @Skus = @Skus, @Count = @Count OUTPUT;

        -- ── Temp objects ──
        CREATE TABLE #scratch (Id INT, Label NVARCHAR(20));
        CREATE TABLE ##global_scratch (Id INT);
        DROP TABLE IF EXISTS #scratch;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE(), @sev INT = ERROR_SEVERITY(), @state INT = ERROR_STATE();
        RAISERROR(@err, @sev, @state);
        THROW 50001, N'reorder failed', 1;
    END CATCH;

    RETURN 0;
END;
GO

-- ── Triggers ──
CREATE OR ALTER TRIGGER inv.trg_Stock_Audit
ON inv.[Stock]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE([Qty])
        INSERT INTO dbo.AuditLog ([Sku], [Delta], [LoggedAt])
        SELECT i.[Sku], i.[Qty] - ISNULL(d.[Qty], 0), SYSUTCDATETIME()
        FROM inserted AS i LEFT JOIN deleted AS d ON d.[Sku] = i.[Sku];
END;
GO

-- ── Security and admin ──
GRANT SELECT, INSERT ON inv.[Stock] TO [warehouse_reader];
DENY DELETE ON inv.[Stock] TO [warehouse_reader];
REVOKE INSERT ON inv.[Stock] FROM [warehouse_reader];
CREATE LOGIN [inventory_app] WITH PASSWORD = N'example-not-a-real-password', CHECK_POLICY = ON;
CREATE USER [inventory_app] FOR LOGIN [inventory_app] WITH DEFAULT_SCHEMA = inv;
ALTER ROLE [db_datareader] ADD MEMBER [inventory_app];
ALTER TABLE inv.[Stock] ADD [Bin] NVARCHAR(10) NULL;
ALTER TABLE inv.[Stock] ALTER COLUMN [Bin] NVARCHAR(20) NULL;
ALTER TABLE inv.[Stock] DROP COLUMN [Bin];
ALTER TABLE inv.[Stock] WITH CHECK ADD CONSTRAINT [CK_Qty] CHECK ([Qty] >= 0);
ALTER INDEX ALL ON inv.[Stock] REBUILD WITH (ONLINE = ON);
UPDATE STATISTICS inv.[Stock] WITH FULLSCAN;
DBCC CHECKDB (N'Warehouse') WITH NO_INFOMSGS;
BACKUP DATABASE [Warehouse] TO DISK = N'/var/opt/mssql/backup/warehouse.bak' WITH COMPRESSION, INIT;
EXEC sp_rename N'inv.Stock', N'StockLines', N'OBJECT';
EXEC sp_help N'inv.Stock';
DROP VIEW IF EXISTS inv.LowStock;
DROP PROCEDURE IF EXISTS inv.usp_Reorder;
WAITFOR DELAY '00:00:01';
GO 2
