#!/usr/bin/env bash
# ================================================================
#  setup-and-test.sh
#  Run this script to install Foundry, build, and test SavingsBank
# ================================================================
set -e

echo "================================================"
echo "  SavingsBank — Foundry Setup & Test Runner"
echo "================================================"

# 1. Install Foundry if not present
if ! command -v forge &> /dev/null; then
    echo "📦 Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    # shellcheck disable=SC1090
    source "$HOME/.bashrc" 2>/dev/null || source "$HOME/.zshrc" 2>/dev/null || true
    foundryup
else
    echo "✅ Foundry already installed: $(forge --version)"
fi

# 2. Navigate to project root (same dir as this script)
cd "$(dirname "$0")"

# 3. Install forge-std dependency
echo ""
echo "📥 Installing forge-std..."
forge install foundry-rs/forge-std --no-commit 2>/dev/null || true

# 4. Build
echo ""
echo "🔨 Building contracts..."
forge build

# 5. Run tests
echo ""
echo "🧪 Running test suite..."
forge test -v --gas-report

# 6. Optional: run with coverage
echo ""
echo "📊 Running coverage report..."
forge coverage 2>/dev/null || echo "Coverage requires lcov (optional)"

echo ""
echo "================================================"
echo "  ✅ All done!"
echo "================================================"
echo ""
echo "To deploy locally:"
echo "  1. In a separate terminal: anvil"
echo "  2. forge script script/DeploySavingsBank.s.sol \"
echo "       --rpc-url http://127.0.0.1:8545 \"
echo "       --broadcast -vvvv"