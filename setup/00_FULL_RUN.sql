-- setup/00_FULL_RUN.sql
-- Master script: run this first to set up entire infrastructure
-- Execute as: snow sql -f setup/00_FULL_RUN.sql

-- Step 1: Roles
@./setup/00_create_roles.sql

-- Step 2: Warehouses  
@./setup/01_create_warehouses.sql

-- Step 3: Databases
@./setup/02_create_databases.sql

-- Step 4: Permissions
@./setup/03_grant_permissions.sql

-- Validation
USE ROLE ACCOUNTADMIN;
SELECT 'Roles created:' as check_type;
SHOW ROLES;

SELECT 'Warehouses created:' as check_type;
SHOW WAREHOUSES;

SELECT 'Databases created:' as check_type;
SHOW DATABASES;

PRINT '✓ Infrastructure setup complete!';
