-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 05, 2026 at 04:57 PM
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
  `course_year` varchar(50) NOT NULL,
  `description_platform` text DEFAULT NULL,
  `photo_url` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `candidates`
--

INSERT INTO `candidates` (`candidate_id`, `poll_id`, `name`, `position`, `party_name`, `course_year`, `description_platform`, `photo_url`) VALUES
(1, 1, 'Alice Thompson', 'President', 'Progressive Party', 'BSIT 4', 'Advocating for better campus Wi-Fi, modernized lab equipment, and student mental health breaks.', NULL),
(2, 1, 'David Miller', 'Vice President', 'Progressive Party', 'BSCOE 3', 'Focused on creating more extracurricular organizations and strengthening the student council voice.', NULL),
(3, 1, 'Sophia Davis', 'Secretary', 'Progressive Party', 'BSCS 2', 'Promises 100% transparency in student council meetings with publicly available digital minutes.', NULL),
(4, 1, 'James Wilson', 'Treasurer', 'Progressive Party', 'BSEE 3', 'Ensuring the student fund is allocated fairly to all departments for their end-of-year events.', NULL),
(5, 1, 'Olivia Brown', 'Auditor', 'Progressive Party', 'BSCE 4', 'Strict auditing of all organizational budgets to prevent misallocation of student fees.', NULL),
(6, 1, 'Liam Garcia', 'PIO', 'Progressive Party', 'BSIT 2', 'Creating a centralized student app for live campus announcements and event tracking.', NULL),
(7, 1, 'Bob Smith', 'President', 'United Students', 'BSCS 4', 'Committed to uniting all departments through university-wide sports fests and hackathons.', NULL),
(8, 1, 'Fiona Gallagher', 'Vice President', 'United Students', 'BSEE 4', 'Building strong connections between alumni and current students for better job placements.', NULL),
(9, 1, 'Ian Somerhalder', 'Secretary', 'United Students', 'BSIT 3', 'Implementing a paperless, digital-first approach for all student requests and clearances.', NULL),
(10, 1, 'Emma Johnson', 'Treasurer', 'United Students', 'BSCOE 2-1', 'Pushing for transparent, real-time financial dashboards accessible to all enrolled students.', NULL),
(11, 1, 'Noah Martinez', 'Auditor', 'United Students', 'BSCE 3', 'A zero-tolerance policy for budget delays, ensuring organizations get their funds on time.', NULL),
(12, 1, 'Mia Anderson', 'PIO', 'United Students', 'BSIT 1', 'Revamping the university social media pages to feature student achievements weekly.', NULL),
(13, 1, 'Charlie Davis', 'President', 'Future Leaders', 'BSCE 4', 'Platform focused on infrastructure: better canteens, clean restrooms, and shaded walkways.', NULL),
(14, 1, 'Hannah Baker', 'Vice President', 'Future Leaders', 'BSIT 4', 'Bridging the gap between the administration and the student body through monthly town halls.', NULL),
(15, 1, 'Lucas White', 'Secretary', 'Future Leaders', 'BSCS 3', 'Organizing the student database to make enrollment and ID replacement faster.', NULL),
(16, 1, 'Ava Taylor', 'Treasurer', 'Future Leaders', 'BSEE 2', 'Lowering ticket prices for university events by securing off-campus corporate sponsorships.', NULL),
(17, 1, 'Ethan Hunt', 'Auditor', 'Future Leaders', 'BSCOE 4', 'Rigorous background checks on all third-party vendors operating inside the campus.', NULL),
(18, 1, 'Isabella Thomas', 'PIO', 'Future Leaders', 'BSCE 2', 'Launching a monthly digital newsletter written by the students, for the students.', NULL),
(19, 1, 'Diana Evans', 'President', 'Innovators Bloc', 'BSCOE 4', 'Tech-driven leadership. Pushing for an e-voting system and automated clearance processes.', NULL),
(20, 1, 'George Bluth', 'Vice President', 'Innovators Bloc', 'BSIT 3', 'Supporting student startups and providing grants for standout capstone projects.', NULL),
(21, 1, 'Jessica Day', 'Secretary', 'Innovators Bloc', 'BSEE 3', 'Streamlining communication so students never miss an important deadline again.', NULL),
(22, 1, 'Mason Clark', 'Treasurer', 'Innovators Bloc', 'BSCS 4', 'Introducing a cashless payment option for the university cafeteria and bookstore.', NULL),
(23, 1, 'Amelia Lewis', 'Auditor', 'Innovators Bloc', 'BSIT 2', 'Modernizing the tracking of student council expenses using blockchain concepts.', NULL),
(24, 1, 'Logan Walker', 'PIO', 'Innovators Bloc', 'BSCE 1', 'Establishing an official student podcast to discuss campus life, academics, and pop culture.', NULL);

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
  `is_published` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `polls`
--

INSERT INTO `polls` (`poll_id`, `title`, `start_time`, `end_time`, `status`, `is_published`) VALUES
(1, 'ELECTION 2026', '2026-03-13 13:38:00', '2026-03-31 13:38:00', 'Published', 1),
(2, 'ELECTION 2027', '2026-04-01 23:47:00', '2026-04-02 23:47:00', 'Draft', 0);

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
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `student_number`, `full_name`, `email`, `course`, `password_hash`, `role`, `is_active`, `created_at`) VALUES
(1, '1234567', 'admin', 'admin@gmail.com', 'Bachelor of Science in Information Technology', '$2b$12$vA6OiFcyAsubvvWXREDwH.HqtAsUiT5vSY4mhz8Qjqp3ZbIW/Bi6O', 'Admin', 1, '2026-03-05 05:05:42'),
(2, '1234569', 'John Doe', 'john@gmail.com', 'Bachelor of Entrepreneurship', '$2b$12$360IOqztfaCmmocJV0/h9.4BM35A9z7fNkKuelUq5wf2256LTFmBS', 'Student', 1, '2026-03-05 06:13:25');

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
  ADD UNIQUE KEY `unique_vote_per_poll` (`user_id`,`poll_id`),
  ADD KEY `poll_id` (`poll_id`),
  ADD KEY `candidate_id` (`candidate_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `candidates`
--
ALTER TABLE `candidates`
  MODIFY `candidate_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `polls`
--
ALTER TABLE `polls`
  MODIFY `poll_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `votes`
--
ALTER TABLE `votes`
  MODIFY `vote_id` int(11) NOT NULL AUTO_INCREMENT;

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
