-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 12, 2026 at 06:20 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `emobile_voting`
--

-- --------------------------------------------------------

--
-- Table structure for table `candidates`
--

CREATE TABLE `candidates` (
  `candidate_id` int(11) NOT NULL,
  `poll_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `position` varchar(50) NOT NULL,
  `party_name` varchar(50) DEFAULT 'Independent',
  `course_year` varchar(80) NOT NULL,
  `description_platform` text DEFAULT NULL,
  `photo_url` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `candidates`
--

INSERT INTO `candidates` (`candidate_id`, `poll_id`, `name`, `position`, `party_name`, `course_year`, `description_platform`, `photo_url`) VALUES
(1, 1, 'Ben Davis', 'President', 'DIGITS Party', 'Bachelor of Science in Information Technology - 4th Year', 'Technology for a better campus.', NULL),
(2, 1, 'Jane Smith', 'President', 'Future Leaders', 'Bachelor of Science in Biology - 4th Year', 'Building sustainable student communities.', NULL),
(3, 1, 'Mark Taylor', 'President', 'Independent', 'Bachelor of Arts in Communication - 4th Year', 'Transparent and open leadership.', NULL),
(4, 1, 'Sarah Connor', 'President', 'Innovators Bloc', 'Bachelor of Science in Tourism Management - 4th Year', 'Innovating the way we learn.', NULL),
(5, 1, 'Emily Clark', 'President', 'Progressive Party', 'Bachelor of Elementary Education - 4th Year', 'Progressive policies for all.', NULL),
(6, 1, 'David Evans', 'President', 'SQU Party', 'Bachelor of Science in Hospitality Management - 4th Year', 'Service and Quality Uncompromised.', NULL),
(7, 1, 'John Wick', 'President', 'United Students', 'Bachelor of Science in Social Work - 4th Year', 'United we stand.', NULL),
(8, 1, 'Anna Wilson', 'Vice President', 'DIGITS Party', 'Bachelor of Science in Information Technology - 3rd Year', 'Empowering the student body.', NULL),
(9, 1, 'Chris Evans', 'Vice President', 'Future Leaders', 'Bachelor of Science in Biology - 3rd Year', 'A future-proof administration.', NULL),
(10, 1, 'Sophia Turner', 'Vice President', 'Independent', 'Bachelor of Arts in Communication - 3rd Year', 'Independent voices matter.', NULL),
(11, 1, 'Liam Neeson', 'Vice President', 'Innovators Bloc', 'Bachelor of Science in Tourism Management - 3rd Year', 'Creative solutions to old problems.', NULL),
(12, 1, 'Olivia Brown', 'Vice President', 'Progressive Party', 'Bachelor of Elementary Education - 3rd Year', 'Education first.', NULL),
(13, 1, 'Lucas Harris', 'Vice President', 'SQU Party', 'Bachelor of Science in Hospitality Management - 3rd Year', 'Excellence in representation.', NULL),
(14, 1, 'Emma White', 'Vice President', 'United Students', 'Bachelor of Science in Social Work - 3rd Year', 'Advocating for student welfare.', NULL),
(15, 1, 'Michael Scott', 'Secretary', 'DIGITS Party', 'Bachelor of Science in Information Technology - 2nd Year', 'Organized and efficient.', NULL),
(16, 1, 'Jessica Alba', 'Secretary', 'Future Leaders', 'Bachelor of Science in Biology - 2nd Year', 'Clear communication channels.', NULL),
(17, 1, 'Robert Downey', 'Secretary', 'Independent', 'Bachelor of Arts in Communication - 2nd Year', 'Unbiased record keeping.', NULL),
(18, 1, 'Megan Fox', 'Secretary', 'Innovators Bloc', 'Bachelor of Science in Tourism Management - 2nd Year', 'Modernizing administration.', NULL),
(19, 1, 'Paul Rudd', 'Secretary', 'Progressive Party', 'Bachelor of Elementary Education - 2nd Year', 'Diligent service.', NULL),
(20, 1, 'Scarlett Johansson', 'Secretary', 'SQU Party', 'Bachelor of Science in Hospitality Management - 2nd Year', 'Service with a smile.', NULL),
(21, 1, 'Tom Holland', 'Secretary', 'United Students', 'Bachelor of Science in Social Work - 2nd Year', 'Connecting with you.', NULL),
(22, 1, 'Natalie Portman', 'Treasurer', 'DIGITS Party', 'Bachelor of Science in Information Technology - 3rd Year', 'Transparent financials.', NULL),
(23, 1, 'Chris Hemsworth', 'Treasurer', 'Future Leaders', 'Bachelor of Science in Biology - 3rd Year', 'Accountability in spending.', NULL),
(24, 1, 'Gal Gadot', 'Treasurer', 'Independent', 'Bachelor of Arts in Communication - 3rd Year', 'Honest budgeting.', NULL),
(25, 1, 'Mark Ruffalo', 'Treasurer', 'Innovators Bloc', 'Bachelor of Science in Tourism Management - 3rd Year', 'Smart funding allocations.', NULL),
(26, 1, 'Brie Larson', 'Treasurer', 'Progressive Party', 'Bachelor of Elementary Education - 3rd Year', 'Progressive resource management.', NULL),
(27, 1, 'Jeremy Renner', 'Treasurer', 'SQU Party', 'Bachelor of Science in Hospitality Management - 3rd Year', 'Quality financial oversight.', NULL),
(28, 1, 'Zoe Saldana', 'Treasurer', 'United Students', 'Bachelor of Science in Social Work - 3rd Year', 'Funds for the students.', NULL),
(29, 1, 'Chadwick Boseman', 'Auditor', 'DIGITS Party', 'Bachelor of Science in Information Technology - 4th Year', 'Strict auditing standards.', NULL),
(30, 1, 'Elizabeth Olsen', 'Auditor', 'Future Leaders', 'Bachelor of Science in Biology - 4th Year', 'Ensuring accuracy.', NULL),
(31, 1, 'Anthony Mackie', 'Auditor', 'Independent', 'Bachelor of Arts in Communication - 4th Year', 'Independent verification.', NULL),
(32, 1, 'Tessa Thompson', 'Auditor', 'Innovators Bloc', 'Bachelor of Science in Tourism Management - 4th Year', 'Modern audit techniques.', NULL),
(33, 1, 'Don Cheadle', 'Auditor', 'Progressive Party', 'Bachelor of Elementary Education - 4th Year', 'Fair and balanced checks.', NULL),
(34, 1, 'Sebastian Stan', 'Auditor', 'SQU Party', 'Bachelor of Science in Hospitality Management - 4th Year', 'Quality assurance.', NULL),
(35, 1, 'Danai Gurira', 'Auditor', 'United Students', 'Bachelor of Science in Social Work - 4th Year', 'United in accountability.', NULL),
(36, 1, 'Tom Hiddleston', 'PIO', 'DIGITS Party', 'Bachelor of Science in Information Technology - 2nd Year', 'Information at your fingertips.', NULL),
(37, 1, 'Karen Gillan', 'PIO', 'Future Leaders', 'Bachelor of Science in Biology - 2nd Year', 'Clear public relations.', NULL),
(38, 1, 'Benedict Cumberbatch', 'PIO', 'Independent', 'Bachelor of Arts in Communication - 2nd Year', 'The voice of the students.', NULL),
(39, 1, 'Gwyneth Paltrow', 'PIO', 'Innovators Bloc', 'Bachelor of Science in Tourism Management - 2nd Year', 'Innovative communication.', NULL),
(40, 1, 'Josh Brolin', 'PIO', 'Progressive Party', 'Bachelor of Elementary Education - 2nd Year', 'Progressive outreach.', NULL),
(41, 1, 'Letitia Wright', 'PIO', 'SQU Party', 'Bachelor of Science in Hospitality Management - 2nd Year', 'Effective information dissemination.', NULL),
(42, 1, 'Winston Duke', 'PIO', 'United Students', 'Bachelor of Science in Social Work - 2nd Year', 'Connecting the community.', NULL),
(43, 2, 'Ryan Reynolds', 'President', 'DIGITS Party', 'Bachelor of Science in Information Technology - 3rd Year', 'Advancing technology access.', NULL),
(44, 2, 'Blake Lively', 'President', 'Future Leaders', 'Bachelor of Science in Biology - 3rd Year', 'Leadership for tomorrow.', NULL),
(45, 2, 'Jake Gyllenhaal', 'President', 'Independent', 'Bachelor of Arts in Communication - 3rd Year', 'Your independent choice.', NULL),
(46, 2, 'Florence Pugh', 'President', 'Innovators Bloc', 'Bachelor of Science in Tourism Management - 3rd Year', 'Innovation in action.', NULL),
(47, 2, 'Tom Hardy', 'President', 'Progressive Party', 'Bachelor of Elementary Education - 3rd Year', 'Moving forward together.', NULL),
(48, 2, 'Margot Robbie', 'President', 'SQU Party', 'Bachelor of Science in Hospitality Management - 3rd Year', 'Serving the student body.', NULL),
(49, 2, 'Chris Pine', 'President', 'United Students', 'Bachelor of Science in Social Work - 3rd Year', 'Strength in unity.', NULL),
(50, 2, 'Anne Hathaway', 'Vice President', 'DIGITS Party', 'Bachelor of Science in Information Technology - 2nd Year', 'Supporting the President’s vision.', NULL),
(51, 2, 'Hugh Jackman', 'Vice President', 'Future Leaders', 'Bachelor of Science in Biology - 2nd Year', 'Building a better future.', NULL),
(52, 2, 'Emma Stone', 'Vice President', 'Independent', 'Bachelor of Arts in Communication - 2nd Year', 'Fair representation.', NULL),
(53, 2, 'Christian Bale', 'Vice President', 'Innovators Bloc', 'Bachelor of Science in Tourism Management - 2nd Year', 'Creative solutions.', NULL),
(54, 2, 'Rachel McAdams', 'Vice President', 'Progressive Party', 'Bachelor of Elementary Education - 2nd Year', 'Progressive support.', NULL),
(55, 2, 'Bradley Cooper', 'Vice President', 'SQU Party', 'Bachelor of Science in Hospitality Management - 2nd Year', 'Quality leadership support.', NULL),
(56, 2, 'Jessica Chastain', 'Vice President', 'United Students', 'Bachelor of Science in Social Work - 2nd Year', 'United advocacy.', NULL),
(57, 2, 'Matt Damon', 'Secretary', 'DIGITS Party', 'Bachelor of Science in Information Technology - 1st Year', 'Digital record keeping.', NULL),
(58, 2, 'Amy Adams', 'Secretary', 'Future Leaders', 'Bachelor of Science in Biology - 1st Year', 'Clear and concise minutes.', NULL),
(59, 2, 'Leonardo DiCaprio', 'Secretary', 'Independent', 'Bachelor of Arts in Communication - 1st Year', 'Independent transparency.', NULL),
(60, 2, 'Mila Kunis', 'Secretary', 'Innovators Bloc', 'Bachelor of Science in Tourism Management - 1st Year', 'Modern documentation.', NULL),
(61, 2, 'Ryan Gosling', 'Secretary', 'Progressive Party', 'Bachelor of Elementary Education - 1st Year', 'Progressive administration.', NULL),
(62, 2, 'Emma Watson', 'Secretary', 'SQU Party', 'Bachelor of Science in Hospitality Management - 1st Year', 'Quality records.', NULL),
(63, 2, 'Daniel Craig', 'Secretary', 'United Students', 'Bachelor of Science in Social Work - 1st Year', 'United documentation.', NULL),
(64, 2, 'Jennifer Lawrence', 'Treasurer', 'DIGITS Party', 'Bachelor of Science in Information Technology - 2nd Year', 'Digital financial management.', NULL),
(65, 2, 'Jared Leto', 'Treasurer', 'Future Leaders', 'Bachelor of Science in Biology - 2nd Year', 'Future-focused budgeting.', NULL),
(66, 2, 'Charlize Theron', 'Treasurer', 'Independent', 'Bachelor of Arts in Communication - 2nd Year', 'Honest accounting.', NULL),
(67, 2, 'Chris Pratt', 'Treasurer', 'Innovators Bloc', 'Bachelor of Science in Tourism Management - 2nd Year', 'Innovative funding.', NULL),
(68, 2, 'Amanda Seyfried', 'Treasurer', 'Progressive Party', 'Bachelor of Elementary Education - 2nd Year', 'Progressive economics.', NULL),
(69, 2, 'Oscar Isaac', 'Treasurer', 'SQU Party', 'Bachelor of Science in Hospitality Management - 2nd Year', 'Quality budget oversight.', NULL),
(70, 2, 'Keira Knightley', 'Treasurer', 'United Students', 'Bachelor of Science in Social Work - 2nd Year', 'United financial integrity.', NULL),
(71, 2, 'Michael Fassbender', 'Auditor', 'DIGITS Party', 'Bachelor of Science in Information Technology - 3rd Year', 'Strict digital audits.', NULL),
(72, 2, 'Marion Cotillard', 'Auditor', 'Future Leaders', 'Bachelor of Science in Biology - 3rd Year', 'Ensuring a secure future.', NULL),
(73, 2, 'Tom Cruise', 'Auditor', 'Independent', 'Bachelor of Arts in Communication - 3rd Year', 'Independent auditing.', NULL),
(74, 2, 'Emily Blunt', 'Auditor', 'Innovators Bloc', 'Bachelor of Science in Tourism Management - 3rd Year', 'Innovative checking.', NULL),
(75, 2, 'Joaquin Phoenix', 'Auditor', 'Progressive Party', 'Bachelor of Elementary Education - 3rd Year', 'Progressive verification.', NULL),
(76, 2, 'Natalie Dormer', 'Auditor', 'SQU Party', 'Bachelor of Science in Hospitality Management - 3rd Year', 'Quality checks.', NULL),
(77, 2, 'Ewan McGregor', 'Auditor', 'United Students', 'Bachelor of Science in Social Work - 3rd Year', 'United in accuracy.', NULL),
(78, 2, 'Rosamund Pike', 'PIO', 'DIGITS Party', 'Bachelor of Science in Information Technology - 1st Year', 'Digital PR strategies.', NULL),
(79, 2, 'Henry Cavill', 'PIO', 'Future Leaders', 'Bachelor of Science in Biology - 1st Year', 'Future-ready outreach.', NULL),
(80, 2, 'Eva Green', 'PIO', 'Independent', 'Bachelor of Arts in Communication - 1st Year', 'Independent student voice.', NULL),
(81, 2, 'James McAvoy', 'PIO', 'Innovators Bloc', 'Bachelor of Science in Tourism Management - 1st Year', 'Innovative public relations.', NULL),
(82, 2, 'Carey Mulligan', 'PIO', 'Progressive Party', 'Bachelor of Elementary Education - 1st Year', 'Progressive information flow.', NULL),
(83, 2, 'Colin Farrell', 'PIO', 'SQU Party', 'Bachelor of Science in Hospitality Management - 1st Year', 'Quality student connection.', NULL),
(84, 2, 'Rebecca Ferguson', 'PIO', 'United Students', 'Bachelor of Science in Social Work - 1st Year', 'Uniting students through info.', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `parties`
--

CREATE TABLE `parties` (
  `party_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `parties`
--

INSERT INTO `parties` (`party_id`, `name`) VALUES
(2, 'DIGITS Party'),
(6, 'Future Leaders'),
(1, 'Independent'),
(7, 'Innovators Bloc'),
(4, 'Progressive Party'),
(3, 'SQU Party'),
(5, 'United Students');

-- --------------------------------------------------------

--
-- Table structure for table `polls`
--

CREATE TABLE `polls` (
  `poll_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime NOT NULL,
  `status` varchar(50) DEFAULT 'Draft',
  `is_published` tinyint(1) DEFAULT 0,
  `is_archived` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `polls`
--

INSERT INTO `polls` (`poll_id`, `title`, `start_time`, `end_time`, `status`, `is_published`, `is_archived`) VALUES
(1, '2026 LNU SSC REGULAR ELECTION', '2026-03-01 08:00:00', '2026-04-10 17:00:00', 'Ended', 1, 0),
(2, '2026 LNU SPECIAL ELECTION', '2026-04-11 08:00:00', '2026-05-30 17:00:00', 'Published', 1, 0);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `student_number` varchar(50) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `course` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('Admin','Student','Staff') DEFAULT 'Student',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `profile_pic_url` varchar(255) DEFAULT NULL,
  `permissions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`permissions`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `student_number`, `full_name`, `email`, `course`, `password_hash`, `role`, `is_active`, `created_at`, `profile_pic_url`, `permissions`) VALUES
(1, '1234567', 'admin', 'admin@gmail.com', 'Bachelor of Science in Information Technology', '$2b$12$vA6OiFcyAsubvvWXREDwH.HqtAsUiT5vSY4mhz8Qjqp3ZbIW/Bi6O', 'Admin', 1, '2026-03-05 05:05:42', NULL, NULL),
(2, '1234569', 'John Doe', 'john@gmail.com', 'Bachelor of Entrepreneurship', '$2b$12$360IOqztfaCmmocJV0/h9.4BM35A9z7fNkKuelUq5wf2256LTFmBS', 'Student', 1, '2026-03-05 06:13:25', NULL, NULL),
(3, '8765431', 'jane', 'jane@gmail.com', 'Bachelor of Arts in English Language', '$2b$12$h0pCbjD.508PV/JF8aUNQOVWoh0nY.7lQIsAfrfCtK6XlFe5EsMIW', 'Student', 1, '2026-03-06 07:15:50', NULL, NULL),
(4, '7654321', 'carl', 'carl@gmail.com', 'Bachelor of Science in Tourism Management', '$2b$12$qpBeD9Ldcrd82e4q4EKL0.aNk2NlxhL1slWGvGKJdvY/aS22fUBeC', 'Student', 1, '2026-03-14 01:17:06', 'uploads/user_20260314171705_116018138_4056146044458962_8949890354613494763_n.jpg', NULL),
(5, '2302184', 'Dorothy Magdaraog', '2302184@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$A.cwkOJXL.jOyfOHCR/XIe3ney2rmj7.1f040INCnHihW.0IfaQbK', 'Student', 1, '2026-03-14 23:34:22', NULL, NULL),
(6, 'STAFF-1774244897', 'Staff 1', 'staff@gmail.com', 'N/A (Staff)', '$2b$12$UQzyWQx9.bR/FFI1BwcBBOoDTRF6LmZua.LVrU4yXDGVe0MSleSLG', 'Staff', 1, '2026-03-22 21:48:17', 'uploads/staff_20260326234516_android-logo-on-transparent-background-free-vector.jpg', '[\"Users / Account Control\", \"Manage Polls\", \"Manage Candidates\", \"Manage Parties\"]'),
(7, '3333333', 'Student Alpha', 'stud1@gmail.com', 'BS Computer Engineering', '$2b$12$360IOqztfaCmmocJV0/h9.4BM35A9z7fNkKuelUq5wf2256LTFmBS', 'Student', 1, '2026-03-26 00:00:00', NULL, NULL),
(8, '4444444', 'Student Bravo', 'stud2@gmail.com', 'BA Communication', '$2b$12$360IOqztfaCmmocJV0/h9.4BM35A9z7fNkKuelUq5wf2256LTFmBS', 'Student', 1, '2026-03-26 00:00:00', NULL, NULL),
(9, '5555555', 'Student Charlie', 'stud3@gmail.com', 'BS Biology', '$2b$12$360IOqztfaCmmocJV0/h9.4BM35A9z7fNkKuelUq5wf2256LTFmBS', 'Student', 1, '2026-03-26 00:00:00', NULL, NULL),
(10, '6666666', 'Student Delta', 'stud4@gmail.com', 'BS Social Work', '$2b$12$360IOqztfaCmmocJV0/h9.4BM35A9z7fNkKuelUq5wf2256LTFmBS', 'Student', 1, '2026-03-26 00:00:00', NULL, NULL),
(11, '7777777', 'Student Echo', 'stud5@gmail.com', 'BS IT', '$2b$12$360IOqztfaCmmocJV0/h9.4BM35A9z7fNkKuelUq5wf2256LTFmBS', 'Student', 1, '2026-03-26 00:00:00', NULL, NULL),
(12, '8888888', 'Student Foxtrot', 'stud6@gmail.com', 'BS Tourism', '$2b$12$360IOqztfaCmmocJV0/h9.4BM35A9z7fNkKuelUq5wf2256LTFmBS', 'Student', 1, '2026-03-26 00:00:00', NULL, NULL),
(13, '9999999', 'Student Golf', 'stud7@gmail.com', 'BS IT', '$2b$12$360IOqztfaCmmocJV0/h9.4BM35A9z7fNkKuelUq5wf2256LTFmBS', 'Student', 1, '2026-03-26 00:00:00', NULL, NULL),
(14, '1010101', 'Student Hotel', 'stud8@gmail.com', 'BS Tourism', '$2b$12$360IOqztfaCmmocJV0/h9.4BM35A9z7fNkKuelUq5wf2256LTFmBS', 'Student', 1, '2026-03-26 00:00:00', NULL, NULL),
(15, '2020202', 'Student India', 'stud9@gmail.com', 'BS Computer Engineering', '$2b$12$360IOqztfaCmmocJV0/h9.4BM35A9z7fNkKuelUq5wf2256LTFmBS', 'Student', 1, '2026-03-26 00:00:00', NULL, NULL),
(16, '3030303', 'Student Juliet', 'stud10@gmail.com', 'BS IT', '$2b$12$360IOqztfaCmmocJV0/h9.4BM35A9z7fNkKuelUq5wf2256LTFmBS', 'Student', 1, '2026-03-26 00:00:00', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `votes`
--

CREATE TABLE `votes` (
  `vote_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `poll_id` int(11) NOT NULL,
  `candidate_id` int(11) NOT NULL,
  `cast_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `votes`
--

INSERT INTO `votes` (`vote_id`, `user_id`, `poll_id`, `candidate_id`, `cast_at`) VALUES
(1, 2, 1, 1, '2026-04-05 02:00:00'),
(2, 2, 1, 8, '2026-04-05 02:00:00'),
(3, 2, 1, 15, '2026-04-05 02:00:00'),
(4, 2, 1, 22, '2026-04-05 02:00:00'),
(5, 2, 1, 29, '2026-04-05 02:00:00'),
(6, 2, 1, 36, '2026-04-05 02:00:00'),
(7, 3, 1, 2, '2026-04-05 02:00:00'),
(8, 3, 1, 9, '2026-04-05 02:00:00'),
(9, 3, 1, 16, '2026-04-05 02:00:00'),
(10, 3, 1, 23, '2026-04-05 02:00:00'),
(11, 3, 1, 30, '2026-04-05 02:00:00'),
(12, 3, 1, 37, '2026-04-05 02:00:00'),
(13, 4, 1, 3, '2026-04-05 02:00:00'),
(14, 4, 1, 10, '2026-04-05 02:00:00'),
(15, 4, 1, 17, '2026-04-05 02:00:00'),
(16, 4, 1, 24, '2026-04-05 02:00:00'),
(17, 4, 1, 31, '2026-04-05 02:00:00'),
(18, 4, 1, 38, '2026-04-05 02:00:00'),
(19, 5, 1, 4, '2026-04-05 02:00:00'),
(20, 5, 1, 11, '2026-04-05 02:00:00'),
(21, 5, 1, 18, '2026-04-05 02:00:00'),
(22, 5, 1, 25, '2026-04-05 02:00:00'),
(23, 5, 1, 32, '2026-04-05 02:00:00'),
(24, 5, 1, 39, '2026-04-05 02:00:00'),
(25, 7, 1, 5, '2026-04-05 02:00:00'),
(26, 7, 1, 12, '2026-04-05 02:00:00'),
(27, 7, 1, 19, '2026-04-05 02:00:00'),
(28, 7, 1, 26, '2026-04-05 02:00:00'),
(29, 7, 1, 33, '2026-04-05 02:00:00'),
(30, 7, 1, 40, '2026-04-05 02:00:00'),
(31, 8, 1, 6, '2026-04-05 02:00:00'),
(32, 8, 1, 13, '2026-04-05 02:00:00'),
(33, 8, 1, 20, '2026-04-05 02:00:00'),
(34, 8, 1, 27, '2026-04-05 02:00:00'),
(35, 8, 1, 34, '2026-04-05 02:00:00'),
(36, 8, 1, 41, '2026-04-05 02:00:00'),
(37, 9, 1, 7, '2026-04-05 02:00:00'),
(38, 9, 1, 14, '2026-04-05 02:00:00'),
(39, 9, 1, 21, '2026-04-05 02:00:00'),
(40, 9, 1, 28, '2026-04-05 02:00:00'),
(41, 9, 1, 35, '2026-04-05 02:00:00'),
(42, 9, 1, 42, '2026-04-05 02:00:00'),
(43, 10, 1, 1, '2026-04-05 02:00:00'),
(44, 10, 1, 9, '2026-04-05 02:00:00'),
(45, 10, 1, 17, '2026-04-05 02:00:00'),
(46, 10, 1, 25, '2026-04-05 02:00:00'),
(47, 10, 1, 33, '2026-04-05 02:00:00'),
(48, 10, 1, 41, '2026-04-05 02:00:00'),
(49, 11, 1, 2, '2026-04-05 02:00:00'),
(50, 11, 1, 10, '2026-04-05 02:00:00'),
(51, 11, 1, 18, '2026-04-05 02:00:00'),
(52, 11, 1, 26, '2026-04-05 02:00:00'),
(53, 11, 1, 34, '2026-04-05 02:00:00'),
(54, 11, 1, 42, '2026-04-05 02:00:00'),
(55, 12, 1, 3, '2026-04-05 02:00:00'),
(56, 12, 1, 11, '2026-04-05 02:00:00'),
(57, 12, 1, 19, '2026-04-05 02:00:00'),
(58, 12, 1, 27, '2026-04-05 02:00:00'),
(59, 12, 1, 35, '2026-04-05 02:00:00'),
(60, 12, 1, 36, '2026-04-05 02:00:00'),
(61, 13, 1, 4, '2026-04-05 02:00:00'),
(62, 13, 1, 12, '2026-04-05 02:00:00'),
(63, 13, 1, 20, '2026-04-05 02:00:00'),
(64, 13, 1, 28, '2026-04-05 02:00:00'),
(65, 13, 1, 29, '2026-04-05 02:00:00'),
(66, 13, 1, 37, '2026-04-05 02:00:00'),
(67, 14, 1, 5, '2026-04-05 02:00:00'),
(68, 14, 1, 13, '2026-04-05 02:00:00'),
(69, 14, 1, 21, '2026-04-05 02:00:00'),
(70, 14, 1, 22, '2026-04-05 02:00:00'),
(71, 14, 1, 30, '2026-04-05 02:00:00'),
(72, 14, 1, 38, '2026-04-05 02:00:00'),
(73, 15, 1, 6, '2026-04-05 02:00:00'),
(74, 15, 1, 14, '2026-04-05 02:00:00'),
(75, 15, 1, 15, '2026-04-05 02:00:00'),
(76, 15, 1, 23, '2026-04-05 02:00:00'),
(77, 15, 1, 31, '2026-04-05 02:00:00'),
(78, 15, 1, 39, '2026-04-05 02:00:00'),
(79, 16, 1, 7, '2026-04-05 02:00:00'),
(80, 16, 1, 8, '2026-04-05 02:00:00'),
(81, 16, 1, 16, '2026-04-05 02:00:00'),
(82, 16, 1, 24, '2026-04-05 02:00:00'),
(83, 16, 1, 32, '2026-04-05 02:00:00'),
(84, 16, 1, 40, '2026-04-05 02:00:00'),
(85, 4, 2, 43, '2026-04-12 02:00:00'),
(86, 4, 2, 50, '2026-04-12 02:00:00'),
(87, 4, 2, 57, '2026-04-12 02:00:00'),
(88, 4, 2, 64, '2026-04-12 02:00:00'),
(89, 4, 2, 71, '2026-04-12 02:00:00'),
(90, 4, 2, 78, '2026-04-12 02:00:00'),
(91, 5, 2, 44, '2026-04-12 02:00:00'),
(92, 5, 2, 51, '2026-04-12 02:00:00'),
(93, 5, 2, 58, '2026-04-12 02:00:00'),
(94, 5, 2, 65, '2026-04-12 02:00:00'),
(95, 5, 2, 72, '2026-04-12 02:00:00'),
(96, 5, 2, 79, '2026-04-12 02:00:00'),
(97, 7, 2, 45, '2026-04-12 02:00:00'),
(98, 7, 2, 52, '2026-04-12 02:00:00'),
(99, 7, 2, 59, '2026-04-12 02:00:00'),
(100, 7, 2, 66, '2026-04-12 02:00:00'),
(101, 7, 2, 73, '2026-04-12 02:00:00'),
(102, 7, 2, 80, '2026-04-12 02:00:00'),
(103, 8, 2, 46, '2026-04-12 02:00:00'),
(104, 8, 2, 53, '2026-04-12 02:00:00'),
(105, 8, 2, 60, '2026-04-12 02:00:00'),
(106, 8, 2, 67, '2026-04-12 02:00:00'),
(107, 8, 2, 74, '2026-04-12 02:00:00'),
(108, 8, 2, 81, '2026-04-12 02:00:00'),
(109, 9, 2, 47, '2026-04-12 02:00:00'),
(110, 9, 2, 54, '2026-04-12 02:00:00'),
(111, 9, 2, 61, '2026-04-12 02:00:00'),
(112, 9, 2, 68, '2026-04-12 02:00:00'),
(113, 9, 2, 75, '2026-04-12 02:00:00'),
(114, 9, 2, 82, '2026-04-12 02:00:00'),
(115, 10, 2, 48, '2026-04-12 02:00:00'),
(116, 10, 2, 55, '2026-04-12 02:00:00'),
(117, 10, 2, 62, '2026-04-12 02:00:00'),
(118, 10, 2, 69, '2026-04-12 02:00:00'),
(119, 10, 2, 76, '2026-04-12 02:00:00'),
(120, 10, 2, 83, '2026-04-12 02:00:00'),
(121, 11, 2, 49, '2026-04-12 02:00:00'),
(122, 11, 2, 56, '2026-04-12 02:00:00'),
(123, 11, 2, 63, '2026-04-12 02:00:00'),
(124, 11, 2, 70, '2026-04-12 02:00:00'),
(125, 11, 2, 77, '2026-04-12 02:00:00'),
(126, 11, 2, 84, '2026-04-12 02:00:00'),
(127, 12, 2, 43, '2026-04-12 02:00:00'),
(128, 12, 2, 51, '2026-04-12 02:00:00'),
(129, 12, 2, 59, '2026-04-12 02:00:00'),
(130, 12, 2, 67, '2026-04-12 02:00:00'),
(131, 12, 2, 75, '2026-04-12 02:00:00'),
(132, 12, 2, 83, '2026-04-12 02:00:00'),
(133, 13, 2, 44, '2026-04-12 02:00:00'),
(134, 13, 2, 52, '2026-04-12 02:00:00'),
(135, 13, 2, 60, '2026-04-12 02:00:00'),
(136, 13, 2, 68, '2026-04-12 02:00:00'),
(137, 13, 2, 76, '2026-04-12 02:00:00'),
(138, 13, 2, 84, '2026-04-12 02:00:00'),
(139, 14, 2, 45, '2026-04-12 02:00:00'),
(140, 14, 2, 53, '2026-04-12 02:00:00'),
(141, 14, 2, 61, '2026-04-12 02:00:00'),
(142, 14, 2, 69, '2026-04-12 02:00:00'),
(143, 14, 2, 77, '2026-04-12 02:00:00'),
(144, 14, 2, 78, '2026-04-12 02:00:00'),
(145, 15, 2, 46, '2026-04-12 02:00:00'),
(146, 15, 2, 54, '2026-04-12 02:00:00'),
(147, 15, 2, 62, '2026-04-12 02:00:00'),
(148, 15, 2, 70, '2026-04-12 02:00:00'),
(149, 15, 2, 71, '2026-04-12 02:00:00'),
(150, 15, 2, 79, '2026-04-12 02:00:00'),
(151, 16, 2, 47, '2026-04-12 02:00:00'),
(152, 16, 2, 55, '2026-04-12 02:00:00'),
(153, 16, 2, 63, '2026-04-12 02:00:00'),
(154, 16, 2, 64, '2026-04-12 02:00:00'),
(155, 16, 2, 72, '2026-04-12 02:00:00'),
(156, 16, 2, 80, '2026-04-12 02:00:00');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `candidates`
--
ALTER TABLE `candidates`
  ADD PRIMARY KEY (`candidate_id`),
  ADD KEY `poll_id` (`poll_id`);

--
-- Indexes for table `parties`
--
ALTER TABLE `parties`
  ADD PRIMARY KEY (`party_id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `polls`
--
ALTER TABLE `polls`
  ADD PRIMARY KEY (`poll_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `student_number` (`student_number`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `votes`
--
ALTER TABLE `votes`
  ADD PRIMARY KEY (`vote_id`),
  ADD KEY `poll_id` (`poll_id`),
  ADD KEY `candidate_id` (`candidate_id`),
  ADD KEY `votes_ibfk_1` (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `candidates`
--
ALTER TABLE `candidates`
  MODIFY `candidate_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=85;

--
-- AUTO_INCREMENT for table `parties`
--
ALTER TABLE `parties`
  MODIFY `party_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `polls`
--
ALTER TABLE `polls`
  MODIFY `poll_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `votes`
--
ALTER TABLE `votes`
  MODIFY `vote_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=157;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `candidates`
--
ALTER TABLE `candidates`
  ADD CONSTRAINT `candidates_ibfk_1` FOREIGN KEY (`poll_id`) REFERENCES `polls` (`poll_id`) ON DELETE CASCADE;

--
-- Constraints for table `votes`
--
ALTER TABLE `votes`
  ADD CONSTRAINT `votes_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `votes_ibfk_2` FOREIGN KEY (`poll_id`) REFERENCES `polls` (`poll_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `votes_ibfk_3` FOREIGN KEY (`candidate_id`) REFERENCES `candidates` (`candidate_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
