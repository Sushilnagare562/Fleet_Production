# Logistic Fleet Backend — Java Spring Boot + PostgreSQL

Single project containing the REST API and its database schema.

```
logisticfleet-backend/
├── src/main/java/com/logisticfleet/     application code
├── src/main/resources/
│   └── application.properties      DB, JWT, CORS config — edit this first
├── schema.sql                       run this against your PostgreSQL DB
└── pom.xml
```

## 1. Prerequisites

- Java 21+
- Maven 3.9+
- PostgreSQL 14+

## 1a. Multi-tenancy migration (upgrading an existing database)

If you already have a running Logistic Fleet database with data in it, run this **once**,
before starting the app with the new backend code:

```bash
psql -d logisticfleet -f migration_v2_multitenancy.sql
```

This creates a `tenants` table, puts all your existing users/trips/expenses/earnings/vehicles
into a single `Default Company` tenant so nothing breaks, and only then makes `tenant_id`
required. Rename it afterwards if you like:

```sql
UPDATE tenants SET company_name = 'Your Real Company Name' WHERE company_name = 'Default Company';
```

Brand-new installs should just use the updated `schema.sql` directly (already includes tenants).

## 2. Create and seed the database

```bash
createdb logisticfleet
psql -d logisticfleet -f schema.sql
```

## 3. Configure `src/main/resources/application.properties`

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/logisticfleet
spring.datasource.username=logisticfleet_user
spring.datasource.password=logisticfleet_pass

logisticfleet.jwt.secret=CHANGE_ME_TO_A_LONG_RANDOM_SECRET_AT_LEAST_256_BITS_LONG

logisticfleet.cors.allowed-origins=http://localhost:*,http://127.0.0.1:*
```

Create the Postgres role if it doesn't exist yet:

```sql
CREATE USER logisticfleet_user WITH PASSWORD 'logisticfleet_pass';
GRANT ALL PRIVILEGES ON DATABASE logisticfleet TO logisticfleet_user;
```

## 4. Run it

```bash
mvn spring-boot:run
```

API is live at `http://localhost:8080/api`.

## 5. Create your first admin user

Registration now asks for a **company name** and a **role** (Admin / Driver / Company Employee).
The first person to register a given company name becomes that company's admin automatically —
anyone registering with a company name that already exists can only join as Driver or Company
Employee (this stops a stranger from typing your company name and self-granting admin).

So simply: register once via `POST /api/auth/register` with `role: "ADMIN"` and your real company
name, and you're the admin of a brand-new tenant. No manual SQL promotion needed anymore.

## Endpoints

See `Logistic Fleet.postman_collection.json` in this folder (or the parent zip) for a ready-to-import
Postman collection covering every controller, with variables for `baseUrl`, `authToken`,
`tripId`, etc. wired up so login → subsequent requests works out of the box.

| Method | Path                          | Access     |
|--------|-------------------------------|------------|
| POST   | /api/auth/register             | Public     |
| POST   | /api/auth/login                 | Public     |
| GET    | /api/trips/my                   | Driver     |
| GET    | /api/trips/{id}                 | Driver     |
| PATCH  | /api/trips/{id}/status          | Driver     |
| POST   | /api/dock-events                | Driver     |
| GET    | /api/dock-events/trip/{tripId}  | Driver     |
| POST   | /api/expenses                   | Driver     |
| GET    | /api/expenses/my                | Driver     |
| GET    | /api/earnings/my                | Driver     |
| GET    | /api/earnings/my/summary        | Driver     |
| POST   | /api/dispatch/trips             | Admin      |
| GET    | /api/dispatch/trips             | Admin      |
| GET    | /api/dispatch/trips/summary     | Admin      |
| POST   | /api/admin/drivers               | Admin      |
| GET    | /api/admin/drivers               | Admin      |
| PATCH  | /api/admin/drivers/{id}/status   | Admin      |
| POST   | /api/admin/vehicles               | Admin      |
| GET    | /api/admin/vehicles               | Admin      |
| PATCH  | /api/admin/vehicles/{id}/status  | Admin      |
| PATCH  | /api/admin/vehicles/{id}/assign-driver | Admin |
| DELETE | /api/admin/vehicles/{id}         | Admin      |
| GET    | /api/admin/expenses               | Admin      |
| PATCH  | /api/admin/expenses/{id}/status  | Admin      |
| POST   | /api/admin/earnings               | Admin      |
| GET    | /api/admin/earnings               | Admin      |
| PATCH  | /api/admin/earnings/{id}/status  | Admin      |

All non-auth routes require `Authorization: Bearer <token>` from `/api/auth/login`.
