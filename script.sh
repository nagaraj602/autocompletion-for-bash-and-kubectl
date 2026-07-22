#!/bin/bash


echo "Starting terminal UX bootstrapping..."

# 1. Install prerequisites based on the OS package manager
if command -v apt-get &> /dev/null; then
    sudo apt-get update -y > /dev/null 2>&1;
    sudo apt-get install -y bash-completion make gawk > /dev/null 2>&1;
elif command -v dnf &> /dev/null; then
    sudo dnf install -y bash-completion make gawk > /dev/null 2>&1;
elif command -v yum &> /dev/null; then
    sudo yum install -y bash-completion make gawk > /dev/null 2>&1;
else
    echo "Warning: Could not detect apt/dnf/yum. Ensure bash-completion, git, make, and gawk are installed manually."
fi

BASHRC_FILE="$HOME/.bashrc"

# 2. Configure kubectl alias and completion (Idempotent)
if ! grep -q "alias k=kubectl" "$BASHRC_FILE"; then
    echo "Configuring kubectl alias and completion..."
    cat << 'EOF' >> "$BASHRC_FILE"

# kubectl alias and tab completion
alias k=kubectl
# Only load completion if kubectl is actually installed on this server
if command -v kubectl &> /dev/null; then
    source <(kubectl completion bash)
    complete -o default -F __start_kubectl k
fi
EOF
else
    echo "kubectl alias already configured in $BASHRC_FILE. Skipping."
fi

# 3. Install ble.sh for "as you type" ghost text autosuggestions
BLESH_DIR="$HOME/.local/share/blesh"

if [ ! -d "$BLESH_DIR" ]; then
    # echo "Compiling and installing ble.sh (Bash Line Editor)..."
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh-src
    make -C /tmp/ble.sh-src install PREFIX="$HOME/.local"
    rm -rf /tmp/ble.sh-src
else
    echo "ble.sh already installed in $BLESH_DIR. Skipping compilation."
fi

# 4. Inject ble.sh into .bashrc (Idempotent)
if ! grep -q "ble.sh" "$BASHRC_FILE"; then
    echo "Enabling ble.sh in $BASHRC_FILE..."
    cat << 'EOF' >> "$BASHRC_FILE"

# ble.sh for modern bash autosuggestions and syntax highlighting
# This must be loaded in interactive sessions
[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh
EOF
else
    echo "ble.sh already enabled in $BASHRC_FILE. Skipping."
fi

echo ""
echo "======================================================"
echo "Setup complete!"
source ~/.bashrc
echo "======================================================"
