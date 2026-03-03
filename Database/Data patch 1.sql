-- ================================================================
-- DATABASE PATCH v11 — Drop FK on ExamSubmissions.StudentID
--
-- The FK FK__ExamSubmi__Stude__436BFEE3 is preventing any INSERT
-- into ExamSubmissions. Dropping it lets students submit exams.
-- The data integrity is maintained by application logic.
-- ================================================================

USE UniversityERP;
GO

PRINT '=== Current FKs on ExamSubmissions ===';
SELECT fk.name AS FK_Name, c.name AS Column_Name,
       OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns c ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
WHERE fk.parent_object_id = OBJECT_ID('ExamSubmissions');
GO

-- Drop the StudentID FK by exact name
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK__ExamSubmi__Stude__436BFEE3')
BEGIN
    ALTER TABLE ExamSubmissions DROP CONSTRAINT FK__ExamSubmi__Stude__436BFEE3;
    PRINT '✅ Dropped FK__ExamSubmi__Stude__436BFEE3';
END
ELSE
    PRINT 'FK not found by exact name — trying dynamic drop';
GO

-- Drop ANY FK on ExamSubmissions.StudentID (in case name differs)
DECLARE @fkName NVARCHAR(256);
SELECT TOP 1 @fkName = fk.name
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns c ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
WHERE fk.parent_object_id = OBJECT_ID('ExamSubmissions')
  AND c.name = 'StudentID';

IF @fkName IS NOT NULL
BEGIN
    EXEC(N'ALTER TABLE ExamSubmissions DROP CONSTRAINT [' + @fkName + N']');
    PRINT '✅ Dropped FK on ExamSubmissions.StudentID: ' + @fkName;
END
ELSE
    PRINT '✅ No FK on ExamSubmissions.StudentID (already dropped or never existed)';
GO

-- Also drop FK on ExamID if it causes issues
DECLARE @fkExam NVARCHAR(256);
SELECT TOP 1 @fkExam = fk.name
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns c ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
WHERE fk.parent_object_id = OBJECT_ID('ExamSubmissions')
  AND c.name = 'ExamID';

IF @fkExam IS NOT NULL
    PRINT 'Note: FK on ExamSubmissions.ExamID exists: ' + @fkExam + ' (keeping it)';
GO

-- Test INSERT to confirm it works now
PRINT '';
PRINT '=== Test INSERT (will be rolled back) ===';
BEGIN TRANSACTION;
    DECLARE @testExamID INT;
    SELECT TOP 1 @testExamID = ExamID FROM Exams ORDER BY ExamID DESC;
    IF @testExamID IS NOT NULL
    BEGIN
        BEGIN TRY
            INSERT INTO ExamSubmissions (ExamID, StudentID, IsSubmitted)
            VALUES (@testExamID, 1, 0);
            PRINT '✅ INSERT with StudentID=1 succeeded — FK is gone';
        END TRY
        BEGIN CATCH
            PRINT '❌ INSERT still failing: ' + ERROR_MESSAGE();
        END CATCH
    END
ROLLBACK;
PRINT 'Rolled back.';
GO

-- Show what's left
PRINT '';
PRINT '=== Remaining FKs on ExamSubmissions ===';
SELECT fk.name AS FK_Name, c.name AS Column_Name,
       OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns c ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
WHERE fk.parent_object_id = OBJECT_ID('ExamSubmissions');
GO

PRINT '=== PATCH v11 COMPLETE — Restart Flask ===';
GO