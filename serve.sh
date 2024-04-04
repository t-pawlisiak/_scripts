#!/bin/bash

export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
    --color=fg:-1,fg+:#e0e0e0,bg:-1,bg+:#383838
    --color=hl:#5f87af,hl+:#5fd7ff,info:#aeaeae,marker:#87ff00
    --color=prompt:#d7005f,spinner:#af5fff,pointer:#af5fff,header:#87afaf
    --color=gutter:-1,border:#383838,separator:#383838,label:#aeaeae
    --color=query:#d9d9d9
    --border="rounded" --border-label=" Testing environment... " --border-label-pos="2" --preview-window="border-rounded"
    --padding="1" --margin="1" --prompt="↓ " --marker=" "
    --pointer="‣" --separator="—" --scrollbar="│" --layout="reverse"
    --info="right"'

# Define a list of supported environments
ENVIRONMENTS=("harry" "john" "jupiter" "mars" "mercury" "neptune" "pluto" "saturn" "venus")

# Define a whitelist of allowed root directory names
WHITELIST=("service-panel")

# Function to check if the current directory is a subdirectory of whitelisted directories and is a Git repository
check_directory_whitelist() {
    local current_path="$PWD"
    local is_whitelisted=false
    local target_path=""

    while [ "$current_path" != "/" ]; do
        dir_name=$(basename "$current_path")

        for whitelist_name in "${WHITELIST[@]}"; do
            if [ "$dir_name" == "$whitelist_name" ]; then
                is_whitelisted=true
                target_path="$current_path"
                break 2 # Exit both the loop over WHITELIST and the while-loop
            fi
        done

        # Move up one directory level
        current_path=$(dirname "$current_path")
    done

    if [ "$is_whitelisted" = true ]; then
        # Print the command to change to the whitelisted directory
        echo "cd '$target_path'"
    else
        echo "Error: You're not in a supported project."
        exit 1
    fi

    # Check if current directory is a Git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: Current directory is not a Git repository."
        exit 1
    fi
}

# Function to check and install fzf
check_install_fzf() {
    if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf is not installed. Attempting to install it..."
        
        # Detect OS
        case "$(uname -s)" in
            Darwin)
                # Install fzf on macOS
                if command -v brew >/dev/null 2>&1; then
                    brew install fzf
                else
                    echo "Homebrew is not installed. Please install Homebrew and try again."
                    exit 1
                fi
                ;;
            Linux)
                # Install fzf on Debian/Ubuntu
                sudo apt-get update
                sudo apt-get install -y fzf
                ;;
            *)
                echo "Unsupported OS. Please install fzf manually."
                exit 1
                ;;
        esac
    fi
}

# Function to select environment using fzf
select_environment() {
    env=$(printf '%s\n' "${ENVIRONMENTS[@]}" | fzf --height ~20)
    echo "Selected Environment: $env"
}

# Main script execution
check_directory_whitelist
check_install_fzf
select_environment

# Kill process on port 9000
lsof -i :9000 | awk '{print $2}' | tail -n +2 | xargs kill -9

# Open browser
open http://localhost:9000/

# Serve
WEBPACK_MODE=development SURVICATE_ENV=$env npm start