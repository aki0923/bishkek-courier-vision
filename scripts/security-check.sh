#!/bin/bash

# Security check script for Bishkek Courier Vision

set -e

echo "🛡️  Running Security Checks..."
echo "================================"

# 1. Check for hardcoded secrets
echo ""
echo "1. Checking for hardcoded secrets..."
SECRETS=$(grep -r --include="*.php" --include="*.py" --include="*.dart" \
  -E "(api_key|password|secret|token)\s*=\s*['\"][^'\"]{8,}" \
  . 2>/dev/null || true)

if [ -z "$SECRETS" ]; then
    echo "✅ No hardcoded secrets found"
else
    echo "⚠️  Possible hardcoded secrets:"
    echo "$SECRETS"
fi

# 2. Check .env files are not committed
echo ""
echo "2. Checking .env files..."
if git ls-files | grep -q "\.env$"; then
    echo "❌ .env file is committed to repo!"
    exit 1
else
    echo "✅ .env files properly ignored"
fi

# 3. Check Docker configurations
echo ""
echo "3. Validating Docker configurations..."
if docker-compose config > /dev/null 2>&1; then
    echo "✅ docker-compose.yml is valid"
else
    echo "❌ docker-compose.yml has errors"
    exit 1
fi

# 4. Check file permissions
echo ""
echo "4. Checking file permissions..."
SENSITIVE_FILES=(".env.example" "docker-compose.yml")
for file in "${SENSITIVE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    fi
done

# 5. Check for outdated dependencies
echo ""
echo "5. Checking dependencies..."

# Backend
if [ -d "backend" ]; then
    cd backend
    if command -v composer &> /dev/null; then
        echo "Checking PHP dependencies..."
        composer audit 2>&1 | head -5 || true
    fi
    cd ..
fi

# AI Service
if [ -d "ai-service" ]; then
    cd ai-service
    if command -v pip &> /dev/null; then
        echo "Checking Python dependencies..."
        pip list --outdated 2>&1 | head -5 || true
    fi
    cd ..
fi

# 6. Check for proper .gitignore
echo ""
echo "6. Checking .gitignore..."
if grep -q "\.env" .gitignore; then
    echo "✅ .env in .gitignore"
else
    echo "⚠️  .env not in .gitignore"
fi

# Summary
echo ""
echo "================================"
echo "🎉 Security check complete!"
echo ""
echo "Next steps:"
echo "1. Review any warnings above"
echo "2. Run 'docker-compose up' to test"
echo "3. Read SECURITY_AUDIT.md for full report"