-- ===================================================================
-- UNIVERSITY ERP - COMPLETE DATABASE SCHEMA
-- MS SQL Server | Run this FIRST before any data scripts
-- ===================================================================
-- HOW TO USE:
--   1. Open SQL Server Management Studio (SSMS)
--   2. Connect to your SQL Server instance
--   3. Run THIS file first (creates all tables)
--   4. Then run SQLQuery 1.sql (inserts all data)
-- ===================================================================

-- Create and switch to the UniversityERP database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'UniversityERP')
BEGIN
    CREATE DATABASE UniversityERP;
    PRINT 'Database UniversityERP created.';
END
ELSE
BEGIN
    PRINT 'Database UniversityERP already exists.';
END
GO

USE UniversityERP;
GO

PRINT '========================================';
PRINT 'Creating Tables...';
PRINT '========================================';
GO

-- ===================================================================
-- TABLE 1: Departments
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Departments')
BEGIN
    CREATE TABLE Departments (
        DepartmentID    INT             IDENTITY(1,1) PRIMARY KEY,
        DepartmentName  NVARCHAR(150)   NOT NULL UNIQUE,
        DepartmentCode  NVARCHAR(20)    NOT NULL UNIQUE,
        CreatedAt       DATETIME        DEFAULT GETDATE()
    );
    PRINT 'Created: Departments';
END
ELSE PRINT 'Exists:  Departments';
GO

-- ===================================================================
-- TABLE 2: Users  (Admin, Teacher, Student — all in one table)
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Users')
BEGIN
    CREATE TABLE Users (
        UserID          INT             IDENTITY(1,1) PRIMARY KEY,
        UserType        NVARCHAR(20)    NOT NULL CHECK (UserType IN ('Admin', 'Teacher', 'Student')),
        UserCode        NVARCHAR(50)    NOT NULL UNIQUE,
        FullName        NVARCHAR(150)   NOT NULL,
        Email           NVARCHAR(150),
        Phone           NVARCHAR(20),
        DateOfBirth     DATE,
        Gender          NVARCHAR(10),
        FatherName      NVARCHAR(150),
        MotherName      NVARCHAR(150),
        PasswordHash    NVARCHAR(255)   NOT NULL,
        IsFirstLogin    BIT             DEFAULT 1,
        DepartmentID    INT             NULL,
        Semester        INT             NULL,
        JoinDate        DATE            DEFAULT GETDATE(),
        Address         NVARCHAR(255),
        IsActive        BIT             DEFAULT 1,
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        UpdatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
    );
    PRINT 'Created: Users';
END
ELSE PRINT 'Exists:  Users';
GO

-- ===================================================================
-- TABLE 3: Subjects
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Subjects')
BEGIN
    CREATE TABLE Subjects (
        SubjectID       INT             IDENTITY(1,1) PRIMARY KEY,
        SubjectName     NVARCHAR(200)   NOT NULL,
        SubjectCode     NVARCHAR(20)    NOT NULL UNIQUE,
        Credits         INT,
        DepartmentID    INT             NOT NULL,
        Semester        INT             NOT NULL,
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
    );
    PRINT 'Created: Subjects';
END
ELSE PRINT 'Exists:  Subjects';
GO

-- ===================================================================
-- TABLE 4: Classes
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Classes')
BEGIN
    CREATE TABLE Classes (
        ClassID         INT             IDENTITY(1,1) PRIMARY KEY,
        ClassName       NVARCHAR(100)   NOT NULL,
        DepartmentID    INT             NOT NULL,
        Semester        INT             NOT NULL,
        Section         NVARCHAR(10)    DEFAULT 'A',
        AcademicYear    NVARCHAR(20),
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
    );
    PRINT 'Created: Classes';
END
ELSE PRINT 'Exists:  Classes';
GO

-- ===================================================================
-- TABLE 5: TeacherSubjects  (Teacher → Subject → Class assignments)
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'TeacherSubjects')
BEGIN
    CREATE TABLE TeacherSubjects (
        TeacherSubjectID    INT         IDENTITY(1,1) PRIMARY KEY,
        TeacherID           INT         NOT NULL,
        SubjectID           INT         NOT NULL,
        ClassID             INT         NOT NULL,
        AcademicYear        NVARCHAR(20),
        AssignedAt          DATETIME    DEFAULT GETDATE(),
        FOREIGN KEY (TeacherID)  REFERENCES Users(UserID),
        FOREIGN KEY (SubjectID)  REFERENCES Subjects(SubjectID),
        FOREIGN KEY (ClassID)    REFERENCES Classes(ClassID)
    );
    PRINT 'Created: TeacherSubjects';
END
ELSE PRINT 'Exists:  TeacherSubjects';
GO

-- ===================================================================
-- TABLE 6: StudentEnrollments  (Student → Class → Subject)
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StudentEnrollments')
BEGIN
    CREATE TABLE StudentEnrollments (
        EnrollmentID    INT             IDENTITY(1,1) PRIMARY KEY,
        StudentID       INT             NOT NULL,
        ClassID         INT             NOT NULL,
        SubjectID       INT             NOT NULL,
        AcademicYear    NVARCHAR(20),
        EnrolledAt      DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (StudentID)  REFERENCES Users(UserID),
        FOREIGN KEY (ClassID)    REFERENCES Classes(ClassID),
        FOREIGN KEY (SubjectID)  REFERENCES Subjects(SubjectID)
    );
    PRINT 'Created: StudentEnrollments';
END
ELSE PRINT 'Exists:  StudentEnrollments';
GO

-- ===================================================================
-- TABLE 7: Timetable
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Timetable')
BEGIN
    CREATE TABLE Timetable (
        TimetableID     INT             IDENTITY(1,1) PRIMARY KEY,
        ClassID         INT             NOT NULL,
        SubjectID       INT             NOT NULL,
        TeacherID       INT             NOT NULL,
        DayOfWeek       NVARCHAR(15)    NOT NULL,   -- Monday, Tuesday, etc.
        StartTime       TIME            NOT NULL,
        EndTime         TIME            NOT NULL,
        RoomNumber      NVARCHAR(50),
        Room            NVARCHAR(50),               -- alias used in some scripts
        AcademicYear    NVARCHAR(20),
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (ClassID)    REFERENCES Classes(ClassID),
        FOREIGN KEY (SubjectID)  REFERENCES Subjects(SubjectID),
        FOREIGN KEY (TeacherID)  REFERENCES Users(UserID)
    );
    PRINT 'Created: Timetable';
END
ELSE PRINT 'Exists:  Timetable';
GO

-- ===================================================================
-- TABLE 8: QRCodes  (for attendance scanning)
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'QRCodes')
BEGIN
    CREATE TABLE QRCodes (
        QRCodeID        INT             IDENTITY(1,1) PRIMARY KEY,
        TeacherID       INT             NOT NULL,
        SubjectID       INT             NOT NULL,
        ClassID         INT             NOT NULL,
        QRToken         NVARCHAR(255)   NOT NULL UNIQUE,
        ExpiresAt       DATETIME        NOT NULL,
        IsUsed          BIT             DEFAULT 0,
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (TeacherID)  REFERENCES Users(UserID),
        FOREIGN KEY (SubjectID)  REFERENCES Subjects(SubjectID),
        FOREIGN KEY (ClassID)    REFERENCES Classes(ClassID)
    );
    PRINT 'Created: QRCodes';
END
ELSE PRINT 'Exists:  QRCodes';
GO

-- ===================================================================
-- TABLE 9: Attendance
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Attendance')
BEGIN
    CREATE TABLE Attendance (
        AttendanceID    INT             IDENTITY(1,1) PRIMARY KEY,
        StudentID       INT             NOT NULL,
        SubjectID       INT             NOT NULL,
        ClassID         INT             NOT NULL,
        QRCodeID        INT             NULL,
        AttendanceDate  DATE            NOT NULL,
        Status          NVARCHAR(20)    DEFAULT 'Present'   CHECK (Status IN ('Present', 'Absent', 'Late')),
        MarkedAt        DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (StudentID)  REFERENCES Users(UserID),
        FOREIGN KEY (SubjectID)  REFERENCES Subjects(SubjectID),
        FOREIGN KEY (ClassID)    REFERENCES Classes(ClassID),
        FOREIGN KEY (QRCodeID)   REFERENCES QRCodes(QRCodeID)
    );
    PRINT 'Created: Attendance';
END
ELSE PRINT 'Exists:  Attendance';
GO

-- ===================================================================
-- TABLE 10: Marks
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Marks')
BEGIN
    CREATE TABLE Marks (
        MarkID          INT             IDENTITY(1,1) PRIMARY KEY,
        StudentID       INT             NOT NULL,
        SubjectID       INT             NOT NULL,
        ClassID         INT             NOT NULL,
        AcademicYear    NVARCHAR(20),
        CA1             DECIMAL(5,2)    DEFAULT 0,
        CA2             DECIMAL(5,2)    DEFAULT 0,
        CA3             DECIMAL(5,2)    DEFAULT 0,
        CA4             DECIMAL(5,2)    DEFAULT 0,
        CA5             DECIMAL(5,2)    DEFAULT 0,
        Midterm         DECIMAL(5,2)    DEFAULT 0,
        Endterm         DECIMAL(5,2)    DEFAULT 0,
        UpdatedBy       INT             NULL,
        UpdatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (StudentID)  REFERENCES Users(UserID),
        FOREIGN KEY (SubjectID)  REFERENCES Subjects(SubjectID),
        FOREIGN KEY (ClassID)    REFERENCES Classes(ClassID)
    );
    PRINT 'Created: Marks';
END
ELSE PRINT 'Exists:  Marks';
GO

-- ===================================================================
-- TABLE 11: StudyMaterials
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StudyMaterials')
BEGIN
    CREATE TABLE StudyMaterials (
        MaterialID      INT             IDENTITY(1,1) PRIMARY KEY,
        SubjectID       INT             NOT NULL,
        ClassID         INT             NOT NULL,
        TeacherID       INT             NOT NULL,
        Title           NVARCHAR(255)   NOT NULL,
        Description     NVARCHAR(500),
        FileName        NVARCHAR(255),
        FilePath        NVARCHAR(500),
        FileType        NVARCHAR(50),
        FileSize        INT,
        UploadedAt      DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (SubjectID)  REFERENCES Subjects(SubjectID),
        FOREIGN KEY (ClassID)    REFERENCES Classes(ClassID),
        FOREIGN KEY (TeacherID)  REFERENCES Users(UserID)
    );
    PRINT 'Created: StudyMaterials';
END
ELSE PRINT 'Exists:  StudyMaterials';
GO

-- ===================================================================
-- TABLE 12: Exams
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Exams')
BEGIN
    CREATE TABLE Exams (
        ExamID          INT             IDENTITY(1,1) PRIMARY KEY,
        SubjectID       INT             NOT NULL,
        ClassID         INT             NOT NULL,
        TeacherID       INT             NOT NULL,
        ExamTitle       NVARCHAR(255)   NOT NULL,
        ExamType        NVARCHAR(50),
        TotalMarks      INT             DEFAULT 100,
        Duration        INT,            -- in minutes
        ExamDate        DATETIME,
        IsPublished     BIT             DEFAULT 0,
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (SubjectID)  REFERENCES Subjects(SubjectID),
        FOREIGN KEY (ClassID)    REFERENCES Classes(ClassID),
        FOREIGN KEY (TeacherID)  REFERENCES Users(UserID)
    );
    PRINT 'Created: Exams';
END
ELSE PRINT 'Exists:  Exams';
GO

-- ===================================================================
-- TABLE 13: ExamQuestions
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ExamQuestions')
BEGIN
    CREATE TABLE ExamQuestions (
        QuestionID      INT             IDENTITY(1,1) PRIMARY KEY,
        ExamID          INT             NOT NULL,
        QuestionText    NVARCHAR(MAX)   NOT NULL,
        OptionA         NVARCHAR(500),
        OptionB         NVARCHAR(500),
        OptionC         NVARCHAR(500),
        OptionD         NVARCHAR(500),
        CorrectAnswer   NVARCHAR(10),
        Marks           INT             DEFAULT 1,
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (ExamID) REFERENCES Exams(ExamID)
    );
    PRINT 'Created: ExamQuestions';
END
ELSE PRINT 'Exists:  ExamQuestions';
GO

-- ===================================================================
-- TABLE 14: OnlineClasses
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'OnlineClasses')
BEGIN
    CREATE TABLE OnlineClasses (
        OnlineClassID   INT             IDENTITY(1,1) PRIMARY KEY,
        SubjectID       INT             NOT NULL,
        ClassID         INT             NOT NULL,
        TeacherID       INT             NOT NULL,
        Title           NVARCHAR(255)   NOT NULL,
        Description     NVARCHAR(500),
        MeetingLink     NVARCHAR(500),
        ScheduledAt     DATETIME,
        Duration        INT,            -- minutes
        IsRecorded      BIT             DEFAULT 0,
        RecordingURL    NVARCHAR(500),
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (SubjectID)  REFERENCES Subjects(SubjectID),
        FOREIGN KEY (ClassID)    REFERENCES Classes(ClassID),
        FOREIGN KEY (TeacherID)  REFERENCES Users(UserID)
    );
    PRINT 'Created: OnlineClasses';
END
ELSE PRINT 'Exists:  OnlineClasses';
GO

-- ===================================================================
-- TABLE 15: FeeStructure
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'FeeStructure')
BEGIN
    CREATE TABLE FeeStructure (
        FeeStructureID  INT             IDENTITY(1,1) PRIMARY KEY,
        DepartmentID    INT             NOT NULL,
        Semester        INT             NOT NULL,
        AcademicYear    NVARCHAR(20),
        TuitionFee      DECIMAL(10,2)   DEFAULT 0,
        LibraryFee      DECIMAL(10,2)   DEFAULT 0,
        LabFee          DECIMAL(10,2)   DEFAULT 0,
        SportsFee       DECIMAL(10,2)   DEFAULT 0,
        OtherFees       DECIMAL(10,2)   DEFAULT 0,
        TotalFee        AS (TuitionFee + LibraryFee + LabFee + SportsFee + OtherFees) PERSISTED,
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
    );
    PRINT 'Created: FeeStructure';
END
ELSE PRINT 'Exists:  FeeStructure';
GO

-- ===================================================================
-- TABLE 16: FeePayments
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'FeePayments')
BEGIN
    CREATE TABLE FeePayments (
        PaymentID       INT             IDENTITY(1,1) PRIMARY KEY,
        StudentID       INT             NOT NULL,
        FeeStructureID  INT             NOT NULL,
        AmountPaid      DECIMAL(10,2)   NOT NULL,
        PaymentDate     DATETIME        DEFAULT GETDATE(),
        PaymentMode     NVARCHAR(50),   -- UPI, Net Banking, Card, Cash, Cheque
        TransactionID   NVARCHAR(100),
        ReceiptNumber   NVARCHAR(100),
        Remarks         NVARCHAR(255),
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (StudentID)      REFERENCES Users(UserID),
        FOREIGN KEY (FeeStructureID) REFERENCES FeeStructure(FeeStructureID)
    );
    PRINT 'Created: FeePayments';
END
ELSE PRINT 'Exists:  FeePayments';
GO

-- ===================================================================
-- TABLE 17: StudentCounts  (summary counts per dept/semester)
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StudentCounts')
BEGIN
    CREATE TABLE StudentCounts (
        StudentCountID  INT             IDENTITY(1,1) PRIMARY KEY,
        DepartmentID    INT             NOT NULL,
        Semester        INT             NOT NULL,
        StudentCount    INT             NOT NULL DEFAULT 0,
        AcademicYear    NVARCHAR(20),
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
    );
    PRINT 'Created: StudentCounts';
END
ELSE PRINT 'Exists:  StudentCounts';
GO

-- ===================================================================
-- TABLE 18: ActivityLogs
-- ===================================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ActivityLogs')
BEGIN
    CREATE TABLE ActivityLogs (
        LogID           INT             IDENTITY(1,1) PRIMARY KEY,
        UserID          INT             NOT NULL,
        Activity        NVARCHAR(100),
        Details         NVARCHAR(500),
        IPAddress       NVARCHAR(50),
        CreatedAt       DATETIME        DEFAULT GETDATE(),
        FOREIGN KEY (UserID) REFERENCES Users(UserID)
    );
    PRINT 'Created: ActivityLogs';
END
ELSE PRINT 'Exists:  ActivityLogs';
GO

-- ===================================================================
-- VERIFICATION
-- ===================================================================
PRINT '';
PRINT '========================================';
PRINT 'SCHEMA CREATION COMPLETE!';
PRINT '========================================';
PRINT '';

SELECT 
    TABLE_NAME,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS c 
     WHERE c.TABLE_NAME = t.TABLE_NAME) AS ColumnCount
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

PRINT '';
PRINT 'NEXT STEP: Run SQLQuery 1.sql to populate data.';
PRINT '========================================';
GO