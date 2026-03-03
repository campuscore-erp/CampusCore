-- ================================================================
-- DATABASE PATCH v4 — Fix Invisible Materials / Exams / Classes
-- 
-- ROOT CAUSE: The MSSQL schema has columns that were not yet added,
-- causing INSERT failures (materials/exams never saved) and 
-- SELECT failures (student queries joining on missing columns).
--
-- Run on: UniversityERP (MSSQL)
-- Safe to run multiple times.
-- ================================================================

USE UniversityERP;
GO

PRINT '=== Starting PATCH v4 ===';
GO

-- ================================================================
-- 1. StudyMaterials — ensure all columns exist
-- ================================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('StudyMaterials') AND name='Description')
BEGIN
    ALTER TABLE StudyMaterials ADD Description NVARCHAR(MAX) NULL;
    PRINT 'Added StudyMaterials.Description';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('StudyMaterials') AND name='FileSize')
BEGIN
    ALTER TABLE StudyMaterials ADD FileSize BIGINT NOT NULL DEFAULT 0;
    PRINT 'Added StudyMaterials.FileSize';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('StudyMaterials') AND name='IsPublished')
BEGIN
    ALTER TABLE StudyMaterials ADD IsPublished BIT NOT NULL DEFAULT 1;
    EXEC sp_executesql N'UPDATE StudyMaterials SET IsPublished=1 WHERE IsPublished IS NULL';
    PRINT 'Added StudyMaterials.IsPublished';
END
GO

-- ================================================================
-- 2. OnlineClasses — ensure all columns exist
-- ================================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('OnlineClasses') AND name='Topic')
BEGIN
    ALTER TABLE OnlineClasses ADD Topic NVARCHAR(500) NULL;
    EXEC sp_executesql N'UPDATE OnlineClasses SET Topic=Title WHERE Topic IS NULL';
    PRINT 'Added OnlineClasses.Topic';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('OnlineClasses') AND name='Description')
BEGIN
    ALTER TABLE OnlineClasses ADD Description NVARCHAR(MAX) NULL;
    PRINT 'Added OnlineClasses.Description';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('OnlineClasses') AND name='ScheduledDate')
BEGIN
    ALTER TABLE OnlineClasses ADD ScheduledDate DATE NULL;
    EXEC sp_executesql N'UPDATE OnlineClasses SET ScheduledDate=CAST(CreatedAt AS DATE) WHERE ScheduledDate IS NULL';
    PRINT 'Added OnlineClasses.ScheduledDate';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('OnlineClasses') AND name='StartTime')
BEGIN
    ALTER TABLE OnlineClasses ADD StartTime NVARCHAR(10) NULL;
    PRINT 'Added OnlineClasses.StartTime';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('OnlineClasses') AND name='EndTime')
BEGIN
    ALTER TABLE OnlineClasses ADD EndTime NVARCHAR(10) NULL;
    PRINT 'Added OnlineClasses.EndTime';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('OnlineClasses') AND name='IsActive')
BEGIN
    ALTER TABLE OnlineClasses ADD IsActive BIT NOT NULL DEFAULT 1;
    EXEC sp_executesql N'UPDATE OnlineClasses SET IsActive=1 WHERE IsActive IS NULL';
    PRINT 'Added OnlineClasses.IsActive';
END
GO

-- ================================================================
-- 3. Exams — ensure all columns exist
-- ================================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Exams') AND name='ExamName')
BEGIN
    ALTER TABLE Exams ADD ExamName NVARCHAR(200) NULL;
    EXEC sp_executesql N'
        UPDATE e SET ExamName = e.ExamType + N'' - '' + s.SubjectCode
        FROM Exams e JOIN Subjects s ON e.SubjectID = s.SubjectID
        WHERE e.ExamName IS NULL
    ';
    PRINT 'Added Exams.ExamName';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Exams') AND name='Instructions')
BEGIN
    ALTER TABLE Exams ADD Instructions NVARCHAR(MAX) NULL;
    PRINT 'Added Exams.Instructions';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Exams') AND name='Duration')
BEGIN
    ALTER TABLE Exams ADD Duration INT NOT NULL DEFAULT 60;
    PRINT 'Added Exams.Duration';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Exams') AND name='IsActive')
BEGIN
    ALTER TABLE Exams ADD IsActive BIT NOT NULL DEFAULT 1;
    EXEC sp_executesql N'UPDATE Exams SET IsActive=1 WHERE IsActive IS NULL';
    PRINT 'Added Exams.IsActive';
END
ELSE
BEGIN
    -- Make sure all existing exams are active
    EXEC sp_executesql N'UPDATE Exams SET IsActive=1 WHERE IsActive IS NULL OR IsActive=0';
    PRINT 'Exams.IsActive backfilled to 1';
END
GO

-- ================================================================
-- 4. ExamQuestions — ensure QuestionOrder exists
-- ================================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ExamQuestions') AND name='QuestionOrder')
BEGIN
    ALTER TABLE ExamQuestions ADD QuestionOrder INT NOT NULL DEFAULT 1;
    EXEC sp_executesql N'
        WITH Ordered AS (
            SELECT QuestionID, ROW_NUMBER() OVER (PARTITION BY ExamID ORDER BY QuestionID) AS rn
            FROM ExamQuestions
        )
        UPDATE eq SET eq.QuestionOrder = o.rn
        FROM ExamQuestions eq JOIN Ordered o ON eq.QuestionID = o.QuestionID
    ';
    PRINT 'Added ExamQuestions.QuestionOrder';
END
GO

-- ================================================================
-- 5. ExamSubmissions — ensure MarksObtained exists
-- ================================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ExamSubmissions') AND name='MarksObtained')
BEGIN
    ALTER TABLE ExamSubmissions ADD MarksObtained DECIMAL(10,2) NULL;
    PRINT 'Added ExamSubmissions.MarksObtained';
END
GO

-- ================================================================
-- 6. Notifications — add UserID column + make StudentID nullable
-- ================================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Notifications') AND name='UserID')
BEGIN
    ALTER TABLE Notifications ADD UserID INT NULL;
    EXEC sp_executesql N'UPDATE Notifications SET UserID=StudentID WHERE UserID IS NULL AND StudentID IS NOT NULL';
    PRINT 'Added Notifications.UserID';
END
GO

-- Make StudentID nullable (drop FK first if needed)
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id=OBJECT_ID('Notifications') AND name='StudentID' AND is_nullable=0
)
BEGIN
    DECLARE @fk   NVARCHAR(256);
    DECLARE @sql  NVARCHAR(512);
    SELECT @fk = fk.name
    FROM   sys.foreign_keys fk
    JOIN   sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    JOIN   sys.columns c ON fkc.parent_object_id=c.object_id AND fkc.parent_column_id=c.column_id
    WHERE  fk.parent_object_id=OBJECT_ID('Notifications') AND c.name='StudentID';

    IF @fk IS NOT NULL
    BEGIN
        SET @sql = N'ALTER TABLE Notifications DROP CONSTRAINT [' + @fk + N']';
        EXEC(@sql);
        PRINT 'Dropped FK on Notifications.StudentID';
    END

    ALTER TABLE Notifications ALTER COLUMN StudentID INT NULL;
    PRINT 'Notifications.StudentID is now nullable';
END
GO

-- ================================================================
-- 7. FeePayments — extra columns
-- ================================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('FeePayments') AND name='AcademicYear')
BEGIN
    ALTER TABLE FeePayments ADD AcademicYear NVARCHAR(10) NOT NULL DEFAULT '2024-25';
    PRINT 'Added FeePayments.AcademicYear';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('FeePayments') AND name='Description')
BEGIN
    ALTER TABLE FeePayments ADD Description NVARCHAR(300) NULL;
    PRINT 'Added FeePayments.Description';
END
GO

-- ================================================================
-- 8. DIAGNOSTIC — show current row counts so you can verify data
-- ================================================================
PRINT '';
PRINT '=== ROW COUNTS ===';
SELECT 'StudyMaterials' AS [Table], COUNT(*) AS Rows FROM StudyMaterials;
SELECT 'OnlineClasses'  AS [Table], COUNT(*) AS Rows FROM OnlineClasses;
SELECT 'Exams'          AS [Table], COUNT(*) AS Rows FROM Exams;
SELECT 'ExamQuestions'  AS [Table], COUNT(*) AS Rows FROM ExamQuestions;
SELECT 'Notifications'  AS [Table], COUNT(*) AS Rows FROM Notifications;
GO

-- ================================================================
-- 9. COLUMN VERIFICATION
-- ================================================================
PRINT '';
PRINT '=== COLUMN CHECK ===';

SELECT t.name AS [Table], c.name AS [Column], tp.name AS [Type],
       CASE c.is_nullable WHEN 1 THEN 'NULL' ELSE 'NOT NULL' END AS Nullable
FROM sys.columns c
JOIN sys.tables  t  ON c.object_id = t.object_id
JOIN sys.types   tp ON c.user_type_id = tp.user_type_id
WHERE t.name IN ('StudyMaterials','OnlineClasses','Exams','ExamQuestions','Notifications','ExamSubmissions')
ORDER BY t.name, c.column_id;
GO

PRINT '=== PATCH v4 COMPLETE ===';
GO