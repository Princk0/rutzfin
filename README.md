# Rutzfin

Rutzfin is a full-stack financial operations dashboard that brings together core banking and analytics workflows into a single, modern application. The project combines a Java Spring Boot backend, a React frontend, and a PostgreSQL data layer to support branch performance monitoring, fraud detection signals, customer insights, and lending health analysis.

## Why this project

This project was built to model a practical financial operations platform where business stakeholders can monitor performance, identify risk indicators, and understand portfolio health through a clear dashboard experience.

It focuses on:

- Operational visibility across branches and departments
- Customer and transaction monitoring
- Risk and fraud signal tracking
- Loan and portfolio health insights
- Data-driven analytics for business decisions

## Architecture

Rutzfin follows a layered architecture:

- Frontend: React + Vite for dashboard pages and interactive data views
- Backend: Java + Spring Boot for REST APIs and service logic
- Database: PostgreSQL with schema, seed data, views, procedures, and analytics queries
- Data flow: UI requests trigger backend API calls, which read from structured SQL views and reporting logic

## Features

- Executive dashboard with KPI summaries
- Branch performance analytics
- Customer overview and account detail views
- Fraud alert monitoring
- Loan health and risk visibility
- SQL-driven analytics and reporting layer

## Tech stack

- Java 25
- Spring Boot 3.5.x
- Maven
- React
- Vite
- PostgreSQL
- REST APIs and dashboard-focused frontend design

## Project structure

```text
.
├── backend/                  # Python-based backend workflow
├── backend-java/             # Spring Boot application
│   ├── src/main/java/        # Java source code
│   ├── src/main/resources/  # application configuration
│   ├── src/test/java/        # unit tests
│   ├── pom.xml              # Maven configuration
│   └── RASPBERRY_PI_SETUP.md
├── frontend/                 # React frontend
├── sql/                      # PostgreSQL schema and SQL scripts
├── .gitignore
├── README.md
├── package-lock.json
└── LICENSE                   # add a license if desired
```

## Getting started

### Prerequisites

- Java 25
- Maven 3.9+
- Node.js 18+
- PostgreSQL 14+

### Backend

Navigate to the Java backend and run the application:

```bash
cd backend-java
mvn spring-boot:run
```

### Frontend

Install dependencies and start the application:

```bash
cd frontend
npm install
npm run dev
```

### Database

Set up the PostgreSQL database using the SQL scripts in the `sql/` folder. For a standard local setup, run the scripts in order:

1. `01_schema.sql`
2. `02_seed_data.sql`
3. `03_indexes.sql`
4. `04_views.sql`
5. `05_stored_procedures.sql`
6. `06_triggers.sql`
7. `07_advanced_queries.sql`

## Testing

Run the backend test suite:

```bash
cd backend-java
mvn test
```

## Portfolio positioning

This project demonstrates:

- Full-stack application design
- Java backend development with Spring Boot
- Frontend dashboard development with React
- Database design and SQL analytics work
- Problem-solving for financial operations and risk visibility

## License

This project is currently provided as a portfolio project and may be updated with a formal open-source license if needed.

## Contact

For questions or collaboration opportunities, feel free to connect via GitHub or LinkedIn.
