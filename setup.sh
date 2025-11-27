#!/bin/bash

# Ralph Project Setup Script
set -e

# Determine script location for finding templates
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running from installed location or repo
if [[ -d "$HOME/.ralph/templates" ]]; then
    TEMPLATE_DIR="$HOME/.ralph/templates"
elif [[ -d "$SCRIPT_DIR/templates" ]]; then
    TEMPLATE_DIR="$SCRIPT_DIR/templates"
else
    echo "Error: Cannot find Ralph templates directory"
    exit 1
fi

PROJECT_NAME=${1:-"my-project"}
SKIP_INTERACTIVE=${2:-""}

echo "🚀 Setting up Ralph project: $PROJECT_NAME"
echo ""

# Create project directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create structure
mkdir -p {specs/stdlib,src,examples,logs,docs/generated}

# Copy templates
cp "$TEMPLATE_DIR/PROMPT.md" .
cp "$TEMPLATE_DIR/fix_plan.md" @fix_plan.md
cp "$TEMPLATE_DIR/AGENT.md" @AGENT.md
cp -r "$TEMPLATE_DIR/specs/"* specs/ 2>/dev/null || true

# Copy setup prompt for interactive onboarding
cp "$TEMPLATE_DIR/SETUP_PROMPT.md" .setup_prompt.md

# Initialize git
git init -q
echo "# $PROJECT_NAME" > README.md
git add .
git commit -q -m "Initial Ralph project setup"

echo "✅ Project structure created!"
echo ""

# Print quick reference
cat << 'EOF'
==================================================
 📚 RALPH QUICK REFERENCE
==================================================

WHAT IS RALPH?
  An autonomous AI development loop that runs Claude Code
  repeatedly to build your project based on PROMPT.md and
  @fix_plan.md specifications.

KEY FILES:
  PROMPT.md      - Instructions Claude follows each loop
  @fix_plan.md   - Prioritized task list (Ralph's TODO)
  @AGENT.md      - Build/run commands for your project
  specs/         - Your project specifications

RUNNING RALPH:
  ralph --monitor            # Start with live dashboard
  ralph                      # Start without monitoring
  ralph --cmd glm --monitor  # Use GLM model instead

THE --cmd FLAG:
  By default, Ralph uses 'claude' command. Use --cmd to
  specify an alternate command (e.g., a wrapper for a
  different model like GLM):

  ralph --cmd glm            # Use 'glm' command
  ralph --cmd my-wrapper     # Use custom wrapper script

DOCUMENTATION:
  https://github.com/txtr99/ralph-claude-code#readme

==================================================
EOF

echo ""

# Check if Claude Code is available
if command -v claude &> /dev/null; then
    echo "🤖 Would you like Claude to help configure your project?"
    echo "   This will customize PROMPT.md and @fix_plan.md for your needs."
    echo ""
    read -p "   Launch interactive setup? [Y/n] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        echo "   Launching Claude Code for interactive setup..."
        echo "   (Describe your project when prompted)"
        echo ""

        # Launch Claude Code with the setup prompt
        claude "$(cat .setup_prompt.md)"

        # Cleanup setup prompt after use
        rm -f .setup_prompt.md

        echo ""
        echo "✅ Setup complete! Run 'ralph --monitor' to start."
    else
        echo ""
        echo "📝 Manual setup required:"
        echo "   1. Edit PROMPT.md - describe your project"
        echo "   2. Edit @fix_plan.md - define your tasks"
        echo "   3. Run: ralph --monitor"

        # Keep setup prompt for later use
        echo ""
        echo "   Tip: Run 'claude \"\$(cat .setup_prompt.md)\"' later for guided setup"
    fi
else
    echo "⚠️  Claude Code not found in PATH"
    echo ""
    echo "📝 Manual setup required:"
    echo "   1. Edit PROMPT.md - describe your project"
    echo "   2. Edit @fix_plan.md - define your tasks"
    echo "   3. Run: ralph --monitor"
    echo ""
    echo "   Install Claude Code: npm install -g @anthropic-ai/claude-code"
fi
