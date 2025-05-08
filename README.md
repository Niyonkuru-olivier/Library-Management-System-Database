# Library-Management-System-Database
               Description

 A complete relational database for a Library Management System built with MySQL. This system tracks:

- Books, authors, publishers, and genres
- Library members and their memberships
- Book loans, reservations, and fines
- Staff members and audit logs

The database enforces data integrity through constraints, relationships, and triggers while optimizing performance with proper indexing.

                  Features

1. Comprehensive Data Model: 10+ tables covering all library operations
2. Data Integrity: PK/FK constraints, CHECK constraints, NOT NULL, UNIQUE
3. Business Logic: Triggers for automatic copy availability updates
4. Audit Trail: Complete change logging
5. Performance Optimized: Proper indexing for critical queries

Setup Instructions

     Prerequisites

- MySQL Server (8.0+ recommended)
- MySQL Workbench or another client

   Installation

1. Clone this repository:
   git clone https://github.com/Niyonkuru-olivier/Library-Management-System-Database.git
   cd Library-Management-System-Database
2. Import the database:
mysql -u username -p < database/library.sql
Or using MySQL Workbench:
1. Open the SQL file
2. Execute all statements
