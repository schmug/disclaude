#!/bin/bash
# Installation script for Claude-Discord Integration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Installing Claude-Discord Integration..."

# Check dependencies
echo "📋 Checking dependencies..."
MISSING_DEPS=()

if ! command -v jq &> /dev/null; then
    MISSING_DEPS+=("jq")
fi

if ! command -v curl &> /dev/null; then
    MISSING_DEPS+=("curl")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "❌ Missing dependencies: ${MISSING_DEPS[*]}"
    echo "Please install them first:"
    echo "  Ubuntu/Debian: sudo apt-get install ${MISSING_DEPS[*]}"
    echo "  macOS: brew install ${MISSING_DEPS[*]}"
    exit 1
fi

echo "✅ All dependencies installed"

# Set up environment file
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo "📝 Creating .env file..."
    cp "$PROJECT_ROOT/examples/.env.example" "$PROJECT_ROOT/.env"
    echo "⚠️  Please edit .env and add your Discord webhook URL"
else
    echo "✅ .env file already exists"
fi

# Make scripts executable
echo "🔧 Setting permissions..."
chmod +x "$PROJECT_ROOT/src/discord-notifier.sh"
find "$PROJECT_ROOT/scripts" -name "*.sh" -type f -exec chmod +x {} \;

# Display Claude configuration
echo ""
echo "✅ Installation complete!"
echo ""
echo "📋 Next steps:"
echo "1. Edit .env and add your Discord webhook URL"
echo "2. Add this to your Claude settings (~/.claude/settings.json):"
echo ""
cat << EOF
{
  "hooks": {
    "Notification": [
      {
        "matcher": ".*",
        "hooks": [{
          "type": "command",
          "command": "cd $PROJECT_ROOT && ./src/discord-notifier.sh"
        }]
      }
    ]
  }
}
EOF
echo ""
echo "3. Test with: ./scripts/test-notification.sh"