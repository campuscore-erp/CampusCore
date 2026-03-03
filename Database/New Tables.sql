-- ===================================================================
-- UNIVERSITY ERP - SCHEMA PATCH SCRIPT
-- Run this in SSMS on your UniversityERP database
-- Adds missing tables that the application expects
-- Safe to run multiple times (all changes are conditional)
-- ===================================================================

USE UniversityERP;
GO

PRINT '========================================'
PRINT 'Applying Schema Patches...'
PRINT '========================================'
GO

-- ===================================================================
-- PATCH 1: Add Notifications table (referenced in teacher routes
--           for online class student notifications)
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Notifications')
BEGIN
    CREATE TABLE Notifications (
        NotificationID  INT             IDENTITY(1,1) PRIMARY KEY,
        UserID          INT             NOT NULL,
        Title           NVARCHAR(255)   NOT NULL,
        Message         NVARCHAR(1000),
        Type            NVARCHAR(50)    DEFAULT 'General',
        IsRead          BIT             DEFAULT 0,
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (UserID) REFERENCES Users(UserID)
    );
    PRINT 'Created: Notifications';
END
ELSE PRINT 'Exists:  Notifications';
GO

-- ===================================================================
-- PATCH 2: Add ExamSubmissions table (referenced in exam routes
--           for tracking student exam attempts)
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ExamSubmissions')
BEGIN
    CREATE TABLE ExamSubmissions (
        SubmissionID    INT             IDENTITY(1,1) PRIMARY KEY,
        ExamID          INT             NOT NULL,
        StudentID       INT             NOT NULL,
        SubmittedAt     DATETIME        DEFAULT GETDATE(),
        TotalScore      DECIMAL(5,2)    DEFAULT 0,
        IsSubmitted     BIT             DEFAULT 0,
        Answers         NVARCHAR(MAX),
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (ExamID)     REFERENCES Exams(ExamID),
        FOREIGN KEY (StudentID)  REFERENCES Users(UserID)
    );
    PRINT 'Created: ExamSubmissions';
END
ELSE PRINT 'Exists:  ExamSubmissions';
GO

-- ===================================================================
-- PATCH 3: Make OnlineClasses.ClassID nullable
--           (allows INSERT without requiring ClassID resolution)
-- ===================================================================
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'OnlineClasses'
      AND COLUMN_NAME = 'ClassID'
      AND IS_NULLABLE = 'NO'
)
BEGIN
    ALTER TABLE OnlineClasses ALTER COLUMN ClassID INT NULL;
    PRINT 'Patched: OnlineClasses.ClassID → nullable';
END
ELSE PRINT 'OK:      OnlineClasses.ClassID already nullable or does not exist';
GO

-- ===================================================================
-- PATCH 4: Make StudyMaterials.ClassID nullable
--           (prevents FK violation when ClassID cannot be resolved)
-- ===================================================================
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'StudyMaterials'
      AND COLUMN_NAME = 'ClassID'
      AND IS_NULLABLE = 'NO'
)
BEGIN
    ALTER TABLE StudyMaterials ALTER COLUMN ClassID INT NULL;
    PRINT 'Patched: StudyMaterials.ClassID → nullable';
END
ELSE PRINT 'OK:      StudyMaterials.ClassID already nullable or does not exist';
GO

-- ===================================================================
-- PATCH 5: Make Exams.ClassID nullable
-- ===================================================================
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Exams'
      AND COLUMN_NAME = 'ClassID'
      AND IS_NULLABLE = 'NO'
)
BEGIN
    ALTER TABLE Exams ALTER COLUMN ClassID INT NULL;
    PRINT 'Patched: Exams.ClassID → nullable';
END
ELSE PRINT 'OK:      Exams.ClassID already nullable or does not exist';
GO

-- ===================================================================
-- PATCH 6: Make Attendance.ClassID nullable
-- ===================================================================
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Attendance'
      AND COLUMN_NAME = 'ClassID'
      AND IS_NULLABLE = 'NO'
)
BEGIN
    ALTER TABLE Attendance ALTER COLUMN ClassID INT NULL;
    PRINT 'Patched: Attendance.ClassID → nullable';
END
ELSE PRINT 'OK:      Attendance.ClassID already nullable or does not exist';
GO

-- ===================================================================
-- PATCH 7: Add TotalQuestions column to Exams (optional feature)
-- ===================================================================
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Exams' AND COLUMN_NAME = 'TotalQuestions'
)
BEGIN
    ALTER TABLE Exams ADD TotalQuestions INT DEFAULT 0;
    PRINT 'Added: Exams.TotalQuestions';
END
ELSE PRINT 'Exists: Exams.TotalQuestions';
GO

-- ===================================================================
-- VERIFICATION
-- ===================================================================
PRINT '';
PRINT 'Patch verification:';
SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('OnlineClasses', 'StudyMaterials', 'Exams', 'Attendance')
  AND COLUMN_NAME = 'ClassID'
ORDER BY TABLE_NAME;

SELECT TABLE_NAME, 'EXISTS' AS Status
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('Notifications', 'ExamSubmissions')
ORDER BY TABLE_NAME;
GO

PRINT '';
PRINT '========================================'
PRINT 'Schema patches applied successfully!'
PRINT 'Now restart your Flask server.'
PRINT '========================================'
GO
