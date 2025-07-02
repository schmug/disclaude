# Claude-Discord Integration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blue)](https://claude.ai/code)

A secure integration that enables Claude Code to send notifications to Discord channels via webhooks.

## 🚀 Features

- **One-way Notifications** - Simple webhook-based messages from Claude to Discord
- **Secure Implementation** - Protection against injection attacks and proper input validation
- **Visual Formatting** - Color-coded Discord embeds based on notification type
- **Environment Configuration** - Secure credential management via environment variables
- **Error Handling** - Automatic retries and rate limit management

## 📋 Prerequisites

- [Claude Code](https://claude.ai/code) installed and configured
- Discord webhook URL ([How to create one](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks))
- `jq` and `curl` installed on your system

## ⚡ Quick Start

### 1. Install Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install jq curl

# macOS
brew install jq curl
```

### 2. Clone and Setup

```bash
git clone https://github.com/schmug/disclaude.git
cd disclaude

# Copy environment template
cp examples/.env.example .env

# Edit .env with your Discord webhook URL
nano .env
```

### 3. Configure Claude Code

Add to your Claude settings (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": ".*",
        "hooks": [{
          "type": "command",
          "command": "cd /path/to/disclaude && ./src/discord-notifier.sh"
        }]
      }
    ]
  }
}
```

### 4. Test the Integration

```bash
# Test directly
export DISCORD_WEBHOOK_URL="your-webhook-url"
echo '{"session_id": "test", "notification": {"type": "info", "message": "Hello Discord!"}}' | ./src/discord-notifier.sh
```

## 📚 Documentation

- [Security Guidelines](./SECURITY.md) - Important security information
- [Claude Integration Guide](./CLAUDE.md) - Claude-specific setup details  
- [Product Requirements](./docs/PRD.md) - Detailed system design

## 🎨 Notification Types

| Type | Color | Emoji | Use Case |
|------|-------|-------|----------|
| `info` | Blue | ℹ️ | General information |
| `success` | Green | ✅ | Successful operations |
| `warning` | Orange | ⚡ | Warnings and cautions |
| `error` | Red | ⚠️ | Errors and failures |

## 🔒 Security

This integration implements several security measures:

- Input validation and sanitization
- Protection against command injection
- Proper JSON escaping
- Environment variable security
- Webhook URL validation

See [SECURITY.md](./SECURITY.md) for details.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](./CONTRIBUTING.md) first.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## 🙏 Acknowledgments

- Built for use with [Claude Code](https://claude.ai/code)
- Discord webhook documentation and API
- The open source community

## 📞 Support

- 📖 [Documentation](./docs/)
- 🐛 [Issue Tracker](https://github.com/schmug/disclaude/issues)
- 💬 [Discussions](https://github.com/schmug/disclaude/discussions)

---

Made with ❤️ for the Claude Code community