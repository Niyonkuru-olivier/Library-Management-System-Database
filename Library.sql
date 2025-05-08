-- Library Management System Database
-- Created by: [Your Name]
-- Date: [Current Date]

-- Create database
CREATE DATABASE IF NOT EXISTS LibraryManagementSystem;
USE LibraryManagementSystem;

-- Members table (stores library members)


CREATE TABLE Members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200),
    date_of_birth DATE,
    membership_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    membership_status ENUM('Active', 'Expired', 'Suspended') NOT NULL DEFAULT 'Active',
    CONSTRAINT chk_email CHECK (email LIKE '%@%.%')
);

-- Publishers table
CREATE TABLE Publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    publisher_name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    phone VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(100),
    CONSTRAINT chk_publisher_email CHECK (email LIKE '%@%.%' OR email IS NULL)
);

-- Authors table
CREATE TABLE Authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    death_date DATE,
    nationality VARCHAR(50),
    biography TEXT,
    CONSTRAINT chk_dates CHECK (death_date IS NULL OR birth_date < death_date)
);

-- Genres table
CREATE TABLE Genres (
    genre_id INT AUTO_INCREMENT PRIMARY KEY,
    genre_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

-- Books table
CREATE TABLE Books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    isbn VARCHAR(13) UNIQUE NOT NULL,
    publisher_id INT,
    publication_year INT,
    edition INT,
    language VARCHAR(30),
    page_count INT,
    summary TEXT,
    total_copies INT NOT NULL DEFAULT 1,
    available_copies INT NOT NULL DEFAULT 1,
    shelf_location VARCHAR(20),
    CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) REFERENCES Publishers(publisher_id),
    CONSTRAINT chk_isbn CHECK (LENGTH(isbn) = 10 OR LENGTH(isbn) = 13),
    CONSTRAINT chk_publication_year CHECK (publication_year >= 1000),
    CONSTRAINT chk_copies CHECK (available_copies <= total_copies AND total_copies >= 0)
);

-- Book-Author relationship (M-M)
CREATE TABLE BookAuthors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    contribution_type VARCHAR(50) DEFAULT 'Primary',
    PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_ba_book FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_ba_author FOREIGN KEY (author_id) REFERENCES Authors(author_id) ON DELETE CASCADE
);
-- Book-Genre relationship (M-M)
CREATE TABLE BookGenres (
    book_id INT NOT NULL,
    genre_id INT NOT NULL,
    PRIMARY KEY (book_id, genre_id),
    CONSTRAINT fk_bg_book FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_bg_genre FOREIGN KEY (genre_id) REFERENCES Genres(genre_id) ON DELETE CASCADE
);

-- Loans table
CREATE TABLE Loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    loan_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date DATE NOT NULL,
    return_date DATE,
    status ENUM('Active', 'Returned', 'Overdue', 'Lost') NOT NULL DEFAULT 'Active',
    late_fee DECIMAL(10,2) DEFAULT 0.00,
    CONSTRAINT fk_loan_book FOREIGN KEY (book_id) REFERENCES Books(book_id),
    CONSTRAINT fk_loan_member FOREIGN KEY (member_id) REFERENCES Members(member_id),
    CONSTRAINT chk_due_date CHECK (due_date > loan_date),
    CONSTRAINT chk_return_date CHECK (return_date IS NULL OR return_date >= loan_date)
);

-- Fines table
CREATE TABLE Fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    issue_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    payment_date DATE,
    status ENUM('Pending', 'Paid', 'Waived') NOT NULL DEFAULT 'Pending',
    CONSTRAINT fk_fine_loan FOREIGN KEY (loan_id) REFERENCES Loans(loan_id),
    CONSTRAINT chk_fine_amount CHECK (amount >= 0),
    CONSTRAINT chk_payment_date CHECK (payment_date IS NULL OR payment_date >= issue_date)
);

-- Reservations table
CREATE TABLE Reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    reservation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATETIME NOT NULL,
    status ENUM('Pending', 'Fulfilled', 'Cancelled', 'Expired') NOT NULL DEFAULT 'Pending',
    CONSTRAINT fk_reservation_book FOREIGN KEY (book_id) REFERENCES Books(book_id),
    CONSTRAINT fk_reservation_member FOREIGN KEY (member_id) REFERENCES Members(member_id),
    CONSTRAINT chk_reservation_dates CHECK (expiry_date > reservation_date),
    CONSTRAINT unique_active_reservation UNIQUE (book_id, member_id)
);

-- Staff table
CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200),
    position VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    salary DECIMAL(10,2),
    CONSTRAINT chk_staff_email CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_salary CHECK (salary >= 0)
);

-- Audit log table
CREATE TABLE AuditLog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action_type VARCHAR(20) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id INT,
    action_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id INT,
    old_values JSON,
    new_values JSON,
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES Staff(staff_id)
);

-- Create triggers to maintain data integrity

-- Trigger to update available copies when a loan is created
DELIMITER //
CREATE TRIGGER after_loan_insert
AFTER INSERT ON Loans
FOR EACH ROW
BEGIN
    UPDATE Books 
    SET available_copies = available_copies - 1 
    WHERE book_id = NEW.book_id;
END//
DELIMITER ;

-- Trigger to update available copies when a loan is returned
DELIMITER //
CREATE TRIGGER after_loan_update
AFTER UPDATE ON Loans
FOR EACH ROW
BEGIN
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        UPDATE Books 
        SET available_copies = available_copies + 1 
        WHERE book_id = NEW.book_id;
    END IF;
END//
DELIMITER ;

-- Trigger to update loan status to Overdue when due date passes
DELIMITER //
CREATE TRIGGER check_overdue_loans
BEFORE UPDATE ON Loans
FOR EACH ROW
BEGIN
    IF NEW.status = 'Active' AND NEW.due_date < CURRENT_DATE THEN
        SET NEW.status = 'Overdue';
    END IF;
END//
DELIMITER ;

-- Create indexes for performance optimization
CREATE INDEX idx_books_title ON Books(title);
CREATE INDEX idx_books_isbn ON Books(isbn);
CREATE INDEX idx_members_email ON Members(email);
CREATE INDEX idx_loans_member ON Loans(member_id);
CREATE INDEX idx_loans_book ON Loans(book_id);
CREATE INDEX idx_loans_dates ON Loans(loan_date, due_date, return_date);
CREATE INDEX idx_reservations_dates ON Reservations(reservation_date, expiry_date);