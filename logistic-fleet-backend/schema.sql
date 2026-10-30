-- Logistic Fleet Database Schema (PostgreSQL)

-- ===================================================================
-- Tenants (companies). Every user, and every trip/expense/earning/
-- vehicle they create, belongs to exactly one tenant so one company's
-- data is never visible to another as the platform scales.
-- ===================================================================
CREATE TABLE tenants (
    id              BIGSERIAL PRIMARY KEY,
    tenant_uid      VARCHAR(36)   NOT NULL UNIQUE,
    company_name    VARCHAR(150)  NOT NULL,
    status          VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, SUSPENDED, INACTIVE
    created_at      TIMESTAMP     NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX idx_tenants_company_name_ci ON tenants (LOWER(company_name));

CREATE TABLE users (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       BIGINT        NOT NULL REFERENCES tenants(id),
    name            VARCHAR(120)  NOT NULL,
    email           VARCHAR(150)  NOT NULL UNIQUE,
    phone           VARCHAR(20)   NOT NULL UNIQUE,
    password_hash   VARCHAR(255)  NOT NULL,
    role            VARCHAR(20)   NOT NULL DEFAULT 'DRIVER', -- DRIVER, ADMIN, COMPANY_EMPLOYEE
    vehicle_number  VARCHAR(30),
    license_number  VARCHAR(40),
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    driver_status   VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, ON_LEAVE, DELETED (soft delete - see AdminDriverService)
    profile_photo   TEXT,                     -- base64-encoded avatar image, no data: prefix
    reset_otp_hash  VARCHAR(255),              -- bcrypt hash of the active "forgot password" OTP, if any
    reset_otp_expiry TIMESTAMP,                -- when the OTP above stops being valid
    created_at      TIMESTAMP     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP     NOT NULL DEFAULT now()
);

CREATE TABLE trips (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       BIGINT        NOT NULL REFERENCES tenants(id),
    trip_code       VARCHAR(30)   NOT NULL UNIQUE,
    driver_id       BIGINT        REFERENCES users(id),
    vehicle_id      BIGINT,       -- FK to vehicles(id), added below since that table is defined further down this file
    origin          VARCHAR(200)  NOT NULL,
    destination     VARCHAR(200)  NOT NULL,
    status          VARCHAR(20)   NOT NULL DEFAULT 'ASSIGNED', -- ASSIGNED, IN_PROGRESS, COMPLETED, CANCELLED
    scheduled_start TIMESTAMP,
    scheduled_end   TIMESTAMP,
    actual_start    TIMESTAMP,
    actual_end      TIMESTAMP,
    distance_km     NUMERIC(8,2),
    notes           TEXT,
    created_at      TIMESTAMP     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP     NOT NULL DEFAULT now()
);

CREATE TABLE route_stops (
    id              BIGSERIAL PRIMARY KEY,
    trip_id         BIGINT        NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    sequence_no     INT           NOT NULL,
    location_name   VARCHAR(200)  NOT NULL,
    latitude        NUMERIC(10,6),
    longitude       NUMERIC(10,6),
    stop_type       VARCHAR(20)   NOT NULL, -- PICKUP, DELIVERY, WAYPOINT
    planned_time    TIMESTAMP,
    created_at      TIMESTAMP     NOT NULL DEFAULT now()
);

CREATE TABLE dock_events (
    id              BIGSERIAL PRIMARY KEY,
    trip_id         BIGINT        NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    route_stop_id   BIGINT        REFERENCES route_stops(id),
    driver_id       BIGINT        NOT NULL REFERENCES users(id),
    event_type      VARCHAR(20)   NOT NULL, -- DOCK_IN, DOCK_OUT
    location_name   VARCHAR(200),
    latitude        NUMERIC(10,6),
    longitude       NUMERIC(10,6),
    event_time      TIMESTAMP     NOT NULL DEFAULT now(),
    remarks         VARCHAR(300)
);

CREATE TABLE expenses (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       BIGINT        NOT NULL REFERENCES tenants(id),
    trip_id         BIGINT        REFERENCES trips(id),
    driver_id       BIGINT        NOT NULL REFERENCES users(id),
    category        VARCHAR(30)   NOT NULL, -- FUEL, TOLL, FOOD, MAINTENANCE, OTHER
    amount          NUMERIC(10,2) NOT NULL,
    description     VARCHAR(300),
    receipt_url     VARCHAR(500),
    expense_date    DATE          NOT NULL,
    status          VARCHAR(20)   NOT NULL DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    review_notes    VARCHAR(300),
    created_at      TIMESTAMP     NOT NULL DEFAULT now()
);

CREATE TABLE earnings (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       BIGINT        NOT NULL REFERENCES tenants(id),
    trip_id         BIGINT        REFERENCES trips(id),
    driver_id       BIGINT        NOT NULL REFERENCES users(id),
    base_amount     NUMERIC(10,2) NOT NULL DEFAULT 0,
    bonus           NUMERIC(10,2) NOT NULL DEFAULT 0,
    deduction       NUMERIC(10,2) NOT NULL DEFAULT 0,
    total_amount    NUMERIC(10,2) NOT NULL DEFAULT 0,
    status          VARCHAR(20)   NOT NULL DEFAULT 'PENDING', -- PENDING, PAID
    period_start    DATE,
    period_end      DATE,
    created_at      TIMESTAMP     NOT NULL DEFAULT now()
);

CREATE TABLE vehicles (
    id                  BIGSERIAL PRIMARY KEY,
    tenant_id           BIGINT        NOT NULL REFERENCES tenants(id),
    vehicle_number      VARCHAR(30)   NOT NULL UNIQUE,
    type                VARCHAR(20)   NOT NULL, -- TRUCK, VAN, BIKE, CAR, OTHER
    model               VARCHAR(100),
    capacity_kg         NUMERIC(10,2),
    status              VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, MAINTENANCE, INACTIVE
    assigned_driver_id  BIGINT        REFERENCES users(id),
    created_at          TIMESTAMP     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP     NOT NULL DEFAULT now()
);

CREATE INDEX idx_trips_driver ON trips(driver_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_route_stops_trip ON route_stops(trip_id);
CREATE INDEX idx_dock_events_trip ON dock_events(trip_id);
CREATE INDEX idx_expenses_driver ON expenses(driver_id);
CREATE INDEX idx_earnings_driver ON earnings(driver_id);
CREATE INDEX idx_vehicles_driver ON vehicles(assigned_driver_id);
CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_trips_tenant ON trips(tenant_id);
CREATE INDEX idx_expenses_tenant ON expenses(tenant_id);
CREATE INDEX idx_earnings_tenant ON earnings(tenant_id);
CREATE INDEX idx_vehicles_tenant ON vehicles(tenant_id);

ALTER TABLE trips ADD CONSTRAINT fk_trips_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id);
CREATE INDEX idx_trips_vehicle ON trips(vehicle_id);
