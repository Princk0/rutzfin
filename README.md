# Rutzfin

Rutzfin is a full-stack banking and financial operations dashboard that combines a Java Spring Boot backend, a React frontend, and PostgreSQL data models for analytics, customer activity, fraud monitoring, lending health, and branch performance.

## Overview

This project includes:

- A Java backend for REST APIs and business logic
- A Vite + React frontend for operational dashboards and views
- PostgreSQL schema, seed data, indexes, views, stored procedures, and triggers
- SQL scripts for banking and analytics workloads

## Tech stack

- Java 25
- Spring Boot 3.5.x
- Maven
- React
- Vite
- PostgreSQL

## Repository structure

```text
.
├── backend/                  # Python backend (if used in local/dev workflows)
├── backend-java/             # Spring Boot application
│   ├── src/main/java/        # Java source files
│   ├── src/main/resources/  # configuration and app properties
│   ├── src/test/java/        # unit tests
│   ├── pom.xml              # Maven build configuration
│   └── RASPBERRY_PI_SETUP.md
├── frontend/                 # React frontend
├── sql/                      # SQL scripts for PostgreSQL setup
├── .gitignore
├── README.md
└── package-lock.json
```

## Prerequisites

Before running the app, install:

- Java 25
- Maven 3.9+
- Node.js 18+
- PostgreSQL 14+

## Backend setup

1. Open the Java backend folder:

```bash
cd backend-java
```

2. Ensure the database environment variables are available. Example:

```bash
export PG_HOST=localhost
export PG_PORT=5432
export PG_DATABASE=rutzfin
export PG_USER=rutzfin_user
export PG_PASSWORD=your_password
```

3. Run the app:

```bash
mvn spring-boot:run
```

The application will start from the Spring Boot entry point in the Java project.

## Frontend setup

1. Open the frontend folder:

```bash
cd frontend
```

2. Install dependencies:

```bash
npm install
```

3. Start the development server:

```bash
npm run dev
```

## Database setup

Import the SQL scripts in order from the `sql/` directory:

1. `01_schema.sql`
2. `02_seed_data.sql`
3. `03_indexes.sql`
4. `04_views.sql`
5. `05_stored_procedures.sql`
6. `06_triggers.sql`
7. `07_advanced_queries.sql`

If you are using the PostgreSQL variant, use the scripts from `sql/postgresql/` as needed.

## Running tests

Java backend:

```bash
cd backend-java
mvn test
```

## Notes

- The project is intended for local development and demonstration of financial operations analytics.
- Update environment variables and database credentials for your deployment environment.
- Keep secrets outside of the repository and use secure deployment configuration for production systems.

## License

This project is provided for educational and internal use unless a separate license is added by the repository owner.
