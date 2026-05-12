#!/usr/bin/env bash
# PostgreSQL smoke test - verify basic PostgreSQL connectivity and operations
set -euo pipefail

RELEASE_NAME="${RELEASE_NAME:-devlake-postgresql}"
NAMESPACE="${NAMESPACE:-devlake-postgresql}"
TIMEOUT="${TIMEOUT:-300}"

echo "=== PostgreSQL Smoke Test ==="
echo "Release: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"
echo "Timeout: ${TIMEOUT}s"
echo ""

# Wait for PostgreSQL pod to be ready
echo "⏳ Waiting for PostgreSQL pod to be ready..."
kubectl wait --for=condition=ready pod \
  -l "app.kubernetes.io/instance=$RELEASE_NAME,devlakeComponent=postgresql" \
  -n "$NAMESPACE" \
  --timeout="${TIMEOUT}s"

POD_NAME=$(kubectl get pod -l "app.kubernetes.io/instance=$RELEASE_NAME,devlakeComponent=postgresql" \
  -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}')

echo "✅ Pod ready: $POD_NAME"
echo ""

# Get PostgreSQL password from secret
echo "🔐 Retrieving PostgreSQL credentials..."
DB_PASSWORD=$(kubectl get secret "${RELEASE_NAME}-db-auth" \
  -n "$NAMESPACE" \
  -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)

DB_USER=$(kubectl get secret "${RELEASE_NAME}-db-auth" \
  -n "$NAMESPACE" \
  -o jsonpath='{.data.POSTGRES_USER}' | base64 -d)

# Test 1: Basic connectivity
echo "📡 Test 1: Basic PostgreSQL connectivity..."
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  pg_isready -U "$DB_USER" 2>&1 | grep -q "accepting connections"
echo "✅ PostgreSQL is accepting connections"
echo ""

# Test 2: Query system info
echo "🔍 Test 2: Query PostgreSQL version..."
VERSION=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  psql -U "$DB_USER" -d lake -t -c "SELECT version();" | head -1 | xargs)
echo "✅ PostgreSQL version: ${VERSION:0:60}..."
echo ""

# Test 3: Check encoding
echo "🔤 Test 3: Verify database encoding..."
ENCODING=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  psql -U "$DB_USER" -d lake -t -c "SHOW server_encoding;" | xargs)

if [[ "$ENCODING" != "UTF8" ]]; then
  echo "❌ Encoding is $ENCODING, expected UTF8"
  exit 1
fi

echo "✅ Encoding: $ENCODING"
echo ""

# Test 4: Create test table and data
echo "🗄️  Test 4: Create and drop test table..."
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  psql -U "$DB_USER" -d lake -c "CREATE TABLE IF NOT EXISTS smoke_test (id SERIAL PRIMARY KEY, data TEXT);"

kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  psql -U "$DB_USER" -d lake -c "INSERT INTO smoke_test (data) VALUES ('test');"

COUNT=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  psql -U "$DB_USER" -d lake -t -c "SELECT COUNT(*) FROM smoke_test;" | xargs)

if [[ "$COUNT" != "1" ]]; then
  echo "❌ Expected 1 row, got $COUNT"
  exit 1
fi

kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  psql -U "$DB_USER" -d lake -c "DROP TABLE smoke_test;"

echo "✅ Table operations successful"
echo ""

# Test 5: Check devlake database exists
echo "🔍 Test 5: Check devlake database..."
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  psql -U "$DB_USER" -d postgres -t -c "\l lake" | grep -q "lake"

echo "✅ Devlake database 'lake' exists"
echo ""

# Test 6: Verify user permissions
echo "👤 Test 6: Verify user has necessary permissions..."
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  psql -U "$DB_USER" -d lake -t -c "SELECT 1;" | grep -q "1"

echo "✅ User $DB_USER has database access"
echo ""

# Test 7: Check connection limit
echo "🔌 Test 7: Check connection settings..."
MAX_CONN=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  psql -U "$DB_USER" -d lake -t -c "SHOW max_connections;" | xargs)

echo "✅ Max connections: $MAX_CONN"
echo ""

echo "🎉 All PostgreSQL smoke tests passed!"
