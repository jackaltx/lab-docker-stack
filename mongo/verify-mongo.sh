#!/bin/bash
# MongoDB Connection Verification Script

set -e

# Load environment variables
source .env

echo "=== MongoDB Connection Verification ==="
echo ""

# Test 1: Check if container is running
echo "1. Checking if mongo container is running..."
if docker ps --format '{{.Names}}' | grep -q "^mongo$"; then
    echo "   ✓ Container 'mongo' is running"
else
    echo "   ✗ Container 'mongo' is NOT running"
    exit 1
fi

echo ""

# Test 2: Test MongoDB authentication
echo "2. Testing MongoDB authentication..."
docker exec mongo mongosh --quiet \
    --username "${MONGO_INITDB_ROOT_USERNAME}" \
    --password "${MONGO_INITDB_ROOT_PASSWORD}" \
    --authenticationDatabase admin \
    --eval "db.adminCommand('ping')" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "   ✓ Authentication successful"
else
    echo "   ✗ Authentication failed"
    exit 1
fi

echo ""

# Test 3: List databases
echo "3. Listing databases..."
docker exec mongo mongosh --quiet \
    --username "${MONGO_INITDB_ROOT_USERNAME}" \
    --password "${MONGO_INITDB_ROOT_PASSWORD}" \
    --authenticationDatabase admin \
    --eval "db.adminCommand('listDatabases').databases.forEach(db => print('   - ' + db.name))"

echo ""

# Test 4: Check if custom user exists
echo "4. Checking custom user '${MONGO_USER}'..."
USER_COUNT=$(docker exec mongo mongosh --quiet \
    --username "${MONGO_INITDB_ROOT_USERNAME}" \
    --password "${MONGO_INITDB_ROOT_PASSWORD}" \
    --authenticationDatabase admin \
    --eval "db.getUsers().users.filter(u => u.user === '${MONGO_USER}').length" \
    admin)

if [ "$USER_COUNT" -gt 0 ]; then
    echo "   ✓ User '${MONGO_USER}' exists"
else
    echo "   ⚠ User '${MONGO_USER}' not found (init script may not have run)"
fi

echo ""

# Test 5: Test mongo-express connectivity
echo "5. Checking mongo-express container..."
if docker ps --format '{{.Names}}' | grep -q "^mongo-express$"; then
    echo "   ✓ Container 'mongo-express' is running"
    echo "   → Access GUI: https://mongo-ui.a0a0.org"
    echo "   → Username: ${ME_CONFIG_BASICAUTH_USERNAME}"
else
    echo "   ✗ Container 'mongo-express' is NOT running"
fi

echo ""
echo "=== Verification Complete ==="
