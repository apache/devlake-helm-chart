#!/usr/bin/env bash
# MySQL smoke test - verify basic MySQL connectivity and operations
set -euo pipefail

RELEASE_NAME="${RELEASE_NAME:-devlake-mysql}"
NAMESPACE="${NAMESPACE:-devlake-mysql}"
TIMEOUT="${TIMEOUT:-300}"

echo "=== MySQL Smoke Test ==="
echo "Release: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"
echo "Timeout: ${TIMEOUT}s"
echo ""

# Wait for MySQL pod to be ready
echo "⏳ Waiting for MySQL pod to be ready..."
kubectl wait --for=condition=ready pod \
  -l "app.kubernetes.io/instance=$RELEASE_NAME,devlakeComponent=mysql" \
  -n "$NAMESPACE" \
  --timeout="${TIMEOUT}s"

POD_NAME=$(kubectl get pod -l "app.kubernetes.io/instance=$RELEASE_NAME,devlakeComponent=mysql" \
  -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}')

echo "✅ Pod ready: $POD_NAME"
echo ""

# Get MySQL root password from secret
echo "🔐 Retrieving MySQL credentials..."
ROOT_PASSWORD=$(kubectl get secret "${RELEASE_NAME}-db-auth" \
  -n "$NAMESPACE" \
  -o jsonpath='{.data.MYSQL_ROOT_PASSWORD}' | base64 -d)

# Test 1: Basic connectivity
echo "📡 Test 1: Basic MySQL connectivity..."
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  mysqladmin ping -uroot -p"$ROOT_PASSWORD" 2>&1 | grep -q "mysqld is alive"
echo "✅ MySQL is alive"
echo ""

# Test 2: Query system info
echo "🔍 Test 2: Query MySQL version..."
VERSION=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  mysql -uroot -p"$ROOT_PASSWORD" -e "SELECT VERSION();" -sN)
echo "✅ MySQL version: $VERSION"
echo ""

# Test 3: Check character set
echo "🔤 Test 3: Verify character set configuration..."
CHARSET=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  mysql -uroot -p"$ROOT_PASSWORD" -e "SHOW VARIABLES LIKE 'character_set_server';" -sN | awk '{print $2}')
COLLATION=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  mysql -uroot -p"$ROOT_PASSWORD" -e "SHOW VARIABLES LIKE 'collation_server';" -sN | awk '{print $2}')

if [[ "$CHARSET" != "utf8mb4" ]]; then
  echo "❌ Character set is $CHARSET, expected utf8mb4"
  exit 1
fi

if [[ "$COLLATION" != "utf8mb4_bin" ]]; then
  echo "❌ Collation is $COLLATION, expected utf8mb4_bin"
  exit 1
fi

echo "✅ Character set: $CHARSET, Collation: $COLLATION"
echo ""

# Test 4: Create test database
echo "🗄️  Test 4: Create and drop test database..."
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  mysql -uroot -p"$ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS smoke_test;"

kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  mysql -uroot -p"$ROOT_PASSWORD" -e "SHOW DATABASES;" | grep -q "smoke_test"

kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  mysql -uroot -p"$ROOT_PASSWORD" -e "DROP DATABASE smoke_test;"

echo "✅ Database operations successful"
echo ""

# Test 5: Check devlake database exists
echo "🔍 Test 5: Check devlake database..."
DB_USER=$(kubectl get secret "${RELEASE_NAME}-db-auth" \
  -n "$NAMESPACE" \
  -o jsonpath='{.data.MYSQL_USER}' | base64 -d)

kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  mysql -uroot -p"$ROOT_PASSWORD" -e "SHOW DATABASES;" | grep -q "lake"

echo "✅ Devlake database 'lake' exists"
echo ""

# Test 6: Verify user can connect
echo "👤 Test 6: Verify devlake user connectivity..."
DB_PASSWORD=$(kubectl get secret "${RELEASE_NAME}-db-auth" \
  -n "$NAMESPACE" \
  -o jsonpath='{.data.MYSQL_PASSWORD}' | base64 -d)

kubectl exec -n "$NAMESPACE" "$POD_NAME" -- \
  mysql -u"$DB_USER" -p"$DB_PASSWORD" -D lake -e "SELECT 1;" -sN | grep -q "1"

echo "✅ User $DB_USER can connect to database"
echo ""

echo "🎉 All MySQL smoke tests passed!"
