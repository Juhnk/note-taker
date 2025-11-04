#!/bin/bash

# Setup script for NoteTaker development environment
# This script:
# - Installs pre-commit hooks
# - Installs SwiftLint
# - Configures git settings
# - Verifies Xcode installation

set -e

echo "🚀 Setting up NoteTaker development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo -e "${BLUE}Project root: $PROJECT_ROOT${NC}"

# 1. Check Xcode installation
echo ""
echo "🔍 Checking Xcode installation..."
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -1)
    echo -e "${GREEN}✓ $XCODE_VERSION installed${NC}"

    # Check Xcode version is 15.0 or later
    VERSION_NUMBER=$(xcodebuild -version | head -1 | awk '{print $2}' | cut -d. -f1)
    if [ "$VERSION_NUMBER" -lt 15 ]; then
        echo -e "${YELLOW}⚠️  Warning: Xcode 15.0+ is recommended for this project${NC}"
    fi
else
    echo -e "${RED}✗ Xcode not found${NC}"
    echo "Please install Xcode 15.0+ from the Mac App Store"
    exit 1
fi

# 2. Check for Homebrew
echo ""
echo "🍺 Checking Homebrew installation..."
if command -v brew &> /dev/null; then
    echo -e "${GREEN}✓ Homebrew installed${NC}"
else
    echo -e "${YELLOW}⚠️  Homebrew not found${NC}"
    echo "Install Homebrew from https://brew.sh"
    echo "Then run this script again"
    exit 1
fi

# 3. Install SwiftLint
echo ""
echo "📝 Installing SwiftLint..."
if command -v swiftlint &> /dev/null; then
    SWIFTLINT_VERSION=$(swiftlint version)
    echo -e "${GREEN}✓ SwiftLint $SWIFTLINT_VERSION already installed${NC}"
else
    echo "Installing SwiftLint via Homebrew..."
    brew install swiftlint
    echo -e "${GREEN}✓ SwiftLint installed${NC}"
fi

# 4. Install pre-commit hook
echo ""
echo "🔗 Installing pre-commit hook..."

GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
PRE_COMMIT_HOOK="$GIT_HOOKS_DIR/pre-commit"
PRE_COMMIT_SCRIPT="$PROJECT_ROOT/scripts/pre-commit"

if [ ! -d "$GIT_HOOKS_DIR" ]; then
    echo -e "${RED}✗ Git hooks directory not found${NC}"
    echo "Make sure you're in a git repository"
    exit 1
fi

# Backup existing pre-commit hook if it exists
if [ -f "$PRE_COMMIT_HOOK" ]; then
    echo "Backing up existing pre-commit hook..."
    mv "$PRE_COMMIT_HOOK" "$PRE_COMMIT_HOOK.backup"
    echo -e "${YELLOW}⚠️  Existing hook backed up to pre-commit.backup${NC}"
fi

# Copy and make executable
cp "$PRE_COMMIT_SCRIPT" "$PRE_COMMIT_HOOK"
chmod +x "$PRE_COMMIT_HOOK"
echo -e "${GREEN}✓ Pre-commit hook installed${NC}"

# 5. Configure git settings (if needed)
echo ""
echo "⚙️  Configuring git settings..."

# Ensure git is configured
if ! git config user.name &> /dev/null; then
    echo -e "${YELLOW}⚠️  Git user.name not configured${NC}"
    echo "Please run: git config --global user.name \"Your Name\""
fi

if ! git config user.email &> /dev/null; then
    echo -e "${YELLOW}⚠️  Git user.email not configured${NC}"
    echo "Please run: git config --global user.email \"your.email@example.com\""
fi

echo -e "${GREEN}✓ Git configuration checked${NC}"

# 6. Create .swiftlint.yml if it doesn't exist
echo ""
echo "📋 Setting up SwiftLint configuration..."

SWIFTLINT_CONFIG="$PROJECT_ROOT/.swiftlint.yml"
if [ ! -f "$SWIFTLINT_CONFIG" ]; then
    echo "Creating .swiftlint.yml..."
    cat > "$SWIFTLINT_CONFIG" << 'EOF'
# SwiftLint Configuration for NoteTaker

disabled_rules:
  - trailing_whitespace

opt_in_rules:
  - empty_count
  - empty_string
  - explicit_init
  - force_unwrapping
  - redundant_optional_initialization
  - private_outlet
  - closure_spacing

excluded:
  - Pods
  - DerivedData
  - .build
  - NoteTaker.xcdatamodeld

line_length:
  warning: 120
  error: 150
  ignores_comments: true

function_body_length:
  warning: 60
  error: 100

type_body_length:
  warning: 300
  error: 500

file_length:
  warning: 500
  error: 1000

identifier_name:
  min_length:
    warning: 2
  max_length:
    warning: 50
  excluded:
    - id
    - i
    - j
    - k
    - x
    - y
    - z

force_cast: error
force_try: error
force_unwrapping: warning

reporter: "xcode"
EOF
    echo -e "${GREEN}✓ .swiftlint.yml created${NC}"
else
    echo -e "${GREEN}✓ .swiftlint.yml already exists${NC}"
fi

# 7. Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Development environment setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Create Xcode project (see PROGRESS.md - Sprint 0.1)"
echo "  2. Start development following docs/DEVELOPMENT_CYCLES.md"
echo "  3. All commits will now run automatic checks"
echo ""
echo "Pre-commit hook will:"
echo "  ✓ Run SwiftLint"
echo "  ✓ Build iOS and macOS targets"
echo "  ✓ Run all tests"
echo "  ✓ Check code coverage (minimum 70%)"
echo "  ✓ Block commits if any checks fail"
echo ""
echo "To skip pre-commit checks (not recommended):"
echo "  git commit --no-verify"
echo ""
echo "Documentation:"
echo "  • PROGRESS.md - Track development progress"
echo "  • docs/TESTING.md - Testing guidelines"
echo "  • docs/DEVELOPMENT_CYCLES.md - Cycle management"
echo "  • docs/GITHUB_WORKFLOW.md - Git workflow"
echo "  • .claude/.claude.md - Development workflow"
echo ""
echo -e "${BLUE}Happy coding! 🎉${NC}"
