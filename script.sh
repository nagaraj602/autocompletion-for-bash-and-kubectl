#!/bin/bash

echo "Starting terminal UX bootstrapping..."

BASHRC_FILE="$HOME/.bashrc"
BLESH_DIR="$HOME/.local/share/blesh"

# 1. Install prerequisites based on the OS package manager
echo "Checking prerequisites..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update -y > /dev/null 2>&1
    sudo apt-get install -y bash-completion make gawk git > /dev/null 2>&1
elif command -v dnf &> /dev/null; then
    sudo dnf install -y bash-completion make gawk git > /dev/null 2>&1
elif command -v yum &> /dev/null; then
    sudo yum install -y bash-completion make gawk git > /dev/null 2>&1
else
    echo "Warning: Could not detect apt/dnf/yum. Ensure bash-completion, git, make, and gawk are installed manually."
fi

# 2. Configure kubectl alias and completion (Idempotent)
if ! grep -q "alias k=kubectl" "$BASHRC_FILE"; then
    echo "Configuring kubectl alias and auto-completion..."
    cat << 'EOF' >> "$BASHRC_FILE"

# kubectl alias and tab completion
alias k=kubectl
# Only load completion if kubectl is actually installed on this server
if command -v kubectl &> /dev/null; then
    source <(kubectl completion bash) 
    complete -o default -F __start_kubectl k > /dev/null 2>&1
fi
EOF
else
    echo "kubectl alias and completion already configured. Skipping."
fi

# Helper function to completely remove ble.sh
remove_blesh() {
    echo "Uninstalling ble.sh..."
    rm -rf "$BLESH_DIR"
    
    # Remove the new marker-based block
    sed -i '/# --- BEGIN BLE.SH ---/,/# --- END BLE.SH ---/d' "$BASHRC_FILE"
    
    # Fallback to remove legacy lines if they exist from a previous run
    sed -i '/# ble.sh for modern bash autosuggestions/d' "$BASHRC_FILE"
    sed -i '/source ~\/.local\/share\/blesh\/ble.sh/d' "$BASHRC_FILE"
    
    echo "ble.sh has been removed."
}

# Helper function to install ble.sh
install_blesh() {
    echo "Compiling and installing ble.sh (this may take a moment)..."
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh-src > /dev/null 2>&1
    make -C /tmp/ble.sh-src install PREFIX="$HOME/.local" > /dev/null 2>&1
    rm -rf /tmp/ble.sh-src

    # Inject with markers for easy removal later
    if ! grep -q "BEGIN BLE.SH" "$BASHRC_FILE"; then
        echo "Enabling ble.sh in $BASHRC_FILE..."
        cat << 'EOF' >> "$BASHRC_FILE"

# --- BEGIN BLE.SH ---
# ble.sh for modern bash autosuggestions and syntax highlighting
# This must be loaded in interactive sessions
[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh
# --- END BLE.SH ---
EOF
    fi
    echo "ble.sh installed successfully."
}

# 3 & 4. Interactive ble.sh management
echo ""
if [ -d "$BLESH_DIR" ]; then
    read -p "ble.sh (auto-suggestions) is already installed. Choose action - [u]ninstall, [f]ix/reinstall, [s]kip (default): " action
    case "$action" in
        [uU])
            remove_blesh
            ;;
        [fF])
            remove_blesh
            install_blesh
            ;;
        *)
            echo "Skipping ble.sh setup."
            ;;
    esac
else
    read -p "Do you want to install ble.sh for auto-suggestions? [y/N]: " action
    case "$action" in
        [yY])
            install_blesh
            ;;
        *)
            echo "Skipping ble.sh installation."
            ;;
    esac
fi

echo ""
echo "======================================================"
echo "Setup complete! If it doesn't work, Run below command or restart your terminal"
echo "source ~/.bashrc"

