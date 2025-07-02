# Contributing to Claude-Discord Integration

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## 🤝 Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Accept feedback gracefully

## 🚀 Getting Started

1. **Fork the Repository**
   ```bash
   # Via GitHub UI or CLI
   gh repo fork schmug/disclaude
   ```

2. **Clone Your Fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/disclaude.git
   cd disclaude
   ```

3. **Set Up Development Environment**
   ```bash
   # Install dependencies
   sudo apt-get install jq curl shellcheck
   
   # Set up pre-commit hooks (optional)
   ./scripts/setup-hooks.sh
   ```

## 🌟 How to Contribute

### Reporting Issues

Before creating an issue:
- Check existing issues to avoid duplicates
- Use issue templates when available
- Include relevant details:
  - Claude Code version
  - Operating system
  - Error messages
  - Steps to reproduce

### Suggesting Features

- Open a discussion first for major features
- Explain the use case and benefits
- Consider implementation complexity
- Be open to alternatives

### Submitting Code

1. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

2. **Follow Coding Standards**
   - Use shellcheck for bash scripts
   - Follow existing code style
   - Add comments for complex logic
   - Keep functions small and focused

3. **Write Tests**
   - Add tests for new features
   - Ensure existing tests pass
   - Test edge cases and error conditions

4. **Commit Guidelines**
   
   Follow [Conventional Commits](https://www.conventionalcommits.org/):
   ```
   feat: Add new notification type
   fix: Handle special characters in messages
   docs: Update installation instructions
   test: Add security test cases
   chore: Update dependencies
   ```

5. **Submit Pull Request**
   - Fill out the PR template completely
   - Link related issues
   - Ensure CI checks pass
   - Respond to review feedback

## 🧪 Testing

Run tests before submitting:

```bash
# Run security tests
./tests/security-test.sh

# Run all tests
./scripts/run-tests.sh

# Check shell scripts
shellcheck src/*.sh
```

## 📋 Pull Request Checklist

- [ ] Code follows project style guidelines
- [ ] Tests added/updated and passing
- [ ] Documentation updated if needed
- [ ] Security implications considered
- [ ] Commit messages follow conventions
- [ ] PR description is complete

## 🔒 Security

- Never commit credentials or tokens
- Validate all user input
- Use proper escaping for shell commands
- Test for injection vulnerabilities
- Report security issues privately

## 📚 Documentation

When adding features:
- Update README if needed
- Add examples to `examples/`
- Document configuration options
- Include error messages and solutions

## 🎯 Development Tips

### Local Testing

```bash
# Test with mock webhook
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/test/test"
echo '{"notification": {"message": "Test"}}' | ./src/discord-notifier.sh
```

### Debugging

```bash
# Enable debug output
export DEBUG=1
./src/discord-notifier.sh
```

### Code Quality

```bash
# Format code
shfmt -i 2 -ci src/*.sh

# Lint scripts
shellcheck -x src/*.sh
```

## 🌍 Community

- Ask questions in [Discussions](https://github.com/schmug/disclaude/discussions)
- Join our community chat (if available)
- Help others with their issues
- Share your use cases

## 📝 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Claude-Discord Integration! 🎉