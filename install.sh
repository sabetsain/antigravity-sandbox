#!/usr/bin/env bash
# ==============================================================================
# agy-sandbox Installer
# ==============================================================================
# 1. Builds the universal agy-sandbox:latest container image using Podman/Docker.
# 2. Symlinks bin/agy-sbx into ~/.local/bin/agy-sbx.
# 3. Verifies system PATH configuration and Podman VM state.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$SCRIPT_DIR/bin/agy-sbx"
TARGET_DIR="$HOME/.local/bin"
TARGET_SYMLINK="$TARGET_DIR/agy-sbx"

# Formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}Installing Containerized Agent Sandbox (agy-sbx)...${NC}"
echo "================================================================================"

# 1. Detect Container Runtime & Verify VM State
RUNTIME=""
if command -v podman >/dev/null 2>&1; then
    RUNTIME="podman"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Check if Podman machine is running on macOS
        if ! podman machine list --format "{{.Running}}" 2>/dev/null | grep -qi "true"; then
            echo -e "${YELLOW}[WARN]${NC} Podman machine is not currently running."
            echo "To start your Podman VM, run:"
            echo "    podman machine start"
            echo ""
        fi
    fi
elif command -v docker >/dev/null 2>&1; then
    RUNTIME="docker"
else
    echo -e "${YELLOW}[WARN]${NC} Neither 'podman' nor 'docker' detected in PATH."
    echo "Please ensure Podman Desktop is installed and started on macOS."
fi

# 2. Build Universal Container Image if runtime is available
if [ -n "$RUNTIME" ]; then
    echo -e "${BLUE}[STEP 1/3]${NC} Building universal container image 'agy-sandbox:latest' via $RUNTIME..."
    if "$RUNTIME" build -t agy-sandbox:latest "$SCRIPT_DIR"; then
        echo -e "${GREEN}[SUCCESS]${NC} Image 'agy-sandbox:latest' built successfully."
    else
        echo -e "${YELLOW}[WARN]${NC} Image build did not complete. You can rebuild later using:"
        echo "    $RUNTIME build -t agy-sandbox:latest \"$SCRIPT_DIR\""
    fi
else
    echo -e "${YELLOW}[SKIP]${NC} Skipping image build step because no container runtime was found."
fi

# 3. Ensure executable permissions on bin/agy-sbx
echo -e "${BLUE}[STEP 2/3]${NC} Setting executable permissions on $BIN_SRC..."
chmod +x "$BIN_SRC"

# 4. Create ~/.local/bin and install symlink
echo -e "${BLUE}[STEP 3/3]${NC} Installing orchestrator CLI symlink to $TARGET_SYMLINK..."
mkdir -p "$TARGET_DIR"
ln -sf "$BIN_SRC" "$TARGET_SYMLINK"
echo -e "${GREEN}[SUCCESS]${NC} Symlinked $TARGET_SYMLINK -> $BIN_SRC"

# 5. Check PATH
echo "================================================================================"
if [[ ":$PATH:" == *":$TARGET_DIR:"* ]]; then
    echo -e "${GREEN}✓ Everything is ready!${NC}"
    echo "You can now run 'agy-sbx --help' from anywhere in your terminal."
else
    echo -e "${YELLOW}! Note:${NC} '$TARGET_DIR' is not currently in your system PATH."
    echo "To access 'agy-sbx' globally, add the following line to your ~/.zshrc or ~/.bashrc:"
    echo ""
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "Then reload your shell: source ~/.zshrc"
fi
