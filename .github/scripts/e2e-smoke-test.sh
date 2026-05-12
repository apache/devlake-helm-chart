#!/usr/bin/env bash
# E2E smoke test - verify DevLake API and UI endpoints are accessible
set -euo pipefail

NAMESPACE="${NAMESPACE:-default}"
SERVICE_PORT="${SERVICE_PORT:-30000}"
TIMEOUT="${TIMEOUT:-300}"
MAX_RETRIES="${MAX_RETRIES:-10}"
RETRY_INTERVAL="${RETRY_INTERVAL:-3}"

echo "=== DevLake E2E Smoke Test ==="
echo "Namespace: $NAMESPACE"
echo "Service Port: $SERVICE_PORT"
echo "Timeout: ${TIMEOUT}s"
echo "Max Retries: $MAX_RETRIES"
echo ""

# Get node IP
echo "🔍 Getting node IP address..."
NODE_IP=$(kubectl get nodes --namespace "$NAMESPACE" -o jsonpath="{.items[0].status.addresses[0].address}")
echo "✅ Node IP: $NODE_IP"
echo ""

BASE_URL="http://${NODE_IP}:${SERVICE_PORT}"

# Test function with retry logic
test_endpoint() {
  local name="$1"
  local url="$2"
  local check_pattern="${3:-}"

  echo "📡 Testing: $name"
  echo "   URL: $url"

  for attempt in $(seq 1 "$MAX_RETRIES"); do
    if [[ $attempt -gt 1 ]]; then
      echo "   Retry $((attempt-1))/$((MAX_RETRIES-1)) after ${RETRY_INTERVAL}s..."
      sleep "$RETRY_INTERVAL"
    fi

    if response=$(curl --silent --show-error --fail --max-time 10 "$url" 2>&1); then
      # If check_pattern provided, verify response contains it
      if [[ -n "$check_pattern" ]]; then
        if echo "$response" | grep -q "$check_pattern"; then
          echo "✅ $name: OK (pattern matched)"
          return 0
        else
          echo "   ⚠️  Response received but pattern not found"
          continue
        fi
      else
        echo "✅ $name: OK"
        return 0
      fi
    else
      echo "   ⚠️  Attempt $attempt failed"
    fi
  done

  echo "❌ $name: FAILED after $MAX_RETRIES attempts"
  return 1
}

# Test 1: Home page
echo "Test 1: DevLake Home Page"
test_endpoint "Home Page" "$BASE_URL"
echo ""

# Test 2: DevLake API health
echo "Test 2: DevLake API - Blueprints Endpoint"
test_endpoint "Blueprints API" "$BASE_URL/api/blueprints"
echo ""

# Test 3: Grafana API health
echo "Test 3: Grafana API Health"
test_endpoint "Grafana Health" "$BASE_URL/grafana/api/health" "database"
echo ""

# Test 4: Additional DevLake API endpoints
echo "Test 4: DevLake Version Info"
test_endpoint "Version Info" "$BASE_URL/api/version"
echo ""

echo "Test 5: DevLake Plugins Endpoint"
test_endpoint "Plugins API" "$BASE_URL/api/plugins"
echo ""

echo "🎉 All E2E smoke tests passed!"
