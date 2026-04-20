-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 20, 2026 at 08:08 AM
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
  `first_name` varchar(50) NOT NULL,
  `middle_name` varchar(50) DEFAULT '',
  `last_name` varchar(50) NOT NULL,
  `position` varchar(50) NOT NULL,
  `party_name` varchar(50) DEFAULT 'Independent',
  `course_year` varchar(80) NOT NULL,
  `description_platform` text DEFAULT NULL,
  `photo_url` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `candidates`
--

INSERT INTO `candidates` (`candidate_id`, `poll_id`, `first_name`, `middle_name`, `last_name`, `position`, `party_name`, `course_year`, `description_platform`, `photo_url`) VALUES
(1, 1, 'Test', 'T', 'Doe', 'President', 'Youth Party', 'Bachelor of Science in Information Technology - 3rd Year', 'VOTE ME', NULL);

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
(1, 'Independent'),
(8, 'Youth Party');

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
(1, 'SSC 2026', '2026-04-21 13:49:00', '2026-04-22 13:49:00', 'Draft', 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `student_number` varchar(50) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `middle_name` varchar(50) DEFAULT '',
  `last_name` varchar(50) NOT NULL,
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

INSERT INTO `users` (`user_id`, `student_number`, `first_name`, `middle_name`, `last_name`, `email`, `course`, `password_hash`, `role`, `is_active`, `created_at`, `profile_pic_url`, `permissions`) VALUES
(1, '1234567', '', '', '', 'admin@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$vA6OiFcyAsubvvWXREDwH.HqtAsUiT5vSY4mhz8Qjqp3ZbIW/Bi6O', 'Admin', 1, '2026-03-05 05:05:42', NULL, NULL),
(21, '7654321', 'John', 'D', 'Doe', 'john@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$aumy9lDFyx4zOpJsKslEw.JuvEQt3O9kVKedXOrwDmzCjWcN5.9Y6', 'Student', 1, '2026-04-19 21:27:40', 'uploads/user_20260420132739_ca5ce4ef33351bc2aaa8e9c573255bc6.jpeg', '[]'),
(22, '2000000', 'Valentina', 'A.', 'Gomez', 'valentina.gomez0@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(23, '2000001', 'Rosa', 'A.', 'Mercado', 'rosa.mercado1@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(24, '2000002', 'Fernando', 'L.', 'Diaz', 'fernando.diaz2@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(25, '2000003', 'Rosa', 'J.', 'Domingo', 'rosa.domingo3@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(26, '2000004', 'Silvia', 'P.', 'Navarro', 'silvia.navarro4@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(27, '2000005', 'Luis', 'I.', 'Bautista', 'luis.bautista5@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(28, '2000006', 'Carmen', 'H.', 'Cordero', 'carmen.cordero6@lnu.edu.ph', 'Bachelor of Special Needs Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(29, '2000007', 'Luisa', 'Z.', 'Ramos', 'luisa.ramos7@lnu.edu.ph', 'Bachelor of Music in Music Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(30, '2000008', 'Marcos', 'I.', 'Diaz', 'marcos.diaz8@lnu.edu.ph', 'Bachelor of Library and Information Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(31, '2000009', 'Mariana', 'F.', 'Valdez', 'mariana.valdez9@lnu.edu.ph', 'Bachelor of Physical Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(32, '2000010', 'Valeria', 'N.', 'Garcia', 'valeria.garcia10@lnu.edu.ph', 'Bachelor of Entrepreneurship', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(33, '2000011', 'Joaquin', 'Y.', 'Villanueva', 'joaquin.villanueva11@lnu.edu.ph', 'Bachelor of Physical Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(34, '2000012', 'Lucia', 'R.', 'Lopez', 'lucia.lopez12@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(35, '2000013', 'Emanuel', 'A.', 'Gonzales', 'emanuel.gonzales13@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(36, '2000014', 'Joaquin', 'N.', 'Bautista', 'joaquin.bautista14@lnu.edu.ph', 'Bachelor of Science in Social Work', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(37, '2000015', 'Julio', 'U.', 'Sarmiento', 'julio.sarmiento15@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(38, '2000016', 'Victoria', 'D.', 'Ortiz', 'victoria.ortiz16@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(39, '2000017', 'Zoe', 'J.', 'Torres', 'zoe.torres17@lnu.edu.ph', 'Bachelor of Science in Social Work', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(40, '2000018', 'Micaela', 'R.', 'Nicolas', 'micaela.nicolas18@lnu.edu.ph', 'Bachelor of Music in Music Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(41, '2000019', 'Vicente', 'U.', 'Nicolas', 'vicente.nicolas19@lnu.edu.ph', 'Bachelor of Physical Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(42, '2000020', 'Fernando', 'O.', 'Ramos', 'fernando.ramos20@lnu.edu.ph', 'Bachelor of Music in Music Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(43, '2000021', 'Zoe', 'Q.', 'Santos', 'zoe.santos21@lnu.edu.ph', 'Bachelor of Early Childhood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(44, '2000022', 'Juliana', 'K.', 'Tolentino', 'juliana.tolentino22@lnu.edu.ph', 'Bachelor of Science in Biology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(45, '2000023', 'Vicente', 'H.', 'Del Rosario', 'vicente.del rosario23@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(46, '2000024', 'Sofia', 'O.', 'Reyes', 'sofia.reyes24@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(47, '2000025', 'Elena', 'I.', 'Villanueva', 'elena.villanueva25@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(48, '2000026', 'Pedro', 'N.', 'Lopez', 'pedro.lopez26@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(49, '2000027', 'Mario', 'P.', 'Ocampo', 'mario.ocampo27@lnu.edu.ph', 'Bachelor of Physical Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(50, '2000028', 'Ricardo', 'S.', 'Perez', 'ricardo.perez28@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(51, '2000029', 'Maria', 'D.', 'Rodriguez', 'maria.rodriguez29@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(52, '2000030', 'Pedro', 'F.', 'Castro', 'pedro.castro30@lnu.edu.ph', 'Bachelor of Early Childhood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(53, '2000031', 'Jorge', 'Z.', 'De Leon', 'jorge.de leon31@lnu.edu.ph', 'Bachelor of Arts in Communication', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(54, '2000032', 'Zoe', 'G.', 'Diaz', 'zoe.diaz32@lnu.edu.ph', 'Bachelor of Technology and Livelihood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(55, '2000033', 'Victor', 'F.', 'Alvarez', 'victor.alvarez33@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(56, '2000034', 'Pedro', 'F.', 'Domingo', 'pedro.domingo34@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(57, '2000035', 'Vicente', 'W.', 'Perez', 'vicente.perez35@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(58, '2000036', 'Micaela', 'P.', 'Alvarez', 'micaela.alvarez36@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(59, '2000037', 'Luisa', 'L.', 'Nicolas', 'luisa.nicolas37@lnu.edu.ph', 'Bachelor of Music in Music Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(60, '2000038', 'Lourdes', 'J.', 'Villanueva', 'lourdes.villanueva38@lnu.edu.ph', 'Bachelor of Entrepreneurship', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(61, '2000039', 'Victor', 'U.', 'Lopez', 'victor.lopez39@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(62, '2000040', 'Camila', 'X.', 'Ignacio', 'camila.ignacio40@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(63, '2000041', 'Teresa', 'X.', 'Miranda', 'teresa.miranda41@lnu.edu.ph', 'Bachelor of Science in Biology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(64, '2000042', 'Luisa', 'R.', 'Miranda', 'luisa.miranda42@lnu.edu.ph', 'Bachelor of Special Needs Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(65, '2000043', 'Joaquin', 'M.', 'Del Rosario', 'joaquin.del rosario43@lnu.edu.ph', 'Bachelor of Music in Music Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(66, '2000044', 'Andres', 'J.', 'Mercado', 'andres.mercado44@lnu.edu.ph', 'Bachelor of Science in Social Work', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(67, '2000045', 'Emilia', 'H.', 'Nicolas', 'emilia.nicolas45@lnu.edu.ph', 'Bachelor of Science in Social Work', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(68, '2000046', 'Emilia', 'W.', 'Castro', 'emilia.castro46@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(69, '2000047', 'Jose', 'C.', 'Alvarez', 'jose.alvarez47@lnu.edu.ph', 'Bachelor of Technology and Livelihood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(70, '2000048', 'Diego', 'Y.', 'Gutierrez', 'diego.gutierrez48@lnu.edu.ph', 'Bachelor of Music in Music Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(71, '2000049', 'Lourdes', 'H.', 'Mercado', 'lourdes.mercado49@lnu.edu.ph', 'Bachelor of Physical Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(72, '2000050', 'Carlos', 'Z.', 'Lopez', 'carlos.lopez50@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(73, '2000051', 'Mario', 'P.', 'Diaz', 'mario.diaz51@lnu.edu.ph', 'Bachelor of Arts in English Language', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(74, '2000052', 'Isabel', 'B.', 'Nicolas', 'isabel.nicolas52@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(75, '2000053', 'Camila', 'Y.', 'Rodriguez', 'camila.rodriguez53@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(76, '2000054', 'Micaela', 'W.', 'Velasco', 'micaela.velasco54@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(77, '2000055', 'Rafael', 'M.', 'Ramos', 'rafael.ramos55@lnu.edu.ph', 'Bachelor of Early Childhood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(78, '2000056', 'Pedro', 'W.', 'Gomez', 'pedro.gomez56@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(79, '2000057', 'Marcos', 'C.', 'Ignacio', 'marcos.ignacio57@lnu.edu.ph', 'Bachelor of Arts in Communication', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(80, '2000058', 'Juan', 'B.', 'Mendoza', 'juan.mendoza58@lnu.edu.ph', 'Bachelor of Early Childhood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(81, '2000059', 'Antonio', 'X.', 'Lopez', 'antonio.lopez59@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(82, '2000060', 'Eduardo', 'Z.', 'Aguilar', 'eduardo.aguilar60@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(83, '2000061', 'Carmen', 'K.', 'Guzman', 'carmen.guzman61@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(84, '2000062', 'Daniela', 'P.', 'Gonzales', 'daniela.gonzales62@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(85, '2000063', 'Isabel', 'U.', 'Domingo', 'isabel.domingo63@lnu.edu.ph', 'Bachelor of Physical Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(86, '2000064', 'Lucia', 'V.', 'Domingo', 'lucia.domingo64@lnu.edu.ph', 'Bachelor of Library and Information Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(87, '2000065', 'Juan', 'D.', 'Valdez', 'juan.valdez65@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(88, '2000066', 'Teresa', 'N.', 'Alvarez', 'teresa.alvarez66@lnu.edu.ph', 'Bachelor of Arts in English Language', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(89, '2000067', 'Lucia', 'Q.', 'Gutierrez', 'lucia.gutierrez67@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(90, '2000068', 'Clara', 'I.', 'Soriano', 'clara.soriano68@lnu.edu.ph', 'Bachelor of Technology and Livelihood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(91, '2000069', 'Lourdes', 'C.', 'Romero', 'lourdes.romero69@lnu.edu.ph', 'Bachelor of Entrepreneurship', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(92, '2000070', 'Maria', 'K.', 'Sison', 'maria.sison70@lnu.edu.ph', 'Bachelor of Special Needs Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(93, '2000071', 'Emilia', 'N.', 'Castro', 'emilia.castro71@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(94, '2000072', 'Maria', 'C.', 'Soriano', 'maria.soriano72@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(95, '2000073', 'Julio', 'Y.', 'Nicolas', 'julio.nicolas73@lnu.edu.ph', 'Bachelor of Science in Social Work', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(96, '2000074', 'Ana', 'E.', 'Velasco', 'ana.velasco74@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(97, '2000075', 'Lourdes', 'S.', 'Gonzales', 'lourdes.gonzales75@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(98, '2000076', 'Emilia', 'I.', 'Villanueva', 'emilia.villanueva76@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(99, '2000077', 'Roberto', 'M.', 'Torres', 'roberto.torres77@lnu.edu.ph', 'Bachelor of Early Childhood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(100, '2000078', 'Isabel', 'T.', 'Rodriguez', 'isabel.rodriguez78@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(101, '2000079', 'Mariana', 'Z.', 'Miranda', 'mariana.miranda79@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(102, '2000080', 'Teresa', 'F.', 'Velasco', 'teresa.velasco80@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(103, '2000081', 'Diego', 'F.', 'Nicolas', 'diego.nicolas81@lnu.edu.ph', 'Bachelor of Entrepreneurship', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(104, '2000082', 'Luisa', 'I.', 'Mendoza', 'luisa.mendoza82@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(105, '2000083', 'Sofia', 'S.', 'Reyes', 'sofia.reyes83@lnu.edu.ph', 'Bachelor of Early Childhood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(106, '2000084', 'Juan', 'G.', 'Flores', 'juan.flores84@lnu.edu.ph', 'Bachelor of Entrepreneurship', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(107, '2000085', 'Clara', 'U.', 'Gonzales', 'clara.gonzales85@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(108, '2000086', 'Eduardo', 'A.', 'Perez', 'eduardo.perez86@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(109, '2000087', 'Diego', 'P.', 'Ramos', 'diego.ramos87@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(110, '2000088', 'Vicente', 'N.', 'Ortiz', 'vicente.ortiz88@lnu.edu.ph', 'Bachelor of Early Childhood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(111, '2000089', 'Fernando', 'X.', 'Aquino', 'fernando.aquino89@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(112, '2000090', 'Joaquin', 'R.', 'Cordero', 'joaquin.cordero90@lnu.edu.ph', 'Bachelor of Entrepreneurship', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(113, '2000091', 'Elena', 'S.', 'Lopez', 'elena.lopez91@lnu.edu.ph', 'Bachelor of Special Needs Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(114, '2000092', 'Eduardo', 'E.', 'Torres', 'eduardo.torres92@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(115, '2000093', 'Emanuel', 'P.', 'Torres', 'emanuel.torres93@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(116, '2000094', 'Valentina', 'Y.', 'Castillo', 'valentina.castillo94@lnu.edu.ph', 'Bachelor of Special Needs Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(117, '2000095', 'Gabriel', 'I.', 'Ortiz', 'gabriel.ortiz95@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(118, '2000096', 'Oscar', 'Q.', 'Miranda', 'oscar.miranda96@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(119, '2000097', 'Juliana', 'D.', 'Castillo', 'juliana.castillo97@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(120, '2000098', 'Martina', 'A.', 'Domingo', 'martina.domingo98@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(121, '2000099', 'Marcos', 'S.', 'Ramos', 'marcos.ramos99@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(122, '2000100', 'Roberto', 'P.', 'Mendoza', 'roberto.mendoza100@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(123, '2000101', 'Pedro', 'U.', 'Sarmiento', 'pedro.sarmiento101@lnu.edu.ph', 'Bachelor of Science in Biology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(124, '2000102', 'Luisa', 'X.', 'De Leon', 'luisa.de leon102@lnu.edu.ph', 'Bachelor of Physical Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(125, '2000103', 'Luisa', 'P.', 'Domingo', 'luisa.domingo103@lnu.edu.ph', 'Bachelor of Science in Social Work', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(126, '2000104', 'Valeria', 'C.', 'Flores', 'valeria.flores104@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(127, '2000105', 'Zoe', 'U.', 'Aquino', 'zoe.aquino105@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(128, '2000106', 'Gabriel', 'E.', 'Cordero', 'gabriel.cordero106@lnu.edu.ph', 'Bachelor of Music in Music Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(129, '2000107', 'Martina', 'T.', 'Domingo', 'martina.domingo107@lnu.edu.ph', 'Bachelor of Arts in Communication', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(130, '2000108', 'Clara', 'E.', 'Mercado', 'clara.mercado108@lnu.edu.ph', 'Bachelor of Technology and Livelihood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(131, '2000109', 'Ana', 'L.', 'Reyes', 'ana.reyes109@lnu.edu.ph', 'Bachelor of Arts in Communication', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(132, '2000110', 'Emilia', 'Y.', 'Flores', 'emilia.flores110@lnu.edu.ph', 'Bachelor of Arts in English Language', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(133, '2000111', 'Juliana', 'H.', 'Cordero', 'juliana.cordero111@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(134, '2000112', 'Victor', 'B.', 'Ignacio', 'victor.ignacio112@lnu.edu.ph', 'Bachelor of Science in Social Work', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(135, '2000113', 'Clara', 'A.', 'Reyes', 'clara.reyes113@lnu.edu.ph', 'Bachelor of Arts in Communication', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(136, '2000114', 'Oscar', 'B.', 'Flores', 'oscar.flores114@lnu.edu.ph', 'Bachelor of Entrepreneurship', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(137, '2000115', 'Gabriel', 'C.', 'De Leon', 'gabriel.de leon115@lnu.edu.ph', 'Bachelor of Arts in English Language', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(138, '2000116', 'Eduardo', 'O.', 'Rodriguez', 'eduardo.rodriguez116@lnu.edu.ph', 'Bachelor of Entrepreneurship', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(139, '2000117', 'Carmen', 'Z.', 'Guzman', 'carmen.guzman117@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(140, '2000118', 'Rafael', 'S.', 'Sarmiento', 'rafael.sarmiento118@lnu.edu.ph', 'Bachelor of Special Needs Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(141, '2000119', 'Vicente', 'I.', 'Cruz', 'vicente.cruz119@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(142, '2000120', 'Pedro', 'X.', 'Santiago', 'pedro.santiago120@lnu.edu.ph', 'Bachelor of Early Childhood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(143, '2000121', 'Francisco', 'B.', 'Del Rosario', 'francisco.del rosario121@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(144, '2000122', 'Beatriz', 'Z.', 'Garcia', 'beatriz.garcia122@lnu.edu.ph', 'Bachelor of Early Childhood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(145, '2000123', 'Mariana', 'D.', 'Bautista', 'mariana.bautista123@lnu.edu.ph', 'Bachelor of Science in Biology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(146, '2000124', 'Lucia', 'M.', 'Ferrer', 'lucia.ferrer124@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(147, '2000125', 'Ricardo', 'D.', 'De Leon', 'ricardo.de leon125@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(148, '2000126', 'Gabriel', 'I.', 'Mercado', 'gabriel.mercado126@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(149, '2000127', 'Joaquin', 'X.', 'Del Rosario', 'joaquin.del rosario127@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(150, '2000128', 'Andres', 'Q.', 'Rivera', 'andres.rivera128@lnu.edu.ph', 'Bachelor of Arts in English Language', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(151, '2000129', 'Valeria', 'R.', 'Miranda', 'valeria.miranda129@lnu.edu.ph', 'Bachelor of Arts in English Language', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(152, '2000130', 'Gabriel', 'F.', 'Villanueva', 'gabriel.villanueva130@lnu.edu.ph', 'Bachelor of Entrepreneurship', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(153, '2000131', 'Isabel', 'K.', 'Santos', 'isabel.santos131@lnu.edu.ph', 'Bachelor of Special Needs Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(154, '2000132', 'Juan', 'M.', 'Perez', 'juan.perez132@lnu.edu.ph', 'Bachelor of Arts in English Language', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(155, '2000133', 'Mario', 'V.', 'Velasco', 'mario.velasco133@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(156, '2000134', 'Mario', 'K.', 'Guzman', 'mario.guzman134@lnu.edu.ph', 'Bachelor of Technology and Livelihood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(157, '2000135', 'Valentina', 'N.', 'Soriano', 'valentina.soriano135@lnu.edu.ph', 'Bachelor of Technology and Livelihood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(158, '2000136', 'Julio', 'K.', 'Cruz', 'julio.cruz136@lnu.edu.ph', 'Bachelor of Science in Biology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(159, '2000137', 'Pedro', 'A.', 'Tolentino', 'pedro.tolentino137@lnu.edu.ph', 'Bachelor of Science in Biology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(160, '2000138', 'Lucia', 'C.', 'Bautista', 'lucia.bautista138@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(161, '2000139', 'Oscar', 'S.', 'Castillo', 'oscar.castillo139@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(162, '2000140', 'Emilia', 'U.', 'Ortiz', 'emilia.ortiz140@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(163, '2000141', 'Eduardo', 'C.', 'Mendoza', 'eduardo.mendoza141@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(164, '2000142', 'Daniela', 'E.', 'Castillo', 'daniela.castillo142@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(165, '2000143', 'Emilia', 'I.', 'Guzman', 'emilia.guzman143@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(166, '2000144', 'Lourdes', 'K.', 'Castro', 'lourdes.castro144@lnu.edu.ph', 'Bachelor of Library and Information Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(167, '2000145', 'Martina', 'E.', 'Pascual', 'martina.pascual145@lnu.edu.ph', 'Bachelor of Music in Music Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(168, '2000146', 'Vicente', 'Q.', 'Nicolas', 'vicente.nicolas146@lnu.edu.ph', 'Bachelor of Physical Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(169, '2000147', 'Micaela', 'U.', 'Villanueva', 'micaela.villanueva147@lnu.edu.ph', 'Bachelor of Arts in English Language', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(170, '2000148', 'Francisco', 'P.', 'Sison', 'francisco.sison148@lnu.edu.ph', 'Bachelor of Science in Social Work', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(171, '2000149', 'Camila', 'R.', 'Ortiz', 'camila.ortiz149@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(172, '2000150', 'Elena', 'U.', 'Domingo', 'elena.domingo150@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(173, '2000151', 'Lourdes', 'Y.', 'Ortiz', 'lourdes.ortiz151@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(174, '2000152', 'Carmen', 'U.', 'Ortiz', 'carmen.ortiz152@lnu.edu.ph', 'Bachelor of Music in Music Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(175, '2000153', 'Emanuel', 'J.', 'Rivera', 'emanuel.rivera153@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(176, '2000154', 'Emanuel', 'E.', 'Ferrer', 'emanuel.ferrer154@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(177, '2000155', 'Oscar', 'H.', 'Torres', 'oscar.torres155@lnu.edu.ph', 'Bachelor of Special Needs Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(178, '2000156', 'Carmen', 'W.', 'Castillo', 'carmen.castillo156@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(179, '2000157', 'Maria', 'W.', 'Alvarez', 'maria.alvarez157@lnu.edu.ph', 'Bachelor of Library and Information Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(180, '2000158', 'Rafael', 'E.', 'Perez', 'rafael.perez158@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(181, '2000159', 'Marcos', 'S.', 'Navarro', 'marcos.navarro159@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(182, '2000160', 'Carmen', 'W.', 'Gonzales', 'carmen.gonzales160@lnu.edu.ph', 'Bachelor of Science in Biology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(183, '2000161', 'Juan', 'X.', 'Cordero', 'juan.cordero161@lnu.edu.ph', 'Bachelor of Entrepreneurship', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(184, '2000162', 'Rosa', 'C.', 'De Leon', 'rosa.de leon162@lnu.edu.ph', 'Bachelor of Science in Social Work', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(185, '2000163', 'Beatriz', 'V.', 'Soriano', 'beatriz.soriano163@lnu.edu.ph', 'Bachelor of Entrepreneurship', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(186, '2000164', 'Mariana', 'T.', 'Sarmiento', 'mariana.sarmiento164@lnu.edu.ph', 'Bachelor of Technology and Livelihood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(187, '2000165', 'Valeria', 'N.', 'Reyes', 'valeria.reyes165@lnu.edu.ph', 'Bachelor of Early Childhood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(188, '2000166', 'Beatriz', 'S.', 'Mercado', 'beatriz.mercado166@lnu.edu.ph', 'Bachelor of Science in Biology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(189, '2000167', 'Camila', 'N.', 'Ocampo', 'camila.ocampo167@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(190, '2000168', 'Victor', 'Z.', 'Villanueva', 'victor.villanueva168@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(191, '2000169', 'Lucia', 'R.', 'Castro', 'lucia.castro169@lnu.edu.ph', 'Bachelor of Special Needs Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(192, '2000170', 'Jose', 'D.', 'Tolentino', 'jose.tolentino170@lnu.edu.ph', 'Bachelor of Science in Biology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(193, '2000171', 'Antonio', 'D.', 'Domingo', 'antonio.domingo171@lnu.edu.ph', 'Bachelor of Music in Music Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(194, '2000172', 'Pedro', 'P.', 'Gomez', 'pedro.gomez172@lnu.edu.ph', 'Bachelor of Arts in English Language', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(195, '2000173', 'Beatriz', 'E.', 'Santiago', 'beatriz.santiago173@lnu.edu.ph', 'Bachelor of Arts in Communication', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(196, '2000174', 'Micaela', 'V.', 'Nicolas', 'micaela.nicolas174@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(197, '2000175', 'Daniela', 'M.', 'Domingo', 'daniela.domingo175@lnu.edu.ph', 'Bachelor of Elementary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(198, '2000176', 'Emilia', 'H.', 'Domingo', 'emilia.domingo176@lnu.edu.ph', 'Bachelor of Special Needs Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(199, '2000177', 'Daniela', 'A.', 'Torres', 'daniela.torres177@lnu.edu.ph', 'Bachelor of Science in Hospitality Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(200, '2000178', 'Camila', 'U.', 'Mendoza', 'camila.mendoza178@lnu.edu.ph', 'Bachelor of Arts in English Language', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(201, '2000179', 'Jose', 'A.', 'Nicolas', 'jose.nicolas179@lnu.edu.ph', 'Bachelor of Music in Music Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(202, '2000180', 'Valeria', 'R.', 'Villanueva', 'valeria.villanueva180@lnu.edu.ph', 'Bachelor of Arts in Communication', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(203, '2000181', 'Juan', 'S.', 'Diaz', 'juan.diaz181@lnu.edu.ph', 'Bachelor of Music in Music Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(204, '2000182', 'Victor', 'S.', 'Miranda', 'victor.miranda182@lnu.edu.ph', 'Bachelor of Arts in English Language', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(205, '2000183', 'Isabel', 'Y.', 'Navarro', 'isabel.navarro183@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(206, '2000184', 'Valentina', 'Q.', 'Romero', 'valentina.romero184@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(207, '2000185', 'Fernando', 'O.', 'Bautista', 'fernando.bautista185@lnu.edu.ph', 'Bachelor of Physical Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(208, '2000186', 'Oscar', 'Q.', 'Ortiz', 'oscar.ortiz186@lnu.edu.ph', 'Bachelor of Arts in Political Science', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(209, '2000187', 'Eduardo', 'V.', 'Romero', 'eduardo.romero187@lnu.edu.ph', 'Bachelor of Arts in English Language', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(210, '2000188', 'Mariana', 'Z.', 'Gutierrez', 'mariana.gutierrez188@lnu.edu.ph', 'Bachelor of Music in Music Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(211, '2000189', 'Beatriz', 'W.', 'Ferrer', 'beatriz.ferrer189@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(212, '2000190', 'Diego', 'D.', 'Nicolas', 'diego.nicolas190@lnu.edu.ph', 'Bachelor of Special Needs Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(213, '2000191', 'Victoria', 'E.', 'Santiago', 'victoria.santiago191@lnu.edu.ph', 'Bachelor of Science in Information Technology', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(214, '2000192', 'Emanuel', 'Z.', 'Perez', 'emanuel.perez192@lnu.edu.ph', 'Bachelor of Arts in Communication', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(215, '2000193', 'Joaquin', 'Q.', 'Tolentino', 'joaquin.tolentino193@lnu.edu.ph', 'Bachelor of Early Childhood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(216, '2000194', 'Juan', 'F.', 'Mercado', 'juan.mercado194@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(217, '2000195', 'Victor', 'P.', 'Mercado', 'victor.mercado195@lnu.edu.ph', 'Bachelor of Technology and Livelihood Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(218, '2000196', 'Beatriz', 'G.', 'Rivera', 'beatriz.rivera196@lnu.edu.ph', 'Bachelor of Science in Social Work', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(219, '2000197', 'Valentina', 'A.', 'Cordero', 'valentina.cordero197@lnu.edu.ph', 'Bachelor of Secondary Education', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(220, '2000198', 'Francisco', 'P.', 'Ignacio', 'francisco.ignacio198@lnu.edu.ph', 'Bachelor of Science in Social Work', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]'),
(221, '2000199', 'Francisco', 'X.', 'Valdez', 'francisco.valdez199@lnu.edu.ph', 'Bachelor of Science in Tourism Management', '$2b$12$T5T8H3qotczhq6R5Nq9/TuEZyn2/vgBCRo5ur7fOHozvtfJNc8B6.', 'Student', 1, '2026-04-19 21:32:32', NULL, '[]');

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
  MODIFY `candidate_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `parties`
--
ALTER TABLE `parties`
  MODIFY `party_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `polls`
--
ALTER TABLE `polls`
  MODIFY `poll_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=222;

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
