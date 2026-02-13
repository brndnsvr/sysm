#!/bin/bash
set -euo pipefail

echo "Installing git hooks..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Install pre-commit hook
if [ -f ".git-hooks/pre-commit" ]; then
    chmod +x .git-hooks/pre-commit
    ln -sf "../../.git-hooks/pre-commit" ".git/hooks/pre-commit"
    echo "✓ Pre-commit hook installed"
else
    echo "Error: .git-hooks/pre-commit not found"
    exit 1
fi

echo ""
echo "Git hooks installed successfully!"
echo ""
echo "The pre-commit hook will:"
echo "  - Format staged Swift files with SwiftFormat"
echo "  - Run SwiftLint on staged files"
echo ""
echo "To skip hooks temporarily, use: git commit --no-verify"
echo ""
echo "To uninstall hooks, run: rm .git/hooks/pre-commit"
