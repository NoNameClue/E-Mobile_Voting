-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 20, 2026 at 02:17 PM
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
(26, 3, 'John Doe', 'President', 'DIGITS Party', 'BS Information Technology - 3rd Year', 'VOTE FOR ME', NULL),
(27, 3, 'Jane Doe', 'President', 'SQU Party', 'BS Computer Engineering - 3rd Year', 'VOTE FOR ME ALWAYS', NULL),
(28, 3, 'Johnny Doe', 'Vice President', 'DIGITS Party', 'BS Information Technology - 3rd Year', 'DON\'T VOTE FOR ME', NULL),
(29, 3, 'Jenny Doe', 'Vice President', 'SQU Party', 'BS Elementary Education - 3rd Year', 'PLEASE VOTE', NULL),
(30, 3, 'John John Doe', 'Secretary', 'DIGITS Party', 'BS Information Technology - 3rd Year', 'VOTE NOW', NULL),
(31, 3, 'JEN JEN DOE', 'Secretary', 'SQU Party', 'BS Secondary Education - 3rd Year', 'VOTE PLEASEEE', NULL),
(32, 3, 'Joenelle Doe', 'Treasurer', 'DIGITS Party', 'BS Information Technology - 3rd Year', 'JUN JUN VOTE', NULL),
(33, 3, 'Jessica Doe', 'Treasurer', 'SQU Party', 'BS Computer Engineering - 3rd Year', NULL, NULL),
(34, 3, 'Jefferson Doe', 'Auditor', 'DIGITS Party', 'BS Tourism Management - 3rd Year', NULL, NULL),
(35, 3, 'Jane Doe 2nd', 'Auditor', 'SQU Party', 'BA Communication - 3rd Year', NULL, NULL),
(36, 3, 'Bob Doe', 'PIO', 'DIGITS Party', 'BS Computer Engineering - 3rd Year', NULL, NULL),
(37, 3, 'Beth Doe', 'PIO', 'SQU Party', 'BS Computer Engineering - 2nd Year', NULL, NULL);

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
(4, 'DIGITS Party'),
(1, 'Independent'),
(5, 'SQU Party');

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
(3, 'ELECTION 2026', '2026-03-16 13:00:00', '2026-03-24 16:25:00', 'Published', 1, 0);

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
  `role` enum('Admin','Student') DEFAULT 'Student',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `profile_pic_url` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `student_number`, `full_name`, `email`, `course`, `password_hash`, `role`, `is_active`, `created_at`, `profile_pic_url`) VALUES
(1, '1234567', 'admin', 'admin@gmail.com', 'Bachelor of Science in Information Technology', '$2b$12$vA6OiFcyAsubvvWXREDwH.HqtAsUiT5vSY4mhz8Qjqp3ZbIW/Bi6O', 'Admin', 1, '2026-03-05 05:05:42', NULL),
(2, '1234569', 'John Doe', 'john@gmail.com', 'Bachelor of Entrepreneurship', '$2b$12$360IOqztfaCmmocJV0/h9.4BM35A9z7fNkKuelUq5wf2256LTFmBS', 'Student', 1, '2026-03-05 06:13:25', NULL),
(3, '8765431', 'jane', 'jane@gmail.com', 'Bachelor of Arts in English Language', '$2b$12$h0pCbjD.508PV/JF8aUNQOVWoh0nY.7lQIsAfrfCtK6XlFe5EsMIW', 'Student', 1, '2026-03-06 07:15:50', NULL),
(4, '7654321', 'carl', 'carl@gmail.com', 'Bachelor of Science in Tourism Management', '$2b$12$qpBeD9Ldcrd82e4q4EKL0.aNk2NlxhL1slWGvGKJdvY/aS22fUBeC', 'Student', 1, '2026-03-14 01:17:06', 'uploads/user_20260314171705_116018138_4056146044458962_8949890354613494763_n.jpg'),
(5, '2302184', 'Dorothy Magdaraog', '2302184@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$A.cwkOJXL.jOyfOHCR/XIe3ney2rmj7.1f040INCnHihW.0IfaQbK', 'Student', 1, '2026-03-14 23:34:22', NULL);

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
  MODIFY `candidate_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT for table `parties`
--
ALTER TABLE `parties`
  MODIFY `party_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `polls`
--
ALTER TABLE `polls`
  MODIFY `poll_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `votes`
--
ALTER TABLE `votes`
  MODIFY `vote_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

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
