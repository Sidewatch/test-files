-- T-SQL (SQL Server): bracket quoting, TOP, a CTE, a table variable and TRY/CATCH.
-- This file DETECTS AS SQL — pick T-SQL from the language picker to see the dialect's keywords.
SET NOCOUNT ON;
DECLARE @ReorderPoint INT = 25;
DECLARE @Low TABLE (Sku NVARCHAR(20), Qty INT);

BEGIN TRY
    BEGIN TRANSACTION;

    ;WITH Recent AS (
        SELECT o.[Number], o.[Total], o.[Status],
               ROW_NUMBER() OVER (PARTITION BY o.[Status] ORDER BY o.[PlacedAt] DESC) AS rn
        FROM dbo.[Orders] AS o WITH (NOLOCK)
        WHERE o.[PlacedAt] >= DATEADD(DAY, -7, SYSUTCDATETIME())
    )
    SELECT TOP (10) [Number], [Total], [Status]
    FROM Recent WHERE rn <= 3
    ORDER BY [Total] DESC;

    INSERT INTO @Low (Sku, Qty)
    SELECT [Sku], [Qty] FROM dbo.[Stock] WHERE [Qty] <= @ReorderPoint;

    IF @@ROWCOUNT > 0
        PRINT CONCAT('reorder ', (SELECT COUNT(*) FROM @Low), ' skus');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
