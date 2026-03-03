-- ================================================================
-- UNIVERSITY ERP — COMPLETE DATABASE (SCHEMA-CORRECT)
-- Based on Active.sql actual schema:
--   All users in Users table (Admin/Teacher/Student)
--   Classes table (one per dept x semester)
--   TeacherSubjects: TeacherID->Users, SubjectID, ClassID->Classes
--   StudentEnrollments: StudentID->Users, ClassID, SubjectID
--   Timetable: ClassID->Classes, SubjectID, TeacherID->Users
--
-- CREDENTIALS:
--   Admin  : admin@university.edu / admin@123
--   Teacher: email / teacher{N}@123  (N = 1 to 50)
--   Student: email / {RollNumber}@student123
-- ================================================================

USE UniversityERP;
GO

-- ================================================================
-- STEP 0: Cleanup in FK-safe order
-- ================================================================
IF OBJECT_ID('ExamSubmissions') IS NOT NULL ALTER TABLE ExamSubmissions NOCHECK CONSTRAINT ALL;
IF OBJECT_ID('Attendance') IS NOT NULL ALTER TABLE Attendance NOCHECK CONSTRAINT ALL;
IF OBJECT_ID('QRCodes') IS NOT NULL ALTER TABLE QRCodes NOCHECK CONSTRAINT ALL;
IF OBJECT_ID('Marks') IS NOT NULL ALTER TABLE Marks NOCHECK CONSTRAINT ALL;
IF OBJECT_ID('StudentEnrollments') IS NOT NULL ALTER TABLE StudentEnrollments NOCHECK CONSTRAINT ALL;
IF OBJECT_ID('TeacherSubjects') IS NOT NULL ALTER TABLE TeacherSubjects NOCHECK CONSTRAINT ALL;
IF OBJECT_ID('ExamQuestions') IS NOT NULL ALTER TABLE ExamQuestions NOCHECK CONSTRAINT ALL;
IF OBJECT_ID('Exams') IS NOT NULL ALTER TABLE Exams NOCHECK CONSTRAINT ALL;
IF OBJECT_ID('StudyMaterials') IS NOT NULL ALTER TABLE StudyMaterials NOCHECK CONSTRAINT ALL;
IF OBJECT_ID('OnlineClasses') IS NOT NULL ALTER TABLE OnlineClasses NOCHECK CONSTRAINT ALL;
IF OBJECT_ID('Timetable') IS NOT NULL ALTER TABLE Timetable NOCHECK CONSTRAINT ALL;
GO
IF OBJECT_ID('ExamSubmissions') IS NOT NULL DELETE FROM ExamSubmissions;
IF OBJECT_ID('Attendance') IS NOT NULL DELETE FROM Attendance;
IF OBJECT_ID('QRCodes') IS NOT NULL DELETE FROM QRCodes;
IF OBJECT_ID('Marks') IS NOT NULL DELETE FROM Marks;
IF OBJECT_ID('StudentEnrollments') IS NOT NULL DELETE FROM StudentEnrollments;
IF OBJECT_ID('ExamQuestions') IS NOT NULL DELETE FROM ExamQuestions;
IF OBJECT_ID('Exams') IS NOT NULL DELETE FROM Exams;
IF OBJECT_ID('StudyMaterials') IS NOT NULL DELETE FROM StudyMaterials;
IF OBJECT_ID('OnlineClasses') IS NOT NULL DELETE FROM OnlineClasses;
IF OBJECT_ID('TeacherSubjects') IS NOT NULL DELETE FROM TeacherSubjects;
IF OBJECT_ID('Timetable') IS NOT NULL DELETE FROM Timetable;
IF OBJECT_ID('Classes') IS NOT NULL DELETE FROM Classes;
IF OBJECT_ID('Subjects') IS NOT NULL DELETE FROM Subjects;
IF OBJECT_ID('FeePayments') IS NOT NULL DELETE FROM FeePayments;
IF OBJECT_ID('ActivityLogs') IS NOT NULL DELETE FROM ActivityLogs;
DELETE FROM Users WHERE UserType IN ('Admin','Teacher','Student');
GO

-- ================================================================
-- STEP 1: Departments (5)
-- ================================================================
IF NOT EXISTS (SELECT 1 FROM Departments WHERE DepartmentID=1)
    INSERT INTO Departments (DepartmentID,DepartmentName,DepartmentCode,TotalSemesters,IsShared,CreatedAt)
    VALUES (1,N'Computer Science & Engineering','CSE',8,0,GETDATE());
ELSE UPDATE Departments SET DepartmentName=N'Computer Science & Engineering',DepartmentCode='CSE' WHERE DepartmentID=1;
IF NOT EXISTS (SELECT 1 FROM Departments WHERE DepartmentID=2)
    INSERT INTO Departments (DepartmentID,DepartmentName,DepartmentCode,TotalSemesters,IsShared,CreatedAt)
    VALUES (2,N'Electronics & Communication Engineering','ECE',8,0,GETDATE());
ELSE UPDATE Departments SET DepartmentName=N'Electronics & Communication Engineering',DepartmentCode='ECE' WHERE DepartmentID=2;
IF NOT EXISTS (SELECT 1 FROM Departments WHERE DepartmentID=3)
    INSERT INTO Departments (DepartmentID,DepartmentName,DepartmentCode,TotalSemesters,IsShared,CreatedAt)
    VALUES (3,N'Electrical & Electronics Engineering','EEE',8,0,GETDATE());
ELSE UPDATE Departments SET DepartmentName=N'Electrical & Electronics Engineering',DepartmentCode='EEE' WHERE DepartmentID=3;
IF NOT EXISTS (SELECT 1 FROM Departments WHERE DepartmentID=4)
    INSERT INTO Departments (DepartmentID,DepartmentName,DepartmentCode,TotalSemesters,IsShared,CreatedAt)
    VALUES (4,N'Mechanical Engineering','MECH',8,0,GETDATE());
ELSE UPDATE Departments SET DepartmentName=N'Mechanical Engineering',DepartmentCode='MECH' WHERE DepartmentID=4;
IF NOT EXISTS (SELECT 1 FROM Departments WHERE DepartmentID=5)
    INSERT INTO Departments (DepartmentID,DepartmentName,DepartmentCode,TotalSemesters,IsShared,CreatedAt)
    VALUES (5,N'Civil Engineering','CIVIL',8,0,GETDATE());
ELSE UPDATE Departments SET DepartmentName=N'Civil Engineering',DepartmentCode='CIVIL' WHERE DepartmentID=5;
GO

-- ================================================================
-- STEP 2: Admin users
--   Admin 1: admin@university.edu  |  Password: admin@123
--   Admin 2: admin2@university.edu |  Password: admin2@123
-- ================================================================
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Admin','ADMIN001',N'System Administrator','admin@university.edu','9000000001','7676aaafb027c825bd9abab78b234070e702752f625b752e55e55b48e607e358',1,'Male','1980-05-15',N'Ramesh Sharma',N'Sunita Sharma',1,1,'2020-01-01',GETDATE(),GETDATE());

INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Admin','ADMIN002',N'Deputy Administrator','admin2@university.edu','9000000002','a3f5c2e8b1d4e9f7c6a2b8d3e5f1c9a7b2d6e8f4c1a5b9d3e7f2c8a4b6d1e9f5',1,'Female','1985-09-22',N'Vijay Mehta',N'Kamla Mehta',1,1,'2021-06-01',GETDATE(),GETDATE());
GO

-- ================================================================
-- STEP 3: Teacher Users (50)
-- ================================================================
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID001',N'Dr. Rajesh Kumar','rajesh.kumar@university.edu','9876543211','8305f9e6e4705387c7beec34a6c658e040355ef19dd3f0718f36863758fa4b29',1,'Male','1975-03-12',N'Suresh Kumar',N'Lakshmi Kumar',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID002',N'Dr. Priya Sharma','priya.sharma@university.edu','9876543212','48f4a39f1d4aff8bf4f24fc80660b2a4d426fa0049241b7149f6b289a7328b16',1,'Female','1978-07-25',N'Ramesh Sharma',N'Geeta Sharma',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID003',N'Dr. Amit Patel','amit.patel@university.edu','9876543213','e5d7e1ccdaa5a948319745e7279d06f1d724284eb64b86d4092187869ce3bbb8',1,'Male','1980-11-08',N'Mahesh Patel',N'Asha Patel',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID004',N'Dr. Sneha Reddy','sneha.reddy@university.edu','9876543214','7d87dcdae1b958069da4568037d364108a0be1390cc5d51fd38b940c4b2f9c17',1,'Female','1976-04-19',N'Kishan Reddy',N'Savitri Reddy',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID005',N'Dr. Vikram Singh','vikram.singh@university.edu','9876543215','9f8785b49cd39846a965b0c82ae2c8b1523e6e232bb32f8411ca7f587e3af0e3',1,'Male','1979-09-30',N'Balram Singh',N'Usha Singh',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID006',N'Dr. Anjali Gupta','anjali.gupta@university.edu','9876543216','d09e0aced65485f2eb56b29e4c15c73151003b403d6e76101d8f5864c599a9f8',1,'Female','1982-01-14',N'Mohan Gupta',N'Radha Gupta',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID007',N'Dr. Rahul Verma','rahul.verma@university.edu','9876543217','b797b7fbca3df52c5586c9cdc40085f7da82578186cdcdfbaf66d096a31832f3',1,'Male','1977-06-22',N'Arun Verma',N'Sita Verma',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID008',N'Dr. Kavita Nair','kavita.nair@university.edu','9876543218','de8aef994a29fc770d4048f3c736badc0e6a6280e34f7392364ea368fa4b6bca',1,'Female','1981-12-05',N'Gopalan Nair',N'Meenakshi Nair',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID009',N'Dr. Suresh Kumar','suresh.kumar@university.edu','9876543219','b5c237301d88afd6500b253d568258dbfd9d54296935edbe2cc27683f9275140',1,'Male','1974-08-17',N'Raju Kumar',N'Shanti Kumar',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID010',N'Dr. Meera Iyer','meera.iyer@university.edu','9876543220','26e9c760a0fd2afec671c25c62d55980281d1c51bad4651610d218db8a79da4c',1,'Female','1983-02-28',N'Krishnan Iyer',N'Parvati Iyer',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID011',N'Dr. Sanjay Das','sanjay.das@university.edu','9876543221','337a4887b3d118b4ff210bd4e9e6fcd3729a5bb97168b8659ba8672a30a5c7c3',2,'Male','1978-10-10',N'Tapan Das',N'Malati Das',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID012',N'Dr. Pooja Malhotra','pooja.malhotra@university.edu','9876543222','555a6ba361b2f1f770e9b2b5976fb21fd2af46f7e963fc8ad3c42bd9dd4f84a8',2,'Female','1980-05-03',N'Ramesh Malhotra',N'Sheela Malhotra',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID013',N'Dr. Karthik Rao','karthik.rao@university.edu','9876543223','58606a477a628062eb4ca1a63efc7d2239585724c0869c8d5cabd13522f0ba2c',2,'Male','1975-07-16',N'Venkat Rao',N'Saraswati Rao',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID014',N'Dr. Divya Krishnan','divya.krishnan@university.edu','9876543224','cf3dab35a3f6a2da08cb1f75c1a1778eccd9bb8a6339e6c5d2a348aed38b5ebc',2,'Female','1982-03-27',N'Subramaniam Krishnan',N'Kamakshi Krishnan',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID015',N'Dr. Arjun Pillai','arjun.pillai@university.edu','9876543225','5f88938d3ad328b47e9502e295a2c3a78a12f48fb1656c9d489b792998bd2204',2,'Male','1977-11-09',N'Gopal Pillai',N'Radhamani Pillai',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID016',N'Dr. Nisha Agarwal','nisha.agarwal@university.edu','9876543226','c150a0fae14fd7c3ad2e7d2335b7c2c7b27d69e86117a24607d4d5029b0e825d',2,'Female','1979-06-21',N'Dinesh Agarwal',N'Pushpa Agarwal',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID017',N'Dr. Prakash Joshi','prakash.joshi@university.edu','9876543227','7d5f9e1413689a269d2684d83afd9612a94729bec647ec84cf4fd29a224cbb74',2,'Male','1976-01-13',N'Madhukar Joshi',N'Vasudha Joshi',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID018',N'Dr. Lakshmi Bhat','lakshmi.bhat@university.edu','9876543228','3e48c2341fe516864b92c8de94b6469501fbe7e2daf376068b4970b44bc8e154',2,'Female','1984-09-04',N'Ramachandra Bhat',N'Indira Bhat',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID019',N'Dr. Manoj Desai','manoj.desai@university.edu','9876543229','3a6a323a96fe22d2943220b33b93101765aa5d8d5b51764d2496063c0180a485',2,'Male','1978-04-18',N'Hasmukh Desai',N'Kokila Desai',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID020',N'Dr. Rashmi Sinha','rashmi.sinha@university.edu','9876543230','74af0c8ee211f100c24ee5e7ce60f0140bef0d05d563e2c597bd1aaec6e32c1b',2,'Female','1981-12-29',N'Rajendra Sinha',N'Mridula Sinha',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID021',N'Dr. Deepak Bhatt','deepak.bhatt@university.edu','9876543231','b0abc1a4fdae25a133b8093c703b3fd3200b80ba7f02d3b2ea101ebcbc80af43',3,'Male','1975-08-11',N'Narayan Bhatt',N'Draupadi Bhatt',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID022',N'Dr. Sunita Chopra','sunita.chopra@university.edu','9876543232','9174a0720c48433429a3c616f6f2c9bf70b985e3c652e11d7d3daca992ed1217',3,'Female','1980-02-24',N'Ramesh Chopra',N'Sarla Chopra',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID023',N'Dr. Ashok Pandey','ashok.pandey@university.edu','9876543233','4f80ec465fac48f3508ff60496b73803f99c29cb008b6dc842cdb4bf04c4807d',3,'Male','1977-06-07',N'Shiv Pandey',N'Kaushalya Pandey',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID024',N'Dr. Ritu Saxena','ritu.saxena@university.edu','9876543234','4abf223defe016a6003a4f74a987dcf9568e757a7c0cecfbdfd48fdfc8cdc2b2',3,'Female','1983-10-19',N'Arvind Saxena',N'Nirmala Saxena',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID025',N'Dr. Naveen Kapoor','naveen.kapoor@university.edu','9876543235','d645e01a54ad901e3fb27ab0aa6cc344808582310227905e2087c82fd4b40717',3,'Male','1979-03-31',N'Rajeev Kapoor',N'Sudha Kapoor',1,1,'2010-07-01',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID026',N'Dr. Smita Deshmukh','smita.deshmukh@university.edu','9876543236','7b6eb0fd36bbdf4f7c596d07c2d389678c5394b1773235e6fd382b6780acab55',3,'Female','1976-07-14',N'Vitthal Deshmukh',N'Ratnamala Deshmukh',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID027',N'Dr. Gaurav Mehta','gaurav.mehta@university.edu','9876543237','c045762c893f4255e244719b9a306ffb199098f4f0ca89a0b9297284b65bfbd8',3,'Male','1981-11-26',N'Rajesh Mehta',N'Hema Mehta',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID028',N'Dr. Preeti Jain','preeti.jain@university.edu','9876543238','9190ca098027def89a1a78b5bd5da90561a9aee69834b4eae0d97b8837f16eb6',3,'Female','1978-05-09',N'Suresh Jain',N'Sudha Jain',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID029',N'Dr. Sandeep Yadav','sandeep.yadav@university.edu','9876543239','edbf0ded8fdd0247eb84739ae7d217771d7eb6ce957b3e551089771ac96dceeb',3,'Male','1980-09-20',N'Dharampal Yadav',N'Savitri Yadav',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID030',N'Dr. Usha Bansal','usha.bansal@university.edu','9876543240','8e4deeca9303694795b2d2e15d5813f67b80c05f95c09101e84e234f945d046f',3,'Female','1974-01-02',N'Kishan Bansal',N'Kamlesh Bansal',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID031',N'Dr. Harish Thakur','harish.thakur@university.edu','9876543241','6b6136b56733f982e684505cc986acbbb3e84567bb7d79f8dc1175272ec7431d',4,'Male','1977-04-15',N'Bhushan Thakur',N'Vimla Thakur',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID032',N'Dr. Radha Ramesh','radha.ramesh@university.edu','9876543242','ebcc9b3197ba02ea7772d5df73c8b6f452afa5febb13f606e6ee7584081c1a6f',4,'Female','1982-08-27',N'Ramkumar Ramesh',N'Radhabai Ramesh',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID033',N'Dr. Mohan Lal','mohan.lal@university.edu','9876543243','f84a6f31b16ade7ff27d3162bf1547cda5b33896905712b58c744f1b5552b871',4,'Male','1975-12-10',N'Jagdish Lal',N'Parbati Lal',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID034',N'Dr. Gayatri Kulkarni','gayatri.kulkarni@university.edu','9876543244','ef06b8b39b13c6e241905f2f768b899d7f941e7bcb7b75929d6d26ec077ed4f7',4,'Female','1979-03-22',N'Anant Kulkarni',N'Sharada Kulkarni',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID035',N'Dr. Ramesh Naidu','ramesh.naidu@university.edu','9876543245','4e082eaf6c3cef98f5a865112e56b6855ad71754ba956285fdfe17df27d8b4e4',4,'Male','1976-07-04',N'Venkataramaiah Naidu',N'Annapurna Naidu',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID036',N'Dr. Neha Mishra','neha.mishra@university.edu','9876543246','23bfbeaa8ae02fa77549118f45d305efad63d8e7f03a99da0aa15c3e3c9e7fd3',4,'Female','1983-11-16',N'Sureshwar Mishra',N'Saroj Mishra',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID037',N'Dr. Vishal Trivedi','vishal.trivedi@university.edu','9876543247','7d1cf08333337537a9e776b97a7fcadee59c4df15320e72b9aaa0e8778cac7a5',4,'Male','1978-02-28',N'Harilal Trivedi',N'Sharda Trivedi',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID038',N'Dr. Shweta Ghosh','shweta.ghosh@university.edu','9876543248','3e56d8eacec176bbeb044dc739cab45d5396f0b1a6cfa64340c8a73bfa9133f5',4,'Female','1981-06-10',N'Sukumar Ghosh',N'Malati Ghosh',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID039',N'Dr. Anil Shetty','anil.shetty@university.edu','9876543249','dae86f15504bbf8a2722af558e1610a072a95ca4435f08dc9cdb34132b11e1ef',4,'Male','1980-10-22',N'Venkatesh Shetty',N'Shakuntala Shetty',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID040',N'Dr. Vaishali Patil','vaishali.patil@university.edu','9876543250','542fc9d334b91409c5d3db214b4e2e48e075151963d09093c3f5b6bddce567f8',4,'Female','1977-04-05',N'Shankar Patil',N'Vandana Patil',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID041',N'Dr. Vinod Khanna','vinod.khanna@university.edu','9876543251','b3995f7db03758247e9649de34f801791e9b89a5a5f343a8db8bee9165ca313f',5,'Male','1975-08-17',N'Satpal Khanna',N'Sneh Khanna',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID042',N'Dr. Leela Madhavan','leela.madhavan@university.edu','9876543252','14ba3a695348d51e0b3cc58870ad68d853d53cfd27f64b5999c40b32fbf77fca',5,'Female','1982-12-29',N'Kesavan Madhavan',N'Sarojini Madhavan',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID043',N'Dr. Ajay Rane','ajay.rane@university.edu','9876543253','a1e7b9b5338806acfb0cf60f7d94d651b748635c17c2f0fdaec5f747cd0f936b',5,'Male','1979-05-11',N'Vishwanath Rane',N'Sulochana Rane',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID044',N'Dr. Swati Venkatesh','swati.venkatesh@university.edu','9876543254','38d3b5815873462b9362490cba1d7d60a0ad368cd405109418b90ddef98db20d',5,'Female','1976-09-23',N'Ramakrishna Venkatesh',N'Ambujam Venkatesh',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID045',N'Dr. Mukesh Tandon','mukesh.tandon@university.edu','9876543255','761c20b5ab5e5055633495fe295cc1e3be78eef8c3f646850372d79504f9be67',5,'Male','1980-01-05',N'Rameshwar Tandon',N'Pushpa Tandon',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID046',N'Dr. Poonam Rathi','poonam.rathi@university.edu','9876543256','22fb9c8e02657135ddba675bfddfc66831de61aa236f01048b46b1716b309eec',5,'Female','1983-04-18',N'Suraj Rathi',N'Sunita Rathi',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID047',N'Dr. Anand Jha','anand.jha@university.edu','9876543257','f40447fd6b9a39f5b81e757a5b37ef7dbba36c3a60d08842995613fe725b5944',5,'Male','1977-08-30',N'Vidyanath Jha',N'Sita Jha',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID048',N'Dr. Savita Mathur','savita.mathur@university.edu','9876543258','37d16aabb7a94e6ef1d2e9d75523515782c5b5e6cc207138894ab9d919af818f',5,'Female','1981-12-12',N'Radheshyam Mathur',N'Shakuntala Mathur',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID049',N'Dr. Tarun Malhotra','tarun.malhotra@university.edu','9876543259','e174721bc4030cb514ec5f27973cf202e36251b6fc88c757c31aa0324fb28f50',5,'Male','1978-03-24',N'Ramesh Malhotra',N'Pushpa Malhotra',1,1,'2010-07-01',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Teacher','TID050',N'Dr. Rekha Pillai','rekha.pillai@university.edu','9876543260','5c5d2d22ba9975d780547dfe6a467b38dee820231e308d20437d673aa45af2b6',5,'Female','1975-07-06',N'Narayanan Pillai',N'Thankamani Pillai',1,1,'2010-07-01',GETDATE(),GETDATE());
GO
GO

-- ================================================================
-- STEP 4: Subjects (160) — SubjectID is a regular NOT NULL column, explicit values provided
-- ================================================================
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE101')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (1,N'Programming in C','CSE101',4,1,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE102')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (2,N'Mathematics I','CSE102',4,1,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE103')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (3,N'Engineering Physics','CSE103',4,1,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE104')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (4,N'Digital Logic Design','CSE104',4,1,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE105')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (5,N'Computer Fundamentals','CSE105',4,1,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE106L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (6,N'C Programming Lab','CSE106L',2,1,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE107L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (7,N'Physics Lab','CSE107L',2,1,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE108L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (8,N'Digital Logic Lab','CSE108L',2,1,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE301')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (9,N'Data Structures','CSE301',4,1,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE302')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (10,N'Discrete Mathematics','CSE302',4,1,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE303')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (11,N'Computer Architecture','CSE303',4,1,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE304')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (12,N'Object Oriented Programming','CSE304',4,1,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE305')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (13,N'Database Management Systems','CSE305',4,1,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE306L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (14,N'Data Structures Lab','CSE306L',2,1,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE307L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (15,N'OOP Lab','CSE307L',2,1,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE308L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (16,N'DBMS Lab','CSE308L',2,1,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE501')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (17,N'Operating Systems','CSE501',4,1,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE502')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (18,N'Computer Networks','CSE502',4,1,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE503')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (19,N'Software Engineering','CSE503',4,1,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE504')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (20,N'Theory of Computation','CSE504',4,1,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE505')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (21,N'Web Technologies','CSE505',4,1,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE506L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (22,N'OS Lab','CSE506L',2,1,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE507L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (23,N'Networks Lab','CSE507L',2,1,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE508L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (24,N'Web Tech Lab','CSE508L',2,1,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE701')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (25,N'Machine Learning','CSE701',4,1,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE702')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (26,N'Cloud Computing','CSE702',4,1,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE703')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (27,N'Cryptography & Security','CSE703',4,1,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE704')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (28,N'Data Mining','CSE704',4,1,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE705')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (29,N'Artificial Intelligence','CSE705',4,1,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE706L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (30,N'ML Lab','CSE706L',2,1,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE707L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (31,N'Project Work','CSE707L',4,1,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CSE708L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (32,N'Seminar','CSE708L',2,1,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE101')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (33,N'Electronic Devices','ECE101',4,2,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE102')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (34,N'Circuit Analysis','ECE102',4,2,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE103')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (35,N'Engineering Mathematics','ECE103',4,2,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE104')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (36,N'Digital Electronics','ECE104',4,2,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE105')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (37,N'Signals & Systems','ECE105',4,2,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE106L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (38,N'Electronics Lab','ECE106L',2,2,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE107L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (39,N'Digital Lab','ECE107L',2,2,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE108L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (40,N'Workshop','ECE108L',2,2,1,GETDATE());
GO
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE301')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (41,N'Analog Circuits','ECE301',4,2,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE302')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (42,N'Electromagnetic Theory','ECE302',4,2,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE303')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (43,N'Communication Systems','ECE303',4,2,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE304')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (44,N'Microprocessors','ECE304',4,2,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE305')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (45,N'Control Systems','ECE305',4,2,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE306L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (46,N'Analog Lab','ECE306L',2,2,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE307L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (47,N'Microprocessor Lab','ECE307L',2,2,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE308L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (48,N'Communication Lab','ECE308L',2,2,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE501')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (49,N'VLSI Design','ECE501',4,2,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE502')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (50,N'Digital Signal Processing','ECE502',4,2,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE503')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (51,N'Wireless Communication','ECE503',4,2,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE504')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (52,N'Embedded Systems','ECE504',4,2,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE505')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (53,N'RF & Microwave','ECE505',4,2,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE506L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (54,N'VLSI Lab','ECE506L',2,2,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE507L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (55,N'DSP Lab','ECE507L',2,2,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE508L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (56,N'Embedded Lab','ECE508L',2,2,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE701')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (57,N'IoT Systems','ECE701',4,2,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE702')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (58,N'5G Technology','ECE702',4,2,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE703')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (59,N'Image Processing','ECE703',4,2,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE704')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (60,N'Radar & Navigation','ECE704',4,2,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE705')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (61,N'Optical Fiber Comm.','ECE705',4,2,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE706L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (62,N'IoT Lab','ECE706L',2,2,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE707L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (63,N'Project Work','ECE707L',4,2,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ECE708L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (64,N'Seminar','ECE708L',2,2,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE101')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (65,N'Electrical Circuits','EEE101',4,3,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE102')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (66,N'Engineering Mathematics I','EEE102',4,3,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE103')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (67,N'Engineering Physics','EEE103',4,3,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE104')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (68,N'Basic Electronics','EEE104',4,3,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE105')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (69,N'Engineering Drawing','EEE105',4,3,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE106L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (70,N'Circuits Lab','EEE106L',2,3,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE107L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (71,N'Physics Lab','EEE107L',2,3,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE108L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (72,N'Workshop Practice','EEE108L',2,3,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE301')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (73,N'Network Analysis','EEE301',4,3,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE302')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (74,N'Electronic Devices','EEE302',4,3,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE303')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (75,N'Signals & Systems','EEE303',4,3,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE304')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (76,N'Digital Electronics','EEE304',4,3,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE305')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (77,N'Electromagnetic Theory','EEE305',4,3,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE306L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (78,N'Network Lab','EEE306L',2,3,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE307L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (79,N'Digital Electronics Lab','EEE307L',2,3,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE308L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (80,N'Signals Lab','EEE308L',2,3,3,GETDATE());
GO
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE501')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (81,N'Power Systems','EEE501',4,3,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE502')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (82,N'Control Systems','EEE502',4,3,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE503')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (83,N'Electric Machines I','EEE503',4,3,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE504')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (84,N'Power Electronics','EEE504',4,3,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE505')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (85,N'Microcontrollers','EEE505',4,3,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE506L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (86,N'Power Systems Lab','EEE506L',2,3,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE507L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (87,N'Control Lab','EEE507L',2,3,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE508L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (88,N'Power Electronics Lab','EEE508L',2,3,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE701')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (89,N'Energy Management','EEE701',4,3,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE702')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (90,N'Renewable Energy Systems','EEE702',4,3,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE703')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (91,N'Smart Grid Technology','EEE703',4,3,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE704')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (92,N'High Voltage Engineering','EEE704',4,3,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE705')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (93,N'Industrial Drives','EEE705',4,3,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE706L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (94,N'Energy Lab','EEE706L',2,3,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE707L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (95,N'Project Work','EEE707L',4,3,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='EEE708L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (96,N'Seminar','EEE708L',2,3,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME101')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (97,N'Engineering Mechanics','ME101',4,4,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME102')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (98,N'Engineering Mathematics I','ME102',4,4,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME103')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (99,N'Engineering Physics','ME103',4,4,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME104')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (100,N'Basic Thermodynamics','ME104',4,4,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME105')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (101,N'Engineering Drawing','ME105',4,4,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME106L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (102,N'Mechanics Lab','ME106L',2,4,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME107L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (103,N'Physics Lab','ME107L',2,4,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME108L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (104,N'Workshop Practice','ME108L',2,4,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME301')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (105,N'Strength of Materials','ME301',4,4,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME302')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (106,N'Fluid Mechanics','ME302',4,4,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME303')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (107,N'Manufacturing Processes','ME303',4,4,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME304')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (108,N'Kinematics of Machinery','ME304',4,4,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME305')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (109,N'Material Science','ME305',4,4,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME306L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (110,N'Strength of Materials Lab','ME306L',2,4,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME307L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (111,N'Fluid Mechanics Lab','ME307L',2,4,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME308L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (112,N'Manufacturing Lab','ME308L',2,4,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME501')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (113,N'Heat Transfer','ME501',4,4,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME502')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (114,N'Machine Design','ME502',4,4,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME503')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (115,N'Industrial Engineering','ME503',4,4,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME504')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (116,N'Dynamics of Machinery','ME504',4,4,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME505')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (117,N'CAD/CAM','ME505',4,4,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME506L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (118,N'Heat Transfer Lab','ME506L',2,4,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME507L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (119,N'Machine Design Lab','ME507L',2,4,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME508L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (120,N'CAD/CAM Lab','ME508L',2,4,5,GETDATE());
GO
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME701')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (121,N'Automobile Engineering','ME701',4,4,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME702')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (122,N'Robotics & Automation','ME702',4,4,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME703')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (123,N'Finite Element Analysis','ME703',4,4,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME704')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (124,N'Refrigeration & AC','ME704',4,4,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME705')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (125,N'Project Management','ME705',4,4,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME706L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (126,N'Automobile Lab','ME706L',2,4,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME707L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (127,N'Project Work','ME707L',4,4,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='ME708L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (128,N'Seminar','ME708L',2,4,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE101')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (129,N'Engineering Mechanics','CE101',4,5,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE102')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (130,N'Engineering Mathematics I','CE102',4,5,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE103')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (131,N'Engineering Physics','CE103',4,5,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE104')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (132,N'Basic Civil Engineering','CE104',4,5,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE105')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (133,N'Engineering Drawing','CE105',4,5,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE106L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (134,N'Surveying Lab','CE106L',2,5,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE107L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (135,N'Physics Lab','CE107L',2,5,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE108L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (136,N'Workshop Practice','CE108L',2,5,1,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE301')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (137,N'Strength of Materials','CE301',4,5,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE302')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (138,N'Fluid Mechanics','CE302',4,5,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE303')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (139,N'Building Materials','CE303',4,5,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE304')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (140,N'Surveying','CE304',4,5,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE305')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (141,N'Structural Analysis I','CE305',4,5,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE306L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (142,N'Strength of Materials Lab','CE306L',2,5,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE307L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (143,N'Fluid Mechanics Lab','CE307L',2,5,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE308L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (144,N'Surveying Lab','CE308L',2,5,3,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE501')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (145,N'Structural Analysis II','CE501',4,5,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE502')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (146,N'Geotechnical Engineering','CE502',4,5,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE503')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (147,N'Transportation Engineering','CE503',4,5,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE504')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (148,N'Water Resources Engineering','CE504',4,5,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE505')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (149,N'Design of RC Structures','CE505',4,5,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE506L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (150,N'Geotechnical Lab','CE506L',2,5,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE507L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (151,N'Transportation Lab','CE507L',2,5,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE508L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (152,N'Concrete Lab','CE508L',2,5,5,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE701')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (153,N'Environmental Engineering','CE701',4,5,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE702')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (154,N'Construction Management','CE702',4,5,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE703')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (155,N'Smart Infrastructure','CE703',4,5,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE704')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (156,N'Prestressed Concrete','CE704',4,5,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE705')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (157,N'Urban Planning','CE705',4,5,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE706L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (158,N'Environmental Lab','CE706L',2,5,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE707L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (159,N'Project Work','CE707L',4,5,7,GETDATE());
IF NOT EXISTS (SELECT 1 FROM Subjects WHERE SubjectCode='CE708L')
    INSERT INTO Subjects (SubjectID,SubjectName,SubjectCode,Credits,DepartmentID,Semester,CreatedAt)
    VALUES (160,N'Seminar','CE708L',2,5,7,GETDATE());
GO
GO

-- ================================================================

-- STEP 5: Classes (20 = 5 depts × 4 semesters)
-- ================================================================
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=1 AND Semester=1 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'CSE Semester 1',1,1,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=1 AND Semester=3 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'CSE Semester 3',1,3,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=1 AND Semester=5 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'CSE Semester 5',1,5,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=1 AND Semester=7 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'CSE Semester 7',1,7,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=2 AND Semester=1 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'ECE Semester 1',2,1,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=2 AND Semester=3 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'ECE Semester 3',2,3,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=2 AND Semester=5 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'ECE Semester 5',2,5,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=2 AND Semester=7 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'ECE Semester 7',2,7,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=3 AND Semester=1 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'EEE Semester 1',3,1,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=3 AND Semester=3 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'EEE Semester 3',3,3,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=3 AND Semester=5 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'EEE Semester 5',3,5,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=3 AND Semester=7 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'EEE Semester 7',3,7,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=4 AND Semester=1 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'MECH Semester 1',4,1,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=4 AND Semester=3 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'MECH Semester 3',4,3,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=4 AND Semester=5 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'MECH Semester 5',4,5,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=4 AND Semester=7 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'MECH Semester 7',4,7,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=5 AND Semester=1 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'CIVIL Semester 1',5,1,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=5 AND Semester=3 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'CIVIL Semester 3',5,3,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=5 AND Semester=5 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'CIVIL Semester 5',5,5,'A','2024-25',GETDATE());
IF NOT EXISTS (SELECT 1 FROM Classes WHERE DepartmentID=5 AND Semester=7 AND AcademicYear='2024-25')
    INSERT INTO Classes (ClassName,DepartmentID,Semester,Section,AcademicYear,CreatedAt)
    VALUES (N'CIVIL Semester 7',5,7,'A','2024-25',GETDATE());
GO

-- ================================================================
-- STEP 6: Student Users (900)
-- Password: {RollNumber}@student123
-- ================================================================
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1001',N'Mahesh Nair','mahesh1cse1@student.university.edu','9218196001','85a69b159fc07affe2b14ef359dad5594cb8da9b5fbbc17574e6af5ffc353195',1,'Male','2004-04-08',N'Arjun Nair',N'Rashmi Nair',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1002',N'Kamala Kumar','kamala2cse1@student.university.edu','9794026542','9929020608147d6ad377d737f596790f8ffd457f2060877a2c5a1b4a8ece58bc',1,'Female','2006-07-08',N'Vishal Kumar',N'Sneha Kumar',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1003',N'Sai Bhat','sai3cse1@student.university.edu','9078161849','5f3e4bd938f0ef21e5fd166dbc3b4cbd415eeeeb19c5719249faf76d3e06585f',1,'Male','2004-10-09',N'Arnav Bhat',N'Sangeetha Bhat',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1004',N'Sneha Hegde','sneha4cse1@student.university.edu','9316475255','5dc4a43ae1380521555128fb17b279fa5419595fae014e1294ddc050b1a84511',1,'Female','2003-05-03',N'Vihaan Hegde',N'Pari Hegde',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1005',N'Sachin Varma','sachin5cse1@student.university.edu','9648350305','9f9a8221a56af0f676ec3c893febe834592921e96c3db0ec28ae814b78c7fe2b',1,'Male','2003-03-15',N'Kabir Varma',N'Vimala Varma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1006',N'Pooja Bhosale','pooja6cse1@student.university.edu','9767242388','1744549fe90efca525cb5090ac77548fed9c6d400e16aa3f923e8442b48c4571',1,'Female','2004-04-21',N'Naresh Bhosale',N'Nithya Bhosale',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1007',N'Jignesh Khanna','jignesh7cse1@student.university.edu','9710122691','dcf53beb6c0050bdf7d2ae6b6e07f52665c59cb709bdfcdc7e2f94e704de8a81',1,'Male','2003-03-17',N'Varun Khanna',N'Bhavana Khanna',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1008',N'Sruthi Dubey','sruthi8cse1@student.university.edu','9184514627','c3f92d1b8f4b0499aec3cc3a79a062f5a8bf32c026292b9f88831116e9e59e58',1,'Female','2002-11-24',N'Nikhil Dubey',N'Sowmya Dubey',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1009',N'Ramesh Malhotra','ramesh9cse1@student.university.edu','9932528809','cb976f497325f15f4461bf145275839bf7e947c9d99bcdb07da95747e659e68e',1,'Male','2004-11-17',N'Rajesh Malhotra',N'Navya Malhotra',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1010',N'Kiara Naidu','kiara10cse1@student.university.edu','9391171822','7bbada429434664f650d4de82faf06846952d3b8f759ade5ef9ce243c723b2ca',1,'Female','2004-04-02',N'Alpesh Naidu',N'Bhargavi Naidu',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1011',N'Kabir Mehta','kabir11cse1@student.university.edu','9346578713','8cc5eba6668ed4083715ba1040ec04a0a2c1a504bec7103a69552ab1e84c64fd',1,'Male','2005-04-18',N'Naveen Mehta',N'Kamala Mehta',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1012',N'Ananya Khanna','ananya12cse1@student.university.edu','9103105183','6c9a356f50198d29a92f0a2b74ae10cf6e807a3170496f450acef0eb28a8a76e',1,'Female','2006-04-01',N'Vishal Khanna',N'Meena Khanna',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1013',N'Arun Iyer','arun13cse1@student.university.edu','9763116566','7e9247ae611af2e6d41ed6f9c9809367e5ce6f2c30a5b8aeb8764275ed5da8f9',1,'Male','2006-08-08',N'Mohan Iyer',N'Nithya Iyer',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1014',N'Saanvi Kulkarni','saanvi14cse1@student.university.edu','9387262473','02356f4a8026e380037084aac31ea38ea47ce5ab84c7e473ca31b810224338ed',1,'Female','2002-04-07',N'Mohan Kulkarni',N'Reshma Kulkarni',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1015',N'Girish Deshpande','girish15cse1@student.university.edu','9801326773','e8036ac9026ae3f3e114cf4428d3cef93a23a53a784ac27d491b8c0f6093d2b7',1,'Male','2002-01-21',N'Hitesh Deshpande',N'Sowmya Deshpande',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1016',N'Priya Bhat','priya16cse1@student.university.edu','9687234309','d856cd9b9102454a20060e04b47e558dc03eb131b0dd9c5c9fbb3cfd1c0e3bab',1,'Female','2004-08-10',N'Aarav Bhat',N'Usha Bhat',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1017',N'Prakash Pandey','prakash17cse1@student.university.edu','9820812191','fd2136667204e8f372a1f5673b0624b6ea1c2404464ce27456c264911e2d7005',1,'Male','2006-08-17',N'Aditya Pandey',N'Saanvi Pandey',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1018',N'Kiara Kulkarni','kiara18cse1@student.university.edu','9916998543','4ffdca819cbf3a1b28fed74ef686daeed15919c922e882b486266979282a26f3',1,'Female','2006-10-02',N'Gaurav Kulkarni',N'Lakshmi Kulkarni',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1019',N'Nikhil Kulkarni','nikhil19cse1@student.university.edu','9107991183','7424fb13dd424d52700419c888f76bf70dea9109bc475d88f1977e4eb53d51f6',1,'Male','2004-08-11',N'Atharv Kulkarni',N'Shobha Kulkarni',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1020',N'Sangeetha Kulkarni','sangeetha20cse1@student.university.edu','9784980841','af4f0a604c144df5be46d8b05e45f403925ec7b2171db1ee42475e392e18c04c',1,'Female','2004-05-06',N'Vihaan Kulkarni',N'Lakshmi Kulkarni',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1021',N'Dhruv Kulkarni','dhruv21cse1@student.university.edu','9493534874','5d36a617e77616f6bc307f6d52695d119e223d27d717620aa1d370ce43876a2a',1,'Male','2006-03-09',N'Arnav Kulkarni',N'Rashmi Kulkarni',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1022',N'Radha Desai','radha22cse1@student.university.edu','9242786801','621692e602ba59dd1777ec89c2bd002b53b3ce870695f0874355ed0f02fe99ef',1,'Female','2002-01-11',N'Nitesh Desai',N'Sunita Desai',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1023',N'Vivaan More','vivaan23cse1@student.university.edu','9204505331','9f8856d7fc68c05033005ad4cf213cef8e16fe67e278089b32cacd174ecc6418',1,'Male','2006-03-14',N'Anand More',N'Revathi More',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1024',N'Sujatha Gowda','sujatha24cse1@student.university.edu','9025634216','41365252875d683ef415d8006a743075a825b4ab3934967fd500b4006ad2c9d1',1,'Female','2003-03-14',N'Reyansh Gowda',N'Lakshmi Gowda',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1025',N'Yash Rao','yash25cse1@student.university.edu','9330365414','29a04012baf8d342ac59a3d6526666202259d5d00eacec5d573162ee0c4d89df',1,'Male','2004-05-27',N'Yogesh Rao',N'Sruthi Rao',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1026',N'Lalitha More','lalitha26cse1@student.university.edu','9294019655','d227b97f86d12428d864190dd8c90323d37b9654b56fe38aa39162184c01f9fb',1,'Female','2002-02-09',N'Arun More',N'Reshma More',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1027',N'Dhruv Bhat','dhruv27cse1@student.university.edu','9608835615','30ef53cbb187d5102c51d64de7e140af9da047049123c622a7838c9b61dfeee0',1,'Male','2003-05-02',N'Jignesh Bhat',N'Nithya Bhat',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1028',N'Jyothi Kale','jyothi28cse1@student.university.edu','9564823662','355198c7e20a11f6aa2ac1dfcfad0f246ada4fd404e187764987e763a5d00114',1,'Female','2004-11-14',N'Ganesh Kale',N'Smitha Kale',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1029',N'Varun Bhatt','varun29cse1@student.university.edu','9699577738','a3211e66e28e30cc83721423461ebd8a1192c6b8ad37b876afe753dd0299913d',1,'Male','2004-05-07',N'Nitesh Bhatt',N'Aadhya Bhatt',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1030',N'Divya Tiwari','divya30cse1@student.university.edu','9343320037','62bf4afd9e968855ca05a94ef8669f5e7b2096e03a11e441a277b474416cfc6e',1,'Female','2006-06-03',N'Suraj Tiwari',N'Radha Tiwari',1,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1031',N'Akash Kulkarni','akash31cse1@student.university.edu','9676320163','e1b85b126059d9426cd1059d19ecc7b80dbe1b3f7ab7559328bed7426ab41104',1,'Male','2003-12-23',N'Mahesh Kulkarni',N'Nithya Kulkarni',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1032',N'Saanvi Bhatt','saanvi32cse1@student.university.edu','9788957986','974296e283bcad2f4c75bd2f9bdb38e074dd23c4e0eccc85ef8871d0015a3ba4',1,'Female','2005-03-26',N'Rohan Bhatt',N'Kiara Bhatt',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1033',N'Jignesh Das','jignesh33cse1@student.university.edu','9348734714','595c4c013475bd471ad1b5eb549aa841a0c5e76b5f5b370e5a8bcf66111548cd',1,'Male','2005-05-25',N'Prakash Das',N'Varsha Das',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1034',N'Swathi Kale','swathi34cse1@student.university.edu','9623166587','09a9f48eb16f9d4f3098ad4185eab7c5e4ddb185db531c1c5666c7d530885968',1,'Female','2003-03-08',N'Arun Kale',N'Ira Kale',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1035',N'Nitesh Patil','nitesh35cse1@student.university.edu','9967054668','5343a85b2a0033a0bf68f31dc6805e4aadb8f25d2d9df01c4b45b9d8fc586157',1,'Male','2006-12-01',N'Pranav Patil',N'Kavitha Patil',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1036',N'Meena Ghosh','meena36cse1@student.university.edu','9656272980','2f31937c9841f40f9dc68ef37fe90727e57dcf0afc4736a571a71e689c16fc08',1,'Female','2005-08-01',N'Yash Ghosh',N'Sunita Ghosh',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1037',N'Gaurav Rajan','gaurav37cse1@student.university.edu','9720465375','c2c5b50d805260f4c449f381c4eb651a33eef52f496391aa3ff57b9a5cdfa356',1,'Male','2005-03-28',N'Arjun Rajan',N'Ira Rajan',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1038',N'Amrutha More','amrutha38cse1@student.university.edu','9805310033','11c6e426222e20e027c26c9605201ec8765c7c1cff982b3df2a88750f6b67bc1',1,'Female','2002-08-01',N'Akash More',N'Rekha More',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1039',N'Rohan Iyer','rohan39cse1@student.university.edu','9745299124','570bcefa536c9f3e02e025055fcbea39cfdd1b1609eed46d1eee63b8305efb31',1,'Male','2002-10-07',N'Vikram Iyer',N'Shobha Iyer',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1040',N'Nisha Kapoor','nisha40cse1@student.university.edu','9193149190','98081e6868f591bda7dc68e8b94b908d9b52e5027b128d3fb5363eae44866076',1,'Female','2005-12-07',N'Tushar Kapoor',N'Usha Kapoor',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1041',N'Suraj Naidu','suraj41cse1@student.university.edu','9671657262','d730313d8cbcd6eb3cdd24d641bafa677ca65e51bdf87f840e4ca86074c88ac9',1,'Male','2004-01-28',N'Vihaan Naidu',N'Smitha Naidu',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1042',N'Sujatha Pawar','sujatha42cse1@student.university.edu','9945314737','fd75f0771fd0e6935c65a2a656ff68cfb7849d0cc1f172081e41eb2626b3a58a',1,'Female','2005-08-14',N'Paresh Pawar',N'Vimala Pawar',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1043',N'Ravi Kumar','ravi43cse1@student.university.edu','9545494808','359e6895721cb8fc1e321916e63616054cdb50927291de1c2264b45117c52ca7',1,'Male','2003-08-07',N'Sandeep Kumar',N'Swathi Kumar',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1044',N'Lakshmi Shenoy','lakshmi44cse1@student.university.edu','9777014363','062bd1b44efe18157c8f52709cbf77d11b9a2a3573f992d55a61e8478d7ffb99',1,'Female','2006-04-23',N'Akash Shenoy',N'Deepa Shenoy',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20241CSE1045',N'Vikram Bhatt','vikram45cse1@student.university.edu','9557444313','0f8bebe33607dd83e88c3918c512c91293f03bfff86f293ce0a381cebb38a648',1,'Male','2005-12-18',N'Naveen Bhatt',N'Sangeetha Bhatt',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3001',N'Naresh Naik','naresh1cse3@student.university.edu','9749894134','066cde6acf77f187a1dce8876d3525dc80829f6f8a3e992916fdcf80277dd2e9',1,'Male','2003-04-24',N'Vinay Naik',N'Kavya Naik',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3002',N'Nisha Sharma','nisha2cse3@student.university.edu','9084271094','eb4a8c6d7f54b2f318c364ee725a38613e1cdb9192836081e1da673d238ed2c2',1,'Female','2003-05-02',N'Suresh Sharma',N'Vimala Sharma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3003',N'Ravi Malhotra','ravi3cse3@student.university.edu','9167190229','a2cc3ae3ebbe3a88c2aabf8a1b4c1a783d5a93a4cd552e2afc7b3e0ee1e29775',1,'Male','2004-08-04',N'Jagdish Malhotra',N'Saanvi Malhotra',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3004',N'Lakshmi Nair','lakshmi4cse3@student.university.edu','9938677496','c569533c269edde44b38cf68b873430a7b3f177e46dc31b8e955a6104fca76bb',1,'Female','2005-10-20',N'Vishal Nair',N'Amrutha Nair',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3005',N'Lokesh Gowda','lokesh5cse3@student.university.edu','9412328120','101d8bd75876b126ebc76dc79db4c4aa34fe079607a899574e568f0d1228bf1b',1,'Male','2003-11-07',N'Arnav Gowda',N'Amrutha Gowda',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3006',N'Varsha Chopra','varsha6cse3@student.university.edu','9713493618','a5384e17be57940153d6fc72402dd690b4838fc7f26c5effdaa3507e99310440',1,'Female','2004-12-10',N'Vivaan Chopra',N'Meena Chopra',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3007',N'Yogesh Menon','yogesh7cse3@student.university.edu','9947174648','eb56251948dbb07de87085c2486de42d3a4b73b7e7939e1d0dbc0b30ce8a7444',1,'Male','2003-05-20',N'Vihaan Menon',N'Saanvi Menon',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3008',N'Ira Trivedi','ira8cse3@student.university.edu','9013990490','9b1f88ada0f463ec3d1d2fe9813d5d404466b9a26afd673124a70ee242d2074b',1,'Female','2004-10-09',N'Vivaan Trivedi',N'Hema Trivedi',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3009',N'Naveen Murthy','naveen9cse3@student.university.edu','9717565512','eab01cce2d5567680f5e13acb2849e264ba7b4e2b04aef76407876366a703877',1,'Male','2003-10-14',N'Rahul Murthy',N'Sunita Murthy',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3010',N'Divya Rajan','divya10cse3@student.university.edu','9154516808','caaed4ea2e615162fa75f57442d5ffc24a8823200ddd5d6fb4a68b824838a8ab',1,'Female','2006-01-15',N'Naresh Rajan',N'Latha Rajan',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3011',N'Ishaan Dubey','ishaan11cse3@student.university.edu','9034824771','f12835d12eb6fe5d110e7083454ced96f983c9e256947a793a002b176192049e',1,'Male','2005-11-15',N'Anand Dubey',N'Sujatha Dubey',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3012',N'Indira Das','indira12cse3@student.university.edu','9131712748','706c78d1a28810961e1792d1dabe16e738fe09a43f61194281fba492d81e4cb0',1,'Female','2002-09-14',N'Ganesh Das',N'Sowmya Das',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3013',N'Nitesh Yadav','nitesh13cse3@student.university.edu','9263982146','f620dd40df94de5bf618f0aa7b8deb44e7db2a77b4953b37cfaf5863870b2ef7',1,'Male','2003-08-18',N'Umesh Yadav',N'Varsha Yadav',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3014',N'Anusha Sharma','anusha14cse3@student.university.edu','9727875588','ba0e24f293812b055deb33c023ecf46f46c3f915dda1a6a28b7d76f53009bf89',1,'Female','2004-10-19',N'Tarun Sharma',N'Jyothi Sharma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3015',N'Rupesh Rao','rupesh15cse3@student.university.edu','9360576627','beb98168e02a8b64b5ae58956d54dd66d29a92d2bb8bc031ec6e21312c746cdc',1,'Male','2003-10-13',N'Umesh Rao',N'Savitha Rao',3,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3016',N'Smitha Khanna','smitha16cse3@student.university.edu','9702621745','0ee90f8e1540c5ca7c9de39385c09257ea037d03d2b5c63b50fe0788fc143c69',1,'Female','2005-02-17',N'Ravi Khanna',N'Navya Khanna',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3017',N'Hitesh Mishra','hitesh17cse3@student.university.edu','9780913431','40e7a46b304e1a6f2a32ac9f1c88b0d2f7460e16df43de3bbdbc491c6e50955e',1,'Male','2006-07-11',N'Hitesh Mishra',N'Lalitha Mishra',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3018',N'Pallavi Das','pallavi18cse3@student.university.edu','9045562386','669a5701ac9df090587e69dd11af10560b04b04ff42e0703f43fe143c333d5bb',1,'Female','2002-01-11',N'Vinay Das',N'Nisha Das',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3019',N'Ayaan Gupta','ayaan19cse3@student.university.edu','9792374740','9a3de9e14d09a7059bc8de0569eb1bc98dbf754b3574cf04f3b1c1377a93bd8d',1,'Male','2006-11-08',N'Lokesh Gupta',N'Usha Gupta',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3020',N'Lalitha Agarwal','lalitha20cse3@student.university.edu','9464743671','a0dd50c991d799dc94e539900329426b5da840d78cda9280badb13d2733ac10b',1,'Female','2005-06-19',N'Kabir Agarwal',N'Diya Agarwal',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3021',N'Deepak Kapoor','deepak21cse3@student.university.edu','9640909743','140c22d537d3a2b03db52f1dc81bf2c9b71f73907ebe25c2db2c2fd8b0050f5d',1,'Male','2004-01-27',N'Tarun Kapoor',N'Savitha Kapoor',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3022',N'Radha Rao','radha22cse3@student.university.edu','9047095214','a2355d22cc272a0e86793e931a2a7e4c43ab3706ee9aeafba8d4db1fd04e74b7',1,'Female','2003-11-04',N'Lokesh Rao',N'Rekha Rao',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3023',N'Ishaan Iyer','ishaan23cse3@student.university.edu','9424745171','0ac2274edd09587832a347ed32299998f4bf64dc83afa536493720542cd0e149',1,'Male','2004-09-17',N'Mukesh Iyer',N'Vimala Iyer',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3024',N'Madhuri Bhatt','madhuri24cse3@student.university.edu','9817549651','844951a40ba9fb03d0e2a6509c0a7686b616a1431baf92536a0fb0e740e576c1',1,'Female','2005-01-09',N'Anand Bhatt',N'Ira Bhatt',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3025',N'Arjun Lal','arjun25cse3@student.university.edu','9174612004','b1ecb0b2bdc5d813efd7a1519f2ef100084b0ec94dcd34a7cb1bdbe7e69e65ca',1,'Male','2004-10-08',N'Alpesh Lal',N'Sowmya Lal',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3026',N'Lakshmi Kulkarni','lakshmi26cse3@student.university.edu','9869261796','cb5b18fb95de57650e2f92c3308bf10476fba91bc6ad708ff34690bf82babfea',1,'Female','2005-08-12',N'Arun Kulkarni',N'Riya Kulkarni',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3027',N'Vinay Naidu','vinay27cse3@student.university.edu','9515850643','9b70fa6baa1fc4434fc71ff7570bfaf464c7ae9e36168ab87e26c120618a3044',1,'Male','2005-04-28',N'Rudra Naidu',N'Pallavi Naidu',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3028',N'Ira Rajan','ira28cse3@student.university.edu','9532931839','c067bb9160f6a34c6259eaf8d06415f19ee7fe14a0a16f9f3b4b212044bda5dc',1,'Female','2006-01-02',N'Rudra Rajan',N'Meera Rajan',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3029',N'Sunil Menon','sunil29cse3@student.university.edu','9228421020','564643757b00a8d12e17a73783889c02bebcd48af9dc10cfcd4393a19bad939f',1,'Male','2002-05-28',N'Mukesh Menon',N'Kamala Menon',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3030',N'Swathi Kumar','swathi30cse3@student.university.edu','9681177589','d5f1dcb1c04f0f663efc28feaecd0e00b608bba268ecfdfb074d085acc69f9b1',1,'Female','2002-03-24',N'Ayaan Kumar',N'Rekha Kumar',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3031',N'Yash Lal','yash31cse3@student.university.edu','9007661771','54e5619e985915281ec2aa2ff3b11ae34e9dba1e1a402f4736c0f2ee60a2b1e5',1,'Male','2006-05-15',N'Vivaan Lal',N'Jyothi Lal',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3032',N'Kamala Menon','kamala32cse3@student.university.edu','9985698478','320b9206b9fd02b9e168805f42eaf8b3001e020e0868c68a0acb4e60f21be8b3',1,'Female','2004-10-21',N'Vihaan Menon',N'Riya Menon',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3033',N'Mukesh Kamath','mukesh33cse3@student.university.edu','9367365766','6b389ddacc13972c5eb0a87fbd2be37881a7cd5dcc4db03ef7aae2dc67d9324a',1,'Male','2006-12-28',N'Dhruv Kamath',N'Meera Kamath',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3034',N'Hema Pandey','hema34cse3@student.university.edu','9711116152','7b848917324c568d8f0ff077adbd4aed9297abde476a6409714fcce27d36afa5',1,'Female','2004-03-22',N'Suraj Pandey',N'Rekha Pandey',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3035',N'Jagdish Bhatt','jagdish35cse3@student.university.edu','9604945198','9d0805ed96e4919a194ba69041c38f228f8356f6b62159658127afc08e223b50',1,'Male','2002-07-12',N'Vishal Bhatt',N'Reshma Bhatt',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3036',N'Meena Shinde','meena36cse3@student.university.edu','9493689980','54c13c30a167b4646e4022c79cabc6c44e57fd6ab7623d41c1152277bf45e4bd',1,'Female','2006-06-04',N'Arnav Shinde',N'Sangeetha Shinde',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3037',N'Ayaan Shah','ayaan37cse3@student.university.edu','9022961201','d96eb8b2cac8ced8810723df7781fa2686e43c8bf033cd7d5b53147306bc302f',1,'Male','2004-06-12',N'Vinay Shah',N'Amrutha Shah',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3038',N'Usha Patil','usha38cse3@student.university.edu','9599102290','0c7816f13d914432ecafb5f5fdc1a66f26726ffdc00a94985fbb800b6fbc2067',1,'Female','2003-06-10',N'Amit Patil',N'Reshma Patil',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3039',N'Rahul Rajan','rahul39cse3@student.university.edu','9438156149','4d887b2f250300d91fff697dc5c8c0078f037192c2d5ee11b93d8127d0b86652',1,'Male','2006-08-14',N'Kartik Rajan',N'Deepa Rajan',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3040',N'Pari Pillai','pari40cse3@student.university.edu','9432445107','82709322d7abe8ca5d29d7645b6832480cf528f43afce1c3fd32071c0953ad3e',1,'Female','2002-01-07',N'Varun Pillai',N'Kamala Pillai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3041',N'Atharv Bhat','atharv41cse3@student.university.edu','9516060715','55db6809167c4edaaa95cfb8166f3a6639ee58e7b953072c939f675a09d01300',1,'Male','2003-09-18',N'Arun Bhat',N'Indira Bhat',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3042',N'Latha Hegde','latha42cse3@student.university.edu','9052975161','1548ff734a9d519fa88425fdfb531faae34a146b84d5784c261f04a3b07bb513',1,'Female','2004-02-13',N'Mahesh Hegde',N'Suma Hegde',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3043',N'Varun Dubey','varun43cse3@student.university.edu','9352181883','aadaa50ca26a51d33fa7d477836668bc97f27ba4e8501d622f90162a0600837e',1,'Male','2004-12-11',N'Sai Dubey',N'Latha Dubey',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3044',N'Jyothi Jadhav','jyothi44cse3@student.university.edu','9243292127','de6dc8dee894cb9f20d6c4d5496d894d5be3fc03899688b6d5e54829b85e4e7e',1,'Female','2003-04-04',N'Dinesh Jadhav',N'Anusha Jadhav',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20231CSE3045',N'Rahul Pillai','rahul45cse3@student.university.edu','9527177449','b7ca9db779c21d74eec446c727fba2b438db95b64ef6fd4c65081a1a00194cff',1,'Male','2006-06-28',N'Rakesh Pillai',N'Nithya Pillai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5001',N'Vihaan Bansal','vihaan1cse5@student.university.edu','9411998679','4dfd6f187894f6e6bbb054c3e9e9551859b8d242bb731c1db131c40e0706c431',1,'Male','2002-01-12',N'Amit Bansal',N'Pallavi Bansal',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5002',N'Madhuri Kapoor','madhuri2cse5@student.university.edu','9820715182','af7f2d25f924fb9151d27c02023ea46ebc0660d8c4a0ec45b8ca49348981e1fb',1,'Female','2004-10-16',N'Dinesh Kapoor',N'Sneha Kapoor',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5003',N'Rahul Dubey','rahul3cse5@student.university.edu','9466590515','0427130c2de9f73bda8935691fd5a619eeea700ade5af155583caa0aced16e64',1,'Male','2003-06-12',N'Naveen Dubey',N'Sujatha Dubey',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5004',N'Divya Mehta','divya4cse5@student.university.edu','9192546291','aa9e551a2c34b63f5e8f0fe11f32f62de8ac3e538c2f1bad15512aa1c773eef4',1,'Female','2006-03-11',N'Mohan Mehta',N'Shobha Mehta',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5005',N'Dinesh Sawant','dinesh5cse5@student.university.edu','9816850542','a779718f1a45b5e6e8d7a1949eb0f505dbdb2a34b2f52fd87574279146878e91',1,'Male','2003-11-23',N'Ravi Sawant',N'Anusha Sawant',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5006',N'Kavitha Ghosh','kavitha6cse5@student.university.edu','9418880592','3c67d106535a1b6f28542c9554d644f93b86ed7124aaf5c671c2cc45b6e93465',1,'Female','2003-03-03',N'Ishaan Ghosh',N'Meena Ghosh',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5007',N'Kabir Malhotra','kabir7cse5@student.university.edu','9706537947','72abb8846cdb0710568bffc0b7b824692e464af10c3560182434edb9103f022c',1,'Male','2006-03-24',N'Nitesh Malhotra',N'Savitha Malhotra',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5008',N'Nisha Pawar','nisha8cse5@student.university.edu','9977468862','2dd53056532f057ed96cbc4141d6cd19a9aefc89e4ddc8201f73552dca9d832f',1,'Female','2003-06-22',N'Mukesh Pawar',N'Varsha Pawar',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5009',N'Atharv Deshpande','atharv9cse5@student.university.edu','9181412478','171a2c89ffc3e2f6f87af871384d212164a16c7067f82a4caa739b6f83a668be',1,'Male','2005-06-18',N'Nikhil Deshpande',N'Saanvi Deshpande',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5010',N'Meena Jadhav','meena10cse5@student.university.edu','9685361530','01a178e439d3f73ac35d3d1aef907306c679da557ea6ce7ef153ed32657fd1ac',1,'Female','2002-07-02',N'Rahul Jadhav',N'Sangeetha Jadhav',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5011',N'Mukesh Menon','mukesh11cse5@student.university.edu','9277901043','24b0064f8a4da3d5e6feef076d9140be35cc508db79671f304d9172b2b7dc432',1,'Male','2004-08-23',N'Atharv Menon',N'Pari Menon',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5012',N'Jyothi Trivedi','jyothi12cse5@student.university.edu','9410369711','abb19c602ddb6653159ba3fe8280c39ae3da061f9b4acc087d36fab34d6f3d2a',1,'Female','2002-05-08',N'Naveen Trivedi',N'Hema Trivedi',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5013',N'Arun Kumar','arun13cse5@student.university.edu','9246095396','76be2644c725c807cee93b43755ad19d593833e66a450fec3b96e4821a72d776',1,'Male','2006-04-23',N'Mahesh Kumar',N'Smitha Kumar',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5014',N'Bhavana Reddy','bhavana14cse5@student.university.edu','9880670654','c3e9fa140f7b006f094f2c47bf6bb120c04c0065489c36905e4dbe4aed443085',1,'Female','2006-09-26',N'Jagdish Reddy',N'Geetha Reddy',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5015',N'Mukesh Reddy','mukesh15cse5@student.university.edu','9520585277','ef63bbae5205f967e02551307b436eed93a4a2a97332633fb203b5dbb7379c65',1,'Male','2002-10-24',N'Deepak Reddy',N'Lakshmi Reddy',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5016',N'Diya Hegde','diya16cse5@student.university.edu','9030548687','9597f7b1e6e124b04bbb980e8b90e6db2323c295f4aa00640ebadc41bee0a411',1,'Female','2002-05-07',N'Sunil Hegde',N'Sruthi Hegde',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5017',N'Tarun Shetty','tarun17cse5@student.university.edu','9415667652','a590c205e0674f330602b1c73aeea5bdb2bd21dd8d0198749d90959acdca1345',1,'Male','2002-11-11',N'Rupesh Shetty',N'Kavitha Shetty',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5018',N'Madhuri Dubey','madhuri18cse5@student.university.edu','9169284511','efb307c57b3009ec7bf7748992b2f5d9a23ce2f510f0deced5a963009f1f3fa9',1,'Female','2002-12-14',N'Kiran Dubey',N'Madhuri Dubey',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5019',N'Rahul Trivedi','rahul19cse5@student.university.edu','9570596401','6388e2901e55311b6ef7eefde9aad46fc3700501ec64150f216686ce83369709',1,'Male','2003-12-15',N'Suresh Trivedi',N'Hema Trivedi',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5020',N'Smitha Pawar','smitha20cse5@student.university.edu','9970213556','56e5d324df25692b9ad73c87fe12be7a30aadd95c81e8ce849e10ed66e8e076e',1,'Female','2003-01-05',N'Prakash Pawar',N'Lalitha Pawar',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5021',N'Sachin Menon','sachin21cse5@student.university.edu','9192856543','7e0c9bf98c162086c5d1b761af72fb3aa88b27c9443e869f6176602aec5818c5',1,'Male','2004-06-15',N'Tushar Menon',N'Pallavi Menon',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5022',N'Rashmi Malhotra','rashmi22cse5@student.university.edu','9447394731','7a08844a0c8d5960ec2131fa4bec2ffac9b8fb8388622b3582509ab4db061d9e',1,'Female','2005-09-04',N'Sandeep Malhotra',N'Geetha Malhotra',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5023',N'Ayaan Kale','ayaan23cse5@student.university.edu','9551884422','a2a8f153c4e85a7b65fa338360c143b36db7e62ab67c1ba52b73e57e6f90f7d7',1,'Male','2002-11-28',N'Suresh Kale',N'Pallavi Kale',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5024',N'Meena Nair','meena24cse5@student.university.edu','9705895782','98606b8421ad77a3165de1c04f9c6e66cd794aa6151532001989d6c52c1f8e65',1,'Female','2003-04-26',N'Ishaan Nair',N'Sridevi Nair',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5025',N'Ganesh Kulkarni','ganesh25cse5@student.university.edu','9691251778','bd18fd03c4ab9b69935d6b75391581d026dc5794588df8b54f0f6aa8984c299b',1,'Male','2005-09-14',N'Suresh Kulkarni',N'Jyothi Kulkarni',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5026',N'Radha Khanna','radha26cse5@student.university.edu','9018242253','744189f574f5cec0dae90c36438613e7bd9cd987ff2746f1889cd5a62a291c81',1,'Female','2003-07-17',N'Ayaan Khanna',N'Kavitha Khanna',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5027',N'Hitesh Gupta','hitesh27cse5@student.university.edu','9498182992','b5c0f6bf33d33e81853f797373740b3236ff954564a9a5dec301ccf984a9275c',1,'Male','2006-05-05',N'Nikhil Gupta',N'Sneha Gupta',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5028',N'Reshma More','reshma28cse5@student.university.edu','9094396907','bc10d6f16e05caa122c248fe5feb2c79aa66ec3a21ae424f8ff081675835cabf',1,'Female','2002-01-03',N'Rakesh More',N'Nithya More',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5029',N'Dinesh Bansal','dinesh29cse5@student.university.edu','9102767735','6e15c6b0dd8662168d6f3283d9f4cb74950368840922f3ee705ce0618e385d2f',1,'Male','2005-05-15',N'Vikram Bansal',N'Lakshmi Bansal',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5030',N'Indira Pandey','indira30cse5@student.university.edu','9588153714','259c8430931c74e9f7c640841409655c49446e29e1b7ca10ab6b14634364b733',1,'Female','2005-03-25',N'Mohan Pandey',N'Sangeetha Pandey',5,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5031',N'Arnav Singh','arnav31cse5@student.university.edu','9259532787','10e298eccfb47260b8f8abe1cbf7340e546d0b7608a8ca6e18bdac611e5edeec',1,'Male','2006-07-08',N'Tarun Singh',N'Usha Singh',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5032',N'Ananya Gupta','ananya32cse5@student.university.edu','9395004797','fc74471cdb3f27a2429e787e29c36bd5cda21b4fe31f5783c14eafce42d6a250',1,'Female','2006-08-08',N'Naresh Gupta',N'Latha Gupta',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5033',N'Hitesh Verma','hitesh33cse5@student.university.edu','9650609835','c7d12872acf874c946806d1c31f684051af2b5a4278e75c18862a144ab307442',1,'Male','2004-12-12',N'Kartik Verma',N'Riya Verma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5034',N'Usha Tiwari','usha34cse5@student.university.edu','9991216558','e915c3e609da7d4493f52db8ccd6d124ecf25fd342b11076c8fe4aa34823d97a',1,'Female','2006-05-27',N'Rahul Tiwari',N'Amrutha Tiwari',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5035',N'Ishaan Trivedi','ishaan35cse5@student.university.edu','9025787298','ef5f48cebdcff567669674f231ef916af70204ea1d23c23dfc3ee4808cac40d2',1,'Male','2006-01-02',N'Rajesh Trivedi',N'Latha Trivedi',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5036',N'Priya Kulkarni','priya36cse5@student.university.edu','9888794705','7febd9141655d6e97a435e639e05c17e7cdd0ff265ebdf6e949a7cbf92c106c0',1,'Female','2004-10-11',N'Lokesh Kulkarni',N'Rashmi Kulkarni',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5037',N'Manoj Bansal','manoj37cse5@student.university.edu','9499309728','3ccb7f1434eb5b1fe9e17165de2a6174928019d4376cde2fa3e9d0ba96be0270',1,'Male','2002-10-16',N'Mukesh Bansal',N'Jyothi Bansal',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5038',N'Sara Jadhav','sara38cse5@student.university.edu','9130756263','0604c39b3b6a00c7e046f324b991fe1bcb47ab5e41d94b0b5613a2662d0ec63f',1,'Female','2002-10-23',N'Tushar Jadhav',N'Lakshmi Jadhav',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5039',N'Rupesh Shinde','rupesh39cse5@student.university.edu','9838578652','8e258bce19605e1fca986fc755571674c27e4c6963622f2a328c921165c1d0b3',1,'Male','2002-12-05',N'Prakash Shinde',N'Jyothi Shinde',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5040',N'Vimala Shetty','vimala40cse5@student.university.edu','9334843443','d8ce294da9962fdbd0bd1fa910e2124c40675ecf6ccd8599e5abd94a59518940',1,'Female','2004-10-16',N'Tushar Shetty',N'Kavitha Shetty',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5041',N'Vikram Shetty','vikram41cse5@student.university.edu','9986652404','65ed71bdb512f06f15d26980085ccadc9ca6e7022d5d80957b53c91bded06f5b',1,'Male','2004-05-04',N'Vishal Shetty',N'Sridevi Shetty',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5042',N'Pallavi Murthy','pallavi42cse5@student.university.edu','9848421993','8700d6454495dc44ee83ad3e60155ff30dbf53a2efb5b4edcf9c269a491abd7c',1,'Female','2005-04-07',N'Nikhil Murthy',N'Rashmi Murthy',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5043',N'Yash Varma','yash43cse5@student.university.edu','9712082677','0dc49c304544d932fdfa3fd3d58b9426076cb2ba3f7483a464a393202ee2b528',1,'Male','2002-07-11',N'Yash Varma',N'Saanvi Varma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5044',N'Swathi Chopra','swathi44cse5@student.university.edu','9380262067','b777393a263520ce7e731d7196a71c68964f5b2bb69807f5e33c4a1d5fde6e97',1,'Female','2002-11-19',N'Dinesh Chopra',N'Saanvi Chopra',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20221CSE5045',N'Aarav Bansal','aarav45cse5@student.university.edu','9788728743','8665479f0085b498e95128774a7e6c8638ecfee2e9980174181237bd7b89a168',1,'Male','2002-06-10',N'Gaurav Bansal',N'Kamala Bansal',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7001',N'Kabir Shenoy','kabir1cse7@student.university.edu','9054932966','b92ee5731c5f55b6f33a1ea95eb04f822108b0448d86e3d6fad4089cfb9720d2',1,'Male','2004-12-06',N'Amit Shenoy',N'Meera Shenoy',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7002',N'Latha Rajan','latha2cse7@student.university.edu','9304637454','cb7dc3e19fa5f8e2eabf486e034a27e33db9531b6be3c628fc834f9319df2ae7',1,'Female','2003-08-11',N'Arnav Rajan',N'Kavya Rajan',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7003',N'Nikhil Murthy','nikhil3cse7@student.university.edu','9174268414','19b88338be3b4fdd4e6054d31583c9e890dc07a09614c131c735b8a6d74b5d6a',1,'Male','2003-01-22',N'Anand Murthy',N'Savitha Murthy',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7004',N'Meena Iyer','meena4cse7@student.university.edu','9568783391','59f5a369dacedba07cabdf948164201548560b2eb82e10c97635a391e17e4889',1,'Female','2005-12-20',N'Vikram Iyer',N'Sara Iyer',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7005',N'Suresh Naidu','suresh5cse7@student.university.edu','9883982258','2dafb352260b63387e3679459370b6fc15222c2bd46b40a7b7d06c5bb08ab812',1,'Male','2002-01-27',N'Vihaan Naidu',N'Nithya Naidu',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7006',N'Indira Khanna','indira6cse7@student.university.edu','9072867908','7aaaabe1f65b809aba4298ad9438a49b0815097f550371370ff4c574a897453e',1,'Female','2006-08-26',N'Sandeep Khanna',N'Ira Khanna',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7007',N'Varun Mehta','varun7cse7@student.university.edu','9065180170','c26060f72cb919c3d7739843a5b30141fbe326d6b6cddcceaeadd566adea8d09',1,'Male','2003-10-03',N'Yogesh Mehta',N'Aadhya Mehta',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7008',N'Kavitha Iyer','kavitha8cse7@student.university.edu','9766182512','a5567f9e9fb48c59cfd8cabcf5166721056546b05c5a7605d0848ea99b4024a3',1,'Female','2005-06-13',N'Sunil Iyer',N'Meera Iyer',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7009',N'Atharv Shenoy','atharv9cse7@student.university.edu','9786863375','900949abcc2d0383b7d62d28a27055c908445f9b1587be6af874a388a4670f6a',1,'Male','2002-01-10',N'Umesh Shenoy',N'Meena Shenoy',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7010',N'Jyothi Naik','jyothi10cse7@student.university.edu','9033119079','7565bbd1673694740182e74654e734c9657fc1bc9e23e283713b4aaac02983a5',1,'Female','2005-10-25',N'Dhruv Naik',N'Pari Naik',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7011',N'Prakash Patel','prakash11cse7@student.university.edu','9028439599','f232f9588f9e0bc8d97d63ce1475f25388f333613f955ebb2ec64709daa2b7ce',1,'Male','2003-09-07',N'Varun Patel',N'Pallavi Patel',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7012',N'Nisha Kulkarni','nisha12cse7@student.university.edu','9440892687','0724fb9bae8c648e12232bf770023956f1d5236a1c8ccfcd96b8951891198a6d',1,'Female','2006-04-14',N'Reyansh Kulkarni',N'Shobha Kulkarni',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7013',N'Mukesh Dubey','mukesh13cse7@student.university.edu','9462873342','75020fececfac464b907d3021904277cfeffb76cb2da7e7a37dc335a59497ff3',1,'Male','2005-07-05',N'Harish Dubey',N'Savitha Dubey',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7014',N'Sowmya Patil','sowmya14cse7@student.university.edu','9634351751','c08d82fd2213e13617efeca82b2d240fcb0b41ae90d849747cce99fd34385a97',1,'Female','2006-09-05',N'Jagdish Patil',N'Suma Patil',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7015',N'Kiran Bhat','kiran15cse7@student.university.edu','9139837354','6dbda34f7fd30b0aec58230e1696d0d95079405f5ff63e641199560ce18e23e5',1,'Male','2006-01-28',N'Tushar Bhat',N'Kamala Bhat',7,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7016',N'Sneha Gowda','sneha16cse7@student.university.edu','9936385467','7a3eb7faa9746cfd8c91aac4c4ae02d4809241f0f1880bcdb8e1608261c17145',1,'Female','2005-04-23',N'Dhruv Gowda',N'Rashmi Gowda',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7017',N'Nikhil Naidu','nikhil17cse7@student.university.edu','9753556093','3cd17af5529aecf66ff90d1a943540de2c567c87ff8d1c16fe7c35f34b9888d4',1,'Male','2005-02-26',N'Rajesh Naidu',N'Deepa Naidu',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7018',N'Rekha Bhatt','rekha18cse7@student.university.edu','9423536937','3dda83a7baf48e13d30a08849f4e0218feca2fcce021f4dda978e98041373603',1,'Female','2006-12-14',N'Rakesh Bhatt',N'Revathi Bhatt',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7019',N'Ramesh Jadhav','ramesh19cse7@student.university.edu','9522872808','7bee5ea67468ed1f0d1603ec27691545365321445c3edadb94f24456dff55c7a',1,'Male','2005-08-06',N'Sandeep Jadhav',N'Jyothi Jadhav',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7020',N'Amrutha Sharma','amrutha20cse7@student.university.edu','9203875099','e8a7fd91bf880896a04fbdae248c0da5fd863c63886af0ceaaf2d2e46c2018f4',1,'Female','2003-02-23',N'Akash Sharma',N'Riya Sharma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7021',N'Arjun Sharma','arjun21cse7@student.university.edu','9848408621','faf129ae18b4015c07757c9a6fb8e95e5ee04605b43f09902a840f3e2c6de315',1,'Male','2005-01-01',N'Arun Sharma',N'Sowmya Sharma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7022',N'Sara Joshi','sara22cse7@student.university.edu','9546156793','e423396513fb8fb78ea5785127d0cbf2c57691dcee8935336d4f349444be2480',1,'Female','2006-05-27',N'Ishaan Joshi',N'Sujatha Joshi',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7023',N'Tushar Jadhav','tushar23cse7@student.university.edu','9668700217','f3beb82330222d7c079bbc78d6e8537f766a46472fb57421a290ad1796eb09c4',1,'Male','2002-02-13',N'Hitesh Jadhav',N'Ira Jadhav',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7024',N'Nithya Shinde','nithya24cse7@student.university.edu','9397401489','24294b93b080f46d90a11d97f17f673df9d992f47fbd5ed4d9722aa38e71519c',1,'Female','2006-01-08',N'Umesh Shinde',N'Navya Shinde',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7025',N'Rakesh Shinde','rakesh25cse7@student.university.edu','9614293968','8d8d03402943ee429c539a99892b233837da37e4e68424a273910d770e51e224',1,'Male','2003-10-05',N'Harish Shinde',N'Ananya Shinde',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7026',N'Sridevi Kamath','sridevi26cse7@student.university.edu','9016315999','2e6df9c32a723e3d1e3dda30c04b6ab0c5231e95aee23c47d72f0af749ad3faa',1,'Female','2006-12-12',N'Mohan Kamath',N'Ira Kamath',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7027',N'Mahesh Shah','mahesh27cse7@student.university.edu','9866296194','3e289a6378ac4d9bbb1c6f9c32dc894aa65c12bd5adffbcfaf054471bdc24682',1,'Male','2005-04-12',N'Mukesh Shah',N'Pallavi Shah',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7028',N'Ira Shah','ira28cse7@student.university.edu','9551104754','43a3b1aee45e32bb0792fc67bbd764af9f33c11cd77d3a1a3f4437c506b5b02d',1,'Female','2003-12-13',N'Reyansh Shah',N'Usha Shah',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7029',N'Ayaan Desai','ayaan29cse7@student.university.edu','9101581995','dc517ed956bd9370379c3e298a245de4f830cd187aa8cd847b359f6aa36236e4',1,'Male','2006-09-14',N'Rahul Desai',N'Sowmya Desai',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7030',N'Divya Patil','divya30cse7@student.university.edu','9398262244','9cfe810ed3f8460663fe3daccc9fe0710af0f22d1bcf398457042639e1fe381c',1,'Female','2002-12-18',N'Pranav Patil',N'Kavitha Patil',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7031',N'Vihaan Das','vihaan31cse7@student.university.edu','9154379937','eed3669f5f9f946df7dfd74602e379b8c5a35fc8a57c510d362b9d7adccdbf7b',1,'Male','2005-05-16',N'Kartik Das',N'Sunita Das',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7032',N'Aadhya Kulkarni','aadhya32cse7@student.university.edu','9575692459','1db00703b99c2e2fa9057b255180da7c0d24603992d596b1789c97a06e282015',1,'Female','2006-07-26',N'Ravi Kulkarni',N'Bhargavi Kulkarni',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7033',N'Harish Malhotra','harish33cse7@student.university.edu','9793564651','7d00f9428afb572a497553af45bc2464c24257644a338150cdc12a1d3597359b',1,'Male','2004-05-24',N'Jagdish Malhotra',N'Latha Malhotra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7034',N'Revathi Agarwal','revathi34cse7@student.university.edu','9737416724','19181de65f420cd8e9201e4b77ed758b92550c5ae8185d64d67fe2baca7c9dc5',1,'Female','2006-01-24',N'Ayaan Agarwal',N'Lalitha Agarwal',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7035',N'Suresh Desai','suresh35cse7@student.university.edu','9796886805','7cfd18dec96abe1e4ff5cda6398aa7bd4dd41b609527778fc439f1f63d93b4f8',1,'Male','2002-08-20',N'Mukesh Desai',N'Usha Desai',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7036',N'Radha Bhosale','radha36cse7@student.university.edu','9529096561','06b7a4d4960e74efe8a9fde6d7e37ce4c25e4d266587650c6d4cff563852af2b',1,'Female','2003-11-22',N'Sai Bhosale',N'Navya Bhosale',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7037',N'Yash Tiwari','yash37cse7@student.university.edu','9937567982','06a336e021f2d6d573bfc9856e4b295f180bdc5adf25fc88a55b21be29c8a8d4',1,'Male','2006-10-23',N'Prakash Tiwari',N'Geetha Tiwari',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7038',N'Navya Chopra','navya38cse7@student.university.edu','9545738757','60d9c10e1bdb0d65f0994aa90afbbdbfa7ee1be08161e97e76d171276533d922',1,'Female','2002-12-05',N'Akash Chopra',N'Ira Chopra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7039',N'Harish Reddy','harish39cse7@student.university.edu','9512382825','05f2a493e1433c291c27ee2ce18beb50802fe0f81e8ac196936f8f25835745b6',1,'Male','2002-01-28',N'Ganesh Reddy',N'Pari Reddy',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7040',N'Meena Pawar','meena40cse7@student.university.edu','9660937966','6be7d665e0a362df0be8905938f4e1ffa70ebf984d04d65183a119e1e16ee047',1,'Female','2003-03-21',N'Varun Pawar',N'Radha Pawar',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7041',N'Kiran Naik','kiran41cse7@student.university.edu','9825537147','553c9add5b65de51b0c6aef07494c4fa45512c226f960726dc2edaba921e8145',1,'Male','2002-10-04',N'Suresh Naik',N'Madhuri Naik',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7042',N'Usha Lal','usha42cse7@student.university.edu','9792499125','5ed91102d043e2daeabbdb48fcc8c6cb12d9d31595daafcebb9b880553dc6b90',1,'Female','2002-06-12',N'Varun Lal',N'Revathi Lal',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7043',N'Dhruv Malhotra','dhruv43cse7@student.university.edu','9692966278','e176c4ac527a508fb4c42b887c923018f1a5dd18fb3aaaf50c432faa7ac61bed',1,'Male','2003-09-13',N'Anand Malhotra',N'Savitha Malhotra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7044',N'Priya Ghosh','priya44cse7@student.university.edu','9790507236','3c0e93d795021ea1610e081b299a2662081d170d2a5a00322d080f9532d0a832',1,'Female','2003-06-27',N'Tarun Ghosh',N'Riya Ghosh',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20211CSE7045',N'Dinesh Ghosh','dinesh45cse7@student.university.edu','9772190340','f76b728ef72d448e0d61ecfd619db4ea2bcc1d48d1d35b2ffe36d9d468e0570f',1,'Male','2005-07-23',N'Akash Ghosh',N'Lalitha Ghosh',7,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1001',N'Tarun Das','tarun1eee1@student.university.edu','9788191485','439a04b94a8c83ebb21dcb548728213d8d23cf19cef89251ef367fb447adc7a7',3,'Male','2006-12-25',N'Sunil Das',N'Sruthi Das',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1002',N'Vimala Krishnan','vimala2eee1@student.university.edu','9074517133','14104cc5649f0dd814fa1455298a6cc1cfb7dcdd2662fcb416df2be92069e235',3,'Female','2003-05-28',N'Kartik Krishnan',N'Navya Krishnan',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1003',N'Rupesh Hegde','rupesh3eee1@student.university.edu','9233095849','c86ef7fec0c0b6c13e8c66c8af1f45f5ca4970286b5e0bfdd327621d6075f5a1',3,'Male','2005-03-20',N'Lokesh Hegde',N'Radha Hegde',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1004',N'Indira Chopra','indira4eee1@student.university.edu','9126042232','c3c042d038655e988aea64faa4dc9a455bb483913bef345e08c6a5f06b2f8a54',3,'Female','2004-09-22',N'Tarun Chopra',N'Nithya Chopra',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1005',N'Ramesh More','ramesh5eee1@student.university.edu','9466711684','1f84971cf42eca05de8a7d44f7b8888ea2b68fa7471928bc521676de7b2e0422',3,'Male','2005-03-19',N'Tushar More',N'Latha More',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1006',N'Deepa Pandey','deepa6eee1@student.university.edu','9518636374','1697d0d4c69a1bf5ee73168bb755174b89d5efa0cc4bb1d2ae6804b407632e57',3,'Female','2002-12-15',N'Manoj Pandey',N'Aadhya Pandey',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1007',N'Vishal Kapoor','vishal7eee1@student.university.edu','9001701277','a3dc7cacff4168c984a0e6688f88017d325b3682d41d782ea743dfed42f4e369',3,'Male','2005-06-22',N'Atharv Kapoor',N'Nithya Kapoor',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1008',N'Savitha Bhosale','savitha8eee1@student.university.edu','9415415206','151d0441bf87abc5675e64a16dcc396d94357bae7cc876b3444fd800fb34407d',3,'Female','2004-03-28',N'Atharv Bhosale',N'Meera Bhosale',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1009',N'Kartik Murthy','kartik9eee1@student.university.edu','9712938700','d2a874e522f22e20920b963726a37d65f28b532475b0e78187dc65a259f7c8b8',3,'Male','2002-01-07',N'Sai Murthy',N'Indira Murthy',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1010',N'Hema Kamath','hema10eee1@student.university.edu','9111554262','ef1149503ea69b16801deaa0d4dab18ede2703f8e686ab9d08913786256e8d28',3,'Female','2002-04-13',N'Atharv Kamath',N'Varsha Kamath',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1011',N'Naveen Kapoor','naveen11eee1@student.university.edu','9326973112','8d0b6453d8eaefd4d4cee77dab95456d5228f94e428228a2f184d86c94a57f62',3,'Male','2003-08-12',N'Aarav Kapoor',N'Sujatha Kapoor',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1012',N'Jyothi Bhat','jyothi12eee1@student.university.edu','9413899940','530517bca254ba37db019e17b3348c1e83b0d2a5a345b6a887371a39775f8d03',3,'Female','2004-03-08',N'Deepak Bhat',N'Hema Bhat',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1013',N'Naveen Trivedi','naveen13eee1@student.university.edu','9037613791','dde728529da2a46323705c476d45cdf1e0559057c396e782d9b636c13d7f5ea2',3,'Male','2005-05-21',N'Rajesh Trivedi',N'Sneha Trivedi',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1014',N'Swathi Iyer','swathi14eee1@student.university.edu','9827109104','57f1e54db5f0875f24cc14c7bfb60e3e28e5ea7e278dacb5425306695f315d2e',3,'Female','2006-07-12',N'Pranav Iyer',N'Bhargavi Iyer',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1015',N'Naresh Sawant','naresh15eee1@student.university.edu','9866618892','824f844f312dd6ce1b38595103ef369208ad9109e226bd756fef131a533a0861',3,'Male','2004-11-23',N'Varun Sawant',N'Smitha Sawant',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1016',N'Ira Tiwari','ira16eee1@student.university.edu','9691463031','b7d038c16565c393591f30e19bdef8166f31cea5aefa5b747f10e3600d8e6441',3,'Female','2003-09-11',N'Paresh Tiwari',N'Pooja Tiwari',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1017',N'Amit Lal','amit17eee1@student.university.edu','9210202758','57ebca8211996e3c7fcbcabbfa237a8ac84a453de9497a47cad288a3a44dc2bd',3,'Male','2004-11-24',N'Sachin Lal',N'Saanvi Lal',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1018',N'Bhavana Iyer','bhavana18eee1@student.university.edu','9056481491','d1816f5ba983bbeb9bfc717a4993603d387b04ee14759082ccf3c4ed9ba660e7',3,'Female','2004-12-04',N'Prakash Iyer',N'Kavitha Iyer',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1019',N'Anand Singh','anand19eee1@student.university.edu','9419138000','79dc5d557c344be39b1ee6dc9c83adcf9ea6dba5636fd3137583380a0b379aae',3,'Male','2003-06-06',N'Sandeep Singh',N'Nithya Singh',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1020',N'Bhavana Bhat','bhavana20eee1@student.university.edu','9635365419','8dea81a3ee18b4143fdb963ca7f3c8409e03904c8902ef3d103bb6f7b3a03d8c',3,'Female','2003-01-18',N'Paresh Bhat',N'Sara Bhat',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1021',N'Tushar Kale','tushar21eee1@student.university.edu','9617445187','94dd63793b0842128b06a708441da90872f51c6d4130259c12d94d4fe8acc1aa',3,'Male','2003-09-02',N'Aditya Kale',N'Kavya Kale',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1022',N'Divya Kapoor','divya22eee1@student.university.edu','9597383206','08d0a494978f59d6324f0b9e1aef1b3e20356be568c4328b634cccdacfabe25d',3,'Female','2006-04-15',N'Mukesh Kapoor',N'Nisha Kapoor',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1023',N'Deepak Varma','deepak23eee1@student.university.edu','9641383670','e1b77534ae72fed3c8488dfb2008726c73520759fee12f542266245a18255712',3,'Male','2002-06-01',N'Nitesh Varma',N'Savitha Varma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1024',N'Ira Patel','ira24eee1@student.university.edu','9571918261','898c4c006e8c62679b2004bbb4a72623746a2fc4ae19af261303c27e8183946b',3,'Female','2006-07-23',N'Paresh Patel',N'Meena Patel',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1025',N'Kartik Rajan','kartik25eee1@student.university.edu','9565574313','dc01c5e0674bae947b099fa21baa12a9ee6d608ede8b0024366b98d2e3bb9515',3,'Male','2003-05-09',N'Jagdish Rajan',N'Riya Rajan',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1026',N'Sara Verma','sara26eee1@student.university.edu','9185374741','7b79ddf0493762a57d7e1a562ab7b61b525343cdd268d3caa62edbf03857a2d3',3,'Female','2005-06-14',N'Kabir Verma',N'Pallavi Verma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1027',N'Yogesh Hegde','yogesh27eee1@student.university.edu','9521356804','99365d357ba8d1c3589b2986be51104691ddaa92d20fe0e52a5a0d9b867e8759',3,'Male','2002-04-27',N'Vinay Hegde',N'Kamala Hegde',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1028',N'Latha Shinde','latha28eee1@student.university.edu','9712100323','b763349e2b3621dfcca1e506a28f6862937190ecc5b0e94626f87780b023aa53',3,'Female','2006-04-04',N'Rahul Shinde',N'Sowmya Shinde',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1029',N'Tushar Varma','tushar29eee1@student.university.edu','9410137215','eace253dc2e5530f7de1e06e5f63f77445bbebf880e6d096c66cbf797b7eb1fa',3,'Male','2002-10-19',N'Naresh Varma',N'Meera Varma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1030',N'Saanvi Das','saanvi30eee1@student.university.edu','9706625324','cf963e2baa10de300292ae7bd0ae32be6a21d456bec4e888cfd34929f26b70ba',3,'Female','2005-12-13',N'Rakesh Das',N'Nithya Das',1,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1031',N'Vivaan Lal','vivaan31eee1@student.university.edu','9768701462','d55a7991b5c4aff59bd4d228150976e287ddb12c0f2d5864804ec1be1db2030c',3,'Male','2003-11-10',N'Lokesh Lal',N'Sujatha Lal',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1032',N'Lakshmi Varma','lakshmi32eee1@student.university.edu','9578759856','800aee5a6c92ba52e8541707d968d0b6ae4c4af281415a0bcfb37f3bb256dec3',3,'Female','2002-07-26',N'Girish Varma',N'Vimala Varma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1033',N'Harish Trivedi','harish33eee1@student.university.edu','9785932133','7cc2f4210790552b56ee618abf4337f27363d3333554af0c38aef43e8c3bfa56',3,'Male','2004-01-26',N'Yash Trivedi',N'Ananya Trivedi',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1034',N'Amrutha Pillai','amrutha34eee1@student.university.edu','9223955905','73f2da7bcb49394caaacbc8b9dbd4f8d7e03fa6cd7624a809be8a99f0abe5a07',3,'Female','2005-06-27',N'Gaurav Pillai',N'Madhuri Pillai',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1035',N'Reyansh Kapoor','reyansh35eee1@student.university.edu','9270103930','ef9fb41dd68e3d3a602760199efdd7d5e775bfe58d56a9cb3ad284f0bf7eea6f',3,'Male','2005-09-10',N'Naresh Kapoor',N'Sneha Kapoor',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1036',N'Reshma Bhosale','reshma36eee1@student.university.edu','9250029218','0303c5fcc7e4d7203e350e27314781c0383fd1d3b532bb562f9b231116930dd4',3,'Female','2003-06-23',N'Lokesh Bhosale',N'Sneha Bhosale',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1037',N'Anand Hegde','anand37eee1@student.university.edu','9545226752','1c56a20b1fa497a9961505c46850300d14710e0146382d5e07ae73733c0746dc',3,'Male','2005-10-04',N'Naresh Hegde',N'Shobha Hegde',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1038',N'Meena Rajan','meena38eee1@student.university.edu','9422096902','863415bdd4acc4f7f70816ec3b90b413c4691c2f188db7ef2ce1eb590feed0b8',3,'Female','2003-07-10',N'Manoj Rajan',N'Anusha Rajan',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1039',N'Mahesh Kapoor','mahesh39eee1@student.university.edu','9135521570','fa47bcf8150b2bf5d64caaf97fb51b1200ab4a03bc9edd95433324f123c86f49',3,'Male','2003-06-24',N'Arnav Kapoor',N'Deepa Kapoor',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1040',N'Savitha Reddy','savitha40eee1@student.university.edu','9067626765','ab5129ac4ab319e0c61c7db1c71344898f76588aaa92f42f5e9cab84fce64d1c',3,'Female','2002-12-01',N'Deepak Reddy',N'Rekha Reddy',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1041',N'Mukesh Deshpande','mukesh41eee1@student.university.edu','9104054115','e0d8bc94977f0a006972e6141ef364a2ca8a722f171f05234a951ae4728897d1',3,'Male','2003-03-15',N'Gaurav Deshpande',N'Meera Deshpande',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1042',N'Jyothi Reddy','jyothi42eee1@student.university.edu','9706296201','f3f94a17217bfef9986e86ff961e71f647b10bc385e2493f2dfb45298d74cf86',3,'Female','2004-10-20',N'Vishal Reddy',N'Ira Reddy',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1043',N'Akash Kamath','akash43eee1@student.university.edu','9443106987','6b583fcbbb4b3d1cdf942ae1d72fad660dd228060f7096e5abaf54179781a2e2',3,'Male','2006-05-22',N'Vishal Kamath',N'Jyothi Kamath',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1044',N'Aadhya Desai','aadhya44eee1@student.university.edu','9103241714','d04f272b43b02ea8d1ad83d49b0ac6141655933f7b7fcfe99c30687d019717fc',3,'Female','2006-08-07',N'Sai Desai',N'Divya Desai',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20243EEE1045',N'Sandeep Kale','sandeep45eee1@student.university.edu','9625652704','2079ea636c2e7eeebaf83236609a73b0ff9b6c5b78bf40f51caedbeee30abbd3',3,'Male','2002-11-18',N'Suraj Kale',N'Rekha Kale',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3001',N'Yash More','yash1eee3@student.university.edu','9115869380','dd10c2f525e9f346c1cb95e5a2eb06051e2020fc1224c11382b5a3b175ff520c',3,'Male','2002-03-25',N'Kiran More',N'Nithya More',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3002',N'Suma Agarwal','suma2eee3@student.university.edu','9416089899','d3a2bd9038605a7a5d27c88458e5ff2c9c7d01f951d66e861d2104029f161220',3,'Female','2006-04-16',N'Tushar Agarwal',N'Varsha Agarwal',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3003',N'Ayaan Das','ayaan3eee3@student.university.edu','9616329451','486916620c2cb21e0903d1906486af9afc7fe88d01d9b8c7055dc3dac857cc07',3,'Male','2003-03-02',N'Umesh Das',N'Pooja Das',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3004',N'Latha Bhatt','latha4eee3@student.university.edu','9099861622','c53d8b019233872483043e6b2fc4936af6e2ce6b64904281e8c5413acb2f4636',3,'Female','2006-08-28',N'Harish Bhatt',N'Sunita Bhatt',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3005',N'Ramesh Verma','ramesh5eee3@student.university.edu','9485646799','f7aed914409215399af506e3c2fac62a43038fc1e1ab4a42bf36ff58037f6dc0',3,'Male','2006-02-26',N'Rakesh Verma',N'Navya Verma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3006',N'Sunita Kulkarni','sunita6eee3@student.university.edu','9606530745','888637da23a2a52c1690db36ba41a042209e5a962f01aff455d12ccf6140d612',3,'Female','2006-11-23',N'Reyansh Kulkarni',N'Sujatha Kulkarni',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3007',N'Ganesh Shah','ganesh7eee3@student.university.edu','9475469137','0dd71b82dc2c12f92be21cb5751fed111b5a31ee6d46b9d1cc5099bd60cd3f56',3,'Male','2002-04-05',N'Nitesh Shah',N'Deepa Shah',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3008',N'Amrutha Dubey','amrutha8eee3@student.university.edu','9214862890','3efd6e8060b60f13fa5eb1f3c61b3eaacf2e99ee2f80b435f8f323e98cc04311',3,'Female','2002-09-26',N'Rupesh Dubey',N'Bhavana Dubey',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3009',N'Nitesh Singh','nitesh9eee3@student.university.edu','9345786103','d84827786d8a70b2d16b6c17cc198162fed7c212b3b04f6b842cafa28f7a6009',3,'Male','2005-01-12',N'Rohan Singh',N'Pari Singh',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3010',N'Pallavi Malhotra','pallavi10eee3@student.university.edu','9524140602','4c4381672eb1d45846c8fbe6f4c75e0b948ee004415e41f6c664a3fd82b79cf6',3,'Female','2006-09-12',N'Jagdish Malhotra',N'Varsha Malhotra',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3011',N'Hitesh Pillai','hitesh11eee3@student.university.edu','9680072290','f579fa4ebbf4ea82b5d74c0d2704a495810b9733e0221e81777c92326867563e',3,'Male','2003-05-21',N'Dinesh Pillai',N'Meena Pillai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3012',N'Madhuri Bansal','madhuri12eee3@student.university.edu','9574374896','b71cedda5eeafd2e119d9f592c3cde062b71a90e1345e850e075fc300e45de8f',3,'Female','2004-07-13',N'Suresh Bansal',N'Indira Bansal',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3013',N'Rajesh Rajan','rajesh13eee3@student.university.edu','9994417154','6b2d27b087eac833ae5c27ebd8dfc195b8a0168a7288ccbf9087327c583533fb',3,'Male','2004-09-21',N'Jagdish Rajan',N'Bhargavi Rajan',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3014',N'Rekha Murthy','rekha14eee3@student.university.edu','9830965207','68b01abb4a4a512761f80af6657879314d6485afea847318ff88a0a2a99b96f4',3,'Female','2004-04-05',N'Suresh Murthy',N'Meera Murthy',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3015',N'Varun Bhat','varun15eee3@student.university.edu','9353875842','1d79212ff234336fa250c9eca3d5a90d28c08e138a6e0043eec534c22c59ec39',3,'Male','2006-12-19',N'Prakash Bhat',N'Pari Bhat',3,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3016',N'Divya Verma','divya16eee3@student.university.edu','9825135346','a0c2efaed5b4c2c05cb456108357b8c5f72367e8ae8765728ca1478ca4c0fe7c',3,'Female','2004-12-26',N'Vikram Verma',N'Riya Verma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3017',N'Nikhil Khanna','nikhil17eee3@student.university.edu','9999173816','ec61ecf3902d946292ad49f077494bd3465c957d60c04264812f35eafc5bd673',3,'Male','2002-08-02',N'Tarun Khanna',N'Sruthi Khanna',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3018',N'Saanvi Deshpande','saanvi18eee3@student.university.edu','9697252175','2ebbf13e53956b8bf63683fd727348d14119842ef482eb4e4639dc65b3ae1365',3,'Female','2003-04-11',N'Hitesh Deshpande',N'Sara Deshpande',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3019',N'Mahesh Singh','mahesh19eee3@student.university.edu','9292712966','bf381d137cb4ae699b571285210a0056f78c0e7e193b1920ed26d48d351cdccb',3,'Male','2004-04-25',N'Aarav Singh',N'Pallavi Singh',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3020',N'Usha Sharma','usha20eee3@student.university.edu','9058300335','a50390b275ced276b43bf858e95f43158990ae720d3cd58d1732ca94ef8f3809',3,'Female','2003-12-12',N'Vivaan Sharma',N'Vimala Sharma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3021',N'Pranav Tiwari','pranav21eee3@student.university.edu','9044789856','882c29b1bdd576d67ab8762d0f7f356e4702275f5eea1fbc0cb50b496ede7396',3,'Male','2003-02-27',N'Manoj Tiwari',N'Nisha Tiwari',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3022',N'Deepa Shetty','deepa22eee3@student.university.edu','9332309821','dec493aedc3d8c3b4421cf5f8deb3e8d71694bbd2b3e042f56aefff14ec63610',3,'Female','2003-07-01',N'Ramesh Shetty',N'Sneha Shetty',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3023',N'Alpesh Varma','alpesh23eee3@student.university.edu','9901001676','d31aa3d2c449faee2e400e8882c6a976a22d46e52b0a9a580607f2287b326789',3,'Male','2006-10-02',N'Nikhil Varma',N'Kavitha Varma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3024',N'Varsha Kamath','varsha24eee3@student.university.edu','9184992618','893a8be8f6317f8a674f9fca63b1aeddcbe953cfe6f462742672eeef550dc95e',3,'Female','2002-05-14',N'Reyansh Kamath',N'Pooja Kamath',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3025',N'Tarun Nair','tarun25eee3@student.university.edu','9348356420','e6757601f99de48a3cf2cfd3289e4d496ade7e5f6d70295e1576c6f5a49fb5ec',3,'Male','2005-04-20',N'Mukesh Nair',N'Navya Nair',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3026',N'Savitha Yadav','savitha26eee3@student.university.edu','9119721811','cc0fa3837627744c67c2e8a577aecdb60e0df40f0945fd93b3fc55d5658c2582',3,'Female','2002-01-22',N'Ravi Yadav',N'Lakshmi Yadav',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3027',N'Amit Chopra','amit27eee3@student.university.edu','9204556110','c345a401d507d6c566149a295abc2f57b3b91079992e98bd3b4f805ac621fe15',3,'Male','2002-02-27',N'Nikhil Chopra',N'Sruthi Chopra',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3028',N'Reshma Shetty','reshma28eee3@student.university.edu','9155216674','b75b9d6008bc56e170a681bb01b55706fcc9c6ffee76ce7e90ffd5cbdc8d34e0',3,'Female','2006-05-24',N'Jignesh Shetty',N'Pallavi Shetty',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3029',N'Girish Patil','girish29eee3@student.university.edu','9021697972','5e37a446d6a79f8dcc8f08572539cb4d121ee4f0d73a52e1994e2f67a5b556a2',3,'Male','2003-02-05',N'Dinesh Patil',N'Madhuri Patil',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3030',N'Sujatha Kumar','sujatha30eee3@student.university.edu','9167014508','d948f4bf01ac8fac136d8b4ef2b2af1432cc58311d612d1b4f045e405d267da3',3,'Female','2003-08-16',N'Rupesh Kumar',N'Lalitha Kumar',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3031',N'Yash Rajan','yash31eee3@student.university.edu','9916375628','e987b9bcc35e5f179e82a7f3fba89b2af2d311807d519e68cb7f10c0e176789b',3,'Male','2006-09-23',N'Rupesh Rajan',N'Reshma Rajan',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3032',N'Aadhya Murthy','aadhya32eee3@student.university.edu','9721753540','edab8515387d584810b48b62c884dd6ebdaf358be279ff1dc833252762fe1285',3,'Female','2006-08-28',N'Rakesh Murthy',N'Priya Murthy',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3033',N'Dinesh Bhat','dinesh33eee3@student.university.edu','9797177517','abd8b2bea9425539a6ed59c5d004d553460e75435826910ffb514fb6d23ad6e5',3,'Male','2003-02-15',N'Varun Bhat',N'Anusha Bhat',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3034',N'Latha Patil','latha34eee3@student.university.edu','9199488375','02f1e93a51087fba9a87972b981846c7ff58a965cbf8c40508009f9ca11f8bab',3,'Female','2006-01-27',N'Vivaan Patil',N'Sowmya Patil',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3035',N'Hitesh Saxena','hitesh35eee3@student.university.edu','9571130554','46996500c92c2be535fc00e5038441070a34eb9b201dfff52a1f6c8016e0b0c9',3,'Male','2006-10-16',N'Ravi Saxena',N'Sowmya Saxena',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3036',N'Savitha Verma','savitha36eee3@student.university.edu','9614933163','53079370be1ff979e7c6d3df4aaaaec39aa3d5e6d8d090cf79082493dd6af238',3,'Female','2005-03-27',N'Vivaan Verma',N'Priya Verma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3037',N'Arnav Naik','arnav37eee3@student.university.edu','9779827080','caa65abe05eb2e954645961acad67444b0f471f7cd3f64036d806f42261b075d',3,'Male','2006-02-25',N'Akash Naik',N'Pari Naik',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3038',N'Varsha Tiwari','varsha38eee3@student.university.edu','9216995866','7af4b448e592184c3ee3ce77ce505facf1cf8363da3f0978e2a5be832fd3b27e',3,'Female','2006-03-24',N'Sunil Tiwari',N'Kavya Tiwari',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3039',N'Varun Mishra','varun39eee3@student.university.edu','9698485833','25366f37f52a4f6d9d4c43064c2047ec991e7b983608cf2fbdf675acc6149a14',3,'Male','2005-03-05',N'Umesh Mishra',N'Divya Mishra',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3040',N'Lalitha Shetty','lalitha40eee3@student.university.edu','9288515879','46eda15cfc4c3151f33c154c3ab29ea9b4d4ba52f753247ff52ccd61e1bd9928',3,'Female','2003-12-21',N'Paresh Shetty',N'Lalitha Shetty',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3041',N'Tarun Kulkarni','tarun41eee3@student.university.edu','9062003424','a7197a6fe82c84b979b525f1e26a6e350ce805be3dd40ff3899dc08164826152',3,'Male','2002-09-04',N'Hitesh Kulkarni',N'Hema Kulkarni',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3042',N'Bhargavi Singh','bhargavi42eee3@student.university.edu','9805719838','cd40af31c50d9b2703690c1d96851beb0a1075727e7f407143d0722d58ee10d4',3,'Female','2004-04-25',N'Vinay Singh',N'Sridevi Singh',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3043',N'Mukesh Sawant','mukesh43eee3@student.university.edu','9066658004','30a09049de821d36845a60f36d24e0be425c75b1e69e003cbe97db133223d4f4',3,'Male','2004-12-22',N'Girish Sawant',N'Savitha Sawant',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3044',N'Bhargavi Pillai','bhargavi44eee3@student.university.edu','9933472122','8e321ab27af6284f747a1a47eaef7e9b141e56544437be7fa06283b35bc25398',3,'Female','2004-10-18',N'Paresh Pillai',N'Radha Pillai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20233EEE3045',N'Pranav Patel','pranav45eee3@student.university.edu','9294057202','513fb55f45111c50b1e4fa525b7ad224aa12c5ce5dccaed3d38c8a280307f788',3,'Male','2006-05-05',N'Kartik Patel',N'Sunita Patel',3,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5001',N'Aditya Salvi','aditya1eee5@student.university.edu','9798515832','e0995f9b88b0caa30615e3a16e35c59487a29c858dcd86706f56f3472e070af7',3,'Male','2006-11-10',N'Rakesh Salvi',N'Radha Salvi',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5002',N'Priya Patil','priya2eee5@student.university.edu','9335554398','c5f971e6fae1851b5889719b8001d218590e5c4e4050d01d9ed4a8e7677fafe3',3,'Female','2005-02-12',N'Arun Patil',N'Vimala Patil',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5003',N'Dhruv Rajan','dhruv3eee5@student.university.edu','9930561648','69fbc37ddc35315091bbe0a21d7d0fe321a40c56e64c5872fbd798b82a5164a6',3,'Male','2003-11-20',N'Deepak Rajan',N'Pallavi Rajan',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5004',N'Geetha Jadhav','geetha4eee5@student.university.edu','9704358112','26fcec8fe7cc8f27878acc482917851cf8d3a859f49835504b67c803c71c4aef',3,'Female','2006-09-15',N'Sunil Jadhav',N'Bhavana Jadhav',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5005',N'Aarav Varma','aarav5eee5@student.university.edu','9138612075','81ac524eaa5048005cb483c45f84fdb3652199f53748b544296abe6f32518ef7',3,'Male','2003-11-14',N'Vihaan Varma',N'Pooja Varma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5006',N'Saanvi Malhotra','saanvi6eee5@student.university.edu','9346676650','bda2c7e891ddada19657d29d5aee860cd861c8d947f906776b13e00277e5936a',3,'Female','2006-02-19',N'Mukesh Malhotra',N'Rekha Malhotra',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5007',N'Aarav Murthy','aarav7eee5@student.university.edu','9015814491','3e8d79da4f98f4257d48749fae03261868c8b8715311da297d1f4db0366b02a8',3,'Male','2002-12-19',N'Mohan Murthy',N'Sujatha Murthy',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5008',N'Latha Jadhav','latha8eee5@student.university.edu','9326842450','9dc29a25f4106dd0646377ff6eaee3a2770245f1f167ba86533e5e6703d05fbf',3,'Female','2005-03-18',N'Suraj Jadhav',N'Ananya Jadhav',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5009',N'Dhruv Patel','dhruv9eee5@student.university.edu','9814353682','4fa08a2277a9197fb07f48ef6f950004c5074d2b1be6a5fa7a7b94e60bedab65',3,'Male','2006-07-18',N'Aarav Patel',N'Nithya Patel',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5010',N'Sujatha More','sujatha10eee5@student.university.edu','9908781414','a045e075bba0432105aa36de002d88b16f4cf26e7464995befeec240d50f2e54',3,'Female','2002-03-22',N'Nikhil More',N'Sneha More',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5011',N'Sandeep Mishra','sandeep11eee5@student.university.edu','9913577594','c99c5688291e245934fcfbee24d540bc2a1c9761d935cdc6ac8138def8f7beb7',3,'Male','2003-02-10',N'Deepak Mishra',N'Riya Mishra',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5012',N'Nithya Kapoor','nithya12eee5@student.university.edu','9053364525','349a1f3a54e93c08abd74b49c7183a45519208810f78804e7414b292bfb70378',3,'Female','2004-07-06',N'Anand Kapoor',N'Madhuri Kapoor',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5013',N'Rahul Shetty','rahul13eee5@student.university.edu','9291428341','2aef4dffc972feca97fc9c7fc92dec791f45d6844c54458f3f319eeb2a69ff8b',3,'Male','2005-09-04',N'Sunil Shetty',N'Nisha Shetty',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5014',N'Smitha Varma','smitha14eee5@student.university.edu','9930848872','5a9deccd8ce3346700e29280d0835ec2464731cc4c1ff9cdf7761bec900fff31',3,'Female','2006-10-13',N'Arjun Varma',N'Anusha Varma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5015',N'Jignesh Salvi','jignesh15eee5@student.university.edu','9881658039','fad6e23970d598573c4182bae51fa8c9413d983661251a6bf5fa7ec24f6f04f6',3,'Male','2004-03-15',N'Manoj Salvi',N'Jyothi Salvi',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5016',N'Riya Jain','riya16eee5@student.university.edu','9275037314','bdf4f4ece3e2078e1814783843b5c3e5694a548d20d43df776c8e36d3c8365f1',3,'Female','2006-10-22',N'Kabir Jain',N'Kavya Jain',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5017',N'Suraj Krishnan','suraj17eee5@student.university.edu','9700518449','8e82c05d49bb8580c73c5e92a495e000d3ea606efdb26a0ee47e59356898d662',3,'Male','2004-07-16',N'Naveen Krishnan',N'Sridevi Krishnan',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5018',N'Usha Murthy','usha18eee5@student.university.edu','9184638655','6f3d49d2f48f87763917eaad15e8efd75a1ff1be809879b050192679c19d4c07',3,'Female','2006-11-27',N'Pranav Murthy',N'Bhavana Murthy',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5019',N'Aarav Tiwari','aarav19eee5@student.university.edu','9184322259','53e981885f8df5fb2c278f7a671a4bcadd0020631f4f454d1352272cf634991e',3,'Male','2005-03-08',N'Alpesh Tiwari',N'Riya Tiwari',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5020',N'Suma Pawar','suma20eee5@student.university.edu','9773926030','11acf0de0d314d52badb249797738d0dface17fcc79f21c36421dbed4f491a13',3,'Female','2002-08-22',N'Ravi Pawar',N'Jyothi Pawar',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5021',N'Kabir Iyer','kabir21eee5@student.university.edu','9024286990','12584e2474e7a08614ce02e67a64fbfaa4a09fc0c68e996a40722e144ac4b1bb',3,'Male','2002-10-05',N'Mahesh Iyer',N'Smitha Iyer',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5022',N'Pooja Jain','pooja22eee5@student.university.edu','9692929842','981cef0bfcade6e5b973a8f4ff596831e0c06bce2bd6d25fc5a87d36bbc8dc0b',3,'Female','2005-03-08',N'Sachin Jain',N'Varsha Jain',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5023',N'Sachin Khanna','sachin23eee5@student.university.edu','9103886291','7a3d777507e6af1b222a79816a6674bf4706cda0de71ee66ee41b41eec53bfe7',3,'Male','2005-07-05',N'Vihaan Khanna',N'Meena Khanna',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5024',N'Pari Kulkarni','pari24eee5@student.university.edu','9729806865','b4a499a07aac1b36a10e90b3b366f8d70a4b67f8c7d3a8018fa256b52adeccff',3,'Female','2006-02-03',N'Mukesh Kulkarni',N'Vimala Kulkarni',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5025',N'Kartik Pillai','kartik25eee5@student.university.edu','9991624731','afb44bf7cc766947211d766a0f36dfe9983e66f113a7181e130d158ba983777d',3,'Male','2005-07-12',N'Naresh Pillai',N'Madhuri Pillai',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5026',N'Suma Mehta','suma26eee5@student.university.edu','9180635651','49573c12c21aaf555fda54032c39827869da42e01c17d5f064731f4b3c62afd2',3,'Female','2002-10-17',N'Ishaan Mehta',N'Aadhya Mehta',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5027',N'Nikhil Mehta','nikhil27eee5@student.university.edu','9946368872','16d953b7479daea95c2e836e9595cf80bc30bebc37fb233e15c39c1966ff04d6',3,'Male','2005-10-12',N'Hitesh Mehta',N'Vimala Mehta',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5028',N'Varsha Mehta','varsha28eee5@student.university.edu','9213721386','b19836f273d0835846c7ecde8b0066a2796345cc341f79bff7813918b97a99fc',3,'Female','2004-12-13',N'Ganesh Mehta',N'Nithya Mehta',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5029',N'Lokesh Kamath','lokesh29eee5@student.university.edu','9012796114','6a115c09b00fd224ce70fcfa55c3c308dba045e8ae8d6cc394c4583a9ff933d6',3,'Male','2002-03-13',N'Tushar Kamath',N'Indira Kamath',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5030',N'Kamala Patel','kamala30eee5@student.university.edu','9849027703','bd7ce7760b3faaf5e3b2f33e11fa559a875d1478fdafd4e84ea3af5423d55c17',3,'Female','2005-10-21',N'Mohan Patel',N'Usha Patel',5,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5031',N'Ishaan Patel','ishaan31eee5@student.university.edu','9392053021','fecf1f667ce7167f570ea32e21a1f68bea40acf32ac29409737869567e884928',3,'Male','2006-09-23',N'Mukesh Patel',N'Kamala Patel',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5032',N'Shobha Kulkarni','shobha32eee5@student.university.edu','9118489554','0f0815b0dbcdcd9161b50c37aeb949635d127cd6456227a7164af8dfebb16f43',3,'Female','2003-09-01',N'Varun Kulkarni',N'Revathi Kulkarni',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5033',N'Amit Kulkarni','amit33eee5@student.university.edu','9818184518','c092717ff3ddc889450b9ae38a52217c2142ac1bece0682f52a9ba8cc29ee7a7',3,'Male','2004-03-14',N'Gaurav Kulkarni',N'Aadhya Kulkarni',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5034',N'Anusha Sawant','anusha34eee5@student.university.edu','9735779071','476b1a5db38dcc1860a2e636042b5f27da97bb8ee951c118d27bbf9893af517c',3,'Female','2005-07-19',N'Gaurav Sawant',N'Rekha Sawant',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5035',N'Mahesh Sawant','mahesh35eee5@student.university.edu','9588043416','0b9b5940facfd7106a9aeb7d20867ba8223879728154a393f0793ef843a246e3',3,'Male','2003-06-14',N'Yash Sawant',N'Lalitha Sawant',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5036',N'Sowmya Malhotra','sowmya36eee5@student.university.edu','9423733343','73ad0db747b2260aa483555bc287d2d30abe9eb225afa77a65303389cef9ff93',3,'Female','2004-04-19',N'Vikram Malhotra',N'Swathi Malhotra',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5037',N'Nitesh Lal','nitesh37eee5@student.university.edu','9790807595','3c6e500b8ca8f65fbe21c1792b627a5d70750c11795e864d964af170f2d15fcf',3,'Male','2002-02-03',N'Deepak Lal',N'Sara Lal',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5038',N'Deepa Malhotra','deepa38eee5@student.university.edu','9920867808','4e8d7f6359f764aec3752a50034da79ffdac6a5e1377b01b6f5a190841d725cc',3,'Female','2004-07-08',N'Ramesh Malhotra',N'Smitha Malhotra',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5039',N'Amit Nair','amit39eee5@student.university.edu','9003691559','5e40a602db4fa960707555d0b84d6f4048aff5c62a76b38c63205fe2729224db',3,'Male','2005-06-23',N'Vinay Nair',N'Geetha Nair',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5040',N'Sowmya Mehta','sowmya40eee5@student.university.edu','9527636556','aade9c9f64a4fbe261035f32407ac622d3c5beb55a255ea06bad5228f23701d5',3,'Female','2005-10-11',N'Rohan Mehta',N'Sunita Mehta',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5041',N'Gaurav Iyer','gaurav41eee5@student.university.edu','9438663227','34650167e76e986b8d8d6b351f25009df953af139980e6f65b6261c92f58668f',3,'Male','2003-02-24',N'Umesh Iyer',N'Nithya Iyer',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5042',N'Suma Ghosh','suma42eee5@student.university.edu','9574489061','94d82684ead726784a000b31fab4a91ea4ad160f0bee563d51af6c403b82b63a',3,'Female','2006-09-24',N'Atharv Ghosh',N'Radha Ghosh',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5043',N'Rudra Jadhav','rudra43eee5@student.university.edu','9545588450','bd171bbe26b5f5d7509e2b80dc377b3cc2dcc482fa29381b834ebdf771ac4796',3,'Male','2002-08-24',N'Nikhil Jadhav',N'Varsha Jadhav',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5044',N'Lalitha Trivedi','lalitha44eee5@student.university.edu','9824558771','54e4bb6269978d7e9723c84e18960b4be5351e7e88b73f4604c1e84f303bf263',3,'Female','2006-11-21',N'Ishaan Trivedi',N'Nithya Trivedi',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20223EEE5045',N'Amit Varma','amit45eee5@student.university.edu','9569961125','d60f083109f9e611ae6477b79ff33df4c91010d4712d19fc83cfe1960582ea05',3,'Male','2003-11-26',N'Jagdish Varma',N'Sara Varma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7001',N'Dinesh Chopra','dinesh1eee7@student.university.edu','9475987622','e7ae24364b49976c86c0c3aa4840f727507698b2360c7fbfd9f3222ae96d7061',3,'Male','2006-11-13',N'Suresh Chopra',N'Sunita Chopra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7002',N'Jyothi Joshi','jyothi2eee7@student.university.edu','9611178006','9059827f350e36d338c46ff4b2f9b88c0a34dbdb43122f2ffc5a02d61b41bc03',3,'Female','2002-04-06',N'Suraj Joshi',N'Rekha Joshi',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7003',N'Nikhil Lal','nikhil3eee7@student.university.edu','9347228200','4ec8fce58ffead683ff371593351ec8061d68426b1331762e403b758ecd07340',3,'Male','2005-05-08',N'Reyansh Lal',N'Ira Lal',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7004',N'Varsha Saxena','varsha4eee7@student.university.edu','9282997968','293dfd9220ad4c7d14c97bc865f1a62657f92d04c83f332fd850ab6d1118a94c',3,'Female','2004-09-15',N'Umesh Saxena',N'Vimala Saxena',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7005',N'Paresh Shetty','paresh5eee7@student.university.edu','9456424008','03306de6af531bcb6eb9ddcdd2f3593e4139a0b2d87f4275bbf38c904068ef9a',3,'Male','2003-02-15',N'Vikram Shetty',N'Vimala Shetty',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7006',N'Divya Yadav','divya6eee7@student.university.edu','9064930853','8bfb628f057a2cb67f358e18eef117cfc11da94ecd186c54e28403297ed21b6a',3,'Female','2005-08-10',N'Arun Yadav',N'Aadhya Yadav',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7007',N'Varun Joshi','varun7eee7@student.university.edu','9416389448','b909f8b949362be4b19a9eb5ebf551e71161bc54d05c43ee9c25b39d79906ab8',3,'Male','2005-07-08',N'Kabir Joshi',N'Indira Joshi',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7008',N'Sneha Shinde','sneha8eee7@student.university.edu','9797497350','90efd1b737c9719f29c6bc862cb008270806d3feeaf80dc38049be5dccb502c2',3,'Female','2003-05-04',N'Vihaan Shinde',N'Kavya Shinde',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7009',N'Arjun Malhotra','arjun9eee7@student.university.edu','9703120735','69ede665691371dfbea177aa9380786836409755adbb465ac7af968200a25f9a',3,'Male','2004-05-05',N'Umesh Malhotra',N'Navya Malhotra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7010',N'Bhavana Saxena','bhavana10eee7@student.university.edu','9204618723','35bebd058ca79cd2be7a129a3f58483e88a05c1a51866739fe4bea8425b716f0',3,'Female','2002-06-03',N'Vinay Saxena',N'Sridevi Saxena',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7011',N'Nitesh Sharma','nitesh11eee7@student.university.edu','9730371837','936d7465f2a4739198770721f76abca7454269f8f3db36b0b98af13d8e266460',3,'Male','2003-07-25',N'Dhruv Sharma',N'Kavitha Sharma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7012',N'Priya Varma','priya12eee7@student.university.edu','9474350313','8d42b06111abeb4801d09bc7eb843d320c33d8026b9b407f16d7086d667f4db7',3,'Female','2006-09-04',N'Mohan Varma',N'Pari Varma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7013',N'Aarav Das','aarav13eee7@student.university.edu','9300979251','a627d7962a8f393dffc845226ba0b1b83ddd2625361378ccf496641a6281985a',3,'Male','2006-02-13',N'Mukesh Das',N'Sunita Das',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7014',N'Ira Pillai','ira14eee7@student.university.edu','9281273585','55cad8869f1c49312db77e54dd23c77d4f14707d56e5e64ba86606e628fbd1d8',3,'Female','2002-01-12',N'Lokesh Pillai',N'Reshma Pillai',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7015',N'Arjun Kamath','arjun15eee7@student.university.edu','9778487392','43d00e565e0f0734332898c444725a7007d32502bcc6502ff95191c1c5c3eb34',3,'Male','2003-05-02',N'Pranav Kamath',N'Sangeetha Kamath',7,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7016',N'Jyothi Saxena','jyothi16eee7@student.university.edu','9182744857','e39339b932e80a112e3b92d312d32b533c85c3ee7cd6ec1c27f8f319e95e9b6b',3,'Female','2006-09-06',N'Kiran Saxena',N'Bhargavi Saxena',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7017',N'Mohan Malhotra','mohan17eee7@student.university.edu','9935186387','87f90115083fd6a51c023dbdd3896af7fe6bb3b8f0d04a9549102377e9dcce19',3,'Male','2006-06-25',N'Alpesh Malhotra',N'Ananya Malhotra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7018',N'Sujatha Chopra','sujatha18eee7@student.university.edu','9810220317','b969765c22b6495c875045956626c6a908da12c67b6d9a37cb41d4d83e8d41eb',3,'Female','2004-02-04',N'Harish Chopra',N'Suma Chopra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7019',N'Gaurav Murthy','gaurav19eee7@student.university.edu','9940539103','0428abc2baf90ea420000708d1ec01e9b74cb11babb72f04347e7f7ffca31658',3,'Male','2005-09-20',N'Nitesh Murthy',N'Usha Murthy',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7020',N'Sruthi Pawar','sruthi20eee7@student.university.edu','9650948014','5db108f1ea60a3e1e6d869566bddf443365c728980c20cc5c068720f664e5a97',3,'Female','2004-09-24',N'Mahesh Pawar',N'Saanvi Pawar',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7021',N'Arnav Verma','arnav21eee7@student.university.edu','9383928861','1b5a5119cad1412f1518b206076a9ff20f0fe4aefe2e425d59876f3e5520c5a8',3,'Male','2006-07-07',N'Mohan Verma',N'Meena Verma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7022',N'Lalitha Saxena','lalitha22eee7@student.university.edu','9286852897','76a2fd40b138e3a02fcac5c995bf50b47bd7eda506e56fe44a994ab92530f5e9',3,'Female','2005-02-06',N'Vinay Saxena',N'Shobha Saxena',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7023',N'Vishal Pandey','vishal23eee7@student.university.edu','9593983684','0be3657618fe56c1bb100144f5fa8a51cfe62dd56a8e10e271d996a7373ab839',3,'Male','2005-11-14',N'Hitesh Pandey',N'Bhavana Pandey',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7024',N'Latha Sharma','latha24eee7@student.university.edu','9824043350','7281372a487e45a39883bfe70a25eac4ff1314f26eb7ac602f1dc74c59ee9020',3,'Female','2004-10-01',N'Mohan Sharma',N'Pari Sharma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7025',N'Rajesh Bhatt','rajesh25eee7@student.university.edu','9752245933','264439f858d7e1f833e285421266a2d35c215df2a875d44c9396260f98ba4f49',3,'Male','2003-02-02',N'Gaurav Bhatt',N'Nithya Bhatt',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7026',N'Nithya Kulkarni','nithya26eee7@student.university.edu','9727919409','abd8158f3a4c35842f1ddce13d4c116266a4838b284bcd61e9d57a148cba4b1a',3,'Female','2002-12-11',N'Gaurav Kulkarni',N'Pooja Kulkarni',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7027',N'Paresh Salvi','paresh27eee7@student.university.edu','9139060480','a711178371caabacccb8d9bf26a16619b8d7b32202f2e5714ae7e84f863ba228',3,'Male','2005-07-28',N'Ravi Salvi',N'Sangeetha Salvi',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7028',N'Sara Pandey','sara28eee7@student.university.edu','9679981364','7d7d018a118982329eac629962f38c630a09aa72524eac1abe67805edab643ba',3,'Female','2003-03-02',N'Rajesh Pandey',N'Savitha Pandey',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7029',N'Atharv Mishra','atharv29eee7@student.university.edu','9864168622','4f2d0e8dd14c34d668ae5ee68eab04aa5ca3e720a5c0e7aac58d69dde86095ca',3,'Male','2006-12-02',N'Sai Mishra',N'Varsha Mishra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7030',N'Deepa Kulkarni','deepa30eee7@student.university.edu','9833146591','fe03d0daa57908c404d2a4aa5c099ee0a9d4e014d3e88c9f52749f4b0aceddba',3,'Female','2003-09-20',N'Dinesh Kulkarni',N'Nithya Kulkarni',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7031',N'Anand Shetty','anand31eee7@student.university.edu','9042597927','543b6a4e4af8af287c38d1531dd768f65d5a3726bfa1194ca4f7b9e1a447c301',3,'Male','2004-10-21',N'Ishaan Shetty',N'Swathi Shetty',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7032',N'Lalitha Naidu','lalitha32eee7@student.university.edu','9039240514','9ca0645e394d969f4d0941f77f62be04d25b5692e53206e4e5a1b95a6a10de22',3,'Female','2002-02-24',N'Reyansh Naidu',N'Amrutha Naidu',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7033',N'Ravi Krishnan','ravi33eee7@student.university.edu','9848792069','46ffe3dee815987e8094cb6795f7cf6c42459269c5e92dc316dfdf9625a98b50',3,'Male','2003-04-18',N'Prakash Krishnan',N'Vimala Krishnan',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7034',N'Rekha Das','rekha34eee7@student.university.edu','9407016451','1784d0b71555ce76e0c7e42f2778b7b0e3bd2abe601de91d988646be1dbbb959',3,'Female','2003-12-20',N'Aditya Das',N'Divya Das',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7035',N'Yash Bhat','yash35eee7@student.university.edu','9981238780','421ede876b206a086c5ccac5f3a9e986369ef6d737efdd467967a561c06883b2',3,'Male','2002-06-16',N'Rajesh Bhat',N'Indira Bhat',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7036',N'Nisha Mishra','nisha36eee7@student.university.edu','9554384046','1593946ef10ba31c1c3c17dac7f94951ebee68e48fd5a2121b6e8d9f604b880b',3,'Female','2003-01-12',N'Sandeep Mishra',N'Latha Mishra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7037',N'Naresh Shah','naresh37eee7@student.university.edu','9216893639','00b27f2ac28ed134fda810d02f89b5c6489c6b62797595875de4720ee47b843b',3,'Male','2004-07-22',N'Yash Shah',N'Sara Shah',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7038',N'Kamala Mishra','kamala38eee7@student.university.edu','9298324826','421117a8477e8e1b6a27c2c3cd4e13c0c5c04607db2bd6ce814cad339265937c',3,'Female','2003-04-21',N'Rahul Mishra',N'Vimala Mishra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7039',N'Paresh Das','paresh39eee7@student.university.edu','9125205664','45c28582f4a7d7014b2c3520fb6ca99954265283ad2f6fd02a802be0a26b813b',3,'Male','2006-09-24',N'Harish Das',N'Diya Das',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7040',N'Kavitha Rao','kavitha40eee7@student.university.edu','9994999393','23565b9627ece7f29433cd90455488b204ccbaf05dde4afb93a69e6e1237a703',3,'Female','2003-01-25',N'Arnav Rao',N'Riya Rao',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7041',N'Sai Kamath','sai41eee7@student.university.edu','9975267722','b8acbb26fd9b5c973f4198419b24c5e12efd5e3f3566c4bcf4f548298e832130',3,'Male','2003-09-28',N'Sunil Kamath',N'Varsha Kamath',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7042',N'Suma Naik','suma42eee7@student.university.edu','9331279757','4736c0534803b25027b1fd497dd9001c1a3e1a3392ed97c49bf232ecfd7561d2',3,'Female','2004-07-08',N'Umesh Naik',N'Aadhya Naik',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7043',N'Varun Salvi','varun43eee7@student.university.edu','9699988081','2c4da60bb00dfb3ce62044443ab214d22783657d52f4322bb4d13e111bc3cb9d',3,'Male','2005-12-11',N'Vivaan Salvi',N'Kamala Salvi',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7044',N'Lakshmi Dubey','lakshmi44eee7@student.university.edu','9803476447','e245d064f86d88751249763b257c04decd120ef25bb33d31eee5ff7f7347f24d',3,'Female','2002-09-13',N'Arun Dubey',N'Latha Dubey',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20213EEE7045',N'Lokesh Bhosale','lokesh45eee7@student.university.edu','9718129826','3ec4edc085144b82ed030ddf45c38dc9e7ed8d5eb25ba542fe6429f3932cadc8',3,'Male','2006-03-15',N'Aditya Bhosale',N'Savitha Bhosale',7,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1001',N'Amit Khanna','amit1mech1@student.university.edu','9452111751','7c0b844d4ab89d2711940549d10931c0385e63ae6376c784c2e03c3a741ea2aa',4,'Male','2003-08-03',N'Jignesh Khanna',N'Indira Khanna',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1002',N'Sujatha Das','sujatha2mech1@student.university.edu','9259222206','bef6f237c2108aa8bb37e890ff6f3be14387d975e4530c0548fd1352d4ea83ea',4,'Female','2005-01-25',N'Pranav Das',N'Sowmya Das',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1003',N'Tarun Varma','tarun3mech1@student.university.edu','9940777809','fe939d12a08505a5c210dd3343dc87f78eeb27b8b0f5d78e1b96dc89df384231',4,'Male','2003-04-01',N'Ayaan Varma',N'Kiara Varma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1004',N'Pooja Khanna','pooja4mech1@student.university.edu','9199038498','958737aa7bd6f37dc8275d31505faf4fce85f8364e684a9b8addf3c9feecde0a',4,'Female','2005-07-15',N'Suraj Khanna',N'Varsha Khanna',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1005',N'Ayaan Menon','ayaan5mech1@student.university.edu','9099451016','a9024df9e3154261b8fa330293cd03a6affdabf400e9c0148797594c13304cdc',4,'Male','2004-01-05',N'Aditya Menon',N'Meera Menon',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1006',N'Sujatha Rajan','sujatha6mech1@student.university.edu','9827950145','e8018a3b41e2da571e7ad996691175436a868a35f69d0f37be2e4113b92cc2c3',4,'Female','2006-10-26',N'Vinay Rajan',N'Savitha Rajan',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1007',N'Ramesh Desai','ramesh7mech1@student.university.edu','9214586833','0696cd2004ed6bbef5834ae25973b3fbef2582090b99fd1032325be6e67f02f9',4,'Male','2002-05-16',N'Nitesh Desai',N'Sowmya Desai',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1008',N'Nithya Shenoy','nithya8mech1@student.university.edu','9946954899','77f0b27cfb291490fc70406661fa2f4cb6366d2e6ef9b3ac17c5ebf352e72030',4,'Female','2006-02-16',N'Umesh Shenoy',N'Radha Shenoy',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1009',N'Sandeep Dubey','sandeep9mech1@student.university.edu','9293430107','99ce486a22b430af005a6baaa31b2efe3378ec9dd6cf1fbc16ba9930a1876c3c',4,'Male','2005-08-26',N'Mohan Dubey',N'Radha Dubey',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1010',N'Madhuri Lal','madhuri10mech1@student.university.edu','9830344144','3c8986f862cf8da26955de13f20c2200bf67f76e2068a467923a67fbafa29f59',4,'Female','2002-06-12',N'Akash Lal',N'Suma Lal',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1011',N'Sunil Sharma','sunil11mech1@student.university.edu','9990235577','a9415c5020d5106b9d5d6347d424ea8ac6ca3a2dde7a086a876ce721716f7246',4,'Male','2004-06-13',N'Dhruv Sharma',N'Lalitha Sharma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1012',N'Varsha Menon','varsha12mech1@student.university.edu','9608495880','6a80b5f2aafb1333364fe80bc388b85e86b4639e7404f016a77b9222707b1101',4,'Female','2006-06-15',N'Mahesh Menon',N'Sruthi Menon',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1013',N'Girish Bhosale','girish13mech1@student.university.edu','9405682996','3ff798b4fc4e839171adf0075233e0ab51716e0e37e8f7a2419598eea3bf4269',4,'Male','2004-02-05',N'Alpesh Bhosale',N'Sridevi Bhosale',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1014',N'Sridevi Naik','sridevi14mech1@student.university.edu','9461735743','a2622437975288fb852e2d46bba3d0f6fdbd8d5dba1e16095a4023ac1d8ca8b5',4,'Female','2004-12-02',N'Ganesh Naik',N'Indira Naik',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1015',N'Dhruv Naidu','dhruv15mech1@student.university.edu','9807823578','2416b33d10d44da8e11e01ae94ae7430a26483008547782fa5f950b1c6f250c3',4,'Male','2003-02-15',N'Mukesh Naidu',N'Pari Naidu',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1016',N'Kavitha Deshpande','kavitha16mech1@student.university.edu','9307681040','ba833a00caa50a7034aedd0af8668777ea0ea000905900c32c5169966e61471b',4,'Female','2006-11-05',N'Arnav Deshpande',N'Anusha Deshpande',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1017',N'Ravi Saxena','ravi17mech1@student.university.edu','9409435334','a9a99a9a1b2cd3d3d6470dff0aba66257fcfb84517400ce0bd563eb7711cb2a9',4,'Male','2002-09-25',N'Alpesh Saxena',N'Pari Saxena',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1018',N'Kavitha Jain','kavitha18mech1@student.university.edu','9410988138','a039006092efcf2582220f7b03540757dc174501805de23be84c3d7e4c39ed32',4,'Female','2004-03-06',N'Suraj Jain',N'Kiara Jain',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1019',N'Kiran Menon','kiran19mech1@student.university.edu','9214958702','78c20fcae712fd90777b7fff29ba157e39dd24f48c7c2a6eb3262268027cd88a',4,'Male','2004-10-08',N'Naresh Menon',N'Indira Menon',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1020',N'Navya Bhat','navya20mech1@student.university.edu','9997954538','c7c7e074472aab1e4ab578806f11c59464ae6f0c5161dc8aaad4a138080244da',4,'Female','2005-07-06',N'Aditya Bhat',N'Ira Bhat',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1021',N'Atharv Gupta','atharv21mech1@student.university.edu','9477332945','124797a9e4d2f88fbe3a7f7b4ef12c1e5a83c8ccda337a55c3073ce16ce77b0b',4,'Male','2005-02-15',N'Yogesh Gupta',N'Madhuri Gupta',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1022',N'Sridevi Deshpande','sridevi22mech1@student.university.edu','9171577245','fcf8157243e714ae5fbdb69b487ba48f38aeb5547f6aa5e9553cb42290859c93',4,'Female','2005-08-01',N'Alpesh Deshpande',N'Swathi Deshpande',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1023',N'Rajesh Verma','rajesh23mech1@student.university.edu','9148769639','8cce32449bc6b6929f7fcf03df20e8124abca440dbc9b2cb2d82be7d7116e336',4,'Male','2002-06-18',N'Varun Verma',N'Anusha Verma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1024',N'Varsha Bhat','varsha24mech1@student.university.edu','9669583219','081e7cb56fde711515b8e8f8050313773ee1688e300e815660f910a2774bd582',4,'Female','2003-12-19',N'Vihaan Bhat',N'Reshma Bhat',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1025',N'Manoj Trivedi','manoj25mech1@student.university.edu','9724619196','521194ed86acede0e5f6fad3a5e5cf9ef03a3f13b18738400b898a0b414943a1',4,'Male','2006-02-27',N'Amit Trivedi',N'Swathi Trivedi',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1026',N'Ira Krishnan','ira26mech1@student.university.edu','9022784699','ae5535d9e12988cea64c6d94209a1666908f7e0ee4679727eeccac1668981569',4,'Female','2006-11-26',N'Yogesh Krishnan',N'Riya Krishnan',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1027',N'Tushar Kulkarni','tushar27mech1@student.university.edu','9651909862','8511811f18c7d5a06ec0be90c9e0e7d87f0d02de95e8656a6884b7575e82fade',4,'Male','2006-11-10',N'Harish Kulkarni',N'Nisha Kulkarni',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1028',N'Bhavana Kale','bhavana28mech1@student.university.edu','9514036965','e63e79486725264e8d158eb935cb7e3a5fdd3e7948a141438ca19b7ab7551d88',4,'Female','2002-12-18',N'Vishal Kale',N'Saanvi Kale',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1029',N'Pranav Desai','pranav29mech1@student.university.edu','9386562422','a30ca14200b93fb542a0751d709ba55e3a967b1f98d36798a9a5d14590c34061',4,'Male','2003-08-05',N'Arun Desai',N'Pooja Desai',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1030',N'Sara Shenoy','sara30mech1@student.university.edu','9267969278','83fe3bea82be043f3e4aaf0da35ef2aa46f64e15d79300588cbef22fad0f7fe7',4,'Female','2005-03-03',N'Alpesh Shenoy',N'Deepa Shenoy',1,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1031',N'Pranav Shetty','pranav31mech1@student.university.edu','9973846895','23ee8cd2391d2b11f29c0dd6672b5849a18e416fb3bbcad8f7ffd9b5283832ef',4,'Male','2005-10-01',N'Yash Shetty',N'Kavya Shetty',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1032',N'Varsha Hegde','varsha32mech1@student.university.edu','9128478189','c2cdda82ab8c0e10ac8d0d4f01c3e46da8f5686cd12091c12c3062778ab417b2',4,'Female','2006-08-23',N'Anand Hegde',N'Kiara Hegde',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1033',N'Mahesh Gowda','mahesh33mech1@student.university.edu','9894905807','29f983e8018c4cf8589fdc2a23da9ce686858efa219313c4df65edd5ba95e2c0',4,'Male','2002-11-21',N'Suraj Gowda',N'Shobha Gowda',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1034',N'Reshma Patil','reshma34mech1@student.university.edu','9094940792','bf671666aadd81cd6f4a5e274e40d1d9bcc3d4a4c558cca28a0d108c5cb5c478',4,'Female','2004-05-06',N'Deepak Patil',N'Madhuri Patil',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1035',N'Girish Gowda','girish35mech1@student.university.edu','9281442944','d670135988f58d939a7ac40a81c6afb7e7a77a70a9dec3c9cd59bc3311732f73',4,'Male','2004-08-03',N'Lokesh Gowda',N'Ananya Gowda',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1036',N'Rashmi Nair','rashmi36mech1@student.university.edu','9752437280','e5c1ebc1b8b640a2f0dd3ea433b55a847e19a93fd9173df0147ba3321f87a4fd',4,'Female','2006-12-05',N'Sachin Nair',N'Kavya Nair',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1037',N'Sachin Jadhav','sachin37mech1@student.university.edu','9637239504','0fa59758fe3e9cdb1548a91980551a966c8e805249f6872a6b7ba94b13a13069',4,'Male','2005-07-25',N'Reyansh Jadhav',N'Bhargavi Jadhav',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1038',N'Priya Saxena','priya38mech1@student.university.edu','9836674286','28556f7f930231d9dcaf1f561e23249a9da9f2962b7ef674547cbaf30c9ad581',4,'Female','2004-08-24',N'Varun Saxena',N'Varsha Saxena',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1039',N'Pranav Pillai','pranav39mech1@student.university.edu','9569454414','559f5072dd5e58f346be8e7e8e2214be194abec75ea99375fbd0622e6b54dc18',4,'Male','2002-02-18',N'Harish Pillai',N'Geetha Pillai',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1040',N'Sruthi Salvi','sruthi40mech1@student.university.edu','9938525800','6dee1f48175efc5aefa0ca21131f0262379cfc21428ec6e849b7541b82d4bec8',4,'Female','2003-12-22',N'Tushar Salvi',N'Rashmi Salvi',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1041',N'Akash Verma','akash41mech1@student.university.edu','9443009109','7a26abef6af7b64336b9638102ca3ff68e8e0bce3876d5f227b2a929618f2907',4,'Male','2005-06-08',N'Naveen Verma',N'Navya Verma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1042',N'Radha Nair','radha42mech1@student.university.edu','9692124471','38cfe1ca21dbe64dc6486ed55d0765d7720ad98b54d6c4402046536696650e6b',4,'Female','2002-10-05',N'Suresh Nair',N'Kiara Nair',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1043',N'Sunil Desai','sunil43mech1@student.university.edu','9140665044','a399b53f2212838c3758fea5d044161dae31a549a8a7fb75304834a024db7ca3',4,'Male','2004-05-06',N'Vinay Desai',N'Shobha Desai',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1044',N'Deepa Rao','deepa44mech1@student.university.edu','9128639174','f05c7931fa21460d41b1ce86d79d610419abd37c25cdbff7da1e37d6b01064b5',4,'Female','2003-11-16',N'Lokesh Rao',N'Latha Rao',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20244MECH1045',N'Vihaan Kapoor','vihaan45mech1@student.university.edu','9200642569','48fe71d1bfe799b94160caedfeeb760f3f701bfed381d29f8f63b939b74217df',4,'Male','2005-01-16',N'Mohan Kapoor',N'Rekha Kapoor',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3001',N'Vikram Desai','vikram1mech3@student.university.edu','9067198554','537a13ba87cc4dd580e4a65edc2115accac529e1e07aad1c21c57158773882a8',4,'Male','2002-09-08',N'Varun Desai',N'Jyothi Desai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3002',N'Bhavana Agarwal','bhavana2mech3@student.university.edu','9432806346','7f3d3f645003b92980944cb694c10ff95cf4d387ac5e1042c31b6b19605d83dc',4,'Female','2002-08-25',N'Hitesh Agarwal',N'Reshma Agarwal',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3003',N'Sandeep Gupta','sandeep3mech3@student.university.edu','9203093761','e36aa95d74de4d78cb810af549349f9e3dc889d7301ff8144b7c2d31579ca3c0',4,'Male','2005-12-07',N'Alpesh Gupta',N'Radha Gupta',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3004',N'Deepa Agarwal','deepa4mech3@student.university.edu','9505061387','92590bc89047808491e92705efdc1f9958cb61e63f0f14e7ca877573b0f59235',4,'Female','2005-01-02',N'Jagdish Agarwal',N'Bhargavi Agarwal',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3005',N'Prakash Khanna','prakash5mech3@student.university.edu','9707903202','a538d6f9a31f20350bca37824cf1d56675f4495f95d6aad3cd7e665f9c9a584f',4,'Male','2002-12-05',N'Yash Khanna',N'Diya Khanna',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3006',N'Navya Saxena','navya6mech3@student.university.edu','9117993136','0a681622c93c9a5f196a26d66263ac7062a041afa8b63d3806a8cd1a1c8c1cac',4,'Female','2006-02-27',N'Lokesh Saxena',N'Priya Saxena',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3007',N'Dhruv Pillai','dhruv7mech3@student.university.edu','9309251142','e6079c3ad66d11519bf9180274664445ddd8b52a3575758b28ba061b94299bfb',4,'Male','2003-06-27',N'Gaurav Pillai',N'Vimala Pillai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3008',N'Savitha Naidu','savitha8mech3@student.university.edu','9021962071','806e47edc882961c715f61bba8df17b7420ad5a4e5c604787b6ec6dcff2b0729',4,'Female','2005-04-19',N'Vishal Naidu',N'Priya Naidu',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3009',N'Rakesh Gupta','rakesh9mech3@student.university.edu','9723248763','869048a427f1aabe4d7168d52ff6d89a53b08e525099055b37f5ae07e4f36a7e',4,'Male','2006-05-14',N'Suresh Gupta',N'Meera Gupta',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3010',N'Kamala Malhotra','kamala10mech3@student.university.edu','9456083318','8f8e6edcfa7d83cca4f005fd223f6656e8c021a8d419e4bff991a033cf018bcd',4,'Female','2006-02-21',N'Suresh Malhotra',N'Deepa Malhotra',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3011',N'Rupesh Naik','rupesh11mech3@student.university.edu','9340312772','d7c977039444eac4bfcd80544ffd6bacf63f37d1e56bf44fad3bcb602f5ed31e',4,'Male','2003-08-25',N'Arun Naik',N'Smitha Naik',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3012',N'Meera Naidu','meera12mech3@student.university.edu','9970108220','9d2e3becb18c62e79a32bd5e8e264861eac78c93222c697c9ce7c662a13c7436',4,'Female','2005-05-11',N'Tarun Naidu',N'Pooja Naidu',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3013',N'Vihaan Kale','vihaan13mech3@student.university.edu','9563531531','6c8811b01a0e314e0f619cbd88325cb5bf5db5c395102d702bc72093d0494843',4,'Male','2005-10-19',N'Rohan Kale',N'Jyothi Kale',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3014',N'Usha Kale','usha14mech3@student.university.edu','9062397265','52bb67ffb6c8e730a39a63a8aee954a99ed02d9722a93e7b26748a7e7442ab85',4,'Female','2005-10-16',N'Yash Kale',N'Diya Kale',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3015',N'Mahesh Shetty','mahesh15mech3@student.university.edu','9090421776','d95da356e52b14b440f8808bc5c202f7ef1d4acb6dd74d9057a824adf4915cea',4,'Male','2003-06-05',N'Umesh Shetty',N'Sunita Shetty',3,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3016',N'Divya Trivedi','divya16mech3@student.university.edu','9831687397','7e251b236868eb9724ec7e7e6a8b74d39287c174a81ee99ad72a0fdcf246d024',4,'Female','2006-03-19',N'Kabir Trivedi',N'Sridevi Trivedi',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3017',N'Aarav Shenoy','aarav17mech3@student.university.edu','9693929060','663a995664501a0705034cf0742373f4828d4b58768c6667dab2e0e98a570979',4,'Male','2003-04-11',N'Kartik Shenoy',N'Rashmi Shenoy',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3018',N'Pari Desai','pari18mech3@student.university.edu','9177318063','97cb02450ed43bb0a500ef2210b5ba5f62bf5178cc6264de7cb5edef546e0581',4,'Female','2005-12-27',N'Naveen Desai',N'Latha Desai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3019',N'Rohan Murthy','rohan19mech3@student.university.edu','9279907726','d20c257b1940197e02a7f214de07eb1eba66f2c5d5cac425c4a40a521bd29601',4,'Male','2005-11-10',N'Sai Murthy',N'Ananya Murthy',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3020',N'Indira Varma','indira20mech3@student.university.edu','9580464989','a709e140c04e54975d5f633a9ad445e2cb5f88e6b4a9dd05fb62597ae7228c76',4,'Female','2002-07-23',N'Aarav Varma',N'Radha Varma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3021',N'Lokesh Kulkarni','lokesh21mech3@student.university.edu','9501657905','9b035b127453f9aea5de88eafeed7ad29d40e32f02fae3665d4cb0b695f436c2',4,'Male','2002-09-22',N'Ravi Kulkarni',N'Rashmi Kulkarni',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3022',N'Indira Reddy','indira22mech3@student.university.edu','9381793355','7c1e29b7425e6b1f38d3cf9a5f691ae182c1a49e0bd39d5c7717d764b993323e',4,'Female','2003-03-11',N'Vishal Reddy',N'Indira Reddy',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3023',N'Tushar Desai','tushar23mech3@student.university.edu','9778817884','cc5834aef79d6289008e893b6e018b2539918c19457c9998a2919df5c9ae8dda',4,'Male','2002-06-12',N'Kiran Desai',N'Saanvi Desai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3024',N'Madhuri Pillai','madhuri24mech3@student.university.edu','9116241124','f067380a4e45c17a1cb67c2f37c91b42c313ab4dbc1e5064826aeae4f6acd6c8',4,'Female','2002-04-15',N'Naresh Pillai',N'Savitha Pillai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3025',N'Reyansh Deshpande','reyansh25mech3@student.university.edu','9827567043','96ce676f0a8701575a7f9ad4df8883aa5451acc8fb886f3f2168f561cb6ac105',4,'Male','2002-05-14',N'Rudra Deshpande',N'Geetha Deshpande',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3026',N'Bhargavi Dubey','bhargavi26mech3@student.university.edu','9579887749','ed66c79b1265b73ffd83aafe513e77575dd11273a5749c7367365ac6c235c615',4,'Female','2005-10-11',N'Dinesh Dubey',N'Reshma Dubey',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3027',N'Mukesh Mehta','mukesh27mech3@student.university.edu','9025472928','61278b48627e43d3c1a3eef5554d5bb4ebc58b2553e9620591e3ae5cb750e181',4,'Male','2004-05-25',N'Yash Mehta',N'Varsha Mehta',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3028',N'Bhargavi Hegde','bhargavi28mech3@student.university.edu','9105927452','d8e250aa19005f4d14e97b303b08d7bf00eb91ceb2763d386a59385ec54f2477',4,'Female','2003-03-08',N'Vinay Hegde',N'Shobha Hegde',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3029',N'Suraj Pandey','suraj29mech3@student.university.edu','9828410672','688a4bcac2668efc065e156cf6106dcbaa1802bfe790002920680b11e108933e',4,'Male','2003-06-15',N'Umesh Pandey',N'Sangeetha Pandey',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3030',N'Sara Sharma','sara30mech3@student.university.edu','9474929751','3675051df8dd2ec5ef7f742d0f0bc864ad98c2109dd17a4ec441ecba8829db69',4,'Female','2006-09-11',N'Umesh Sharma',N'Rashmi Sharma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3031',N'Atharv Pillai','atharv31mech3@student.university.edu','9937515093','c013db1ed033f408e303a6892032e66b70a1225301398d26382f592a9296536f',4,'Male','2004-01-13',N'Vishal Pillai',N'Kiara Pillai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3032',N'Sridevi Salvi','sridevi32mech3@student.university.edu','9718637599','b991998088aec01e09cf5ccbd4c400a52bf0276fa6a8ebcbf1a697619c2a857a',4,'Female','2002-02-18',N'Kiran Salvi',N'Sneha Salvi',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3033',N'Varun Menon','varun33mech3@student.university.edu','9045547813','f836de8ec498405ef95cea0e04b2c3e18a7e91aee903d8caa2c44a3fae3e488d',4,'Male','2004-07-12',N'Suresh Menon',N'Hema Menon',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3034',N'Madhuri Jain','madhuri34mech3@student.university.edu','9299123478','4787423212a96debd7544e4a6619a24f9a42740dcc8a25ad3ab47406c241ae10',4,'Female','2005-12-14',N'Tarun Jain',N'Priya Jain',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3035',N'Ramesh Bhat','ramesh35mech3@student.university.edu','9628792326','7130330038f1c16bd3d876951e0bb703c7cdc7de0ddf9549bed750306f80bb50',4,'Male','2005-11-09',N'Sai Bhat',N'Aadhya Bhat',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3036',N'Pari Jadhav','pari36mech3@student.university.edu','9873002447','72e61d535012a1dabead7eda923419c5952d73b7c4fa95e46a5248ccf44cbff3',4,'Female','2006-05-16',N'Yogesh Jadhav',N'Nisha Jadhav',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3037',N'Ayaan Ghosh','ayaan37mech3@student.university.edu','9471959796','a19a89a9cdba223d7175ba15cb84aef9291b20c2722594f5aca8cf07fbf9dc7f',4,'Male','2003-01-04',N'Paresh Ghosh',N'Savitha Ghosh',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3038',N'Savitha Jadhav','savitha38mech3@student.university.edu','9042902572','aa3c1c5531f46e38cd960051c5e61aba738321fb63f8cdb5a17a2898dc11ae29',4,'Female','2006-12-19',N'Dhruv Jadhav',N'Bhavana Jadhav',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3039',N'Kiran Naidu','kiran39mech3@student.university.edu','9481832192','8b631dbf9974a000a992204aced8763dc2caa6a6813db0c1c3ad034e91ca4d2b',4,'Male','2004-01-10',N'Akash Naidu',N'Radha Naidu',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3040',N'Anusha Shinde','anusha40mech3@student.university.edu','9518952028','0c31b10c93f6d6618540e826445a6e5fab17117b46f886fd969dbfae16bce34f',4,'Female','2004-05-22',N'Tushar Shinde',N'Madhuri Shinde',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3041',N'Akash Mishra','akash41mech3@student.university.edu','9833898881','0b49e4e02b20df1924eb75bb70fd485955801995d73cacb7d23503335ee023f6',4,'Male','2002-04-05',N'Paresh Mishra',N'Priya Mishra',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3042',N'Kiara Jadhav','kiara42mech3@student.university.edu','9527985240','875c5fc33a65f341d7f47218c27b34f3218e8d51bbfb740e679398ed9ed0b042',4,'Female','2005-06-10',N'Atharv Jadhav',N'Ananya Jadhav',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3043',N'Atharv Shinde','atharv43mech3@student.university.edu','9321611076','4f863e87352e076402369c094cc16937058085e53e2db6a2a5f36b078119548d',4,'Male','2003-05-05',N'Vinay Shinde',N'Sara Shinde',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3044',N'Pari Sawant','pari44mech3@student.university.edu','9140140119','151c5e0d92fd72d9be42bb6aebf9fb6c5066e69b775c3bda570165de5df72316',4,'Female','2006-01-16',N'Suraj Sawant',N'Smitha Sawant',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20234MECH3045',N'Ayaan Rajan','ayaan45mech3@student.university.edu','9495528938','649c85ddf03a08deae6a7370fe8d6e15ad9bc6248ab0ee3f8a33befd519e255a',4,'Male','2002-03-28',N'Deepak Rajan',N'Ananya Rajan',3,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5001',N'Yogesh Khanna','yogesh1mech5@student.university.edu','9342801387','6c6a8c425e21df49233a8c058d9fb5b88cbbe6c009f40834e6f900e5083acb3f',4,'Male','2006-04-23',N'Ramesh Khanna',N'Aadhya Khanna',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5002',N'Pallavi Pillai','pallavi2mech5@student.university.edu','9638361517','652e23ca772593a8b6e56c0b8e541c20f0bebf59938b8413c8434ceaa33a8b2d',4,'Female','2003-06-13',N'Jagdish Pillai',N'Navya Pillai',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5003',N'Sandeep Naik','sandeep3mech5@student.university.edu','9015716479','71b5e1e180e6601a55d52f1009411d8a952954eb3c4dafbe9fc63112ae301bc5',4,'Male','2004-09-24',N'Anand Naik',N'Indira Naik',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5004',N'Meena Bhatt','meena4mech5@student.university.edu','9175207167','afc2665bdda38acc4aaa375a57216c6bf10e7e49fb91a6680c2d6a2c343b209e',4,'Female','2005-04-28',N'Akash Bhatt',N'Divya Bhatt',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5005',N'Reyansh Kulkarni','reyansh5mech5@student.university.edu','9215353961','737f4229890f73cd012d8a4ca85e9c4b4a65adc155de44ee265d37f0ac26a01e',4,'Male','2006-02-24',N'Varun Kulkarni',N'Savitha Kulkarni',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5006',N'Sunita Naik','sunita6mech5@student.university.edu','9657967842','067575536b57e86869bb0d9042becd698bb4ebd23583787f5681d4c537daefb6',4,'Female','2006-10-09',N'Suresh Naik',N'Kavitha Naik',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5007',N'Dhruv Mehta','dhruv7mech5@student.university.edu','9010170269','08ce5d62607c6c71976f2d2e891849a67ea588d0d970cb09f5ab5f38838b6b28',4,'Male','2003-11-05',N'Sandeep Mehta',N'Deepa Mehta',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5008',N'Nisha Lal','nisha8mech5@student.university.edu','9877347784','25f034d4dee474de1cd7ecdd4f583c101030a47c8de2073019e4895de431c5ea',4,'Female','2002-11-25',N'Lokesh Lal',N'Navya Lal',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5009',N'Vivaan Desai','vivaan9mech5@student.university.edu','9677002842','61faad9f45088d9412925ec6d1b65ff4511fad806554ccc45119318470b1f673',4,'Male','2005-08-11',N'Alpesh Desai',N'Kiara Desai',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5010',N'Nisha Hegde','nisha10mech5@student.university.edu','9788977828','67c4ffc8d4f7445ce66e43c1a08e933df92de8dabd8699fe67360b5931cadf77',4,'Female','2002-10-22',N'Pranav Hegde',N'Deepa Hegde',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5011',N'Sandeep Khanna','sandeep11mech5@student.university.edu','9450090255','d1557d20b1c0f1024b1463c0d21638df7b63975193dc0c420c329b0478dd196e',4,'Male','2006-11-12',N'Umesh Khanna',N'Usha Khanna',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5012',N'Amrutha Kale','amrutha12mech5@student.university.edu','9556503334','3033ef5fe21f121aedbb7e3aa3a91c9aacbc5db0b9c32b10e4c2570da0c84035',4,'Female','2005-02-14',N'Mahesh Kale',N'Reshma Kale',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5013',N'Rupesh Bansal','rupesh13mech5@student.university.edu','9507698640','0180fa1c1b9fde2043557329e44b308b8e981cf56277f6e08cfcaa829f5041ea',4,'Male','2003-01-18',N'Dhruv Bansal',N'Reshma Bansal',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5014',N'Ananya Pandey','ananya14mech5@student.university.edu','9171357852','b08a8fd891ed1eafaee01eec70fbb411b83d255ce9ce9146fad3f89334e8cf0d',4,'Female','2005-06-19',N'Pranav Pandey',N'Nithya Pandey',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5015',N'Umesh Desai','umesh15mech5@student.university.edu','9440496391','67162354b95f76782c9c907340668b2dfaa75840f6762e40bb1fa53c728d1505',4,'Male','2002-09-07',N'Ishaan Desai',N'Deepa Desai',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5016',N'Revathi Mishra','revathi16mech5@student.university.edu','9635148468','b3f02dc13aa7fcea5f0bcd480297d32c48a47363942b2fc2375b95367e142eb2',4,'Female','2006-09-16',N'Kiran Mishra',N'Diya Mishra',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5017',N'Lokesh Tiwari','lokesh17mech5@student.university.edu','9829737489','fd2322b5ce2a8b88dbc77647e40a41dc9b87a2f90e010803a90611684a9df6b2',4,'Male','2006-03-01',N'Amit Tiwari',N'Shobha Tiwari',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5018',N'Jyothi Varma','jyothi18mech5@student.university.edu','9232466513','8dc32282dedd7b1302d47e895c060dcd9ace35c7ef608805118aa2c9dfb4ea29',4,'Female','2003-06-15',N'Aditya Varma',N'Geetha Varma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5019',N'Yogesh Chopra','yogesh19mech5@student.university.edu','9363123034','d42341bdb1c43a7351d9b5827eda569cdca8b735fbe6dbbbd9d56e5af9f40cf3',4,'Male','2004-11-20',N'Dinesh Chopra',N'Priya Chopra',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5020',N'Hema Desai','hema20mech5@student.university.edu','9204482070','abda4e948d50c59ccde211c9a95e68321862f1ddc13047fa2e0f55fd58bb0e71',4,'Female','2003-03-09',N'Dinesh Desai',N'Pari Desai',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5021',N'Sachin Bansal','sachin21mech5@student.university.edu','9162319818','e02d0c5e4ba77312e2310e41fd67aa20cf3a228e8f7e2ded921bd6fbddd55fac',4,'Male','2005-06-22',N'Rupesh Bansal',N'Diya Bansal',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5022',N'Rekha Ghosh','rekha22mech5@student.university.edu','9559636321','e91cea6d8446d74e6863bcfc4687879cff23a8e14963710f03e84d311af6f877',4,'Female','2003-10-04',N'Alpesh Ghosh',N'Ira Ghosh',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5023',N'Rahul Patil','rahul23mech5@student.university.edu','9515867342','a7dd91723dbe13725d8426c18d705f634fadd4648adbe15743945266af678ff9',4,'Male','2002-08-18',N'Nikhil Patil',N'Revathi Patil',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5024',N'Anusha Bansal','anusha24mech5@student.university.edu','9034864518','7694e597a3d025c7c5086a78182350caaeb55b007d36e06f4db41f94f61524b1',4,'Female','2006-01-27',N'Arjun Bansal',N'Meera Bansal',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5025',N'Pranav Sharma','pranav25mech5@student.university.edu','9343275604','d32a9f7f422ea5c88d601aae2d32a7102cd223b25b158e9b252995cd12677ab3',4,'Male','2004-05-03',N'Paresh Sharma',N'Latha Sharma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5026',N'Varsha Gowda','varsha26mech5@student.university.edu','9124815698','75b9b370cb6743286a6f8be0bf41fe9be2c91bb29ace763bf52141b0c47d9f70',4,'Female','2004-12-14',N'Akash Gowda',N'Bhargavi Gowda',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5027',N'Vinay Kumar','vinay27mech5@student.university.edu','9206345911','6f50571cd268194713c96e460222ad698e062165b6aebb76747985b64c69f36f',4,'Male','2003-11-15',N'Ramesh Kumar',N'Saanvi Kumar',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5028',N'Indira Salvi','indira28mech5@student.university.edu','9657724295','ed516f1875978bee603530b47c1d1f0f1a67f4e2131ed7fd3fb2e065ddbe8cde',4,'Female','2003-10-22',N'Nitesh Salvi',N'Meera Salvi',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5029',N'Sai Patil','sai29mech5@student.university.edu','9930089317','a2a60d8271d3343b070987f62c8e303b6b98d9d3fdbe015aeb1ad20c0d76bbab',4,'Male','2005-07-27',N'Anand Patil',N'Kavya Patil',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5030',N'Sujatha Desai','sujatha30mech5@student.university.edu','9291086771','1b3ac69bd7112ed3e9495010efbe7c4cf9c339f2b6b8bf3a0622e2cf01b3235a',4,'Female','2003-02-12',N'Sachin Desai',N'Rekha Desai',5,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5031',N'Naresh Deshpande','naresh31mech5@student.university.edu','9762639343','c1d6e7022ffd2d2ce03a3644e7f66fa495c819c51a48d142819d44a07e80f3ec',4,'Male','2004-05-24',N'Yogesh Deshpande',N'Sridevi Deshpande',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5032',N'Sridevi Menon','sridevi32mech5@student.university.edu','9735971072','072dc9a5dc4f86148f45cf7b5a5005b163514e58fe750a17d603d0db5cb536ae',4,'Female','2004-04-20',N'Arjun Menon',N'Divya Menon',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5033',N'Tushar Krishnan','tushar33mech5@student.university.edu','9411800537','195a7652ec48c42923249cc9e07ee4a1c37414399ed4811b0828c2ff82c13a20',4,'Male','2005-12-20',N'Suresh Krishnan',N'Usha Krishnan',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5034',N'Shobha Pawar','shobha34mech5@student.university.edu','9896465280','b3b7d9d012f460475592e1697ef50ee4dcfa9ec20d3e917ebdf9e8c9a003f6c3',4,'Female','2002-01-09',N'Sachin Pawar',N'Indira Pawar',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5035',N'Kabir Tiwari','kabir35mech5@student.university.edu','9586241502','d3c9bcd0213b0495d98a97053161ceca65c76803ecd544ad9b3a99526369a67c',4,'Male','2005-03-03',N'Sandeep Tiwari',N'Reshma Tiwari',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5036',N'Hema Chopra','hema36mech5@student.university.edu','9562572870','00fdffd2df8bf6f7669fa313c6fe7bb16bf9e2f8866b8cb5bcbbdc99bbaf4acc',4,'Female','2006-05-17',N'Jignesh Chopra',N'Rekha Chopra',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5037',N'Yash Malhotra','yash37mech5@student.university.edu','9761707587','9cde82e4a21cf95ad404cc44e954fe46e273aff85581faee71797e9c3d086ff9',4,'Male','2004-03-23',N'Vivaan Malhotra',N'Varsha Malhotra',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5038',N'Jyothi Deshpande','jyothi38mech5@student.university.edu','9422849939','02bf06a4ceb986bd816d86835b376793f8b77f4b1d630dd4bbf6a95fb56abf8e',4,'Female','2004-02-07',N'Reyansh Deshpande',N'Kiara Deshpande',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5039',N'Sunil Kapoor','sunil39mech5@student.university.edu','9715041659','1178d518389f56638d615831051730d010aaa5c238bcf592d57949a48e33d49d',4,'Male','2002-04-25',N'Ayaan Kapoor',N'Suma Kapoor',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5040',N'Sara Kumar','sara40mech5@student.university.edu','9490509759','9207da57b9bb57090320ba3bc9b31c16720e41156900eab6454bc09f0b3d3ecd',4,'Female','2005-08-21',N'Sai Kumar',N'Sruthi Kumar',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5041',N'Girish Murthy','girish41mech5@student.university.edu','9896164236','b9d842b5e151592dcd45affccaf265296f8bc7115322bc2cd37703100a1767ab',4,'Male','2002-12-03',N'Tarun Murthy',N'Swathi Murthy',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5042',N'Kavitha Kulkarni','kavitha42mech5@student.university.edu','9764925158','4ddc2db52c17f402b266b6b0c99f35c5be60112500b549cbe3bd6080cc0ab9c6',4,'Female','2003-02-10',N'Tarun Kulkarni',N'Meera Kulkarni',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5043',N'Alpesh Bhat','alpesh43mech5@student.university.edu','9165926610','fe81a7c94760ee49af4e0c3ceeb5dbf7b5b592f8488a52a42ea112ad92851188',4,'Male','2006-10-14',N'Vikram Bhat',N'Sunita Bhat',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5044',N'Lalitha Pillai','lalitha44mech5@student.university.edu','9814761742','a484351868239ba9ab333f85fb8bad5fe49ef0fe272141dcc6e92a43fc697028',4,'Female','2003-08-17',N'Dinesh Pillai',N'Lalitha Pillai',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20224MECH5045',N'Naveen Desai','naveen45mech5@student.university.edu','9081866179','e107f4ee69aa26c58a83e5a03f9470231e230036a824f64b3b7c646ea4dd6ec2',4,'Male','2002-09-03',N'Tarun Desai',N'Nithya Desai',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7001',N'Sai Salvi','sai1mech7@student.university.edu','9722601645','c53f39f58e2a08ad34204adc20b3bf1b664fe3e2f4009c153fbd8433eea91bbc',4,'Male','2002-12-22',N'Rajesh Salvi',N'Ananya Salvi',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7002',N'Rekha Mishra','rekha2mech7@student.university.edu','9194168006','7fdcd5db3ea8fab8ad91f1c6b988f05a3186dd0efd21fc9fdfb4390b8919afc7',4,'Female','2003-04-06',N'Jagdish Mishra',N'Madhuri Mishra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7003',N'Dinesh Yadav','dinesh3mech7@student.university.edu','9974995641','67ad5f015793b9d428323dbb49412bcbe8ff32fa1a6a4ead32590ad51e3b3918',4,'Male','2005-11-24',N'Amit Yadav',N'Savitha Yadav',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7004',N'Sneha Nair','sneha4mech7@student.university.edu','9723683147','1c7aae869d7af61924802afb75a70b01f38a3c07c8633e4ff429fc7308716034',4,'Female','2003-01-07',N'Yogesh Nair',N'Ananya Nair',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7005',N'Arjun Nair','arjun5mech7@student.university.edu','9079334960','a55ec7938f475d047072b710be56e1835f66fc0f879e2c09d6e6da7b50903ca0',4,'Male','2005-08-16',N'Kabir Nair',N'Sara Nair',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7006',N'Radha Shinde','radha6mech7@student.university.edu','9998407678','77346e7cdada7f8949f18049a1c731e6cfa10d9dd46ad93ebaddceb42ef2d598',4,'Female','2005-08-24',N'Suresh Shinde',N'Hema Shinde',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7007',N'Yash Hegde','yash7mech7@student.university.edu','9581467179','5bcf194b5d0ab9a9cb6bd0a7dc00c3b398f629e0b458ef177892ce1481006ba0',4,'Male','2002-07-19',N'Aditya Hegde',N'Geetha Hegde',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7008',N'Savitha Desai','savitha8mech7@student.university.edu','9757383959','646af32ea2923dadb01457f649575c0dc05a348a7aaf5e2127351f7c6d58d352',4,'Female','2004-12-07',N'Arjun Desai',N'Priya Desai',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7009',N'Alpesh Chopra','alpesh9mech7@student.university.edu','9572934172','9f53ec943d81867d4f8b828e49e5acbfe1475f40dbfc8af1d5cbbffb1ec4bab7',4,'Male','2005-07-27',N'Mohan Chopra',N'Indira Chopra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7010',N'Kamala Ghosh','kamala10mech7@student.university.edu','9338005452','736cd5f459f3c9dd9c69425ecc7965eda844160c9dc258fa5e5888e20e8a21ce',4,'Female','2005-08-10',N'Arnav Ghosh',N'Sridevi Ghosh',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7011',N'Girish Reddy','girish11mech7@student.university.edu','9183745508','8d85f744e9012e99c4d7def542e3cc657c3cca326ebf46283664c9ee6e36345f',4,'Male','2002-10-08',N'Ravi Reddy',N'Hema Reddy',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7012',N'Kamala Rajan','kamala12mech7@student.university.edu','9711991808','47701ca57daaf2a688f939083c458d33e43c14a7a9e5d5e54959970e5b51db37',4,'Female','2002-08-26',N'Arnav Rajan',N'Indira Rajan',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7013',N'Rupesh Krishnan','rupesh13mech7@student.university.edu','9787125521','e69ba461e01c03d26ebe156cf547bc5e1a144ca06ddb1298a373ef0a509c5747',4,'Male','2003-12-10',N'Paresh Krishnan',N'Bhavana Krishnan',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7014',N'Suma Salvi','suma14mech7@student.university.edu','9482145653','73110f03326cd86b864ca8e850f30f85fe75fb16d691d95282e357dae9585780',4,'Female','2003-08-11',N'Sunil Salvi',N'Aadhya Salvi',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7015',N'Mukesh Pillai','mukesh15mech7@student.university.edu','9785072081','a9c8e11c02484b3cf196d99e9c49ba0adf3cfbadbefdea25c09e9522ef3969c6',4,'Male','2005-07-14',N'Atharv Pillai',N'Madhuri Pillai',7,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7016',N'Latha Salvi','latha16mech7@student.university.edu','9029084668','db894fb6215eaef334542d81e86db9b2744440896c07bdd38635f1f5db2b1956',4,'Female','2002-07-25',N'Kabir Salvi',N'Hema Salvi',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7017',N'Aarav Jadhav','aarav17mech7@student.university.edu','9673899756','93da589ab44e02fb65b4607957b2bf7cacfa45726f053f321e18373043e1335a',4,'Male','2006-03-23',N'Kiran Jadhav',N'Geetha Jadhav',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7018',N'Vimala Mishra','vimala18mech7@student.university.edu','9431884852','47a4f9e8ef734894a189bb344b4a81018255387b584af17c5b44a51a4b146a8b',4,'Female','2003-09-18',N'Pranav Mishra',N'Jyothi Mishra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7019',N'Manoj Mehta','manoj19mech7@student.university.edu','9810548510','75a1052b62e1889306381cdc002724f41ad84c260f61077ee44cfdbe53dfdcf4',4,'Male','2004-12-14',N'Rohan Mehta',N'Bhargavi Mehta',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7020',N'Rashmi Sharma','rashmi20mech7@student.university.edu','9989354492','6a9a155c7159a733eff67858b5e0c0b894cd9e0d921d1271e81125b111d1f82f',4,'Female','2003-12-19',N'Amit Sharma',N'Reshma Sharma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7021',N'Prakash Joshi','prakash21mech7@student.university.edu','9571266110','d90ec7190b63ec6b6ae46cd7be19ed8bce5d2caffd73860d70ef0a1e18634fb6',4,'Male','2006-10-07',N'Arnav Joshi',N'Swathi Joshi',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7022',N'Diya Naidu','diya22mech7@student.university.edu','9864976776','9ae69b91e6d8133b81abfe43178029f67850ea61dc6fa0d5436c0b0cdc17d215',4,'Female','2005-10-18',N'Tushar Naidu',N'Geetha Naidu',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7023',N'Rajesh Iyer','rajesh23mech7@student.university.edu','9881377028','92ba92e02c2a790e59c033323dacad28ddd9a93c2e59ac862186ef2527d77469',4,'Male','2005-03-23',N'Sandeep Iyer',N'Indira Iyer',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7024',N'Suma Nair','suma24mech7@student.university.edu','9821545447','dd10e85b420c6228a8d62c26c85042c9de4525e00ddd48a3aa12d45275570196',4,'Female','2006-05-02',N'Dhruv Nair',N'Bhavana Nair',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7025',N'Mukesh Khanna','mukesh25mech7@student.university.edu','9270185106','f6fe08d4d2a1a94f9e2b0b3942407b6b893aa5d317677c2b500d37e09303443b',4,'Male','2004-05-07',N'Akash Khanna',N'Saanvi Khanna',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7026',N'Nithya Jain','nithya26mech7@student.university.edu','9922877725','1fe6cd4489f8c9e5dbd2819a7d87d4191caeae6cb5a431d2fd061a0bcf12e99d',4,'Female','2005-08-27',N'Jignesh Jain',N'Reshma Jain',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7027',N'Jignesh Kulkarni','jignesh27mech7@student.university.edu','9412094818','59543229b63ec0a269b75b96645bc7ed7a0c10df269ba772edf86e8fb5a8a720',4,'Male','2002-11-15',N'Ravi Kulkarni',N'Vimala Kulkarni',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7028',N'Nithya Naik','nithya28mech7@student.university.edu','9780182043','928ec3daa66764997671431227d794921752b94af4630aefd7276a6ceb83aec0',4,'Female','2006-04-25',N'Aditya Naik',N'Nithya Naik',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7029',N'Sai Pawar','sai29mech7@student.university.edu','9070562608','d30c62165a2296110dd52023ab3975b4bc076f6eb48bf07f748cf3804182659f',4,'Male','2004-07-19',N'Arun Pawar',N'Kamala Pawar',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7030',N'Ira Nair','ira30mech7@student.university.edu','9224124620','67a420e0bacbe1bdc94ab3d22bb58fa5e8b93f6986f1ecebbfa1edfe46df8d32',4,'Female','2006-03-10',N'Umesh Nair',N'Navya Nair',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7031',N'Arjun Hegde','arjun31mech7@student.university.edu','9265461033','7cfb155d7f95a1e7cfe229496f5f6a7c3c79094cf2838dff1a1dfb291077a36e',4,'Male','2005-02-11',N'Aditya Hegde',N'Nisha Hegde',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7032',N'Lakshmi Ghosh','lakshmi32mech7@student.university.edu','9405786170','f5939a979299b5f12321b66f135e8483b10a4b34debb9f4c7d63207a89a54423',4,'Female','2006-07-04',N'Rajesh Ghosh',N'Amrutha Ghosh',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7033',N'Kiran Bhatt','kiran33mech7@student.university.edu','9824967183','9d808ee649a89197fee453b91034f9860cae44353707d211f0cb114754640126',4,'Male','2002-04-25',N'Jagdish Bhatt',N'Revathi Bhatt',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7034',N'Vimala Das','vimala34mech7@student.university.edu','9700794200','d7b92e1b2c28b6a2db334cc564d07285df7615a4f4d39fc9888a55bb41f6ead5',4,'Female','2006-07-18',N'Mukesh Das',N'Lakshmi Das',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7035',N'Sachin Mehta','sachin35mech7@student.university.edu','9398402891','dc20ed4cdae6fe602f15dd8bc3b9355bbf37e3f9a84072025d130d467a356975',4,'Male','2005-06-27',N'Nitesh Mehta',N'Lalitha Mehta',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7036',N'Savitha Nair','savitha36mech7@student.university.edu','9398554743','16b9f3cb7f202a9ab50995db7289606e7f7191797d989bfc837e17472d536306',4,'Female','2006-05-14',N'Nitesh Nair',N'Riya Nair',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7037',N'Rudra Saxena','rudra37mech7@student.university.edu','9209700268','ca1017ae6b9a8ee8af79c87c9fa70a61860805ba4d18111058798ac3ddbfe0b8',4,'Male','2004-01-23',N'Jagdish Saxena',N'Kamala Saxena',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7038',N'Vimala Gupta','vimala38mech7@student.university.edu','9715695620','5010f36821d3d1ca611b46e7410d680c8d7ebbc2a1eaaf6a45564d38d7509703',4,'Female','2002-09-01',N'Mukesh Gupta',N'Meera Gupta',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7039',N'Rakesh Rao','rakesh39mech7@student.university.edu','9453194337','904cfde71a59881e08ed0978441fbc2fb5449f3b66008d193e17217152547c8f',4,'Male','2003-12-01',N'Rahul Rao',N'Aadhya Rao',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7040',N'Sunita Ghosh','sunita40mech7@student.university.edu','9361498728','eb52ef57d67b90c25610354f13ffa0971586b5d301993a146996677d0ac2cb35',4,'Female','2006-04-01',N'Jignesh Ghosh',N'Indira Ghosh',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7041',N'Gaurav Malhotra','gaurav41mech7@student.university.edu','9249384308','873012f14686e7e0f871e77ce8df2a03a5769159b61427a6170b6c5588cc6236',4,'Male','2003-12-03',N'Vihaan Malhotra',N'Revathi Malhotra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7042',N'Sruthi Sharma','sruthi42mech7@student.university.edu','9641877580','a1cfeb61b423d68ef527c835bc4f1d3efa88fb71f94b109a17ba66611a6efeb1',4,'Female','2002-06-14',N'Naresh Sharma',N'Hema Sharma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7043',N'Kiran Bhosale','kiran43mech7@student.university.edu','9635190361','d5d1bd6956077fadf9cff25309f218166723916574dbee646b0c9b2eb18a63c8',4,'Male','2005-06-01',N'Akash Bhosale',N'Vimala Bhosale',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7044',N'Priya Mishra','priya44mech7@student.university.edu','9609543173','c977ded372753302fea5f91c1b70af1bb3ac0956ce967e1fb803a2b7dab6b875',4,'Female','2002-01-16',N'Ganesh Mishra',N'Diya Mishra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20214MECH7045',N'Yogesh Mishra','yogesh45mech7@student.university.edu','9997179110','93bf116f4812bfc0fa5f1be9be373381adf480adc8af11c44a449b95d5713059',4,'Male','2003-02-25',N'Naveen Mishra',N'Sridevi Mishra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1001',N'Harish Kulkarni','harish1civil1@student.university.edu','9704961108','522e7d97be2bf80a249aeaa538cae0c0c14b83b5e41912cf2b316e72d4d83971',5,'Male','2002-03-02',N'Hitesh Kulkarni',N'Savitha Kulkarni',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1002',N'Latha Verma','latha2civil1@student.university.edu','9990767699','eb649945775e44c18df258e4a37d20ee4bf898f94c42681fba513914b7d3ae91',5,'Female','2005-04-28',N'Lokesh Verma',N'Amrutha Verma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1003',N'Amit Dubey','amit3civil1@student.university.edu','9091939284','f1554499aaf5688b371512d7a9bc0b76fbbbaddf30368c2ac191b6ac42003127',5,'Male','2003-02-04',N'Ravi Dubey',N'Revathi Dubey',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1004',N'Jyothi Lal','jyothi4civil1@student.university.edu','9002496854','6c7fb9a5d142d6e126a51145fd1c47312372ccb823e35ee25726667919136c63',5,'Female','2003-03-26',N'Rahul Lal',N'Kavya Lal',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1005',N'Reyansh Yadav','reyansh5civil1@student.university.edu','9089203880','970957594d4104b5f82cdab1bb3ac3ad6035a4951eeb10cfc675b1b1e547699b',5,'Male','2004-05-12',N'Ganesh Yadav',N'Kamala Yadav',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1006',N'Sneha Varma','sneha6civil1@student.university.edu','9779599594','9a708d40dbc4c4026e02140d6755ef9a9ebf762a58e9500f5cb816bd62b26fdb',5,'Female','2002-06-07',N'Paresh Varma',N'Sneha Varma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1007',N'Arnav Saxena','arnav7civil1@student.university.edu','9033793375','e3247b8237b06c7b2ebb1bba1c53e720e25b150f9982e5c96a5b1d9721947ffb',5,'Male','2002-08-08',N'Alpesh Saxena',N'Sridevi Saxena',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1008',N'Latha Malhotra','latha8civil1@student.university.edu','9508124739','9c7f29d222ca35600e0085ace78e564863d5a69346a682c7456f6e89a17aa218',5,'Female','2004-01-03',N'Yogesh Malhotra',N'Aadhya Malhotra',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1009',N'Umesh Kumar','umesh9civil1@student.university.edu','9425832302','e3c5f77811260bc78be248ef7bead4ebe625bbaded4b4f44fdc84c720f8eca91',5,'Male','2004-03-08',N'Ishaan Kumar',N'Sneha Kumar',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1010',N'Ananya More','ananya10civil1@student.university.edu','9153473552','dc28f93717561be1a6906601a3fa497ab271200bc6ea8f22d9f9cf040a379369',5,'Female','2005-11-26',N'Tushar More',N'Riya More',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1011',N'Alpesh Hegde','alpesh11civil1@student.university.edu','9338655963','4a786ede0edcc762fb1088618484412a8e9784731f823828bee099218155ddfc',5,'Male','2003-03-26',N'Vihaan Hegde',N'Kiara Hegde',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1012',N'Vimala Chopra','vimala12civil1@student.university.edu','9428973179','ff43e17e1456b85596789bf0a7c5ca4c50c6a7eee9bfae71fe3c67f091761fb0',5,'Female','2004-04-02',N'Mukesh Chopra',N'Sara Chopra',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1013',N'Pranav Naik','pranav13civil1@student.university.edu','9872558777','b94e3498af6618829f88a64bc2fede3c25a0a66e7b07254a9bd59225390fca83',5,'Male','2006-06-16',N'Alpesh Naik',N'Meera Naik',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1014',N'Sridevi Khanna','sridevi14civil1@student.university.edu','9736346692','d0a14c377e73eade203c0eea6a646603257b980b97157f720d88667f77d84791',5,'Female','2003-04-07',N'Dinesh Khanna',N'Pari Khanna',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1015',N'Vishal Gupta','vishal15civil1@student.university.edu','9853907895','8230aec42b0b21c9a60d83c28f2f397eb70306ff1bc4b3b1e96ccf18580586dd',5,'Male','2002-05-15',N'Atharv Gupta',N'Amrutha Gupta',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1016',N'Hema Patil','hema16civil1@student.university.edu','9602734151','c051cdc3b5932b373ebb67435e45f9a3bd20dae75f2faefd0bfa3426ae74173c',5,'Female','2005-06-09',N'Anand Patil',N'Madhuri Patil',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1017',N'Arun Murthy','arun17civil1@student.university.edu','9115083535','fa0a47b5410104dc17b7117e8c86f0b6624b508c5a2c87b4ec493d0da5464082',5,'Male','2004-04-04',N'Sai Murthy',N'Sridevi Murthy',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1018',N'Kamala Iyer','kamala18civil1@student.university.edu','9445669078','b5de7862ee327c589735ce0b6db340e43b802d1502952eb46e0f0a1f46dabaa6',5,'Female','2006-05-01',N'Hitesh Iyer',N'Amrutha Iyer',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1019',N'Yash Pillai','yash19civil1@student.university.edu','9898775153','353714e110087891ee79aa5fc091c878ce436635e7b08722f42d4514f264409e',5,'Male','2003-08-08',N'Mohan Pillai',N'Rashmi Pillai',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1020',N'Pallavi Jain','pallavi20civil1@student.university.edu','9924075536','54a85a4f71fe629651941f83ef15177486edb553233b3992c59e35cf446fa521',5,'Female','2002-06-05',N'Hitesh Jain',N'Sowmya Jain',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1021',N'Ganesh Pandey','ganesh21civil1@student.university.edu','9259999663','0d6e679112526f917bb219729e4f0e07ed6a517f2d5acd1936c0f2d454625013',5,'Male','2006-01-05',N'Manoj Pandey',N'Ananya Pandey',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1022',N'Vimala Bhat','vimala22civil1@student.university.edu','9741218209','0aa412e7072bdf4600be849d1e6262fbc7a1648fa61cbdc1420e4959b3860ffe',5,'Female','2002-06-19',N'Ishaan Bhat',N'Varsha Bhat',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1023',N'Ishaan Reddy','ishaan23civil1@student.university.edu','9481705802','38adf81ec17f859869cdc3b3c63aff03aad2e68f83ee25d34eeba9707ef3e81f',5,'Male','2004-04-08',N'Paresh Reddy',N'Usha Reddy',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1024',N'Priya Nair','priya24civil1@student.university.edu','9163234672','966f76bf9c7284682d8a6bed0febd462087990fe352eb74e3d96da3b918d623d',5,'Female','2005-08-24',N'Atharv Nair',N'Vimala Nair',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1025',N'Manoj Rao','manoj25civil1@student.university.edu','9027169385','00283e37e4ab4cb63e289afe6d9ce21457192261d5aba245b3b7b92541719adb',5,'Male','2005-05-07',N'Rajesh Rao',N'Indira Rao',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1026',N'Sruthi Saxena','sruthi26civil1@student.university.edu','9754692632','185bc2067ff849acbae8974d5edbfad21f62b4053d0e7f30f3674abc5b977779',5,'Female','2002-05-21',N'Gaurav Saxena',N'Pari Saxena',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1027',N'Amit Bhat','amit27civil1@student.university.edu','9160324841','ae0652d78ef4e84ab203e7d5c2dca2be2cd6c4b9772fb5a6885d1e5ae837c4c7',5,'Male','2003-12-19',N'Paresh Bhat',N'Shobha Bhat',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1028',N'Sowmya Nair','sowmya28civil1@student.university.edu','9567243807','1001d4c71b24480b4bc0a33b0e5142bcf02042f2e4ae6ae951aca1b72e1ae933',5,'Female','2002-09-25',N'Anand Nair',N'Diya Nair',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1029',N'Pranav Mishra','pranav29civil1@student.university.edu','9041257771','c4ce4655b841ab6781f75be53326df1d81bdedb02eb3714b0d93d8e4156f44e2',5,'Male','2003-07-02',N'Prakash Mishra',N'Latha Mishra',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1030',N'Indira Jain','indira30civil1@student.university.edu','9091241862','89ab308adff7ab9c4b029bf66a705ac08e700a78b6a4ea0bcdbdf926f41e2371',5,'Female','2004-03-06',N'Atharv Jain',N'Varsha Jain',1,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1031',N'Reyansh Jain','reyansh31civil1@student.university.edu','9837081647','74b502624b2d96fc1eecacea05a45440f9aca7cba2bbc60ec8e05a1675b97891',5,'Male','2003-12-02',N'Deepak Jain',N'Kavya Jain',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1032',N'Saanvi Salvi','saanvi32civil1@student.university.edu','9331060053','545a12a742a156c480d2d1e13651bb826db48c5d7d4c823072983471949a1bdf',5,'Female','2003-04-12',N'Pranav Salvi',N'Kavitha Salvi',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1033',N'Jagdish Kulkarni','jagdish33civil1@student.university.edu','9068155839','4a24c62ddaeed570e90576522464a4d2c69a17c67f013a807b566a765a89dfc7',5,'Male','2003-12-06',N'Arnav Kulkarni',N'Madhuri Kulkarni',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1034',N'Hema Nair','hema34civil1@student.university.edu','9206506373','9721b71291798f03f0596264b92bf315e66aa6e84805faffbbe584c39299c514',5,'Female','2002-06-11',N'Yash Nair',N'Pooja Nair',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1035',N'Vivaan Reddy','vivaan35civil1@student.university.edu','9971892419','d2899bf6aec1747427008d599a1da05becc03eb07cd20bb7230c6461584f4a33',5,'Male','2005-05-25',N'Alpesh Reddy',N'Pooja Reddy',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1036',N'Reshma Malhotra','reshma36civil1@student.university.edu','9150997683','4838c9518fba8765d969a51de338c273c2b0562a19621929758e040992fa2055',5,'Female','2004-11-16',N'Mahesh Malhotra',N'Amrutha Malhotra',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1037',N'Yash Kumar','yash37civil1@student.university.edu','9639102574','9344763fea53c122c85187cc065529b030a458c7a56e1544db88e8ed0516348d',5,'Male','2002-05-08',N'Lokesh Kumar',N'Amrutha Kumar',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1038',N'Pooja Murthy','pooja38civil1@student.university.edu','9524508640','a3e017d79f48ea91d262842e1f07f9ce0a20ad950faeb55c47622cca290db3f8',5,'Female','2006-08-24',N'Vivaan Murthy',N'Lakshmi Murthy',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1039',N'Rohan Krishnan','rohan39civil1@student.university.edu','9396852701','ffc695f34522f6ed5c4ebe185c8b3abcc7a475ff0b98c277eb92247694a3aad6',5,'Male','2003-11-23',N'Arun Krishnan',N'Saanvi Krishnan',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1040',N'Sneha Singh','sneha40civil1@student.university.edu','9298338167','92928947ddb27bd6b2a37011aa7595339941e9cb8c2460bbd306baa545f9d0f9',5,'Female','2003-03-03',N'Mahesh Singh',N'Sara Singh',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1041',N'Rohan Desai','rohan41civil1@student.university.edu','9973471566','81c440ee21e08d2d62cbbb472c140f5177fafcb9bf2f698f5c30dd90643db815',5,'Male','2003-05-10',N'Ayaan Desai',N'Kamala Desai',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1042',N'Hema Tiwari','hema42civil1@student.university.edu','9706614982','f681227a11e7b303669f9a71b6f3bcd64ded7bda8da0a0443b69e3d9ea477db7',5,'Female','2005-03-27',N'Lokesh Tiwari',N'Rashmi Tiwari',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1043',N'Pranav Saxena','pranav43civil1@student.university.edu','9971527323','3ee1ecce5c536cd98e9a6103cd5c404c541651262d2bc1a777cdd86d69c17811',5,'Male','2004-07-18',N'Ganesh Saxena',N'Sruthi Saxena',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1044',N'Jyothi Shenoy','jyothi44civil1@student.university.edu','9567491601','1c2c2f1a009a6a95999bc1677b8c0786ada534a62cf68e72285cfa8151c926dc',5,'Female','2005-07-13',N'Anand Shenoy',N'Deepa Shenoy',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20245CIVIL1045',N'Ishaan Naik','ishaan45civil1@student.university.edu','9750663370','d2eaf7f1e02a1e6db6d90edc292d9cd15b40346373448885c1ce1bf8a9ece6c5',5,'Male','2004-09-23',N'Kartik Naik',N'Rekha Naik',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3001',N'Vinay Rajan','vinay1civil3@student.university.edu','9243992011','22ad03f7e89fb2c1a7229af1c57a050c0885076ee969426eb213c5f9fe1fb1ad',5,'Male','2004-10-15',N'Dinesh Rajan',N'Sara Rajan',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3002',N'Ira Dubey','ira2civil3@student.university.edu','9644886946','a22b42712a4071a85f622f72ff03f7725968752570c3dcc5f929253c31362e2e',5,'Female','2005-03-27',N'Paresh Dubey',N'Sneha Dubey',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3003',N'Sunil Pawar','sunil3civil3@student.university.edu','9364027011','a3f8201db94674a0015a5c6eab98f681844af74ff206c4b42c128e92dde7ed94',5,'Male','2003-05-24',N'Deepak Pawar',N'Anusha Pawar',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3004',N'Suma Murthy','suma4civil3@student.university.edu','9522372817','d91f84d96c7de67e4ce87106d43296afc0cad28ba153cbc5576bc662f3d4789a',5,'Female','2005-03-06',N'Tarun Murthy',N'Jyothi Murthy',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3005',N'Ishaan Singh','ishaan5civil3@student.university.edu','9679121416','49152a463dfb55361a4b57f6c0b34697e8ce791e96f9ec42504febf468bca1de',5,'Male','2003-05-28',N'Prakash Singh',N'Kavya Singh',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3006',N'Reshma Kumar','reshma6civil3@student.university.edu','9100409013','03743ec81dbc39990eb80a8521903838424b30c9161cb27d20bc957c1ffbdbcf',5,'Female','2005-08-22',N'Manoj Kumar',N'Lakshmi Kumar',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3007',N'Sachin Dubey','sachin7civil3@student.university.edu','9596555535','80d666f1e6ec6054c55210dde66ee94318568310adf044c6c8e639a828d3a6b6',5,'Male','2004-08-16',N'Jagdish Dubey',N'Amrutha Dubey',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3008',N'Sujatha Singh','sujatha8civil3@student.university.edu','9762091843','ecb1c831aece1dcec9ec46041f8cf276e461e4f164f87cb7aa6a336d51e5b4c8',5,'Female','2004-02-01',N'Umesh Singh',N'Sangeetha Singh',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3009',N'Rajesh Patil','rajesh9civil3@student.university.edu','9505057397','7098acedcc5c4061a225394e66593893868dc0b1535652e57125a7e74e2dcd48',5,'Male','2002-11-27',N'Suraj Patil',N'Sneha Patil',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3010',N'Sangeetha Desai','sangeetha10civil3@student.university.edu','9493289802','2a27020e5b2e2310c03bb106fcc5b0af64f1222630210baf183253dd621ffe50',5,'Female','2002-12-13',N'Naresh Desai',N'Varsha Desai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3011',N'Nitesh Pillai','nitesh11civil3@student.university.edu','9783332116','25e154e0f59e63244123383fb32cbe1e01bebbd9639075f893901627a9cf0130',5,'Male','2003-08-04',N'Vishal Pillai',N'Sruthi Pillai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3012',N'Usha Salvi','usha12civil3@student.university.edu','9128715399','057917f0cbf3db6e44f8a335b806ea8b57d7111796ab79628002b8188ac99bb6',5,'Female','2004-11-16',N'Kiran Salvi',N'Meena Salvi',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3013',N'Paresh Hegde','paresh13civil3@student.university.edu','9863341411','856b00731f045855cd93b838e7461d4f9cf010988ea8ab762040b4af1a7028d6',5,'Male','2005-11-21',N'Prakash Hegde',N'Rashmi Hegde',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3014',N'Kiara Kapoor','kiara14civil3@student.university.edu','9040983665','b5e9e91bf67a27f0be81dc14115bab8fe7ccd1bf038f389eb15c7608014299c3',5,'Female','2004-07-19',N'Anand Kapoor',N'Riya Kapoor',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3015',N'Naveen Rajan','naveen15civil3@student.university.edu','9087524377','b5054c13dc228ea27276df46f627dcb097a98c1cf2b838ce0e9cf5e42cbe04f5',5,'Male','2003-02-13',N'Sachin Rajan',N'Revathi Rajan',3,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3016',N'Sara Gowda','sara16civil3@student.university.edu','9481497374','cfa731715398723fcd538a9f9ad779fe8eacd6935130853352c3dfe14c825bd8',5,'Female','2002-10-11',N'Suraj Gowda',N'Madhuri Gowda',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3017',N'Umesh Pawar','umesh17civil3@student.university.edu','9302764208','a062ee7fa3d1cfc190fe29a2c7379ba8877f924712dfe7fe1b0433daf491e6ed',5,'Male','2003-12-26',N'Ravi Pawar',N'Sara Pawar',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3018',N'Lalitha Yadav','lalitha18civil3@student.university.edu','9844386125','bf45016517338193967b192219ee858d7231c4c33c7baba7aa678bed082becb3',5,'Female','2005-07-03',N'Deepak Yadav',N'Amrutha Yadav',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3019',N'Hitesh Hegde','hitesh19civil3@student.university.edu','9774233305','bacadf5fe9585aa00fd9a01d9eef8529d00b1de1910c758c60ad374860a5423e',5,'Male','2003-10-05',N'Ganesh Hegde',N'Sruthi Hegde',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3020',N'Lalitha Sawant','lalitha20civil3@student.university.edu','9201572018','6c2451922bb4070a348784102e3a5c682fed6aacb1e61b1a17588ab9ac6402c2',5,'Female','2005-07-22',N'Hitesh Sawant',N'Sara Sawant',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3021',N'Kartik Menon','kartik21civil3@student.university.edu','9136749261','994c8592ba77eed549a2b0a9b7d964602aff64c06153fb7512e4703b4a3921b3',5,'Male','2005-04-02',N'Mahesh Menon',N'Jyothi Menon',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3022',N'Sunita Varma','sunita22civil3@student.university.edu','9111783099','cf8a7babab7fa0e73dd175629c58871fdee88113bc8238240b46f26a82ef558e',5,'Female','2004-01-04',N'Dinesh Varma',N'Pallavi Varma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3023',N'Vinay Gowda','vinay23civil3@student.university.edu','9764921518','39a7f101d8cccbc8ce5a47108b714204dfdce796241f52d395d2715f31501f78',5,'Male','2006-03-13',N'Arnav Gowda',N'Sridevi Gowda',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3024',N'Anusha Agarwal','anusha24civil3@student.university.edu','9898131292','a02e671865255e520f3cf9123d737921afadb74da9978e2929a3033d7d6bc46e',5,'Female','2006-08-03',N'Mukesh Agarwal',N'Madhuri Agarwal',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3025',N'Girish Pandey','girish25civil3@student.university.edu','9218401184','dd673c5c1dd4c99e3b891bfd41c2f11650edb71d5c1a465c3c694202244d8ee3',5,'Male','2003-10-07',N'Dhruv Pandey',N'Pari Pandey',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3026',N'Hema Rajan','hema26civil3@student.university.edu','9487297585','1e1769eb8038acd1cb0a59a7936a9af57293428e44b93f2adc0fc3f0169a072d',5,'Female','2004-01-17',N'Aarav Rajan',N'Lakshmi Rajan',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3027',N'Rudra Kamath','rudra27civil3@student.university.edu','9324329839','e50f8e69c57d2bcd48400b3b88ed141ef3ca4d384a44eed8fd009a2874358d89',5,'Male','2002-04-02',N'Arnav Kamath',N'Shobha Kamath',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3028',N'Hema Reddy','hema28civil3@student.university.edu','9267146283','dae54a0b1767155b36a6acd4014e5e070ff39a767878c2b6a33ccf698eb5b44a',5,'Female','2004-07-21',N'Vishal Reddy',N'Rekha Reddy',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3029',N'Dinesh Jadhav','dinesh29civil3@student.university.edu','9256609314','f54a59b1b4f26857d1c5e272647b447f073b5ecaed954492da0e4bb06dba78a0',5,'Male','2003-07-27',N'Rajesh Jadhav',N'Kamala Jadhav',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3030',N'Lalitha Bhatt','lalitha30civil3@student.university.edu','9554234016','20bc4ac35445d8b9eebc6d094fe017e0b9c54edb106aa68228feeaac09fb301e',5,'Female','2004-11-03',N'Akash Bhatt',N'Diya Bhatt',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3031',N'Naresh Verma','naresh31civil3@student.university.edu','9497185948','1eaaa618367f9c25b80336b697810a8f181bea211f247f4d8483ce5b736fbf01',5,'Male','2003-09-24',N'Mukesh Verma',N'Kiara Verma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3032',N'Swathi Naik','swathi32civil3@student.university.edu','9889679240','81137b08f73944a87c41cebc49cabc04a64fe1b79428e91c9449339007fd025b',5,'Female','2004-12-22',N'Pranav Naik',N'Kavya Naik',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3033',N'Suraj Iyer','suraj33civil3@student.university.edu','9053967275','c0d22d1248356c5d3fab5eb24f57404a8d0521c1ff54d29af065cb18dd3c9a65',5,'Male','2006-12-09',N'Reyansh Iyer',N'Usha Iyer',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3034',N'Divya Shah','divya34civil3@student.university.edu','9341465111','dd8b653de6b1a9e23f01da8d7ea7e0acd92b722ae07157eacb371f2c038ffb83',5,'Female','2006-12-27',N'Naresh Shah',N'Hema Shah',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3035',N'Kabir Kapoor','kabir35civil3@student.university.edu','9068277881','939995c6a65480febb31c19366a46d5d68842f29ede3df8847715f611c4ef4e2',5,'Male','2004-09-16',N'Aditya Kapoor',N'Ira Kapoor',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3036',N'Bhargavi Gowda','bhargavi36civil3@student.university.edu','9538909728','79713a640e925b2944c52fdbda8d53b01a366b9cace499d70e01bcf0c1351100',5,'Female','2005-12-18',N'Aarav Gowda',N'Indira Gowda',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3037',N'Vihaan Naidu','vihaan37civil3@student.university.edu','9676251538','10420cbfc1215c7321e93ff581a3f524f76bbaf3ab56e2f328ac950344f3d595',5,'Male','2006-06-02',N'Nitesh Naidu',N'Riya Naidu',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3038',N'Nisha Yadav','nisha38civil3@student.university.edu','9963480797','1cfce79ad0c3e65758571387f61c71e3cbd70954a61c9422e538aa0562d52fe4',5,'Female','2003-01-24',N'Tarun Yadav',N'Rekha Yadav',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3039',N'Lokesh Saxena','lokesh39civil3@student.university.edu','9526501673','2c0756fd9994a11920fc4c19bbe60645df0dacf8affb6ba42877797c18926af0',5,'Male','2004-02-01',N'Ravi Saxena',N'Nisha Saxena',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3040',N'Sara Patil','sara40civil3@student.university.edu','9437654562','354f985a8177150346b308a42c2db2c5f99500174df5b0f8e5d1a0d288111671',5,'Female','2002-03-25',N'Dhruv Patil',N'Deepa Patil',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3041',N'Nitesh Jain','nitesh41civil3@student.university.edu','9053134026','572cedd8af570dc11958d12da76a6e077c1ecaa2c7ef50acecc04b9713aebcc6',5,'Male','2004-12-14',N'Kabir Jain',N'Riya Jain',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3042',N'Priya Rajan','priya42civil3@student.university.edu','9787256862','6bb9a305041ebb39659689a46d4c2c33f6b6c6288bf634840f447dc97bf9e821',5,'Female','2004-02-14',N'Ishaan Rajan',N'Varsha Rajan',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3043',N'Atharv Menon','atharv43civil3@student.university.edu','9056906744','fceebb920a93de57b3e07ab343ecb7c256b8d0700fe7f9fcc6e4962e95ee38c3',5,'Male','2002-11-08',N'Deepak Menon',N'Smitha Menon',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3044',N'Lakshmi Lal','lakshmi44civil3@student.university.edu','9414363718','f6fa810931d601df13e9aa8752f0dd8615599de2ea9f4b03af9262a76ac85d0e',5,'Female','2006-03-08',N'Reyansh Lal',N'Jyothi Lal',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20235CIVIL3045',N'Hitesh Khanna','hitesh45civil3@student.university.edu','9260432609','f85eb73c8775bbe97b5bfa211f138c396947a90a9792df7bfede384f54dbe656',5,'Male','2003-04-04',N'Mahesh Khanna',N'Radha Khanna',3,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5001',N'Pranav Patil','pranav1civil5@student.university.edu','9670860414','d988b979894767bf8fb7f13be6aa52fcf152069e85683036aec18d19c59878e7',5,'Male','2003-04-11',N'Naveen Patil',N'Nisha Patil',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5002',N'Indira Patil','indira2civil5@student.university.edu','9005347491','c1fd712119b6acd8e0998dbba66bf6d824113ec8c994ab191c45520a36ebfad6',5,'Female','2002-03-02',N'Rohan Patil',N'Swathi Patil',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5003',N'Naresh Ghosh','naresh3civil5@student.university.edu','9082555989','19c6bbb43eb92e85082f03bc421f3d9e692027cfb21b6ecd9ecbca5244b3c848',5,'Male','2004-02-04',N'Anand Ghosh',N'Reshma Ghosh',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5004',N'Usha Gupta','usha4civil5@student.university.edu','9910933711','da81c4bb4e9c1a749a114bd0fd8ea293f3e30f3e2a1216e5e3cda82ba61d3803',5,'Female','2003-11-24',N'Alpesh Gupta',N'Navya Gupta',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5005',N'Ganesh Shenoy','ganesh5civil5@student.university.edu','9202368485','1df6ed4adf1efca76d5967f79304d8bc96a364a2ec3c4974f0208dbf05098ee6',5,'Male','2003-09-24',N'Vikram Shenoy',N'Amrutha Shenoy',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5006',N'Radha Hegde','radha6civil5@student.university.edu','9880294240','65e1b5285c73a5e209d53c2fc8da23a984e57f0880197fec2ba248f2a390de6c',5,'Female','2002-08-14',N'Dhruv Hegde',N'Hema Hegde',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5007',N'Ishaan Gowda','ishaan7civil5@student.university.edu','9812786866','081bfde1dc52d84f404fd208f67a3e2d7aed07e7e5fe05aa9da1adf5e5cb0603',5,'Male','2005-11-18',N'Yogesh Gowda',N'Latha Gowda',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5008',N'Kavya Sharma','kavya8civil5@student.university.edu','9087884434','3898cbbf490a5b8ddc3cbe092da34cd0d74edd3190d223e956aa388ca6db1f8b',5,'Female','2003-10-23',N'Kabir Sharma',N'Nithya Sharma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5009',N'Dhruv Das','dhruv9civil5@student.university.edu','9024240338','235637b62deafa999b1e94fccf4876d8920842daec274db28ce834ff2d36bf01',5,'Male','2006-04-10',N'Yash Das',N'Pari Das',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5010',N'Radha Trivedi','radha10civil5@student.university.edu','9842694500','26e3e5b0846126ba2fd8e10338be981cb9d53f69114786f74926d151bd5cc080',5,'Female','2004-02-23',N'Umesh Trivedi',N'Bhavana Trivedi',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5011',N'Mohan Shah','mohan11civil5@student.university.edu','9916498373','6ddd2ea15e6d979e2bcb39b24bfe5509e3be0606601aff8b5a8255eade796024',5,'Male','2002-09-22',N'Ayaan Shah',N'Rekha Shah',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5012',N'Revathi Varma','revathi12civil5@student.university.edu','9365271727','cef28675b1b18785f8641eb296df9351eb7e71d57614b21f5c9d5e84d2f1e268',5,'Female','2005-03-15',N'Girish Varma',N'Amrutha Varma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5013',N'Gaurav Ghosh','gaurav13civil5@student.university.edu','9042269312','b95c41888b45c8e122bbad7daa3b9ba9c1e617bc25aac1c8f174e43fbe62d439',5,'Male','2003-11-10',N'Naresh Ghosh',N'Jyothi Ghosh',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5014',N'Sruthi Bhosale','sruthi14civil5@student.university.edu','9209166010','8a30f2ba6f9dbd8fada41b4bcd32d5f17dfcbf1ee8e892741adaecc015132b6a',5,'Female','2002-12-17',N'Dinesh Bhosale',N'Latha Bhosale',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5015',N'Rohan Salvi','rohan15civil5@student.university.edu','9001851327','850b25a8165191677da7010d8f28db77bef900d5e6d0cf1ca928b7366ceebdb8',5,'Male','2003-11-20',N'Sai Salvi',N'Sunita Salvi',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5016',N'Anusha Das','anusha16civil5@student.university.edu','9084810018','6125981605b0fb75b29a2764d0aa2b5a479c605fdc5d50e9dac7d52e2c49d0c9',5,'Female','2005-03-08',N'Ganesh Das',N'Reshma Das',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5017',N'Alpesh More','alpesh17civil5@student.university.edu','9366254361','4b7846c7a04de9294f37be0551cd9f0655f431c4f14062abed976085cef64d15',5,'Male','2002-04-01',N'Akash More',N'Sara More',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5018',N'Meena Verma','meena18civil5@student.university.edu','9515109226','33e6b29fd3f299a91d6c511e34e328eb0101a1ae23b772d33e4376eff1549d88',5,'Female','2004-02-20',N'Jagdish Verma',N'Divya Verma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5019',N'Ayaan Pillai','ayaan19civil5@student.university.edu','9451475410','907ff37334a0855cd1a55b6d54b7b4368ac9557517a609b9e4b353b476c2706f',5,'Male','2004-10-27',N'Kartik Pillai',N'Sara Pillai',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5020',N'Swathi Menon','swathi20civil5@student.university.edu','9964215226','d12de1fc6f67eb4c86eea45a672641427451a9db335755fb6ed9b846afd3517a',5,'Female','2005-02-04',N'Pranav Menon',N'Pallavi Menon',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5021',N'Kartik Yadav','kartik21civil5@student.university.edu','9236687887','00fd9ea576766bdaa564deec43af5b40a65b400f1dbf5c57b6625b16dc897136',5,'Male','2006-11-11',N'Vinay Yadav',N'Suma Yadav',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5022',N'Revathi Hegde','revathi22civil5@student.university.edu','9313503058','f2a43031240cbe94793c4fe16ee3ef21f4d06a5f6691ffc97deb1226b59f03f3',5,'Female','2006-12-26',N'Akash Hegde',N'Geetha Hegde',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5023',N'Aditya Bhosale','aditya23civil5@student.university.edu','9286333021','89fb585426481524c1c1b1731827ddb6173cd4914129c1015878e5dbb015ed56',5,'Male','2003-05-15',N'Deepak Bhosale',N'Bhavana Bhosale',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5024',N'Jyothi Kumar','jyothi24civil5@student.university.edu','9191792025','3c2c9884efa86827fddb7cdd1048770d03900914fea0764fa3711d97945e0d7c',5,'Female','2004-01-23',N'Vinay Kumar',N'Hema Kumar',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5025',N'Vihaan Sharma','vihaan25civil5@student.university.edu','9272847657','90e57124441c31616d4a9aca452d5d1707d693eaad92ad505a9566b357cc4261',5,'Male','2005-03-25',N'Gaurav Sharma',N'Bhargavi Sharma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5026',N'Kiara Menon','kiara26civil5@student.university.edu','9282066784','ac46cd4b3876b0342ee117f3c399ec12606f30cd46228797bd4769680454dd09',5,'Female','2002-10-25',N'Aditya Menon',N'Meera Menon',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5027',N'Ganesh Hegde','ganesh27civil5@student.university.edu','9862369036','b064f250470611d04d055e77b4326048d03ecb8baab87a1f41358e3868669cbd',5,'Male','2003-05-03',N'Yash Hegde',N'Hema Hegde',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5028',N'Bhargavi Reddy','bhargavi28civil5@student.university.edu','9662056341','913b8c84404bc5ce57452a689c8ac027e54b25811b58d25e94b000e112a91147',5,'Female','2005-08-11',N'Yogesh Reddy',N'Savitha Reddy',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5029',N'Sachin Salvi','sachin29civil5@student.university.edu','9281139043','2be939f2d49f68e70072b97af59591b1615fc3b2a91119db95c82d62b386f36d',5,'Male','2002-04-10',N'Hitesh Salvi',N'Reshma Salvi',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5030',N'Lakshmi Shah','lakshmi30civil5@student.university.edu','9700514054','c742eaa8fa3895d16e5740539c98a0cc02aed3bf033db4dee65f77ea448171bb',5,'Female','2006-01-19',N'Sai Shah',N'Nithya Shah',5,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5031',N'Ishaan Pandey','ishaan31civil5@student.university.edu','9156818209','30c643d1eb5a5c53ed7b2908b3a69f5a9da66111fc2d518ee0341613b312a54f',5,'Male','2004-03-23',N'Ramesh Pandey',N'Latha Pandey',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5032',N'Revathi Deshpande','revathi32civil5@student.university.edu','9711332288','ff7f4c8ac991d742c584fc2d8b071f994089b65e36ebba2cddfb573411678877',5,'Female','2004-03-05',N'Hitesh Deshpande',N'Pari Deshpande',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5033',N'Rakesh Salvi','rakesh33civil5@student.university.edu','9596063399','9d72eba198aa7822f890d99afaf36528a14dea0fdcdd4c62ff0378db69226809',5,'Male','2003-06-10',N'Ravi Salvi',N'Pallavi Salvi',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5034',N'Radha Ghosh','radha34civil5@student.university.edu','9481717524','e36da64bbd07ce5e1c6a47f126632d72f86358a5ee8234547358df914e663a95',5,'Female','2002-03-25',N'Arnav Ghosh',N'Madhuri Ghosh',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5035',N'Gaurav Naidu','gaurav35civil5@student.university.edu','9747472197','0c1fe7b2b202781f66a10ced2f95bdafc6fa94cb4ae02ce83e7487bb75c05a6a',5,'Male','2002-03-23',N'Deepak Naidu',N'Ira Naidu',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5036',N'Sujatha Bhosale','sujatha36civil5@student.university.edu','9955168740','3cb93ef44c521dcebd73cca77abe1ccd52dcdd966220ac11a1c8ff096c96c3f2',5,'Female','2005-06-17',N'Tushar Bhosale',N'Riya Bhosale',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5037',N'Vinay Jadhav','vinay37civil5@student.university.edu','9629613671','b68c16f34214618eb849231e8bc496cc42a4ea7c8c604b5088c87189d83b6143',5,'Male','2003-02-10',N'Vishal Jadhav',N'Aadhya Jadhav',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5038',N'Meera Agarwal','meera38civil5@student.university.edu','9216636515','fcdcef01d0a4aab1a99bfba8838768c86cf2cbee98f644dca65fdcbc59c1c65a',5,'Female','2005-02-03',N'Jignesh Agarwal',N'Anusha Agarwal',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5039',N'Prakash Yadav','prakash39civil5@student.university.edu','9272359096','1d1bacc3dd433448fe881568ba56e4c5dbefba9f4e59ce7ff9dee0ba78c7d589',5,'Male','2005-01-18',N'Dhruv Yadav',N'Sunita Yadav',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5040',N'Varsha Krishnan','varsha40civil5@student.university.edu','9442121461','7f3312a4394e47e76d5fbce1a9a68cfc2229f40e69f0f82723086c9090329072',5,'Female','2002-11-14',N'Aditya Krishnan',N'Pooja Krishnan',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5041',N'Naveen Krishnan','naveen41civil5@student.university.edu','9654235677','880916e795fe3816d37d1d38b8670ab5d00e12a28c43e1afc5b9cb3484136bd9',5,'Male','2003-01-03',N'Suraj Krishnan',N'Rekha Krishnan',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5042',N'Sangeetha Bhosale','sangeetha42civil5@student.university.edu','9931992550','c149010472863eb4b6acb33a43f6515432b1a5f3b0dcd240c76aaa255ba89877',5,'Female','2005-01-18',N'Vinay Bhosale',N'Nithya Bhosale',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5043',N'Sandeep Deshpande','sandeep43civil5@student.university.edu','9072791033','7ef184b36b99aa569519e71c686cecf93ff0663897f1d4d7f9f08e1cabd14b78',5,'Male','2005-05-17',N'Harish Deshpande',N'Kiara Deshpande',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5044',N'Kamala Bhat','kamala44civil5@student.university.edu','9905504481','a383b5dab10e7106bdd66ef86068e85609b68a4d6c23a38fcbd8952c9a806c71',5,'Female','2003-04-22',N'Rudra Bhat',N'Sangeetha Bhat',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20225CIVIL5045',N'Akash Patil','akash45civil5@student.university.edu','9512765289','b74fdad286a5ba6d0c7c1a72b13eab14955736619b339bf3ab91e745acd9f343',5,'Male','2006-07-17',N'Deepak Patil',N'Sangeetha Patil',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7001',N'Pranav Chopra','pranav1civil7@student.university.edu','9911110961','5dd9b116c39436120004897f7017fdf44d830e0e0b414a236845dabb259d8779',5,'Male','2005-11-10',N'Hitesh Chopra',N'Shobha Chopra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7002',N'Navya Varma','navya2civil7@student.university.edu','9463378613','f245b4a0e9ae6e208ba44bb0375fcd1e33c3d9410f67daf59cf04b6862d522ce',5,'Female','2006-01-22',N'Rahul Varma',N'Smitha Varma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7003',N'Deepak Sawant','deepak3civil7@student.university.edu','9605384444','dc281bf19e54fb0c926dea483d8e54c3309ae5fa7c31f5c5147ebe223ba4f0d9',5,'Male','2005-11-23',N'Paresh Sawant',N'Sruthi Sawant',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7004',N'Aadhya Kale','aadhya4civil7@student.university.edu','9258955296','913b0b52ab295f89316ad863a5c93490c8ee24fa77298e65ff6fad840aecdddf',5,'Female','2002-01-01',N'Paresh Kale',N'Suma Kale',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7005',N'Ishaan Lal','ishaan5civil7@student.university.edu','9262658263','f0df63d3f9b0dee215a49bd7b1a54f2d86bfd160c53079e0a72f1591883edd02',5,'Male','2002-10-14',N'Dinesh Lal',N'Latha Lal',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7006',N'Kiara Varma','kiara6civil7@student.university.edu','9825311060','fe773e49e60e8e0f7f7ab7caaf20d6412a8a094fe1d280203fbea5ef90737444',5,'Female','2005-11-09',N'Gaurav Varma',N'Sridevi Varma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7007',N'Suresh Agarwal','suresh7civil7@student.university.edu','9275233438','0b1376255251b61087ed992e1a6bca0e0eabbcde83bbd699ffcc1b43f62965a2',5,'Male','2006-07-01',N'Paresh Agarwal',N'Ira Agarwal',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7008',N'Kavitha Mehta','kavitha8civil7@student.university.edu','9091179112','14968f3950597023c2348ae02469935683afd19d3a0c66e57a4c1ee3ed6bec6c',5,'Female','2004-02-05',N'Suraj Mehta',N'Saanvi Mehta',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7009',N'Sai Reddy','sai9civil7@student.university.edu','9706171366','68c8e5c97fb39c3d80b4e203e67cfd3a12c6f738eb47a4cc437822b859a3ac04',5,'Male','2003-07-04',N'Sandeep Reddy',N'Bhavana Reddy',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7010',N'Madhuri Das','madhuri10civil7@student.university.edu','9990155799','21c099e8e2dee763f7eabc24910e79adbf9dfd4bcaeaec348cea1911ec754705',5,'Female','2002-03-22',N'Ayaan Das',N'Nisha Das',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7011',N'Naveen Gowda','naveen11civil7@student.university.edu','9808823513','d6f34e16239cb2dc5bff74c5d717cc033dd167aa8ea08104af8aaef039e7b568',5,'Male','2003-10-01',N'Nikhil Gowda',N'Kiara Gowda',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7012',N'Meena Gupta','meena12civil7@student.university.edu','9731584776','91fee3519220b517cbb90ca472f37428828af1a8bc5723e450d79777de7a6be1',5,'Female','2003-05-09',N'Mohan Gupta',N'Savitha Gupta',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7013',N'Nikhil Malhotra','nikhil13civil7@student.university.edu','9994237676','71504dc48b424f1f893b54751268fc6b6688af07162735c3409dd19e371e5512',5,'Male','2004-07-04',N'Ishaan Malhotra',N'Lalitha Malhotra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7014',N'Sujatha Verma','sujatha14civil7@student.university.edu','9551720849','cccab85ec552628ccf489a9e90be2663d6319777a9324c840c42aa4470573270',5,'Female','2005-04-19',N'Sachin Verma',N'Usha Verma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7015',N'Yogesh Kulkarni','yogesh15civil7@student.university.edu','9125625313','67c8fdbbb2419330b98f654a02d5e178a3175235f485d83344a145a711c893fd',5,'Male','2004-07-01',N'Dinesh Kulkarni',N'Geetha Kulkarni',7,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7016',N'Sara Salvi','sara16civil7@student.university.edu','9053795381','415b49c9e5ae85d866eb9e29f0cfbdc3c2ec6e68e13b27df3356ae3cad84bf44',5,'Female','2002-06-23',N'Harish Salvi',N'Kiara Salvi',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7017',N'Rudra Dubey','rudra17civil7@student.university.edu','9919665533','b803b60278e906e64cad0446a0731223b09c2cb055a6a886c75436e29cbf33de',5,'Male','2006-05-23',N'Rudra Dubey',N'Navya Dubey',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7018',N'Pari Shah','pari18civil7@student.university.edu','9959639040','5695e827c619dbec07c3ae1e97a16c5885490b55d94e251d9cbf12d99edfe0bd',5,'Female','2002-08-06',N'Akash Shah',N'Kiara Shah',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7019',N'Paresh Saxena','paresh19civil7@student.university.edu','9805017164','2aa04ac4cedc31dc0affccdd374648803a144fc5676b6105be754b32c04a8bdb',5,'Male','2005-01-18',N'Tarun Saxena',N'Riya Saxena',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7020',N'Latha Gupta','latha20civil7@student.university.edu','9064771591','704076bb9453dc941e09d4c9881a1b196877bc461b271449bcc0923a0b85d1ef',5,'Female','2004-08-20',N'Vishal Gupta',N'Kavitha Gupta',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7021',N'Yogesh Sharma','yogesh21civil7@student.university.edu','9632135800','fb101b6fa2e44e316bc706d9089174bec20bdf9c4ffa844a42fae9c09f8c3e48',5,'Male','2004-12-24',N'Atharv Sharma',N'Navya Sharma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7022',N'Saanvi Bansal','saanvi22civil7@student.university.edu','9642297125','9c436a4e52b354f46b97b237fce97fcf685d1ca934f3a7e4c74beec1914b4031',5,'Female','2004-12-20',N'Vihaan Bansal',N'Rekha Bansal',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7023',N'Alpesh Shinde','alpesh23civil7@student.university.edu','9883977457','40a83fcd8e9e3261ba10e9b36d380da1ecf4bc264e3bbc919c63d5b175e8f4e6',5,'Male','2005-11-04',N'Jagdish Shinde',N'Suma Shinde',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7024',N'Kavitha Chopra','kavitha24civil7@student.university.edu','9331170303','ef6a2c80506ffdf803be37e2e93c1e455b6f1e9ea1cded2a4df980426e1376b6',5,'Female','2004-09-27',N'Suresh Chopra',N'Ira Chopra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7025',N'Sandeep Verma','sandeep25civil7@student.university.edu','9547281235','df65dd7c0c5b7c93b6332266be51351aa6f84fb6c4c5d868a078998158916ce8',5,'Male','2006-09-17',N'Ravi Verma',N'Pooja Verma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7026',N'Sneha Salvi','sneha26civil7@student.university.edu','9249127113','0e00d95dd459e2ec33b262ebdebc2b282a728c0a1d238c56dde39d4b5896fe36',5,'Female','2002-05-14',N'Varun Salvi',N'Sneha Salvi',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7027',N'Kiran Kumar','kiran27civil7@student.university.edu','9418156326','991d2c0375b24a3a1dfa0a9ee2ecc6bb41e6cf8da56b9cb09dce44972dbf9fa8',5,'Male','2006-08-12',N'Vikram Kumar',N'Shobha Kumar',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7028',N'Reshma Singh','reshma28civil7@student.university.edu','9663436294','049b1294b085dd5f867cb3069a42a369102eef3bbe1f6737a344e44001a30311',5,'Female','2004-02-02',N'Rahul Singh',N'Sunita Singh',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7029',N'Arnav Pillai','arnav29civil7@student.university.edu','9100943181','2379df884a58eb9bfee9cfe2d52ef94d29a9a280a350220e7ff940a457329d4f',5,'Male','2003-02-08',N'Aditya Pillai',N'Meera Pillai',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7030',N'Latha Kulkarni','latha30civil7@student.university.edu','9235494012','4c6f01e650ca1545081b0b3bdb542757fd0c4c256e85f09eafaeef59eecb574c',5,'Female','2004-08-07',N'Arnav Kulkarni',N'Meena Kulkarni',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7031',N'Prakash Bansal','prakash31civil7@student.university.edu','9122572076','0cf2739ccfba665b9caf35ab1dde822f009c60de2920e6d15dbccc6c37782bc9',5,'Male','2003-03-11',N'Hitesh Bansal',N'Savitha Bansal',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7032',N'Rekha Kulkarni','rekha32civil7@student.university.edu','9790737100','73eb320f42073b86a412d698c3456b9cd5dae7b564327b03b5bf82794f1826e6',5,'Female','2002-10-12',N'Vihaan Kulkarni',N'Priya Kulkarni',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7033',N'Naveen Tiwari','naveen33civil7@student.university.edu','9457758474','17074c391eafc0fecd5848f3a623627b534d3aacb2d7534078752f5c20f1a6da',5,'Male','2003-02-04',N'Kabir Tiwari',N'Amrutha Tiwari',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7034',N'Anusha Shetty','anusha34civil7@student.university.edu','9971480263','950896c47660dca4a48979dc2f2f366042f8badfc9d17892cb825a7c8725be60',5,'Female','2004-09-25',N'Ganesh Shetty',N'Indira Shetty',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7035',N'Sandeep Kumar','sandeep35civil7@student.university.edu','9136148782','d3fb93b284cc27f575cede1a317d587f3737673f19c39810e36b32fd353ee502',5,'Male','2005-06-07',N'Rohan Kumar',N'Nithya Kumar',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7036',N'Latha Khanna','latha36civil7@student.university.edu','9985916795','9bf54c66e3393734ebe964c6c17074ef8253959c4b74937afde8953f1e1547d9',5,'Female','2004-04-02',N'Akash Khanna',N'Sunita Khanna',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7037',N'Sandeep Pillai','sandeep37civil7@student.university.edu','9982474140','f5dd7225e67d93029dcff4d140d3908fc707cded538215b39b0ed2819c96d3f9',5,'Male','2003-09-10',N'Reyansh Pillai',N'Sruthi Pillai',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7038',N'Divya Jadhav','divya38civil7@student.university.edu','9065004254','846f95e5bbdd20fca0defa179700d255ab118157008c96f730e909d8f75f0590',5,'Female','2002-08-10',N'Manoj Jadhav',N'Kiara Jadhav',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7039',N'Reyansh Gupta','reyansh39civil7@student.university.edu','9691430753','b19001f17b3667b5185e973a0df684801e61de94720b43130662e757935193ba',5,'Male','2003-12-07',N'Suresh Gupta',N'Sunita Gupta',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7040',N'Latha Kale','latha40civil7@student.university.edu','9296592342','446691d99355b762f291576377e4036eb8cd78ac7e8146dc98f5933d317bf56c',5,'Female','2004-10-10',N'Arnav Kale',N'Rekha Kale',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7041',N'Ganesh Bansal','ganesh41civil7@student.university.edu','9826612875','0ebe8e461d1ac7c3408ea664c0da7dece5566360df50bdec2d12f6380f5f9ce1',5,'Male','2006-11-15',N'Sai Bansal',N'Nisha Bansal',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7042',N'Sruthi Patil','sruthi42civil7@student.university.edu','9061294398','6e4e9b7cdc7247bc5a4115983c8beed82fee937641d6710b39f952c0f74d7133',5,'Female','2005-01-18',N'Jagdish Patil',N'Suma Patil',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7043',N'Jignesh Kapoor','jignesh43civil7@student.university.edu','9607870104','ccb5adf7fc54413f4cc65f1f5857d7415031962bffb4bd6d192a36e40b3950df',5,'Male','2002-07-05',N'Alpesh Kapoor',N'Divya Kapoor',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7044',N'Kamala Verma','kamala44civil7@student.university.edu','9501980382','7e7e6f19e4eb2cc2aab8bb0971d07f3fc1fa03b28202fc393dafd49c1e38e883',5,'Female','2006-08-23',N'Yogesh Verma',N'Divya Verma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20215CIVIL7045',N'Yash Kale','yash45civil7@student.university.edu','9407931102','cc336e14f686c5b5da4c3976180986d94ecbe6f80820857ef561992a37369866',5,'Male','2003-05-21',N'Tushar Kale',N'Radha Kale',7,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1001',N'Aakash Rao','aakash1ece1@student.university.edu','9100000001','f4a660663a072122d1abc4221a282895beb1fa50ff7a0133126d8cb7be34cc2b',2,'Male','2002-02-02',N'Mr. Rao',N'Mrs. Rao',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1002',N'Bhavna Shetty','bhavna2ece1@student.university.edu','9100000002','58a12bd4d6dff2c7bc69402bb9683bf9f236a11632aa956c726fc93903cdae75',2,'Female','2001-03-03',N'Mr. Shetty',N'Mrs. Shetty',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1003',N'Chetan Nair','chetan3ece1@student.university.edu','9100000003','a844f8fb6692b495103661ed7514d9e534a114d4ee45e2b6c4f6522201b6e2b5',2,'Male','2003-04-04',N'Mr. Nair',N'Mrs. Nair',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1004',N'Deepa Pillai','deepa4ece1@student.university.edu','9100000004','b22cdb79cbaf5cd91a1098018449de4e2c4791fc7b92ad26be0d9ccb5c3f6851',2,'Female','2002-05-05',N'Mr. Pillai',N'Mrs. Pillai',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1005',N'Eshan Menon','eshan5ece1@student.university.edu','9100000005','0d4cc304d9ff3cf5b46285ad9f8b4ee804a6632e423ebfca70e315aecd288eb3',2,'Male','2001-06-06',N'Mr. Menon',N'Mrs. Menon',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1006',N'Farida Kumar','farida6ece1@student.university.edu','9100000006','3ed750e81ca28ec3216b2363d4b0efc05db5f9d734c6e792ee68822e577fbea7',2,'Female','2003-07-07',N'Mr. Kumar',N'Mrs. Kumar',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1007',N'Girish Gupta','girish7ece1@student.university.edu','9100000007','135381b1d10c554bdda2ce3672dd55175906c3c021feab154a5c2c42c6f4aed3',2,'Male','2002-08-08',N'Mr. Gupta',N'Mrs. Gupta',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1008',N'Heena Singh','heena8ece1@student.university.edu','9100000008','b0469afc2148c4cf43aab3f41c6f858f97f7ea23bd9041accfb4187540483b31',2,'Female','2001-09-09',N'Mr. Singh',N'Mrs. Singh',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1009',N'Ishan Sharma','ishan9ece1@student.university.edu','9100000009','22746d469f897398db15fc9b17640463e4867ab2d4e795d89ea50a33cbcc1233',2,'Male','2003-10-10',N'Mr. Sharma',N'Mrs. Sharma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1010',N'Jaya Patel','jaya10ece1@student.university.edu','9100000010','4a4b99935b157f81d5d09153e65e82c5850b43768619e470bd0dd221259c15bc',2,'Female','2002-11-11',N'Mr. Patel',N'Mrs. Patel',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1011',N'Kiran Iyer','kiran11ece1@student.university.edu','9100000011','97f5376b800a3753caf43253660c201ebabcca6eb8b452526bd44e4ee9ba047f',2,'Male','2001-12-12',N'Mr. Iyer',N'Mrs. Iyer',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1012',N'Lata Krishnan','lata12ece1@student.university.edu','9100000012','5b893b39ba52e35d795dd9bc3929642f949c376b8bb006cae0ab7457a53fd7db',2,'Female','2003-01-13',N'Mr. Krishnan',N'Mrs. Krishnan',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1013',N'Mohan Verma','mohan13ece1@student.university.edu','9100000013','604534f2a10bae495a7471d532d4cff4ed48e84dad432eabeca727b2de0876ab',2,'Male','2002-02-14',N'Mr. Verma',N'Mrs. Verma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1014',N'Neelu Pandey','neelu14ece1@student.university.edu','9100000014','604969f846e4b41fd422dbf2ec3543f578e8cd7f5b2cd453b76310261c8e96fc',2,'Female','2001-03-15',N'Mr. Pandey',N'Mrs. Pandey',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1015',N'Omar Mishra','omar15ece1@student.university.edu','9100000015','4577935b04a582e895b1090781b364dbd9c515c71cbf1697cf88c1a8e0ee950b',2,'Male','2003-04-16',N'Mr. Mishra',N'Mrs. Mishra',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1016',N'Preethi Joshi','preethi16ece1@student.university.edu','9100000016','04e6069d8ad71ae15e3a9ddb49167e6e5e6e532ff19b4eba2a6a646dc1eda1ee',2,'Female','2002-05-17',N'Mr. Joshi',N'Mrs. Joshi',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1017',N'Rima Agarwal','rima17ece1@student.university.edu','9100000017','6bf40d6a50cf428542ac77ca8a4e46efacd9628bdf38132e0009b9e6010a9aca',2,'Male','2001-06-18',N'Mr. Agarwal',N'Mrs. Agarwal',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1018',N'Sajan Mehta','sajan18ece1@student.university.edu','9100000018','f9ba5838904f97e70225c1ed5ade8f438fa9889e55cd6303e750f85f4c1a0e9d',2,'Female','2003-07-19',N'Mr. Mehta',N'Mrs. Mehta',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1019',N'Tina Shah','tina19ece1@student.university.edu','9100000019','f1c88724490a4cee6496306a081104a1d5413404cc0cab0e61a6ed96adb87893',2,'Male','2002-08-20',N'Mr. Shah',N'Mrs. Shah',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1020',N'Uday Das','uday20ece1@student.university.edu','9100000020','acdec934733f543384427b46c334a70f88e72ac875e4f439cf954d2932b852cf',2,'Female','2001-09-21',N'Mr. Das',N'Mrs. Das',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1021',N'Vani Rao','vani21ece1@student.university.edu','9100000021','14a03e7211b3888f9f69ec57e786a9af9bb5ce2ed2fe4f7c6f086c4010296a74',2,'Male','2003-10-22',N'Mr. Rao',N'Mrs. Rao',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1022',N'Wasim Shetty','wasim22ece1@student.university.edu','9100000022','cadc37c6ff09ae19e9fa8dc08f1b802d5716f540813f09fd16dcc96216774469',2,'Female','2002-11-23',N'Mr. Shetty',N'Mrs. Shetty',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1023',N'Yatin Nair','yatin23ece1@student.university.edu','9100000023','1ca0ade8095c0c30bf429fac1a32ebdcdd653931ecd6a31900c5371d525d8b8b',2,'Male','2001-12-24',N'Mr. Nair',N'Mrs. Nair',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1024',N'Zara Pillai','zara24ece1@student.university.edu','9100000024','8f60344c82f05988a08ec28bd826439ba734f56069de7c654e23fbc40191e43d',2,'Female','2003-01-25',N'Mr. Pillai',N'Mrs. Pillai',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1025',N'Abhay Menon','abhay25ece1@student.university.edu','9100000025','a129abf3a54ad1cfbc6a30288b8a3a7fa7274341b6aae5edc1c57dd80f227b53',2,'Male','2002-02-26',N'Mr. Menon',N'Mrs. Menon',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1026',N'Bina Kumar','bina26ece1@student.university.edu','9100000026','5834fba6cde4ef5f74f178550f397718fb23f925f73b78def5a08146d32a107c',2,'Female','2001-03-27',N'Mr. Kumar',N'Mrs. Kumar',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1027',N'Chirag Gupta','chirag27ece1@student.university.edu','9100000027','eed71a706d06f11af50042b718d93c5dd5ae57280bf9bfff3aa8b6d7edaa8b4f',2,'Male','2003-04-28',N'Mr. Gupta',N'Mrs. Gupta',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1028',N'Dolly Singh','dolly28ece1@student.university.edu','9100000028','12eefeac96676b5beaedcc764f932e55bd5ffc74df158991bc1a9790c6f91216',2,'Female','2002-05-01',N'Mr. Singh',N'Mrs. Singh',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1029',N'Eshwar Sharma','eshwar29ece1@student.university.edu','9100000029','199dae67379dc2e8894940d00ded0653b3028581a953743c9a96225f30e7c22f',2,'Male','2001-06-02',N'Mr. Sharma',N'Mrs. Sharma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1030',N'Fatima Patel','fatima30ece1@student.university.edu','9100000030','2ff5640fb4caa6f9b0194b453ab239e4f7fe46d6fe6ac492f9bb60327ad5e582',2,'Female','2003-07-03',N'Mr. Patel',N'Mrs. Patel',1,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1031',N'Ganesh Iyer','ganesh31ece1@student.university.edu','9100000031','722939dd7b9383669bfaa29e09bc4330653aafc21b5bb19382a5cd09c8bd0635',2,'Male','2002-08-04',N'Mr. Iyer',N'Mrs. Iyer',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1032',N'Hina Krishnan','hina32ece1@student.university.edu','9100000032','318ac437b011305cea2af3159cdb1a8ef03f0a42226950d174e8d6c46ff63495',2,'Female','2001-09-05',N'Mr. Krishnan',N'Mrs. Krishnan',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1033',N'Indra Verma','indra33ece1@student.university.edu','9100000033','0fc69a1276e1c7e75df22aa8345950e35b1fc1fd688fa381a603df3cf6488016',2,'Male','2003-10-06',N'Mr. Verma',N'Mrs. Verma',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1034',N'Jatin Pandey','jatin34ece1@student.university.edu','9100000034','640098ff6639bca68d46322bc78b591f9751ff19e40e27bea181ef9c2abdc505',2,'Female','2002-11-07',N'Mr. Pandey',N'Mrs. Pandey',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1035',N'Kavya Mishra','kavya35ece1@student.university.edu','9100000035','aa5b82c98ca32878d611f1587eceea3d34819cd8061737656ba2745289d9d7c1',2,'Male','2001-12-08',N'Mr. Mishra',N'Mrs. Mishra',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1036',N'Lalit Joshi','lalit36ece1@student.university.edu','9100000036','aaea7c3e4af59cdc81ec4e50628fd77fa28cd61f5a72c37c9f76d4e69b46092e',2,'Female','2003-01-09',N'Mr. Joshi',N'Mrs. Joshi',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1037',N'Mona Agarwal','mona37ece1@student.university.edu','9100000037','e58d1f0784f3efee82c7c84450e99faf22b424baaf8a8237c423e26ecbc6a812',2,'Male','2002-02-10',N'Mr. Agarwal',N'Mrs. Agarwal',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1038',N'Neeraj Mehta','neeraj38ece1@student.university.edu','9100000038','bc440a386969ef45d9eb7d11054b462217999331057fc124be0103811be6b774',2,'Female','2001-03-11',N'Mr. Mehta',N'Mrs. Mehta',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1039',N'Pavan Shah','pavan39ece1@student.university.edu','9100000039','5f6302702c8664af9731230031be049d8a64469aa0a72584c1f6e05eee39ed10',2,'Male','2003-04-12',N'Mr. Shah',N'Mrs. Shah',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1040',N'Riya Das','riya40ece1@student.university.edu','9100000040','6ad618a4e8d4b3cc756fb3dd338baf6a8bede135dd2653513cd261c6790603b3',2,'Female','2002-05-13',N'Mr. Das',N'Mrs. Das',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1041',N'Aakash Rao','aakash41ece1@student.university.edu','9100000041','06127980c6c713d88223209923195804e6b60bbf0e6fb81dd05de713b1decaa8',2,'Male','2001-06-14',N'Mr. Rao',N'Mrs. Rao',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1042',N'Bhavna Shetty','bhavna42ece1@student.university.edu','9100000042','5c2805b272fbf07a7521a5a898bc47d68fc5d6a2c54ff11de7accaf91e6e2c28',2,'Female','2003-07-15',N'Mr. Shetty',N'Mrs. Shetty',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1043',N'Chetan Nair','chetan43ece1@student.university.edu','9100000043','11ffb1e3d442e7fdecc690e4aa07ff9620678827e7288f636ba19405450d23f8',2,'Male','2002-08-16',N'Mr. Nair',N'Mrs. Nair',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1044',N'Deepa Pillai','deepa44ece1@student.university.edu','9100000044','fa746986ced4766347cac977f6dfd33aba63608bd7aca80833882f6dc55f55cb',2,'Female','2001-09-17',N'Mr. Pillai',N'Mrs. Pillai',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20242ECE1045',N'Eshan Menon','eshan45ece1@student.university.edu','9100000045','1327c6dff8c1b0a12f4c3990ae2a22d5a5db4296019a0063ed2cd6351df16020',2,'Male','2003-10-18',N'Mr. Menon',N'Mrs. Menon',1,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3001',N'Aakash Rao','aakash1ece3@student.university.edu','9100000046','1e8b2158b670580b57ff08495e5f7f600fce1761f1940c5016fa86090bb62b20',2,'Male','2002-02-02',N'Mr. Rao',N'Mrs. Rao',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3002',N'Bhavna Shetty','bhavna2ece3@student.university.edu','9100000047','0d8fa7b27042a5cb49f19c257f2a81ed96335ef77c484e0beb7f3f6e87c7c1cd',2,'Female','2001-03-03',N'Mr. Shetty',N'Mrs. Shetty',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3003',N'Chetan Nair','chetan3ece3@student.university.edu','9100000048','562125e6621da932c735e7e4c156128872c9d58800b7bb0922ec933fc3aec291',2,'Male','2003-04-04',N'Mr. Nair',N'Mrs. Nair',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3004',N'Deepa Pillai','deepa4ece3@student.university.edu','9100000049','e6ebd7e1614a1cd694b814802848b29fe56d6e3bb45bf52e103984371c2ac8cf',2,'Female','2002-05-05',N'Mr. Pillai',N'Mrs. Pillai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3005',N'Eshan Menon','eshan5ece3@student.university.edu','9100000050','1dc3aa86fb7026f4aa65c89dc9477dd868f94f21f80f290d77530da29aa16e48',2,'Male','2001-06-06',N'Mr. Menon',N'Mrs. Menon',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3006',N'Farida Kumar','farida6ece3@student.university.edu','9100000051','40f3b0c48f4cf3813f1acfa3d790a21bed1a7314a5dad8e18320f8a2732a9462',2,'Female','2003-07-07',N'Mr. Kumar',N'Mrs. Kumar',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3007',N'Girish Gupta','girish7ece3@student.university.edu','9100000052','47f9865645708e191046978c19b98e7496de93e3a293167c00cb63bd032d3fb6',2,'Male','2002-08-08',N'Mr. Gupta',N'Mrs. Gupta',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3008',N'Heena Singh','heena8ece3@student.university.edu','9100000053','67b9d6a6d25b7717db1ed9b88a1df4db051ed9ef8a677a200145202919e0b0f7',2,'Female','2001-09-09',N'Mr. Singh',N'Mrs. Singh',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3009',N'Ishan Sharma','ishan9ece3@student.university.edu','9100000054','516192abc57e86feacff73515ed2734358e2c5a565dd26a80c97b2a7fb163961',2,'Male','2003-10-10',N'Mr. Sharma',N'Mrs. Sharma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3010',N'Jaya Patel','jaya10ece3@student.university.edu','9100000055','1092d7e1ac0c7b189e1d48275b309976ab5481378e142e979f5cf755e8b63bd7',2,'Female','2002-11-11',N'Mr. Patel',N'Mrs. Patel',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3011',N'Kiran Iyer','kiran11ece3@student.university.edu','9100000056','885c76260ba5431f40b8a987da71180a132b1ad741d83ea4222e98b98ea33568',2,'Male','2001-12-12',N'Mr. Iyer',N'Mrs. Iyer',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3012',N'Lata Krishnan','lata12ece3@student.university.edu','9100000057','ee8224472758abe9bec2457b62bafd220ed1532ad0ad58cf0459192560ff2f19',2,'Female','2003-01-13',N'Mr. Krishnan',N'Mrs. Krishnan',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3013',N'Mohan Verma','mohan13ece3@student.university.edu','9100000058','503d239cf1893b61544f5918e025fc57aab08334735fb7364994ec8881a0e434',2,'Male','2002-02-14',N'Mr. Verma',N'Mrs. Verma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3014',N'Neelu Pandey','neelu14ece3@student.university.edu','9100000059','544a663610ed6987eda36b51313cebfcf6628d903ad1908d37495869fa1ffdbf',2,'Female','2001-03-15',N'Mr. Pandey',N'Mrs. Pandey',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3015',N'Omar Mishra','omar15ece3@student.university.edu','9100000060','2b6aa234ec5cd931e78e71603b0c0391a0e239e15d8b9f7cb8e75cb5b897dd3f',2,'Male','2003-04-16',N'Mr. Mishra',N'Mrs. Mishra',3,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3016',N'Preethi Joshi','preethi16ece3@student.university.edu','9100000061','74524d8cd0af15211f99b42a028429a2b6f9d1de6990a8b327b655b5e3950cfd',2,'Female','2002-05-17',N'Mr. Joshi',N'Mrs. Joshi',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3017',N'Rima Agarwal','rima17ece3@student.university.edu','9100000062','5acff4a038a92d41af43eb32ed53889fb7c3654c6f24f253c471ed8939251bba',2,'Male','2001-06-18',N'Mr. Agarwal',N'Mrs. Agarwal',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3018',N'Sajan Mehta','sajan18ece3@student.university.edu','9100000063','2744489b2f6c959a933c51662d376f474098fbdd94307a494566e5f2a7b84f27',2,'Female','2003-07-19',N'Mr. Mehta',N'Mrs. Mehta',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3019',N'Tina Shah','tina19ece3@student.university.edu','9100000064','d3922dd236e5cfbfe9e7e124456921e31e05cce3fecb995565afa189551a1a6e',2,'Male','2002-08-20',N'Mr. Shah',N'Mrs. Shah',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3020',N'Uday Das','uday20ece3@student.university.edu','9100000065','a752cf64180524fec123cf8930025df4ca3b94b83077da52e02f8a41efaa5c0f',2,'Female','2001-09-21',N'Mr. Das',N'Mrs. Das',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3021',N'Vani Rao','vani21ece3@student.university.edu','9100000066','6976910faf3edaa8be8ca6a88824df7717f4547b19d6be643df7720ae8f56443',2,'Male','2003-10-22',N'Mr. Rao',N'Mrs. Rao',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3022',N'Wasim Shetty','wasim22ece3@student.university.edu','9100000067','c8eb6a21c1b023ab8e0613c158ae9ea8dbd940f349014b7ef180d360ab51606c',2,'Female','2002-11-23',N'Mr. Shetty',N'Mrs. Shetty',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3023',N'Yatin Nair','yatin23ece3@student.university.edu','9100000068','451a95697b48be56d76231d908531754667106e70827b9b0c3c878bd1e849791',2,'Male','2001-12-24',N'Mr. Nair',N'Mrs. Nair',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3024',N'Zara Pillai','zara24ece3@student.university.edu','9100000069','4ac9e71b27a89117780aa1413a14a61a3cb862f8341356ae806b0532bcf3c0fd',2,'Female','2003-01-25',N'Mr. Pillai',N'Mrs. Pillai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3025',N'Abhay Menon','abhay25ece3@student.university.edu','9100000070','e1e659c21afdf4280ff932a5c9c1e7ff5bea044491a02f51428642db667a4a94',2,'Male','2002-02-26',N'Mr. Menon',N'Mrs. Menon',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3026',N'Bina Kumar','bina26ece3@student.university.edu','9100000071','c44fb4df4050faa993c829fe2460bd7268749a849ce4805d4daaf18904f51456',2,'Female','2001-03-27',N'Mr. Kumar',N'Mrs. Kumar',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3027',N'Chirag Gupta','chirag27ece3@student.university.edu','9100000072','cddd12d73ceca0ef5401a657a535b98f139edca427760080f90c5acfb12473ed',2,'Male','2003-04-28',N'Mr. Gupta',N'Mrs. Gupta',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3028',N'Dolly Singh','dolly28ece3@student.university.edu','9100000073','7ed1e11be9cbbfaa1452abc4f1aeff6baa89f9e3c1e5aeb7deea27736b7675de',2,'Female','2002-05-01',N'Mr. Singh',N'Mrs. Singh',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3029',N'Eshwar Sharma','eshwar29ece3@student.university.edu','9100000074','59d0e3c554f61ef0ee7e088ed4393e5941e50ac1bb3577f0286b4e03d9627042',2,'Male','2001-06-02',N'Mr. Sharma',N'Mrs. Sharma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3030',N'Fatima Patel','fatima30ece3@student.university.edu','9100000075','0b9bcd3940cba931ab88cf5956719912cbab9699e7e698966f83d9ac5c3bdc6d',2,'Female','2003-07-03',N'Mr. Patel',N'Mrs. Patel',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3031',N'Ganesh Iyer','ganesh31ece3@student.university.edu','9100000076','1ad1f791e3be59473b25abcb31cd9f562e488fad4757307c5753bdf44e98bbf1',2,'Male','2002-08-04',N'Mr. Iyer',N'Mrs. Iyer',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3032',N'Hina Krishnan','hina32ece3@student.university.edu','9100000077','08a5a7514f0b970358a39a8086b1555f1296dee97ce92935bd2afef073dcdc3b',2,'Female','2001-09-05',N'Mr. Krishnan',N'Mrs. Krishnan',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3033',N'Indra Verma','indra33ece3@student.university.edu','9100000078','de8e31c1c98e52a750bfc00d411335e5d967ac8fa7479e7e0f9164f550a5e774',2,'Male','2003-10-06',N'Mr. Verma',N'Mrs. Verma',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3034',N'Jatin Pandey','jatin34ece3@student.university.edu','9100000079','2caa32a49d5f9532945402ed42fe99e2d8f6a3031e462ece86ee5ed59e9a764c',2,'Female','2002-11-07',N'Mr. Pandey',N'Mrs. Pandey',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3035',N'Kavya Mishra','kavya35ece3@student.university.edu','9100000080','468f307a0e357d466ff5ae37b673df596230e8e4673007c1e229bda156b602ce',2,'Male','2001-12-08',N'Mr. Mishra',N'Mrs. Mishra',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3036',N'Lalit Joshi','lalit36ece3@student.university.edu','9100000081','7ea1d460c7bbe088577e00363e3f49cb50098465ef0515da86b925011ab75513',2,'Female','2003-01-09',N'Mr. Joshi',N'Mrs. Joshi',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3037',N'Mona Agarwal','mona37ece3@student.university.edu','9100000082','95b47704e065bfbc605dd474645418a8908c67e2df2d2569fdabdc501f096a63',2,'Male','2002-02-10',N'Mr. Agarwal',N'Mrs. Agarwal',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3038',N'Neeraj Mehta','neeraj38ece3@student.university.edu','9100000083','91e085cbaa0b7f4e71aeb3b704a9e3bfc27714278ba89c12b8e5bf380d0725ce',2,'Female','2001-03-11',N'Mr. Mehta',N'Mrs. Mehta',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3039',N'Pavan Shah','pavan39ece3@student.university.edu','9100000084','102886336878e225f8a1e468bc8d8dd1d92c5235941319b5293a0b0d137dfa65',2,'Male','2003-04-12',N'Mr. Shah',N'Mrs. Shah',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3040',N'Riya Das','riya40ece3@student.university.edu','9100000085','b864b571017205c7eed42d3d47fe296734dffc4569e998d97a1c8ee172d46f48',2,'Female','2002-05-13',N'Mr. Das',N'Mrs. Das',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3041',N'Aakash Rao','aakash41ece3@student.university.edu','9100000086','e8b9e7176665d372525b043a94e16a26b9ba266919ac64850e8577adc7bdd60b',2,'Male','2001-06-14',N'Mr. Rao',N'Mrs. Rao',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3042',N'Bhavna Shetty','bhavna42ece3@student.university.edu','9100000087','172f6b5d49394a56cc254e660a2c689682c7a8fdc294bd03f011f2943a7ee31c',2,'Female','2003-07-15',N'Mr. Shetty',N'Mrs. Shetty',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3043',N'Chetan Nair','chetan43ece3@student.university.edu','9100000088','f31c9d3935cf81a9ce59c6b385a14e64d74cec14baad1e86e5299670e293bccc',2,'Male','2002-08-16',N'Mr. Nair',N'Mrs. Nair',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3044',N'Deepa Pillai','deepa44ece3@student.university.edu','9100000089','cc4391c75b06c1efea773015054be9eb237f829035d0729a7555cca696efe10b',2,'Female','2001-09-17',N'Mr. Pillai',N'Mrs. Pillai',3,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20232ECE3045',N'Eshan Menon','eshan45ece3@student.university.edu','9100000090','59e869049b418529a11db541f2f56909fb492bb1f2d2dd4aa204884084739ce0',2,'Male','2003-10-18',N'Mr. Menon',N'Mrs. Menon',3,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5001',N'Aakash Rao','aakash1ece5@student.university.edu','9100000091','e1f35574490a6a6c22c0e6111f8ec62911b289736cc82e54da0f932127fdd340',2,'Male','2002-02-02',N'Mr. Rao',N'Mrs. Rao',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5002',N'Bhavna Shetty','bhavna2ece5@student.university.edu','9100000092','bb023589bb8dd4fff1b6ac585678481f6374cf67031c21973ddec7881bb0e4d7',2,'Female','2001-03-03',N'Mr. Shetty',N'Mrs. Shetty',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5003',N'Chetan Nair','chetan3ece5@student.university.edu','9100000093','91507c94feca0612b7ef6149e4c08503656355c156649cdec660d781ce5e1920',2,'Male','2003-04-04',N'Mr. Nair',N'Mrs. Nair',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5004',N'Deepa Pillai','deepa4ece5@student.university.edu','9100000094','29f326bde2c99d60a59479627350168d3a4a4e2dd74a5ab4697405a2a57a41e4',2,'Female','2002-05-05',N'Mr. Pillai',N'Mrs. Pillai',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5005',N'Eshan Menon','eshan5ece5@student.university.edu','9100000095','582e79e5897573cf3026d8cce36f7125a01dbb4dab4958821e17487a21ce51a7',2,'Male','2001-06-06',N'Mr. Menon',N'Mrs. Menon',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5006',N'Farida Kumar','farida6ece5@student.university.edu','9100000096','7839d9fabfbe19f56288c64a2f77cf2da137a708f0364dc93b07945ec1c27837',2,'Female','2003-07-07',N'Mr. Kumar',N'Mrs. Kumar',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5007',N'Girish Gupta','girish7ece5@student.university.edu','9100000097','ac75bb2b632c120d25d0782c286e8d15f62b50179cf5bd9945e27df9424ecb61',2,'Male','2002-08-08',N'Mr. Gupta',N'Mrs. Gupta',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5008',N'Heena Singh','heena8ece5@student.university.edu','9100000098','a84da5c2a1ff4f53672fd5752e2dbe24c57c1c89dca744f3c7230cda2ac2bc37',2,'Female','2001-09-09',N'Mr. Singh',N'Mrs. Singh',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5009',N'Ishan Sharma','ishan9ece5@student.university.edu','9100000099','9ec1374dd9502e6a450a941c37a9afe1d34b37e900f542d04dbc6d5f619709f5',2,'Male','2003-10-10',N'Mr. Sharma',N'Mrs. Sharma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5010',N'Jaya Patel','jaya10ece5@student.university.edu','9100000100','55cac18fa4ce72aa0df9d9a282b41611ad92a479bc34f0a40412d739bb35be38',2,'Female','2002-11-11',N'Mr. Patel',N'Mrs. Patel',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5011',N'Kiran Iyer','kiran11ece5@student.university.edu','9100000101','61dbe5e1d3ff04c5a908aa42fe34fa3f4c73672255978c8e2666fb9c30d37c53',2,'Male','2001-12-12',N'Mr. Iyer',N'Mrs. Iyer',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5012',N'Lata Krishnan','lata12ece5@student.university.edu','9100000102','4cee75f5dea851dde5352e01d0d246ddb3a1801793e16a1dbc9a95f77520a3bd',2,'Female','2003-01-13',N'Mr. Krishnan',N'Mrs. Krishnan',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5013',N'Mohan Verma','mohan13ece5@student.university.edu','9100000103','1cdf470b1fc2451dae46f138f2d9468085737ba29ee46380a1193d2730707323',2,'Male','2002-02-14',N'Mr. Verma',N'Mrs. Verma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5014',N'Neelu Pandey','neelu14ece5@student.university.edu','9100000104','14a3ca0e90a1d51adba1d5cf5a5962fd24b3d22a469127536e1af8e07875a334',2,'Female','2001-03-15',N'Mr. Pandey',N'Mrs. Pandey',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5015',N'Omar Mishra','omar15ece5@student.university.edu','9100000105','84c441eb44b192b9f8bbddd0b5bceeb28ee3a0e1fee43855f9a3784acccd0769',2,'Male','2003-04-16',N'Mr. Mishra',N'Mrs. Mishra',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5016',N'Preethi Joshi','preethi16ece5@student.university.edu','9100000106','b48498a29c9d4d64c407fb76b5f108af970ca4075a668941c82d57f0a2dbf2da',2,'Female','2002-05-17',N'Mr. Joshi',N'Mrs. Joshi',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5017',N'Rima Agarwal','rima17ece5@student.university.edu','9100000107','8b8274cb4be249b9a34b117616da40bdbb7d2b21e281ff97093dacaf7688c7c1',2,'Male','2001-06-18',N'Mr. Agarwal',N'Mrs. Agarwal',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5018',N'Sajan Mehta','sajan18ece5@student.university.edu','9100000108','11bb0af07503aa3b49a34da7dffaab0b5e8b79c438a0fbbfc3eb63f153a43826',2,'Female','2003-07-19',N'Mr. Mehta',N'Mrs. Mehta',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5019',N'Tina Shah','tina19ece5@student.university.edu','9100000109','27f78a3e09bb9ed339de5766cb550501ff3075fdf4ac78a6592092517d3a204a',2,'Male','2002-08-20',N'Mr. Shah',N'Mrs. Shah',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5020',N'Uday Das','uday20ece5@student.university.edu','9100000110','125b2029a60b79f44f2dd5ee3cda38ca8a9baef8e45ee420f153110eba45ced3',2,'Female','2001-09-21',N'Mr. Das',N'Mrs. Das',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5021',N'Vani Rao','vani21ece5@student.university.edu','9100000111','2e8a0fe0f20713fed6a9cfdf742478925de89fa8395845dd8a57b0c5246af216',2,'Male','2003-10-22',N'Mr. Rao',N'Mrs. Rao',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5022',N'Wasim Shetty','wasim22ece5@student.university.edu','9100000112','b2d2bae7c94e6f094748bc984472e93850cc45830e9ce92ac22a46f61a16b8c8',2,'Female','2002-11-23',N'Mr. Shetty',N'Mrs. Shetty',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5023',N'Yatin Nair','yatin23ece5@student.university.edu','9100000113','cbafd4adfd0aa8c6f99b635f2e8cec95540a702b3f804c4495d726dfe5f86572',2,'Male','2001-12-24',N'Mr. Nair',N'Mrs. Nair',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5024',N'Zara Pillai','zara24ece5@student.university.edu','9100000114','7b5e38e714336b97cbb41c60ea9cc7b81141ad7b6aa59a4ea699318d6e915bde',2,'Female','2003-01-25',N'Mr. Pillai',N'Mrs. Pillai',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5025',N'Abhay Menon','abhay25ece5@student.university.edu','9100000115','049fa53c6c85123e3c90dd4aa5b56918ebdbefafe44918db752fc4a091b57451',2,'Male','2002-02-26',N'Mr. Menon',N'Mrs. Menon',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5026',N'Bina Kumar','bina26ece5@student.university.edu','9100000116','a2c6ddd196e13b0b53e9b7ff3d110e455b7b93c9796b5537a5c9071a2a1df740',2,'Female','2001-03-27',N'Mr. Kumar',N'Mrs. Kumar',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5027',N'Chirag Gupta','chirag27ece5@student.university.edu','9100000117','028c508cc7b33271d9c683bc6bffc1ecdefb62701b389f38580fb9fec379700b',2,'Male','2003-04-28',N'Mr. Gupta',N'Mrs. Gupta',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5028',N'Dolly Singh','dolly28ece5@student.university.edu','9100000118','f3c31b5fca99ace7be15753e15ff43aa94506bb64c5d6af4b0021c6e8ff0cfde',2,'Female','2002-05-01',N'Mr. Singh',N'Mrs. Singh',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5029',N'Eshwar Sharma','eshwar29ece5@student.university.edu','9100000119','f729a46d2b2c6bd93d6c37404f8b70c22ee2b60a452d6f9b19e427ec89967232',2,'Male','2001-06-02',N'Mr. Sharma',N'Mrs. Sharma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5030',N'Fatima Patel','fatima30ece5@student.university.edu','9100000120','ff15a72c33df2c803134eabd8f9c0e13d7ef1acaa49bc8a6d823a66b990bcae8',2,'Female','2003-07-03',N'Mr. Patel',N'Mrs. Patel',5,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5031',N'Ganesh Iyer','ganesh31ece5@student.university.edu','9100000121','d67d07b83361218831f52e2bbb36b00a909aa8d668013e51bba0e12d3327f8f0',2,'Male','2002-08-04',N'Mr. Iyer',N'Mrs. Iyer',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5032',N'Hina Krishnan','hina32ece5@student.university.edu','9100000122','8a8227aa7140c0be6f148fba54f8277cdf1c4ef0cb8fc770fbbe5d4610051c03',2,'Female','2001-09-05',N'Mr. Krishnan',N'Mrs. Krishnan',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5033',N'Indra Verma','indra33ece5@student.university.edu','9100000123','64e6b4b6f6597f57b060b8712cd05eb4a057d5493957f3269f50263e96d65afd',2,'Male','2003-10-06',N'Mr. Verma',N'Mrs. Verma',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5034',N'Jatin Pandey','jatin34ece5@student.university.edu','9100000124','27ac90e399552e3343ec2dd4ab7515c37897b4db5f0e86a58ec5e51146818014',2,'Female','2002-11-07',N'Mr. Pandey',N'Mrs. Pandey',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5035',N'Kavya Mishra','kavya35ece5@student.university.edu','9100000125','6612c6cf10108024c370144c617f3b21721d06107202f5c37aa41bfbb1dcf434',2,'Male','2001-12-08',N'Mr. Mishra',N'Mrs. Mishra',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5036',N'Lalit Joshi','lalit36ece5@student.university.edu','9100000126','c030dcee2a416aaa1a3514a61c82ed949fb214ffd7c88cae1ac2bbe21b458abe',2,'Female','2003-01-09',N'Mr. Joshi',N'Mrs. Joshi',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5037',N'Mona Agarwal','mona37ece5@student.university.edu','9100000127','a1f8cb7a951628794d1d04d382ba43e2a9a574c107337664c73f6b78e1c25b37',2,'Male','2002-02-10',N'Mr. Agarwal',N'Mrs. Agarwal',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5038',N'Neeraj Mehta','neeraj38ece5@student.university.edu','9100000128','9def4cefa5612ccfe7956c9b1368f5da25a5de03d225fe2b0ec33b61887ce5b2',2,'Female','2001-03-11',N'Mr. Mehta',N'Mrs. Mehta',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5039',N'Pavan Shah','pavan39ece5@student.university.edu','9100000129','2a686bc06b62ba1b38b58e009cea92747aba23543e32c4575f7c609ace4ec0a0',2,'Male','2003-04-12',N'Mr. Shah',N'Mrs. Shah',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5040',N'Riya Das','riya40ece5@student.university.edu','9100000130','3e26d7a1f11b7aff644789267313290fd217fcd764a271b19820ba123f594e5a',2,'Female','2002-05-13',N'Mr. Das',N'Mrs. Das',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5041',N'Aakash Rao','aakash41ece5@student.university.edu','9100000131','c6da0fc770c0b9d72d1a2109991b71b4ad6c2a657f6d040f28b5eae4a1b67c46',2,'Male','2001-06-14',N'Mr. Rao',N'Mrs. Rao',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5042',N'Bhavna Shetty','bhavna42ece5@student.university.edu','9100000132','80c480ed10f68b97f9f1cb90498f398c2efa748aa30bcd64df138d036f5e4326',2,'Female','2003-07-15',N'Mr. Shetty',N'Mrs. Shetty',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5043',N'Chetan Nair','chetan43ece5@student.university.edu','9100000133','977208d219595211f176a6c851d77cb5ffe9086ff4d310c28478141591afc213',2,'Male','2002-08-16',N'Mr. Nair',N'Mrs. Nair',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5044',N'Deepa Pillai','deepa44ece5@student.university.edu','9100000134','c7b5720a61c6662e2bb8009cab1c1a30d310cf35663fc0efc953dfce1a3d0cfc',2,'Female','2001-09-17',N'Mr. Pillai',N'Mrs. Pillai',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20222ECE5045',N'Eshan Menon','eshan45ece5@student.university.edu','9100000135','45ccd0f6857440de412b27274dfa87909e7340af9502d81a0b68952d5152fc79',2,'Male','2003-10-18',N'Mr. Menon',N'Mrs. Menon',5,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7001',N'Aakash Rao','aakash1ece7@student.university.edu','9100000136','5a583ebfa6dd22259ffe4f4540e9330de3f3801855a4b6cb5032f57794d0df8e',2,'Male','2002-02-02',N'Mr. Rao',N'Mrs. Rao',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7002',N'Bhavna Shetty','bhavna2ece7@student.university.edu','9100000137','118cfe3635c89b430e08e46a73ab5b510e628c33177749ed7e7f926d16dcf80c',2,'Female','2001-03-03',N'Mr. Shetty',N'Mrs. Shetty',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7003',N'Chetan Nair','chetan3ece7@student.university.edu','9100000138','7f93db1441ffa1d975cec3cf05a9f2a7ce7ac58dd3b6b25a610dabc0f466619d',2,'Male','2003-04-04',N'Mr. Nair',N'Mrs. Nair',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7004',N'Deepa Pillai','deepa4ece7@student.university.edu','9100000139','064b2ce5f69befd2c08012371f5c0ff3e37089dabd634bb29c75724146d4a2bb',2,'Female','2002-05-05',N'Mr. Pillai',N'Mrs. Pillai',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7005',N'Eshan Menon','eshan5ece7@student.university.edu','9100000140','d7ca8c7442c2efc91d5434a440a05ffc449c16f22e2d4ae1309aca328ccd6ea2',2,'Male','2001-06-06',N'Mr. Menon',N'Mrs. Menon',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7006',N'Farida Kumar','farida6ece7@student.university.edu','9100000141','d699606d88dcd5fe7918aca0bd2ecf97a565c54821bb76dac3c73aaba256490a',2,'Female','2003-07-07',N'Mr. Kumar',N'Mrs. Kumar',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7007',N'Girish Gupta','girish7ece7@student.university.edu','9100000142','75426e8eb80c38197794c18b95385ab42bbfc064f7e8d17c93088417cf47f80e',2,'Male','2002-08-08',N'Mr. Gupta',N'Mrs. Gupta',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7008',N'Heena Singh','heena8ece7@student.university.edu','9100000143','bfcc069ae9558b8dc6ab9ebff4ef03f4d16de7540998189ed1c7637a69d2db28',2,'Female','2001-09-09',N'Mr. Singh',N'Mrs. Singh',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7009',N'Ishan Sharma','ishan9ece7@student.university.edu','9100000144','f7cee9a6a4bac306daf5fc0b928ca814f256519fcdcd88609a845cdbd6df7991',2,'Male','2003-10-10',N'Mr. Sharma',N'Mrs. Sharma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7010',N'Jaya Patel','jaya10ece7@student.university.edu','9100000145','9282bfde1adc82d6d222c754245956515663cff60fc26f30d3bb60e28ac0deba',2,'Female','2002-11-11',N'Mr. Patel',N'Mrs. Patel',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7011',N'Kiran Iyer','kiran11ece7@student.university.edu','9100000146','fcb3a2aef7638730adc59d8d3a1660d1d225cae5b14975ea6cce045d1e5a42dc',2,'Male','2001-12-12',N'Mr. Iyer',N'Mrs. Iyer',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7012',N'Lata Krishnan','lata12ece7@student.university.edu','9100000147','a6c56a8543cff96be4adaa2a6cf648e9d63ae7755edd22ffa91c3f3373de6b4b',2,'Female','2003-01-13',N'Mr. Krishnan',N'Mrs. Krishnan',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7013',N'Mohan Verma','mohan13ece7@student.university.edu','9100000148','fd2f9872d192b1486740be180bfe46f4c5863cb993b764a49fca2f965f7a9143',2,'Male','2002-02-14',N'Mr. Verma',N'Mrs. Verma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7014',N'Neelu Pandey','neelu14ece7@student.university.edu','9100000149','52f5fd41ee9cfe18fec33ea7d1ddd076fe6b13668f163b395f1a47bc02763c03',2,'Female','2001-03-15',N'Mr. Pandey',N'Mrs. Pandey',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7015',N'Omar Mishra','omar15ece7@student.university.edu','9100000150','4e82ece34075c063e33fc9e37879867bed969115f5100bcbc03ccf4434e2df6f',2,'Male','2003-04-16',N'Mr. Mishra',N'Mrs. Mishra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7016',N'Preethi Joshi','preethi16ece7@student.university.edu','9100000151','80c0ddfb1491401220d19b9eab600f0513e79060c69945f4c48ac52c5c6d742e',2,'Female','2002-05-17',N'Mr. Joshi',N'Mrs. Joshi',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7017',N'Rima Agarwal','rima17ece7@student.university.edu','9100000152','04cbe81682d88ec12bd1000496578d5508452b2f892c204d042aa9b1761bd621',2,'Male','2001-06-18',N'Mr. Agarwal',N'Mrs. Agarwal',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7018',N'Sajan Mehta','sajan18ece7@student.university.edu','9100000153','8022c690b316b0840474e57f76a81b4ced055809f13f1ff6c95a8133531f3f28',2,'Female','2003-07-19',N'Mr. Mehta',N'Mrs. Mehta',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7019',N'Tina Shah','tina19ece7@student.university.edu','9100000154','29572c9a2b3634a20897f65d639ccf9c4ba809ab9630e92ea0c083f6ad19da36',2,'Male','2002-08-20',N'Mr. Shah',N'Mrs. Shah',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7020',N'Uday Das','uday20ece7@student.university.edu','9100000155','0ec252e783d58ed289073b592c6b97ca8d3de9efff4465336b98025217a2671f',2,'Female','2001-09-21',N'Mr. Das',N'Mrs. Das',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7021',N'Vani Rao','vani21ece7@student.university.edu','9100000156','fa99193145314f56e6cc44cd8bfdcd63745027ebd0af81b54c385503f3377464',2,'Male','2003-10-22',N'Mr. Rao',N'Mrs. Rao',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7022',N'Wasim Shetty','wasim22ece7@student.university.edu','9100000157','c8ce79ec38a8a1fb95fd4cefb2c7d35cdcb14f1a18104524f681bb06a0e90eb5',2,'Female','2002-11-23',N'Mr. Shetty',N'Mrs. Shetty',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7023',N'Yatin Nair','yatin23ece7@student.university.edu','9100000158','8bfd01a421f60f122c9f5f7be7cea0967ea8e2d6eec0a04d8550b40b87da95b3',2,'Male','2001-12-24',N'Mr. Nair',N'Mrs. Nair',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7024',N'Zara Pillai','zara24ece7@student.university.edu','9100000159','d80668a14c8b6ee4f98d7add656f2b35baa215ae8180d943f66b3853f3ce69ce',2,'Female','2003-01-25',N'Mr. Pillai',N'Mrs. Pillai',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7025',N'Abhay Menon','abhay25ece7@student.university.edu','9100000160','3cedb58fc24c480b714e5c0a89782a332676067cf2390d6723c128310c0f5c52',2,'Male','2002-02-26',N'Mr. Menon',N'Mrs. Menon',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7026',N'Bina Kumar','bina26ece7@student.university.edu','9100000161','5f8c4f06b6c6d38f85900b14ec4c20f5e338e061582bdb3b77f86799e6686654',2,'Female','2001-03-27',N'Mr. Kumar',N'Mrs. Kumar',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7027',N'Chirag Gupta','chirag27ece7@student.university.edu','9100000162','b4670c0c0655344fffee39b4e0510be7e038bd7edce3e5ad2b65261425009c63',2,'Male','2003-04-28',N'Mr. Gupta',N'Mrs. Gupta',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7028',N'Dolly Singh','dolly28ece7@student.university.edu','9100000163','4ad989bbfb168bd6a4209ace177a915b628ebc3f46cd0a3c80abe057012154b2',2,'Female','2002-05-01',N'Mr. Singh',N'Mrs. Singh',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7029',N'Eshwar Sharma','eshwar29ece7@student.university.edu','9100000164','1faad5e89abdfbf7c654a4cb4dc749587d51a161681554e3bf622e4be35ec0b4',2,'Male','2001-06-02',N'Mr. Sharma',N'Mrs. Sharma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7030',N'Fatima Patel','fatima30ece7@student.university.edu','9100000165','04441fd8e52965d061a0cf8c50426a7f85c5a766c5ec295680cff857599db533',2,'Female','2003-07-03',N'Mr. Patel',N'Mrs. Patel',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7031',N'Ganesh Iyer','ganesh31ece7@student.university.edu','9100000166','3099eab8e253ad3ef6a618633e1d64dd1d82e6d88ebdebe7ce6044877b8bf347',2,'Male','2002-08-04',N'Mr. Iyer',N'Mrs. Iyer',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7032',N'Hina Krishnan','hina32ece7@student.university.edu','9100000167','c8964a2dbd2d74e85a7491c914b2d7d995a3a2a2c202f9140eaaaaec95ef37c0',2,'Female','2001-09-05',N'Mr. Krishnan',N'Mrs. Krishnan',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7033',N'Indra Verma','indra33ece7@student.university.edu','9100000168','90f84fdaf567076d522b00fb90668c21a2531d2e16729903ab08f21d2cef8edf',2,'Male','2003-10-06',N'Mr. Verma',N'Mrs. Verma',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7034',N'Jatin Pandey','jatin34ece7@student.university.edu','9100000169','00e9eed6817a1f698abb38c06dd2ceb673aa77f584e1811eef2247fc8ade6dff',2,'Female','2002-11-07',N'Mr. Pandey',N'Mrs. Pandey',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7035',N'Kavya Mishra','kavya35ece7@student.university.edu','9100000170','8605033310c4105ffdb059ce5b97c4dd8630e3ee29cb3be3b513cb9322ab3ba0',2,'Male','2001-12-08',N'Mr. Mishra',N'Mrs. Mishra',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7036',N'Lalit Joshi','lalit36ece7@student.university.edu','9100000171','03f326c63a87b57cbb6f42e790462765784cce8135ccabade6e153e6145ba998',2,'Female','2003-01-09',N'Mr. Joshi',N'Mrs. Joshi',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7037',N'Mona Agarwal','mona37ece7@student.university.edu','9100000172','d2d6f4892529db34a8ab3fad76b85d36cf3e493cf91e5cd200688e7186941f1d',2,'Male','2002-02-10',N'Mr. Agarwal',N'Mrs. Agarwal',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7038',N'Neeraj Mehta','neeraj38ece7@student.university.edu','9100000173','a431589df6742dea04a4cb977372bdf2f13c70c9210a3e8e0f729ed95d8642b0',2,'Female','2001-03-11',N'Mr. Mehta',N'Mrs. Mehta',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7039',N'Pavan Shah','pavan39ece7@student.university.edu','9100000174','86cd8afbf39294b37cc16f3cd41ea1e36c4db0debfddd95c73b53da46203f568',2,'Male','2003-04-12',N'Mr. Shah',N'Mrs. Shah',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7040',N'Riya Das','riya40ece7@student.university.edu','9100000175','0bc5248378e3261156fdd89a4dd242fedf2f38a9772751200f394ce8db4c4204',2,'Female','2002-05-13',N'Mr. Das',N'Mrs. Das',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7041',N'Aakash Rao','aakash41ece7@student.university.edu','9100000176','ff1eae6d1e8ecd307c5ef511cbc1a668ee1960d3e34f03cd3da0c67c7e9ea2fe',2,'Male','2001-06-14',N'Mr. Rao',N'Mrs. Rao',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7042',N'Bhavna Shetty','bhavna42ece7@student.university.edu','9100000177','737ead5ac7442236f2a274d7eb4e3211caa9cfa6c6883784d6df2447759209d5',2,'Female','2003-07-15',N'Mr. Shetty',N'Mrs. Shetty',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7043',N'Chetan Nair','chetan43ece7@student.university.edu','9100000178','4f9304c8493526f653ec7b627a47ad16c79a8459fbeca5bd83c55049704a0c16',2,'Male','2002-08-16',N'Mr. Nair',N'Mrs. Nair',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7044',N'Deepa Pillai','deepa44ece7@student.university.edu','9100000179','5a67692e43d5496a91acd8e910091b51bf386b8eafc3160e512e58f4023a804f',2,'Female','2001-09-17',N'Mr. Pillai',N'Mrs. Pillai',7,1,1,'2024-07-15',GETDATE(),GETDATE());
INSERT INTO Users (UserType,UserCode,FullName,Email,Phone,PasswordHash,DepartmentID,Gender,DateOfBirth,FatherName,MotherName,Semester,IsFirstLogin,IsActive,JoinDate,CreatedAt,UpdatedAt)
VALUES ('Student','STUID20212ECE7045',N'Eshan Menon','eshan45ece7@student.university.edu','9100000180','3e08abe15da6e583cc8f75a392882fa7af01886c7654d30a7a96790afa6714b9',2,'Male','2003-10-18',N'Mr. Menon',N'Mrs. Menon',7,1,1,'2024-07-15',GETDATE(),GETDATE());
GO
GO

-- ================================================================

-- ================================================================
-- STEP 7: Timetable — CORRECTED
-- Theory subjects: 3 periods/week on different days (e.g. Mon/Wed/Fri)
-- Lab subjects:    2 periods/week on different days (e.g. Mon/Thu)
-- ZERO teacher conflicts, ZERO class conflicts
-- Days well-distributed, not same subject every single day
-- ================================================================
IF OBJECT_ID('Timetable') IS NOT NULL DELETE FROM Timetable;
GO

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),1,1,'Monday','09:00','09:50','CSE-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),1,1,'Wednesday','11:00','11:50','CSE-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),1,1,'Friday','13:40','14:30','CSE-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),1,1,'Monday','10:00','10:50','CSE-1-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),1,1,'Tuesday','12:00','12:50','CSE-1-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),1,1,'Thursday','14:40','15:30','CSE-1-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003'),1,1,'Tuesday','11:00','11:50','CSE-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003'),1,1,'Wednesday','13:40','14:30','CSE-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003'),1,1,'Friday','15:40','16:30','CSE-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID004'),1,1,'Monday','12:00','12:50','CSE-1-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID004'),1,1,'Thursday','15:40','16:30','CSE-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID004'),1,1,'Friday','16:40','17:30','CSE-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005'),1,1,'Tuesday','13:40','14:30','CSE-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005'),1,1,'Thursday','16:40','17:30','CSE-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005'),1,1,'Friday','09:00','09:50','CSE-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE106L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID006'),1,1,'Monday','14:40','15:30','CSE-1-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE106L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID006'),1,1,'Thursday','09:00','09:50','CSE-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE107L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007'),1,1,'Tuesday','15:40','16:30','CSE-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE107L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007'),1,1,'Friday','10:00','10:50','CSE-1-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE108L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008'),1,1,'Wednesday','16:40','17:30','CSE-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE108L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008'),1,1,'Friday','11:00','11:50','CSE-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009'),1,3,'Monday','09:00','09:50','CSE-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009'),1,3,'Wednesday','11:00','11:50','CSE-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009'),1,3,'Friday','13:40','14:30','CSE-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010'),1,3,'Monday','10:00','10:50','CSE-3-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010'),1,3,'Tuesday','12:00','12:50','CSE-3-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010'),1,3,'Thursday','14:40','15:30','CSE-3-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),1,3,'Tuesday','11:00','11:50','CSE-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),1,3,'Wednesday','13:40','14:30','CSE-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),1,3,'Friday','15:40','16:30','CSE-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),1,3,'Monday','12:00','12:50','CSE-3-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),1,3,'Thursday','15:40','16:30','CSE-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),1,3,'Friday','16:40','17:30','CSE-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003'),1,3,'Tuesday','13:40','14:30','CSE-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003'),1,3,'Thursday','16:40','17:30','CSE-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003'),1,3,'Friday','09:00','09:50','CSE-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE306L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID004'),1,3,'Monday','14:40','15:30','CSE-3-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE306L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID004'),1,3,'Thursday','09:00','09:50','CSE-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE307L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005'),1,3,'Tuesday','15:40','16:30','CSE-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE307L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005'),1,3,'Friday','10:00','10:50','CSE-3-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE308L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID006'),1,3,'Wednesday','16:40','17:30','CSE-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE308L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID006'),1,3,'Friday','11:00','11:50','CSE-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007'),1,5,'Monday','09:00','09:50','CSE-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007'),1,5,'Wednesday','11:00','11:50','CSE-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007'),1,5,'Friday','13:40','14:30','CSE-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008'),1,5,'Monday','10:00','10:50','CSE-5-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008'),1,5,'Tuesday','12:00','12:50','CSE-5-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008'),1,5,'Thursday','14:40','15:30','CSE-5-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009'),1,5,'Tuesday','11:00','11:50','CSE-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009'),1,5,'Wednesday','13:40','14:30','CSE-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009'),1,5,'Friday','15:40','16:30','CSE-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010'),1,5,'Monday','12:00','12:50','CSE-5-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010'),1,5,'Thursday','15:40','16:30','CSE-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010'),1,5,'Friday','16:40','17:30','CSE-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),1,5,'Tuesday','13:40','14:30','CSE-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),1,5,'Thursday','16:40','17:30','CSE-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),1,5,'Friday','09:00','09:50','CSE-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE506L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),1,5,'Monday','14:40','15:30','CSE-5-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE506L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),1,5,'Thursday','09:00','09:50','CSE-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE507L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003'),1,5,'Tuesday','15:40','16:30','CSE-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE507L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003'),1,5,'Friday','10:00','10:50','CSE-5-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE508L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID004'),1,5,'Wednesday','16:40','17:30','CSE-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE508L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID004'),1,5,'Friday','11:00','11:50','CSE-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005'),1,7,'Monday','09:00','09:50','CSE-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005'),1,7,'Wednesday','11:00','11:50','CSE-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005'),1,7,'Friday','13:40','14:30','CSE-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID006'),1,7,'Monday','10:00','10:50','CSE-7-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID006'),1,7,'Tuesday','12:00','12:50','CSE-7-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID006'),1,7,'Thursday','14:40','15:30','CSE-7-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007'),1,7,'Tuesday','11:00','11:50','CSE-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007'),1,7,'Wednesday','13:40','14:30','CSE-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007'),1,7,'Friday','15:40','16:30','CSE-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008'),1,7,'Monday','12:00','12:50','CSE-7-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008'),1,7,'Thursday','15:40','16:30','CSE-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008'),1,7,'Friday','16:40','17:30','CSE-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009'),1,7,'Tuesday','13:40','14:30','CSE-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009'),1,7,'Thursday','16:40','17:30','CSE-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009'),1,7,'Friday','09:00','09:50','CSE-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE706L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010'),1,7,'Monday','14:40','15:30','CSE-7-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE706L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010'),1,7,'Thursday','09:00','09:50','CSE-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE707L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),1,7,'Tuesday','15:40','16:30','CSE-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE707L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),1,7,'Friday','10:00','10:50','CSE-7-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE708L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),1,7,'Wednesday','16:40','17:30','CSE-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=1 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE708L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),1,7,'Friday','11:00','11:50','CSE-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),2,1,'Monday','09:00','09:50','ECE-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),2,1,'Wednesday','11:00','11:50','ECE-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),2,1,'Friday','13:40','14:30','ECE-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),2,1,'Monday','10:00','10:50','ECE-1-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),2,1,'Tuesday','12:00','12:50','ECE-1-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),2,1,'Thursday','14:40','15:30','ECE-1-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013'),2,1,'Tuesday','11:00','11:50','ECE-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013'),2,1,'Wednesday','13:40','14:30','ECE-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013'),2,1,'Friday','15:40','16:30','ECE-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID014'),2,1,'Monday','12:00','12:50','ECE-1-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID014'),2,1,'Thursday','15:40','16:30','ECE-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID014'),2,1,'Friday','16:40','17:30','ECE-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015'),2,1,'Tuesday','13:40','14:30','ECE-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015'),2,1,'Thursday','16:40','17:30','ECE-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015'),2,1,'Friday','09:00','09:50','ECE-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE106L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID016'),2,1,'Monday','14:40','15:30','ECE-1-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE106L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID016'),2,1,'Thursday','09:00','09:50','ECE-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE107L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017'),2,1,'Tuesday','15:40','16:30','ECE-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE107L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017'),2,1,'Friday','10:00','10:50','ECE-1-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE108L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018'),2,1,'Wednesday','16:40','17:30','ECE-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE108L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018'),2,1,'Friday','11:00','11:50','ECE-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019'),2,3,'Monday','09:00','09:50','ECE-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019'),2,3,'Wednesday','11:00','11:50','ECE-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019'),2,3,'Friday','13:40','14:30','ECE-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020'),2,3,'Monday','10:00','10:50','ECE-3-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020'),2,3,'Tuesday','12:00','12:50','ECE-3-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020'),2,3,'Thursday','14:40','15:30','ECE-3-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),2,3,'Tuesday','11:00','11:50','ECE-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),2,3,'Wednesday','13:40','14:30','ECE-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),2,3,'Friday','15:40','16:30','ECE-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),2,3,'Monday','12:00','12:50','ECE-3-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),2,3,'Thursday','15:40','16:30','ECE-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),2,3,'Friday','16:40','17:30','ECE-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013'),2,3,'Tuesday','13:40','14:30','ECE-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013'),2,3,'Thursday','16:40','17:30','ECE-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013'),2,3,'Friday','09:00','09:50','ECE-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE306L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID014'),2,3,'Monday','14:40','15:30','ECE-3-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE306L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID014'),2,3,'Thursday','09:00','09:50','ECE-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE307L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015'),2,3,'Tuesday','15:40','16:30','ECE-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE307L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015'),2,3,'Friday','10:00','10:50','ECE-3-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE308L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID016'),2,3,'Wednesday','16:40','17:30','ECE-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE308L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID016'),2,3,'Friday','11:00','11:50','ECE-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017'),2,5,'Monday','09:00','09:50','ECE-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017'),2,5,'Wednesday','11:00','11:50','ECE-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017'),2,5,'Friday','13:40','14:30','ECE-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018'),2,5,'Monday','10:00','10:50','ECE-5-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018'),2,5,'Tuesday','12:00','12:50','ECE-5-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018'),2,5,'Thursday','14:40','15:30','ECE-5-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019'),2,5,'Tuesday','11:00','11:50','ECE-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019'),2,5,'Wednesday','13:40','14:30','ECE-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019'),2,5,'Friday','15:40','16:30','ECE-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020'),2,5,'Monday','12:00','12:50','ECE-5-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020'),2,5,'Thursday','15:40','16:30','ECE-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020'),2,5,'Friday','16:40','17:30','ECE-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),2,5,'Tuesday','13:40','14:30','ECE-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),2,5,'Thursday','16:40','17:30','ECE-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),2,5,'Friday','09:00','09:50','ECE-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE506L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),2,5,'Monday','14:40','15:30','ECE-5-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE506L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),2,5,'Thursday','09:00','09:50','ECE-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE507L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013'),2,5,'Tuesday','15:40','16:30','ECE-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE507L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013'),2,5,'Friday','10:00','10:50','ECE-5-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE508L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID014'),2,5,'Wednesday','16:40','17:30','ECE-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE508L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID014'),2,5,'Friday','11:00','11:50','ECE-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015'),2,7,'Monday','09:00','09:50','ECE-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015'),2,7,'Wednesday','11:00','11:50','ECE-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015'),2,7,'Friday','13:40','14:30','ECE-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID016'),2,7,'Monday','10:00','10:50','ECE-7-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID016'),2,7,'Tuesday','12:00','12:50','ECE-7-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID016'),2,7,'Thursday','14:40','15:30','ECE-7-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017'),2,7,'Tuesday','11:00','11:50','ECE-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017'),2,7,'Wednesday','13:40','14:30','ECE-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017'),2,7,'Friday','15:40','16:30','ECE-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018'),2,7,'Monday','12:00','12:50','ECE-7-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018'),2,7,'Thursday','15:40','16:30','ECE-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018'),2,7,'Friday','16:40','17:30','ECE-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019'),2,7,'Tuesday','13:40','14:30','ECE-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019'),2,7,'Thursday','16:40','17:30','ECE-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019'),2,7,'Friday','09:00','09:50','ECE-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE706L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020'),2,7,'Monday','14:40','15:30','ECE-7-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE706L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020'),2,7,'Thursday','09:00','09:50','ECE-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE707L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),2,7,'Tuesday','15:40','16:30','ECE-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE707L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),2,7,'Friday','10:00','10:50','ECE-7-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE708L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),2,7,'Wednesday','16:40','17:30','ECE-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=2 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE708L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),2,7,'Friday','11:00','11:50','ECE-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),3,1,'Monday','09:00','09:50','EEE-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),3,1,'Wednesday','11:00','11:50','EEE-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),3,1,'Friday','13:40','14:30','EEE-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),3,1,'Monday','10:00','10:50','EEE-1-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),3,1,'Tuesday','12:00','12:50','EEE-1-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),3,1,'Thursday','14:40','15:30','EEE-1-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023'),3,1,'Tuesday','11:00','11:50','EEE-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023'),3,1,'Wednesday','13:40','14:30','EEE-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023'),3,1,'Friday','15:40','16:30','EEE-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID024'),3,1,'Monday','12:00','12:50','EEE-1-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID024'),3,1,'Thursday','15:40','16:30','EEE-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID024'),3,1,'Friday','16:40','17:30','EEE-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025'),3,1,'Tuesday','13:40','14:30','EEE-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025'),3,1,'Thursday','16:40','17:30','EEE-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025'),3,1,'Friday','09:00','09:50','EEE-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE106L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID026'),3,1,'Monday','14:40','15:30','EEE-1-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE106L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID026'),3,1,'Thursday','09:00','09:50','EEE-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE107L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027'),3,1,'Tuesday','15:40','16:30','EEE-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE107L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027'),3,1,'Friday','10:00','10:50','EEE-1-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE108L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028'),3,1,'Wednesday','16:40','17:30','EEE-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE108L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028'),3,1,'Friday','11:00','11:50','EEE-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029'),3,3,'Monday','09:00','09:50','EEE-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029'),3,3,'Wednesday','11:00','11:50','EEE-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029'),3,3,'Friday','13:40','14:30','EEE-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030'),3,3,'Monday','10:00','10:50','EEE-3-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030'),3,3,'Tuesday','12:00','12:50','EEE-3-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030'),3,3,'Thursday','14:40','15:30','EEE-3-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),3,3,'Tuesday','11:00','11:50','EEE-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),3,3,'Wednesday','13:40','14:30','EEE-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),3,3,'Friday','15:40','16:30','EEE-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),3,3,'Monday','12:00','12:50','EEE-3-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),3,3,'Thursday','15:40','16:30','EEE-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),3,3,'Friday','16:40','17:30','EEE-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023'),3,3,'Tuesday','13:40','14:30','EEE-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023'),3,3,'Thursday','16:40','17:30','EEE-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023'),3,3,'Friday','09:00','09:50','EEE-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE306L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID024'),3,3,'Monday','14:40','15:30','EEE-3-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE306L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID024'),3,3,'Thursday','09:00','09:50','EEE-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE307L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025'),3,3,'Tuesday','15:40','16:30','EEE-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE307L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025'),3,3,'Friday','10:00','10:50','EEE-3-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE308L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID026'),3,3,'Wednesday','16:40','17:30','EEE-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE308L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID026'),3,3,'Friday','11:00','11:50','EEE-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027'),3,5,'Monday','09:00','09:50','EEE-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027'),3,5,'Wednesday','11:00','11:50','EEE-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027'),3,5,'Friday','13:40','14:30','EEE-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028'),3,5,'Monday','10:00','10:50','EEE-5-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028'),3,5,'Tuesday','12:00','12:50','EEE-5-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028'),3,5,'Thursday','14:40','15:30','EEE-5-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029'),3,5,'Tuesday','11:00','11:50','EEE-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029'),3,5,'Wednesday','13:40','14:30','EEE-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029'),3,5,'Friday','15:40','16:30','EEE-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030'),3,5,'Monday','12:00','12:50','EEE-5-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030'),3,5,'Thursday','15:40','16:30','EEE-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030'),3,5,'Friday','16:40','17:30','EEE-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),3,5,'Tuesday','13:40','14:30','EEE-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),3,5,'Thursday','16:40','17:30','EEE-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),3,5,'Friday','09:00','09:50','EEE-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE506L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),3,5,'Monday','14:40','15:30','EEE-5-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE506L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),3,5,'Thursday','09:00','09:50','EEE-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE507L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023'),3,5,'Tuesday','15:40','16:30','EEE-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE507L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023'),3,5,'Friday','10:00','10:50','EEE-5-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE508L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID024'),3,5,'Wednesday','16:40','17:30','EEE-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE508L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID024'),3,5,'Friday','11:00','11:50','EEE-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025'),3,7,'Monday','09:00','09:50','EEE-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025'),3,7,'Wednesday','11:00','11:50','EEE-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025'),3,7,'Friday','13:40','14:30','EEE-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID026'),3,7,'Monday','10:00','10:50','EEE-7-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID026'),3,7,'Tuesday','12:00','12:50','EEE-7-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID026'),3,7,'Thursday','14:40','15:30','EEE-7-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027'),3,7,'Tuesday','11:00','11:50','EEE-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027'),3,7,'Wednesday','13:40','14:30','EEE-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027'),3,7,'Friday','15:40','16:30','EEE-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028'),3,7,'Monday','12:00','12:50','EEE-7-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028'),3,7,'Thursday','15:40','16:30','EEE-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028'),3,7,'Friday','16:40','17:30','EEE-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029'),3,7,'Tuesday','13:40','14:30','EEE-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029'),3,7,'Thursday','16:40','17:30','EEE-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029'),3,7,'Friday','09:00','09:50','EEE-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE706L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030'),3,7,'Monday','14:40','15:30','EEE-7-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE706L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030'),3,7,'Thursday','09:00','09:50','EEE-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE707L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),3,7,'Tuesday','15:40','16:30','EEE-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE707L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),3,7,'Friday','10:00','10:50','EEE-7-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE708L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),3,7,'Wednesday','16:40','17:30','EEE-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=3 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE708L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),3,7,'Friday','11:00','11:50','EEE-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),4,1,'Monday','09:00','09:50','ME-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),4,1,'Wednesday','11:00','11:50','ME-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),4,1,'Friday','13:40','14:30','ME-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),4,1,'Monday','10:00','10:50','ME-1-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),4,1,'Tuesday','12:00','12:50','ME-1-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),4,1,'Thursday','14:40','15:30','ME-1-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033'),4,1,'Tuesday','11:00','11:50','ME-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033'),4,1,'Wednesday','13:40','14:30','ME-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033'),4,1,'Friday','15:40','16:30','ME-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID034'),4,1,'Monday','12:00','12:50','ME-1-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID034'),4,1,'Thursday','15:40','16:30','ME-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID034'),4,1,'Friday','16:40','17:30','ME-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035'),4,1,'Tuesday','13:40','14:30','ME-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035'),4,1,'Thursday','16:40','17:30','ME-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035'),4,1,'Friday','09:00','09:50','ME-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME106L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID036'),4,1,'Monday','14:40','15:30','ME-1-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME106L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID036'),4,1,'Thursday','09:00','09:50','ME-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME107L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037'),4,1,'Tuesday','15:40','16:30','ME-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME107L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037'),4,1,'Friday','10:00','10:50','ME-1-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME108L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038'),4,1,'Wednesday','16:40','17:30','ME-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME108L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038'),4,1,'Friday','11:00','11:50','ME-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039'),4,3,'Monday','09:00','09:50','ME-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039'),4,3,'Wednesday','11:00','11:50','ME-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039'),4,3,'Friday','13:40','14:30','ME-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040'),4,3,'Monday','10:00','10:50','ME-3-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040'),4,3,'Tuesday','12:00','12:50','ME-3-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040'),4,3,'Thursday','14:40','15:30','ME-3-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),4,3,'Tuesday','11:00','11:50','ME-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),4,3,'Wednesday','13:40','14:30','ME-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),4,3,'Friday','15:40','16:30','ME-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),4,3,'Monday','12:00','12:50','ME-3-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),4,3,'Thursday','15:40','16:30','ME-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),4,3,'Friday','16:40','17:30','ME-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033'),4,3,'Tuesday','13:40','14:30','ME-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033'),4,3,'Thursday','16:40','17:30','ME-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033'),4,3,'Friday','09:00','09:50','ME-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME306L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID034'),4,3,'Monday','14:40','15:30','ME-3-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME306L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID034'),4,3,'Thursday','09:00','09:50','ME-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME307L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035'),4,3,'Tuesday','15:40','16:30','ME-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME307L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035'),4,3,'Friday','10:00','10:50','ME-3-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME308L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID036'),4,3,'Wednesday','16:40','17:30','ME-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME308L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID036'),4,3,'Friday','11:00','11:50','ME-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037'),4,5,'Monday','09:00','09:50','ME-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037'),4,5,'Wednesday','11:00','11:50','ME-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037'),4,5,'Friday','13:40','14:30','ME-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038'),4,5,'Monday','10:00','10:50','ME-5-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038'),4,5,'Tuesday','12:00','12:50','ME-5-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038'),4,5,'Thursday','14:40','15:30','ME-5-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039'),4,5,'Tuesday','11:00','11:50','ME-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039'),4,5,'Wednesday','13:40','14:30','ME-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039'),4,5,'Friday','15:40','16:30','ME-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040'),4,5,'Monday','12:00','12:50','ME-5-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040'),4,5,'Thursday','15:40','16:30','ME-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040'),4,5,'Friday','16:40','17:30','ME-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),4,5,'Tuesday','13:40','14:30','ME-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),4,5,'Thursday','16:40','17:30','ME-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),4,5,'Friday','09:00','09:50','ME-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME506L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),4,5,'Monday','14:40','15:30','ME-5-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME506L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),4,5,'Thursday','09:00','09:50','ME-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME507L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033'),4,5,'Tuesday','15:40','16:30','ME-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME507L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033'),4,5,'Friday','10:00','10:50','ME-5-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME508L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID034'),4,5,'Wednesday','16:40','17:30','ME-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME508L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID034'),4,5,'Friday','11:00','11:50','ME-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035'),4,7,'Monday','09:00','09:50','ME-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035'),4,7,'Wednesday','11:00','11:50','ME-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035'),4,7,'Friday','13:40','14:30','ME-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID036'),4,7,'Monday','10:00','10:50','ME-7-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID036'),4,7,'Tuesday','12:00','12:50','ME-7-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID036'),4,7,'Thursday','14:40','15:30','ME-7-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037'),4,7,'Tuesday','11:00','11:50','ME-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037'),4,7,'Wednesday','13:40','14:30','ME-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037'),4,7,'Friday','15:40','16:30','ME-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038'),4,7,'Monday','12:00','12:50','ME-7-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038'),4,7,'Thursday','15:40','16:30','ME-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038'),4,7,'Friday','16:40','17:30','ME-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039'),4,7,'Tuesday','13:40','14:30','ME-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039'),4,7,'Thursday','16:40','17:30','ME-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039'),4,7,'Friday','09:00','09:50','ME-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME706L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040'),4,7,'Monday','14:40','15:30','ME-7-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME706L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040'),4,7,'Thursday','09:00','09:50','ME-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME707L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),4,7,'Tuesday','15:40','16:30','ME-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME707L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),4,7,'Friday','10:00','10:50','ME-7-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME708L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),4,7,'Wednesday','16:40','17:30','ME-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=4 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME708L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),4,7,'Friday','11:00','11:50','ME-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),5,1,'Monday','09:00','09:50','CE-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),5,1,'Wednesday','11:00','11:50','CE-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE101'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),5,1,'Friday','13:40','14:30','CE-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),5,1,'Monday','10:00','10:50','CE-1-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),5,1,'Tuesday','12:00','12:50','CE-1-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE102'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),5,1,'Thursday','14:40','15:30','CE-1-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043'),5,1,'Tuesday','11:00','11:50','CE-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043'),5,1,'Wednesday','13:40','14:30','CE-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE103'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043'),5,1,'Friday','15:40','16:30','CE-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID044'),5,1,'Monday','12:00','12:50','CE-1-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID044'),5,1,'Thursday','15:40','16:30','CE-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE104'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID044'),5,1,'Friday','16:40','17:30','CE-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045'),5,1,'Tuesday','13:40','14:30','CE-1-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045'),5,1,'Thursday','16:40','17:30','CE-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE105'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045'),5,1,'Friday','09:00','09:50','CE-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE106L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID046'),5,1,'Monday','14:40','15:30','CE-1-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE106L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID046'),5,1,'Thursday','09:00','09:50','CE-1-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE107L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047'),5,1,'Tuesday','15:40','16:30','CE-1-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE107L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047'),5,1,'Friday','10:00','10:50','CE-1-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE108L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048'),5,1,'Wednesday','16:40','17:30','CE-1-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=1 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE108L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048'),5,1,'Friday','11:00','11:50','CE-1-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049'),5,3,'Monday','09:00','09:50','CE-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049'),5,3,'Wednesday','11:00','11:50','CE-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE301'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049'),5,3,'Friday','13:40','14:30','CE-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050'),5,3,'Monday','10:00','10:50','CE-3-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050'),5,3,'Tuesday','12:00','12:50','CE-3-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE302'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050'),5,3,'Thursday','14:40','15:30','CE-3-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),5,3,'Tuesday','11:00','11:50','CE-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),5,3,'Wednesday','13:40','14:30','CE-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE303'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),5,3,'Friday','15:40','16:30','CE-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),5,3,'Monday','12:00','12:50','CE-3-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),5,3,'Thursday','15:40','16:30','CE-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE304'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),5,3,'Friday','16:40','17:30','CE-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043'),5,3,'Tuesday','13:40','14:30','CE-3-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043'),5,3,'Thursday','16:40','17:30','CE-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE305'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043'),5,3,'Friday','09:00','09:50','CE-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE306L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID044'),5,3,'Monday','14:40','15:30','CE-3-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE306L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID044'),5,3,'Thursday','09:00','09:50','CE-3-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE307L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045'),5,3,'Tuesday','15:40','16:30','CE-3-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE307L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045'),5,3,'Friday','10:00','10:50','CE-3-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE308L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID046'),5,3,'Wednesday','16:40','17:30','CE-3-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=3 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE308L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID046'),5,3,'Friday','11:00','11:50','CE-3-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047'),5,5,'Monday','09:00','09:50','CE-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047'),5,5,'Wednesday','11:00','11:50','CE-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE501'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047'),5,5,'Friday','13:40','14:30','CE-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048'),5,5,'Monday','10:00','10:50','CE-5-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048'),5,5,'Tuesday','12:00','12:50','CE-5-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE502'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048'),5,5,'Thursday','14:40','15:30','CE-5-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049'),5,5,'Tuesday','11:00','11:50','CE-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049'),5,5,'Wednesday','13:40','14:30','CE-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE503'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049'),5,5,'Friday','15:40','16:30','CE-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050'),5,5,'Monday','12:00','12:50','CE-5-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050'),5,5,'Thursday','15:40','16:30','CE-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE504'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050'),5,5,'Friday','16:40','17:30','CE-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),5,5,'Tuesday','13:40','14:30','CE-5-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),5,5,'Thursday','16:40','17:30','CE-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE505'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),5,5,'Friday','09:00','09:50','CE-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE506L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),5,5,'Monday','14:40','15:30','CE-5-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE506L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),5,5,'Thursday','09:00','09:50','CE-5-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE507L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043'),5,5,'Tuesday','15:40','16:30','CE-5-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE507L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043'),5,5,'Friday','10:00','10:50','CE-5-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE508L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID044'),5,5,'Wednesday','16:40','17:30','CE-5-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=5 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE508L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID044'),5,5,'Friday','11:00','11:50','CE-5-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045'),5,7,'Monday','09:00','09:50','CE-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045'),5,7,'Wednesday','11:00','11:50','CE-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE701'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045'),5,7,'Friday','13:40','14:30','CE-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID046'),5,7,'Monday','10:00','10:50','CE-7-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID046'),5,7,'Tuesday','12:00','12:50','CE-7-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE702'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID046'),5,7,'Thursday','14:40','15:30','CE-7-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047'),5,7,'Tuesday','11:00','11:50','CE-7-R3',3,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047'),5,7,'Wednesday','13:40','14:30','CE-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE703'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047'),5,7,'Friday','15:40','16:30','CE-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=4)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048'),5,7,'Monday','12:00','12:50','CE-7-R4',4,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048'),5,7,'Thursday','15:40','16:30','CE-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE704'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048'),5,7,'Friday','16:40','17:30','CE-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=5)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049'),5,7,'Tuesday','13:40','14:30','CE-7-R5',5,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049'),5,7,'Thursday','16:40','17:30','CE-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE705'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049'),5,7,'Friday','09:00','09:50','CE-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Monday' AND PeriodNumber=6)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE706L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050'),5,7,'Monday','14:40','15:30','CE-7-R6',6,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Thursday' AND PeriodNumber=1)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE706L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050'),5,7,'Thursday','09:00','09:50','CE-7-R1',1,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Tuesday' AND PeriodNumber=7)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE707L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),5,7,'Tuesday','15:40','16:30','CE-7-R7',7,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=2)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE707L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),5,7,'Friday','10:00','10:50','CE-7-R2',2,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Wednesday' AND PeriodNumber=8)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE708L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),5,7,'Wednesday','16:40','17:30','CE-7-R8',8,GETDATE());

IF NOT EXISTS (SELECT 1 FROM Timetable WHERE DepartmentID=5 AND Semester=7 AND DayOfWeek='Friday' AND PeriodNumber=3)
INSERT INTO Timetable (SubjectID,TeacherID,DepartmentID,Semester,DayOfWeek,StartTime,EndTime,RoomNumber,PeriodNumber,CreatedAt)
VALUES ((SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE708L'),(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),5,7,'Friday','11:00','11:50','CE-7-R3',3,GETDATE());

-- ================================================================
-- STEP 8: TeacherSubjects (160 assignments)
-- ================================================================
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE101'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE101'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE101'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE101'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE303'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE303'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE303'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE303'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE505'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE505'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE505'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE505'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE707L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID001'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE707L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE707L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE707L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE102'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE102'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE102'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE102'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE304'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE304'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE304'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE304'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE506L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE506L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE506L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE506L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE708L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID002'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE708L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE708L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE708L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE103'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE103'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE103'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE103'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE305'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE305'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE305'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE305'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE507L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID003'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE507L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE507L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE507L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID004') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE104'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID004'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE104'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE104'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE104'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID004') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE306L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID004'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE306L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE306L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE306L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID004') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE508L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID004'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE508L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE508L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE508L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE105'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE105'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE105'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE105'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE307L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE307L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE307L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE307L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE701'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID005'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE701'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE701'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE701'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID006') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE106L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID006'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE106L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE106L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE106L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID006') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE308L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID006'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE308L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE308L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE308L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID006') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE702'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID006'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE702'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE702'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE702'));
GO
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE107L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE107L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE107L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE107L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE501'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE501'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE501'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE501'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE703'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID007'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE703'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE703'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE703'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE108L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE108L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE108L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE108L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE502'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE502'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE502'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE502'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE704'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID008'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE704'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE704'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE704'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE301'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE301'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE301'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE301'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE503'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE503'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE503'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE503'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE705'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID009'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE705'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE705'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE705'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE302'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE302'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE302'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE302'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE504'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE504'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE504'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE504'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE706L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID010'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CSE706L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CSE706L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CSE706L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE101'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE101'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE101'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE101'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE303'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE303'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE303'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE303'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE505'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE505'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE505'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE505'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE707L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID011'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE707L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE707L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE707L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE102'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE102'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE102'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE102'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE304'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE304'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE304'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE304'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE506L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE506L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE506L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE506L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE708L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID012'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE708L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE708L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE708L'));
GO
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE103'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE103'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE103'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE103'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE305'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE305'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE305'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE305'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE507L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID013'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE507L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE507L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE507L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID014') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE104'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID014'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE104'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE104'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE104'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID014') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE306L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID014'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE306L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE306L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE306L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID014') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE508L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID014'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE508L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE508L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE508L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE105'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE105'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE105'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE105'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE307L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE307L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE307L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE307L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE701'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID015'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE701'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE701'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE701'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID016') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE106L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID016'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE106L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE106L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE106L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID016') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE308L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID016'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE308L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE308L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE308L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID016') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE702'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID016'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE702'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE702'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE702'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE107L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE107L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE107L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE107L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE501'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE501'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE501'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE501'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE703'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID017'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE703'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE703'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE703'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE108L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE108L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE108L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE108L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE502'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE502'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE502'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE502'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE704'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID018'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE704'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE704'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE704'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE301'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE301'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE301'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE301'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE503'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE503'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE503'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE503'));
GO
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE705'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID019'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE705'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE705'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE705'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE302'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE302'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE302'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE302'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE504'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE504'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE504'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE504'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE706L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID020'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ECE706L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ECE706L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ECE706L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE101'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE101'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE101'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE101'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE303'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE303'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE303'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE303'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE505'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE505'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE505'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE505'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE707L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID021'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE707L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE707L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE707L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE102'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE102'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE102'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE102'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE304'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE304'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE304'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE304'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE506L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE506L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE506L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE506L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE708L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID022'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE708L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE708L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE708L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE103'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE103'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE103'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE103'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE305'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE305'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE305'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE305'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE507L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID023'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE507L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE507L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE507L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID024') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE104'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID024'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE104'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE104'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE104'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID024') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE306L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID024'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE306L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE306L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE306L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID024') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE508L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID024'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE508L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE508L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE508L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE105'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE105'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE105'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE105'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE307L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE307L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE307L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE307L'));
GO
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE701'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID025'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE701'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE701'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE701'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID026') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE106L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID026'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE106L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE106L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE106L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID026') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE308L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID026'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE308L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE308L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE308L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID026') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE702'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID026'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE702'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE702'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE702'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE107L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE107L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE107L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE107L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE501'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE501'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE501'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE501'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE703'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID027'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE703'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE703'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE703'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE108L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE108L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE108L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE108L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE502'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE502'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE502'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE502'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE704'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID028'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE704'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE704'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE704'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE301'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE301'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE301'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE301'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE503'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE503'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE503'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE503'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE705'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID029'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE705'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE705'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE705'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE302'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE302'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE302'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE302'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE504'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE504'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE504'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE504'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE706L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID030'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='EEE706L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='EEE706L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='EEE706L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME101'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME101'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME101'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME101'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME303'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME303'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME303'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME303'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME505'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME505'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME505'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME505'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME707L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID031'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME707L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME707L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME707L'));
GO
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME102'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME102'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME102'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME102'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME304'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME304'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME304'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME304'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME506L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME506L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME506L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME506L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME708L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID032'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME708L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME708L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME708L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME103'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME103'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME103'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME103'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME305'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME305'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME305'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME305'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME507L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID033'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME507L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME507L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME507L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID034') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME104'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID034'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME104'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME104'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME104'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID034') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME306L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID034'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME306L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME306L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME306L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID034') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME508L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID034'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME508L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME508L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME508L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME105'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME105'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME105'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME105'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME307L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME307L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME307L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME307L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME701'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID035'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME701'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME701'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME701'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID036') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME106L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID036'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME106L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME106L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME106L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID036') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME308L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID036'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME308L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME308L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME308L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID036') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME702'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID036'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME702'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME702'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME702'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME107L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME107L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME107L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME107L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME501'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME501'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME501'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME501'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME703'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID037'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME703'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME703'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME703'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME108L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME108L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME108L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME108L'));
GO
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME502'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME502'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME502'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME502'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME704'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID038'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME704'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME704'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME704'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME301'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME301'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME301'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME301'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME503'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME503'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME503'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME503'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME705'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID039'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME705'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME705'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME705'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME302'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME302'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME302'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME302'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME504'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME504'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME504'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME504'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME706L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID040'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='ME706L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='ME706L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='ME706L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE101'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE101'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE101'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE101'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE303'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE303'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE303'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE303'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE505'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE505'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE505'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE505'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE707L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID041'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE707L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE707L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE707L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE102'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE102'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE102'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE102'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE304'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE304'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE304'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE304'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE506L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE506L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE506L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE506L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE708L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID042'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE708L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE708L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE708L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE103'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE103'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE103'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE103'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE305'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE305'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE305'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE305'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE507L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID043'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE507L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE507L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE507L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID044') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE104'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID044'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE104'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE104'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE104'));
GO
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID044') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE306L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID044'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE306L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE306L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE306L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID044') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE508L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID044'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE508L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE508L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE508L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE105'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE105'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE105'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE105'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE307L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE307L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE307L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE307L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE701'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID045'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE701'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE701'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE701'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID046') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE106L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID046'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE106L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE106L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE106L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID046') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE308L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID046'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE308L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE308L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE308L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID046') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE702'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID046'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE702'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE702'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE702'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE107L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE107L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE107L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE107L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE501'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE501'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE501'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE501'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE703'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID047'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE703'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE703'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE703'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE108L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE108L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE108L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE108L'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE502'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE502'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE502'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE502'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE704'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID048'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE704'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE704'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE704'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE301'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE301'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE301'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE301'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE503'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE503'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE503'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE503'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE705'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID049'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE705'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE705'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE705'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE302'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE302'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE302'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE302'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE504'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE504'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE504'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE504'));
IF NOT EXISTS (SELECT 1 FROM TeacherSubjects WHERE TeacherID=(SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050') AND SubjectID=(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE706L'))
INSERT INTO TeacherSubjects (TeacherID,SubjectID,DepartmentID,Semester)
VALUES ((SELECT TOP 1 UserID FROM Users WHERE UserCode='TID050'),(SELECT TOP 1 SubjectID FROM Subjects WHERE SubjectCode='CE706L'),(SELECT TOP 1 DepartmentID FROM Subjects WHERE SubjectCode='CE706L'),(SELECT TOP 1 Semester FROM Subjects WHERE SubjectCode='CE706L'));
GO
GO

-- ================================================================
-- STEP 9: StudentEnrollments — one enrollment record per student
-- ================================================================
INSERT INTO StudentEnrollments (StudentID)
SELECT u.UserID
FROM Users u
WHERE u.UserType = 'Student' AND u.IsActive = 1
  AND NOT EXISTS (SELECT 1 FROM StudentEnrollments se WHERE se.StudentID = u.UserID);
GO

-- ================================================================
-- STEP 10: Re-enable FK constraints
-- ================================================================
IF OBJECT_ID('ExamSubmissions') IS NOT NULL ALTER TABLE ExamSubmissions CHECK CONSTRAINT ALL;
IF OBJECT_ID('Attendance') IS NOT NULL ALTER TABLE Attendance CHECK CONSTRAINT ALL;
IF OBJECT_ID('QRCodes') IS NOT NULL ALTER TABLE QRCodes CHECK CONSTRAINT ALL;
IF OBJECT_ID('Marks') IS NOT NULL ALTER TABLE Marks CHECK CONSTRAINT ALL;
IF OBJECT_ID('StudentEnrollments') IS NOT NULL ALTER TABLE StudentEnrollments CHECK CONSTRAINT ALL;
IF OBJECT_ID('TeacherSubjects') IS NOT NULL ALTER TABLE TeacherSubjects CHECK CONSTRAINT ALL;
IF OBJECT_ID('ExamQuestions') IS NOT NULL ALTER TABLE ExamQuestions CHECK CONSTRAINT ALL;
IF OBJECT_ID('Exams') IS NOT NULL ALTER TABLE Exams CHECK CONSTRAINT ALL;
IF OBJECT_ID('StudyMaterials') IS NOT NULL ALTER TABLE StudyMaterials CHECK CONSTRAINT ALL;
IF OBJECT_ID('OnlineClasses') IS NOT NULL ALTER TABLE OnlineClasses CHECK CONSTRAINT ALL;
IF OBJECT_ID('Timetable') IS NOT NULL ALTER TABLE Timetable CHECK CONSTRAINT ALL;
GO

-- ================================================================
-- STEP 11: VERIFICATION — run after to confirm success
-- ================================================================
SELECT 'Admin'               AS Entity, COUNT(*) AS Count FROM Users WHERE UserType='Admin'
UNION ALL SELECT 'Teachers',            COUNT(*) FROM Users WHERE UserType='Teacher' AND IsActive=1
UNION ALL SELECT 'Students',            COUNT(*) FROM Users WHERE UserType='Student' AND IsActive=1
UNION ALL SELECT 'Departments',         COUNT(*) FROM Departments
UNION ALL SELECT 'Classes',             COUNT(*) FROM Classes WHERE AcademicYear='2024-25'
UNION ALL SELECT 'Subjects',            COUNT(*) FROM Subjects
UNION ALL SELECT 'Timetable Slots',     COUNT(*) FROM Timetable
UNION ALL SELECT 'TeacherSubjects',     COUNT(*) FROM TeacherSubjects
UNION ALL SELECT 'StudentEnrollments',  COUNT(*) FROM StudentEnrollments;
GO

-- Sample: student full timetable with teacher names
SELECT TOP 10
    u.FullName AS Student, u.UserCode AS RollNo, d.DepartmentCode AS Branch, u.Semester,
    sub.SubjectCode, sub.SubjectName, t.FullName AS Teacher, t.UserCode AS TCode,
    tt.DayOfWeek, CONVERT(VARCHAR,tt.StartTime,108) AS Start, CONVERT(VARCHAR,tt.EndTime,108) AS [End], tt.RoomNumber
FROM StudentEnrollments se
JOIN Users u      ON u.UserID        = se.StudentID
JOIN Departments d ON d.DepartmentID  = u.DepartmentID
JOIN Subjects sub ON sub.DepartmentID = u.DepartmentID AND sub.Semester = u.Semester
JOIN Timetable tt ON tt.SubjectID     = sub.SubjectID
JOIN Users t      ON t.UserID         = tt.TeacherID
WHERE u.UserType = 'Student'
ORDER BY u.UserCode, tt.DayOfWeek, tt.StartTime;
GO

-- Health: students with NO enrollments (must be 0)
SELECT COUNT(*) AS StudentsWithNoEnrollments FROM Users u WHERE u.UserType='Student' AND u.IsActive=1
  AND NOT EXISTS (SELECT 1 FROM StudentEnrollments se WHERE se.StudentID=u.UserID);
GO

-- Health: teachers with NO timetable slots (must return 0 rows)
SELECT u.UserCode, u.FullName FROM Users u WHERE u.UserType='Teacher' AND u.IsActive=1
  AND NOT EXISTS (SELECT 1 FROM Timetable tt WHERE tt.TeacherID=u.UserID);
GO