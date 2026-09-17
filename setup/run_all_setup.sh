#!/bin/bash

echo "===== SNOWFLAKE SETUP ====="
echo ""

# Step 1: Create roles
echo "Step 1: Creating roles..."
snow sql -f setup/00_create_roles.sql
if [ $? -eq 0 ]; then
  echo "✓ Roles created successfully"
else
  echo "✗ Failed to create roles"
  exit 1
fi

echo ""

# Step 2: Create warehouses
echo "Step 2: Creating warehouses..."
snow sql -f setup/01_create_warehouses.sql
if [ $? -eq 0 ]; then
  echo "✓ Warehouses created successfully"
else
  echo "✗ Failed to create warehouses"
  exit 1
fi

echo ""

# Step 3: Create databases
echo "Step 3: Creating databases..."
snow sql -f setup/02_create_databases.sql
if [ $? -eq 0 ]; then
  echo "✓ Databases created successfully"
else
  echo "✗ Failed to create databases"
  exit 1
fi

echo ""

# Step 4: Grant permissions
echo "Step 4: Granting permissions..."
snow sql -f setup/03_grant_permissions.sql
if [ $? -eq 0 ]; then
  echo "✓ Permissions granted successfully"
else
  echo "✗ Failed to grant permissions"
  exit 1
fi

echo ""
echo "===== ✓ ALL SETUP COMPLETE ====="
