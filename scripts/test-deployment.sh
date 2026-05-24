#!/bin/bash

# Final deployment test script

set -e

echo "🧪 Testing Bishkek Courier Vision Deployment"
echo "============================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

fail() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Test 1: Docker Compose Configuration
echo ""
echo "1️⃣  Validating Docker Compose..."
if docker-compose config > /dev/null 2>&1; then
    pass "docker-compose.yml is valid"
else
    fail "docker-compose.yml has errors"
fi

# Test 2: Build All Services
echo ""
echo "2️⃣  Building all services..."
if docker-compose build --quiet 2>&1; then
    pass "All services built successfully"
else
    fail "Build failed"
fi

# Test 3: Start Services
echo ""
echo "3️⃣  Starting services..."
docker-compose up -d
sleep 30  # Wait for services to start

# Test 4: Check All Containers Are Running
echo ""
echo "4️⃣  Checking container status..."
CONTAINERS=("bcv_mysql" "bcv_backend" "bcv_ai" "bcv_nginx")
for container in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        pass "$container is running"
    else
        fail "$container is not running"
    fi
done

# Test 5: Health Checks
echo ""
echo "5️⃣  Testing health endpoints..."

# Backend
if curl -s -f http://localhost:8000/api/health > /dev/null; then
    pass "Backend health check passed"
else
    warn "Backend health check failed"
fi

# AI Service
if curl -s -f http://localhost:5000/ai/health > /dev/null; then
    pass "AI service health check passed"
else
    warn "AI service health check failed (Groq key might not be set)"
fi

# Nginx (if used)
if curl -s -f http://localhost/health > /dev/null; then
    pass "Nginx health check passed"
else
    warn "Nginx health check skipped"
fi

# Test 6: Database Connectivity
echo ""
echo "6️⃣  Testing database..."
if docker-compose exec -T mysql mysqladmin ping -h localhost -u root -prootpassword > /dev/null 2>&1; then
    pass "Database is accessible"
else
    fail "Database connection failed"
fi

# Test 7: API Endpoints
echo ""
echo "7️⃣  Testing API endpoints..."

# Get addresses
if curl -s http://localhost:8000/api/addresses | grep -q "success"; then
    pass "GET /api/addresses works"
else
    warn "GET /api/addresses failed"
fi

# Test login
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"courier_id":"4821","aggregator":"yandex_pro"}')

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
    pass "POST /api/auth/login works"
else
    warn "Login endpoint failed"
fi

# Test 8: Logs
echo ""
echo "8️⃣  Checking logs..."
if docker-compose logs backend 2>&1 | tail -20 | grep -q -i "error"; then
    warn "Errors found in backend logs"
else
    pass "No critical errors in backend logs"
fi

# Test 9: Performance
echo ""
echo "9️⃣  Performance test..."
START=$(date +%s%N)
curl -s http://localhost:8000/api/addresses > /dev/null
END=$(date +%s%N)
DURATION=$((($END - $START) / 1000000))

if [ $DURATION -lt 1000 ]; then
    pass "API response time: ${DURATION}ms"
else
    warn "API response slow: ${DURATION}ms"
fi

# Summary
echo ""
echo "============================================"
echo "🎉 Deployment Test Complete!"
echo ""
echo "Services running:"
docker-compose ps
echo ""
echo "Next steps:"
echo "1. Run mobile app: cd mobile && flutter run"
echo "2. View logs: docker-compose logs -f"
echo "3. Stop: docker-compose down"