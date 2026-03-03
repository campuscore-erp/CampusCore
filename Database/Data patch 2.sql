-- ================================================================
-- DATABASE PATCH v10 — Fix All Remaining Column Issues
--
-- Issues found in server logs:
--   1. Exams.StartTime / Exams.EndTime — column does not exist
--   2. Notifications.StudentID — column does not exist (use UserID)
--   3. ExamSubmissions FK violation — StudentID FK to Users.UserID
--      is too strict; need to verify it points to correct column
--
-- Safe to run multiple times.
-- ================================================================

USE UniversityERP;
GO

PRINT '=== Starting PATCH v10 ===';
GO

-- ================================================================
-- 1. Exams — add StartTime and EndTime (queries reference them)
-- ================================================================
PRINT '=== Exams columns ===';
SELECT c.name AS [Column], tp.name AS [Type],
       CASE c.is_nullable WHEN 1 THEN 'NULL' ELSE 'NOT NULL' END AS Nullable
FROM sys.columns c
JOIN sys.tables t  ON c.object_id = t.object_id
JOIN sys.types  tp ON c.user_type_id = tp.user_type_id
WHERE t.name = 'Exams' ORDER BY c.column_id;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Exams') AND name='StartTime')
BEGIN
    ALTER TABLE Exams ADD StartTime NVARCHAR(10) NULL;
    PRINT '✅ Added Exams.StartTime';
END
ELSE PRINT '✅ Exams.StartTime OK';
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Exams') AND name='EndTime')
BEGIN
    ALTER TABLE Exams ADD EndTime NVARCHAR(10) NULL;
    PRINT '✅ Added Exams.EndTime';
END
ELSE PRINT '✅ Exams.EndTime OK';
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Exams') AND name='ExamName')
BEGIN
    ALTER TABLE Exams ADD ExamName NVARCHAR(500) NULL;
    EXEC sp_executesql N'UPDATE Exams SET ExamName = ISNULL(ExamTitle, ExamType) WHERE ExamName IS NULL';
    PRINT '✅ Added Exams.ExamName';
END
ELSE PRINT '✅ Exams.ExamName OK';
GO

-- ================================================================
-- 2. Notifications — add StudentID if missing (some queries use it)
-- ================================================================
PRINT '';
PRINT '=== Notifications columns ===';
SELECT c.name AS [Column], tp.name AS [Type],
       CASE c.is_nullable WHEN 1 THEN 'NULL' ELSE 'NOT NULL' END AS Nullable
FROM sys.columns c
JOIN sys.tables t  ON c.object_id = t.object_id
JOIN sys.types  tp ON c.user_type_id = tp.user_type_id
WHERE t.name = 'Notifications' ORDER BY c.column_id;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Notifications') AND name='StudentID')
BEGIN
    ALTER TABLE Notifications ADD StudentID INT NULL;
    -- Sync StudentID from UserID if UserID exists
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Notifications') AND name='UserID')
        EXEC sp_executesql N'UPDATE Notifications SET StudentID=UserID WHERE StudentID IS NULL AND UserID IS NOT NULL';
    PRINT '✅ Added Notifications.StudentID';
END
ELSE PRINT '✅ Notifications.StudentID OK';
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Notifications') AND name='UserID')
BEGIN
    ALTER TABLE Notifications ADD UserID INT NULL;
    -- Sync from StudentID
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Notifications') AND name='StudentID')
        EXEC sp_executesql N'UPDATE Notifications SET UserID=StudentID WHERE UserID IS NULL AND StudentID IS NOT NULL';
    PRINT '✅ Added Notifications.UserID';
END
ELSE PRINT '✅ Notifications.UserID OK';
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('Notifications') AND name='IsRead')
BEGIN
    ALTER TABLE Notifications ADD IsRead BIT NOT NULL DEFAULT 0;
    PRINT '✅ Added Notifications.IsRead';
END
ELSE PRINT '✅ Notifications.IsRead OK';
GO

-- ================================================================
-- 3. ExamSubmissions FK — show what the FK actually requires
--    The FK FK__ExamSubmi__Stude__436BFEE3 ties StudentID -> Users.UserID
--    This is CORRECT — we just need to make sure we pass the right UserID
-- ================================================================
PRINT '';
PRINT '=== ExamSubmissions FK info ===';
SELECT
    fk.name AS FK_Name,
    OBJECT_NAME(fk.parent_object_id) AS [Table],
    c_parent.name AS [Column],
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    c_ref.name AS ReferencedColumn
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns c_parent ON fkc.parent_object_id = c_parent.object_id
                          AND fkc.parent_column_id = c_parent.column_id
JOIN sys.columns c_ref ON fkc.referenced_object_id = c_ref.object_id
                       AND fkc.referenced_column_id = c_ref.column_id
WHERE fk.parent_object_id = OBJECT_ID('ExamSubmissions');
GO

-- Show lowest UserIDs so we can verify student UserIDs exist
PRINT '';
PRINT '=== Users sample (first 5 by UserID) ===';
SELECT TOP 5 UserID, UserCode, UserType, IsActive
FROM Users ORDER BY UserID;
GO

PRINT '=== Students sample (lowest UserIDs) ===';
SELECT TOP 5 UserID, UserCode, UserType
FROM Users WHERE UserType = 'Student' ORDER BY UserID;
GO

-- ================================================================
-- 4. ExamSubmissions — verify columns
-- ================================================================
PRINT '';
PRINT '=== ExamSubmissions schema ===';
SELECT c.name AS [Column], tp.name AS [Type],
       CASE c.is_nullable WHEN 1 THEN 'NULL' ELSE 'NOT NULL' END AS Nullable,
       OBJECT_DEFINITION(c.default_object_id) AS [Default]
FROM sys.columns c
JOIN sys.tables t  ON c.object_id = t.object_id
JOIN sys.types  tp ON c.user_type_id = tp.user_type_id
WHERE t.name = 'ExamSubmissions' ORDER BY c.column_id;
GO

-- ================================================================
-- 5. DIAGNOSTIC — what UserID does the student D1S1N01 have?
-- ================================================================
PRINT '';
PRINT '=== Student D1S1N01 UserID ===';
SELECT UserID, UserCode, UserType, IsActive
FROM Users WHERE UserCode = 'D1S1N01';
GO

PRINT '=== All student UserIDs (first 10) ===';
SELECT TOP 10 UserID, UserCode, FullName, IsActive
FROM Users WHERE UserType = 'Student' ORDER BY UserID;
GO

PRINT '=== PATCH v10 COMPLETE ===';
GO