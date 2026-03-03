-- ================================================================
-- DATABASE PATCH v6c — Confirm & Verify (no back-fill needed)
--
-- What we now know about this schema:
--   • Timetable has NO ClassID column
--   • StudentEnrollments has only StudentID (no ClassID, no SubjectID)
--   • Marks.ClassID is already nullable (fixed in v6) ✅
--
-- This patch only:
--   1. Verifies Marks.ClassID is nullable (and fixes it if somehow reverted)
--   2. Verifies all other required Marks columns exist
--   3. Prints the full Marks schema so you can confirm
--
-- Safe to run multiple times.
-- ================================================================

USE UniversityERP;
GO

PRINT '=== Starting PATCH v6c ===';
GO

-- ================================================================
-- 1. Ensure Marks.ClassID is nullable (idempotent safety check)
-- ================================================================
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Marks')
      AND name = 'ClassID'
      AND is_nullable = 0
)
BEGIN
    -- Drop FK if it was somehow re-added
    DECLARE @fk NVARCHAR(256);
    SELECT @fk = fk.name
    FROM sys.foreign_keys fk
    JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    JOIN sys.columns c ON fkc.parent_object_id = c.object_id
                      AND fkc.parent_column_id  = c.column_id
    WHERE fk.parent_object_id = OBJECT_ID('Marks') AND c.name = 'ClassID';
    IF @fk IS NOT NULL
    BEGIN
        DECLARE @sql NVARCHAR(512) = N'ALTER TABLE Marks DROP CONSTRAINT [' + @fk + N']';
        EXEC(@sql);
        PRINT 'Dropped FK on Marks.ClassID';
    END
    ALTER TABLE Marks ALTER COLUMN ClassID INT NULL;
    PRINT '✅ Marks.ClassID set to nullable';
END
ELSE
BEGIN
    PRINT '✅ Marks.ClassID is already nullable — OK';
END
GO

-- ================================================================
-- 2. Ensure AcademicYear exists
-- ================================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Marks') AND name='AcademicYear')
BEGIN
    ALTER TABLE Marks ADD AcademicYear NVARCHAR(10) NULL DEFAULT '2024-25';
    PRINT '✅ Added Marks.AcademicYear';
END
ELSE PRINT '✅ Marks.AcademicYear OK';
GO

-- ================================================================
-- 3. Ensure UpdatedAt exists
-- ================================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Marks') AND name='UpdatedAt')
BEGIN
    ALTER TABLE Marks ADD UpdatedAt DATETIME NULL DEFAULT GETDATE();
    EXEC sp_executesql N'UPDATE Marks SET UpdatedAt = GETDATE() WHERE UpdatedAt IS NULL';
    PRINT '✅ Added Marks.UpdatedAt';
END
ELSE PRINT '✅ Marks.UpdatedAt OK';
GO

-- ================================================================
-- 4. Ensure CA1-CA5, Midterm, Endterm exist
-- ================================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Marks') AND name='CA1')
    ALTER TABLE Marks ADD CA1 DECIMAL(5,2) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Marks') AND name='CA2')
    ALTER TABLE Marks ADD CA2 DECIMAL(5,2) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Marks') AND name='CA3')
    ALTER TABLE Marks ADD CA3 DECIMAL(5,2) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Marks') AND name='CA4')
    ALTER TABLE Marks ADD CA4 DECIMAL(5,2) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Marks') AND name='CA5')
    ALTER TABLE Marks ADD CA5 DECIMAL(5,2) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Marks') AND name='Midterm')
    ALTER TABLE Marks ADD Midterm DECIMAL(5,2) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Marks') AND name='Endterm')
    ALTER TABLE Marks ADD Endterm DECIMAL(5,2) NULL;
PRINT '✅ CA1-CA5, Midterm, Endterm verified';
GO

-- ================================================================
-- 5. Final schema verification
-- ================================================================
PRINT '';
PRINT '=== Final Marks Table Schema ===';
SELECT
    c.name  AS [Column],
    tp.name AS [Type],
    CASE c.is_nullable WHEN 1 THEN 'NULL' ELSE 'NOT NULL' END AS Nullable,
    OBJECT_DEFINITION(c.default_object_id) AS [Default]
FROM sys.columns c
JOIN sys.tables  t  ON c.object_id    = t.object_id
JOIN sys.types   tp ON c.user_type_id = tp.user_type_id
WHERE t.name = 'Marks'
ORDER BY c.column_id;
GO

PRINT '';
PRINT '=== Row counts ===';
SELECT COUNT(*)                   AS TotalRows          FROM Marks;
SELECT COUNT(DISTINCT StudentID)  AS UniqueStudents     FROM Marks;
SELECT COUNT(*)                   AS NullClassIDRows    FROM Marks WHERE ClassID IS NULL;
GO

PRINT '';
PRINT '=== PATCH v6c COMPLETE ===';
PRINT 'ClassID is nullable. Now replace teacher_routes_merged.py and restart Flask.';
GO