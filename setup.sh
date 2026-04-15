#!/usr/bin/env bash
set -euo pipefail

echo "=== IMC Prosperity VPS Setup ==="

# Install uv if not present
if ! command -v uv &> /dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Install Claude Code if not present
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
fi

# Create venv and install dependencies
echo "Setting up Python environment..."
uv sync

# Verify backtester works
echo "Verifying backtester installation..."
uv run prosperity4btest --help > /dev/null 2>&1 && echo "prosperity4btest: OK" || echo "prosperity4btest: FAILED"

# Check for API key
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo ""
    echo "WARNING: ANTHROPIC_API_KEY not set."
    echo "  export ANTHROPIC_API_KEY=sk-ant-..."
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "To run autoresearch:"
echo "  cd $(pwd)"
echo "  claude"
echo "  # Then tell Claude to read program.md and begin"
