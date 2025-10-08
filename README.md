# Library Loan Management System

A REST API application to help library administrators streamline the book lending process. Built with Ruby on Rails 7.1.5.

## Table of Contents
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Database Schema](#database-schema)
- [Business Rules](#business-rules)
- [API Endpoints](#api-endpoints)
- [Setup Instructions](#setup-instructions)
- [Running Tests](#running-tests)

## Features

- **Book Management**: Add, update, delete, and view books with stock tracking
- **Borrower Management**: Manage borrower information with unique ID cards
- **Loan Management**: Track book borrowing and returns
- **Stock Availability**: Real-time tracking of available book stock
- **Overdue Tracking**: Automatic identification of overdue loans
- **Business Rule Enforcement**:
  - Maximum 30-day loan period
  - One active loan per borrower at a time
  - Automatic stock availability checking
- **Simple UI**: Dashboard for testing all functionality

## Technology Stack

- **Ruby**: 3.3.0
- **Rails**: 7.1.5
- **Database**: SQLite3
- **Testing**: RSpec, FactoryBot, Shoulda Matchers
- **Containerization**: Docker & Docker Compose

## Database Schema

### DDL (Data Definition Language)

```sql
-- Books Table
CREATE TABLE books (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title VARCHAR NOT NULL,
    isbn VARCHAR NOT NULL UNIQUE,
    stock INTEGER NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT check_stock_non_negative CHECK (stock >= 0)
);

CREATE UNIQUE INDEX index_books_on_isbn ON books (isbn);
CREATE UNIQUE INDEX index_books_on_title ON books (title);

-- Borrowers Table
CREATE TABLE borrowers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_card_number VARCHAR NOT NULL UNIQUE,
    name VARCHAR NOT NULL,
    email VARCHAR NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL
);

CREATE UNIQUE INDEX index_borrowers_on_id_card_number ON borrowers (id_card_number);

-- Loans Table
CREATE TABLE loans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    book_id INTEGER NOT NULL,
    borrower_id INTEGER NOT NULL,
    borrowed_at DATETIME NOT NULL,
    due_date DATETIME NOT NULL,
    returned_at DATETIME,
    status VARCHAR NOT NULL DEFAULT 'active',
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    FOREIGN KEY (book_id) REFERENCES books (id),
    FOREIGN KEY (borrower_id) REFERENCES borrowers (id),
    CONSTRAINT check_status_values CHECK (status IN ('active', 'returned', 'overdue'))
);

CREATE INDEX index_loans_on_book_id ON loans (book_id);
CREATE INDEX index_loans_on_borrower_id ON loans (borrower_id);
CREATE INDEX index_loans_on_status ON loans (status);
```

### Entity Relationship Diagram

```
┌─────────────────┐
│     Books       │
├─────────────────┤
│ id (PK)         │
│ title           │
│ isbn (UNIQUE)   │
│ stock           │
│ created_at      │
│ updated_at      │
└────────┬────────┘
         │
         │ 1:N
         │
┌────────▼────────┐
│     Loans       │
├─────────────────┤
│ id (PK)         │
│ book_id (FK)    │
│ borrower_id(FK) │
│ borrowed_at     │
│ due_date        │
│ returned_at     │
│ status          │
│ created_at      │
│ updated_at      │
└────────┬────────┘
         │
         │ N:1
         │
┌────────▼────────┐
│   Borrowers     │
├─────────────────┤
│ id (PK)         │
│ id_card_number  │
│ name            │
│ email           │
│ created_at      │
│ updated_at      │
└─────────────────┘
```

## Business Rules

### Loan Management Rules

1. **30-Day Maximum Loan Period**
   - Due date cannot exceed 30 days from borrowed date
   - Enforced at validation level in the Loan model

2. **One Book Per Loan**
   - Each loan transaction involves exactly one book
   - Borrowers must return current book before borrowing another

3. **No Concurrent Loans**
   - A borrower can only have one active loan at a time
   - Includes both 'active' and 'overdue' status loans
   - Validated before creating new loans

4. **Stock Availability**
   - Books must have available stock to be borrowed
   - Available stock = Total stock - (Active loans + Overdue loans)
   - Returned loans free up stock immediately

5. **Loan Status Management**
   - **Active**: Book is currently borrowed and not overdue
   - **Overdue**: Due date has passed and book not returned
   - **Returned**: Book has been returned

### Validation Rules

**Books:**
- Title must be present and unique
- ISBN must be present and unique
- Stock must be non-negative integer

**Borrowers:**
- ID card number must be unique
- Name must be present
- Email must be valid format

**Loans:**
- Borrowed date, due date, and status must be present
- Status must be one of: active, returned, overdue
- Custom validations enforce business rules

## API Endpoints

### Books API

```
GET    /api/books          # List all books
POST   /api/books          # Create a new book
GET    /api/books/:id      # Show book details
PUT    /api/books/:id      # Update book
DELETE /api/books/:id      # Delete book (only if no active loans)
```

**Request Body Example (Create/Update):**
```json
{
  "book": {
    "title": "The Great Gatsby",
    "isbn": "978-0-7432-7356-5",
    "stock": 5
  }
}
```

### Borrowers API

```
GET    /api/borrowers          # List all borrowers
POST   /api/borrowers          # Create a new borrower
GET    /api/borrowers/:id      # Show borrower details
PUT    /api/borrowers/:id      # Update borrower
DELETE /api/borrowers/:id      # Delete borrower (only if no active loans)
```

**Request Body Example (Create/Update):**
```json
{
  "borrower": {
    "id_card_number": "ID001",
    "name": "John Doe",
    "email": "john.doe@email.com"
  }
}
```

### Loans API

```
GET    /api/loans              # List all loans (supports ?status= filter)
POST   /api/loans              # Create a new loan (borrow book)
GET    /api/loans/:id          # Show loan details
PUT    /api/loans/:id          # Update loan
DELETE /api/loans/:id          # Delete loan
POST   /api/loans/:id/return_book  # Return a borrowed book
GET    /api/loans/overdue      # List all overdue loans
```

**Request Body Example (Create Loan):**
```json
{
  "loan": {
    "book_id": 1,
    "borrower_id": 1,
    "due_date": "2025-11-07"
  }
}
```

**Response Example:**
```json
{
  "id": 1,
  "book": {
    "id": 1,
    "title": "The Great Gatsby",
    "isbn": "978-0-7432-7356-5"
  },
  "borrower": {
    "id": 1,
    "name": "John Doe",
    "id_card_number": "ID001"
  },
  "borrowed_at": "2025-10-08T10:30:00.000Z",
  "due_date": "2025-11-07T10:30:00.000Z",
  "returned_at": null,
  "status": "active",
  "overdue": false,
  "days_overdue": 0
}
```

## Setup Instructions

### Prerequisites
- Docker and Docker Compose installed

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd libloan
   ```

2. **Build and start Docker containers:**
   ```bash
   docker-compose up --build -d
   ```

3. **Setup database:**
   ```bash
   docker-compose exec web bundle exec rails db:create db:migrate
   ```

4. **Seed sample data (optional):**
   ```bash
   docker-compose exec web bundle exec rails db:seed
   ```

5. **Start Rails server:**
   ```bash
   docker exec -d <container-id> bash -c "cd /app && bundle exec rails s -b 0.0.0.0"
   ```

6. **Access the application:**
   - UI Dashboard: http://localhost:3000
   - API: http://localhost:3000/api/*

### Without Docker

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Setup database:**
   ```bash
   rails db:create db:migrate db:seed
   ```

3. **Start server:**
   ```bash
   rails server
   ```

## Running Tests

The application uses RSpec for testing with 68 comprehensive test cases covering all models and business logic.

```bash
# Run all tests
docker exec <container-id> bash -c "cd /app && bundle exec rspec"

# Run specific test file
docker exec <container-id> bash -c "cd /app && bundle exec rspec spec/models/book_spec.rb"

# Run with documentation format
docker exec <container-id> bash -c "cd /app && bundle exec rspec --format documentation"
```

### Test Coverage

- **Book Model**: 15 examples
- **Borrower Model**: 17 examples  
- **Loan Model**: 36 examples
- **Total**: 68 examples, 0 failures

## Project Structure

```
libloan/
├── app/
│   ├── controllers/
│   │   ├── api/
│   │   │   ├── books_controller.rb
│   │   │   ├── borrowers_controller.rb
│   │   │   └── loans_controller.rb
│   │   ├── application_controller.rb
│   │   └── dashboard_controller.rb
│   ├── models/
│   │   ├── book.rb
│   │   ├── borrower.rb
│   │   └── loan.rb
│   └── views/
│       ├── dashboard/
│       │   └── index.html.erb
│       └── layouts/
│           └── application.html.erb
├── config/
│   ├── routes.rb
│   └── database.yml
├── db/
│   ├── migrate/
│   ├── schema.rb
│   └── seeds.rb
├── spec/
│   ├── factories/
│   │   ├── books.rb
│   │   ├── borrowers.rb
│   │   └── loans.rb
│   ├── models/
│   │   ├── book_spec.rb
│   │   ├── borrower_spec.rb
│   │   └── loan_spec.rb
│   ├── rails_helper.rb
│   └── spec_helper.rb
├── docker-compose.yml
├── Dockerfile
└── README.md
```
