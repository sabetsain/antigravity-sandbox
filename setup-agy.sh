#!/usr/bin/env bash
set -euo pipefail

# Try official installer
if curl -fsSL https://antigravity.google/cli/install.sh 2>/dev/null | bash -s -- --dir /usr/local/bin 2>/dev/null; then
    echo "Antigravity CLI installed successfully via official installer."
    chmod +x /usr/local/bin/agy 2>/dev/null || true
    exit 0
fi

echo "Official installer unavailable during build; installing fail-fast wrapper script..."
cat << 'EOF' > /usr/local/bin/agy
#!/usr/bin/env bash
set -euo pipefail

# 1. Check if official binary exists alongside
if [ -x "/usr/local/bin/agy.real" ]; then
    exec /usr/local/bin/agy.real "$@"
elif [ -x "/usr/local/bin/agy.bin" ]; then
    exec /usr/local/bin/agy.bin "$@"
fi

# 2. Handler for CLI inspection flags
case "${1:-}" in
    --version|-v)
        echo "agy version 1.0.0 (containerized-agent-sandbox)"
        exit 0
        ;;
    --help|-h)
        echo "Google Antigravity CLI (agy) - Containerized Agent Sandbox"
        echo "Usage: agy [options] [command]"
        echo ""
        echo "Options:"
        echo "  --dangerously-skip-permissions  Execute operations without confirmation prompts"
        echo "  --auto-approve                  Execute operations without confirmation prompts"
        echo "  -v, --version                   Display version information"
        echo "  -h, --help                      Display this help menu"
        exit 0
        ;;
    *)
        # 3. Fail fast with an explicit error when agy binary is missing
        printf "\033[0;31m[ERROR]\033[0m Antigravity CLI binary 'agy' is not installed in this container image.\n" >&2
        printf "The official installer was unreachable during image build.\n" >&2
        printf "To test commands or configure the container environment manually, run:\n" >&2
        printf "    agy-sbx shell [task-name]\n\n" >&2
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/agy
echo "Fail-fast wrapper installed at /usr/local/bin/agy"
