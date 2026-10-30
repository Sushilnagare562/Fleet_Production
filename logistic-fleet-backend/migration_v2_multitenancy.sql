-- ===================================================================
-- Logistic Fleet Migration v2: Multi-tenancy
-- ===================================================================
-- Run this ONCE against your existing Logistic Fleet database before deploying
-- the updated backend. It is safe to run on a database that already has
-- live users/trips/expenses/earnings/vehicles: it creates a "Default
-- Company" tenant, attaches every existing row to it, and only then
-- applies the NOT NULL constraint — so nothing is lost or orphaned.
--
-- After this migration:
--   - All data you already have keeps working exactly as before, now
--     under a single tenant called 'Default Company'.
--   - You can rename that tenant via SQL if you want it to reflect your
--     actual company name:
--       UPDATE tenants SET company_name = 'Your Real Company Name'
--       WHERE company_name = 'Default Company';
--   - New signups create/join their own tenants going forward.
--
-- Wrapped in a transaction so it either fully applies or not at all.
-- ===================================================================

BEGIN;

-- 1. Create the tenants table (safe if it doesn't exist yet).
CREATE TABLE IF NOT EXISTS tenants (
    id              BIGSERIAL PRIMARY KEY,
    tenant_uid      VARCHAR(36)   NOT NULL UNIQUE,
    company_name    VARCHAR(150)  NOT NULL,
    status          VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMP     NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_tenants_company_name_ci ON tenants (LOWER(company_name));

-- 2. Seed a default tenant for all pre-existing data (idempotent).
INSERT INTO tenants (tenant_uid, company_name, status)
SELECT gen_random_uuid()::text, 'Default Company', 'ACTIVE'
WHERE NOT EXISTS (SELECT 1 FROM tenants WHERE LOWER(company_name) = LOWER('Default Company'));
-- NOTE: if gen_random_uuid() is unavailable on your Postgres version,
-- either `CREATE EXTENSION IF NOT EXISTS pgcrypto;` first, or replace
-- gen_random_uuid()::text with md5(random()::text || clock_timestamp()::text).

-- 3. Add tenant_id as NULLABLE first on every affected table.
ALTER TABLE users    ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE trips    ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE earnings ADD COLUMN IF NOT EXISTS tenant_id BIGINT;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS tenant_id BIGINT;

-- 4. Backfill every existing row with the default tenant's id.
UPDATE users    SET tenant_id = (SELECT id FROM tenants WHERE LOWER(company_name) = LOWER('Default Company')) WHERE tenant_id IS NULL;
UPDATE trips    SET tenant_id = (SELECT id FROM tenants WHERE LOWER(company_name) = LOWER('Default Company')) WHERE tenant_id IS NULL;
UPDATE expenses SET tenant_id = (SELECT id FROM tenants WHERE LOWER(company_name) = LOWER('Default Company')) WHERE tenant_id IS NULL;
UPDATE earnings SET tenant_id = (SELECT id FROM tenants WHERE LOWER(company_name) = LOWER('Default Company')) WHERE tenant_id IS NULL;
UPDATE vehicles SET tenant_id = (SELECT id FROM tenants WHERE LOWER(company_name) = LOWER('Default Company')) WHERE tenant_id IS NULL;

-- 5. Now that every row has a tenant, enforce NOT NULL + add FKs.
ALTER TABLE users    ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE trips    ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE expenses ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE earnings ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE vehicles ALTER COLUMN tenant_id SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_users_tenant') THEN
        ALTER TABLE users ADD CONSTRAINT fk_users_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_trips_tenant') THEN
        ALTER TABLE trips ADD CONSTRAINT fk_trips_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_expenses_tenant') THEN
        ALTER TABLE expenses ADD CONSTRAINT fk_expenses_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_earnings_tenant') THEN
        ALTER TABLE earnings ADD CONSTRAINT fk_earnings_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_vehicles_tenant') THEN
        ALTER TABLE vehicles ADD CONSTRAINT fk_vehicles_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id);
    END IF;
END $$;

-- 6. Widen the users.role check/enum-equivalent: nothing to do for a plain
--    VARCHAR column — 'COMPANY_EMPLOYEE' will just work as a new value.

-- 7. Helpful indexes for tenant-scoped queries.
CREATE INDEX IF NOT EXISTS idx_users_tenant    ON users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_trips_tenant    ON trips(tenant_id);
CREATE INDEX IF NOT EXISTS idx_expenses_tenant ON expenses(tenant_id);
CREATE INDEX IF NOT EXISTS idx_earnings_tenant ON earnings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_tenant ON vehicles(tenant_id);

COMMIT;

-- ===================================================================
-- After running this, verify with:
--   SELECT * FROM tenants;
--   SELECT id, name, email, tenant_id, role FROM users;
-- Every existing user/trip/expense/earning/vehicle should now show the
-- 'Default Company' tenant_id.
-- ===================================================================
