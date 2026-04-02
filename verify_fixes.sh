#!/bin/bash
# Quick verification script for real login fixes
# Run this to verify the fixes are in place

echo "🔍 Verifying Real Login Fixes..."
echo ""

ERRORS=0

# Check 1: AccountDashboard has authLoading
echo "✓ Checking AccountDashboard for authLoading..."
if grep -q "isLoading: authLoading" src/pages/AccountDashboard.tsx; then
    echo "  ✅ authLoading destructure found"
else
    echo "  ❌ authLoading NOT found - FIX INCOMPLETE"
    ERRORS=$((ERRORS + 1))
fi

# Check 2: AccountDashboard has loading spinner
if grep -q "animate-spin" src/pages/AccountDashboard.tsx; then
    echo "  ✅ Loading spinner found"
else
    echo "  ❌ Loading spinner NOT found"
    ERRORS=$((ERRORS + 1))
fi

# Check 3: RiderDashboard has early authLoading check
echo ""
echo "✓ Checking RiderDashboard for auth loading check..."
if grep -q "!isDemoMode && authLoading" src/pages/RiderDashboard.tsx; then
    echo "  ✅ Early auth loading check found"
else
    echo "  ❌ Early auth loading check NOT found"
    ERRORS=$((ERRORS + 1))
fi

# Check 4: Verification page uses user_id field
echo ""
echo "✓ Checking Verification page query fix..."
if grep -q ".eq('user_id', userData.user.id)" src/pages/Verification.tsx; then
    echo "  ✅ user_id field (correct) found"
else
    echo "  ❌ user_id field NOT found - might still have 'id' field"
    ERRORS=$((ERRORS + 1))
fi

# Check 5: Verification uses maybeSingle
if grep -q "maybeSingle()" src/pages/Verification.tsx; then
    echo "  ✅ maybeSingle() found"
else
    echo "  ❌ maybeSingle() NOT found"
    ERRORS=$((ERRORS + 1))
fi

# Summary
echo ""
echo "================================"
if [ $ERRORS -eq 0 ]; then
    echo "✅ ALL FIXES VERIFIED! Ready to test real login."
    echo ""
    echo "Next steps:"
    echo "1. npm run dev"
    echo "2. Open http://localhost:8081/auth"
    echo "3. Try demo mode (sanity check)"
    echo "4. Test real login with Supabase credentials"
    echo "5. Watch for loading spinner on pages"
    exit 0
else
    echo "❌ FOUND $ERRORS ISSUES - Some fixes may be missing"
    exit 1
fi
