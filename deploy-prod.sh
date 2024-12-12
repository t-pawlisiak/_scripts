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

# Define a whitelist of allowed root directory names
WHITELIST=("service-panel" "module-surveys-web" "module-surveys-respondent")

# Define a pipeline names
PIPELINE=("panel" "static" "respondent")

# Function to check if the current directory is a subdirectory of whitelisted directories and is a Git repository
check_directory_whitelist() {
    local current_path="$PWD"
    local is_whitelisted=false

    while [ "$current_path" != "/" ]; do
        dir_name=$(basename "$current_path")

        for i in "${!WHITELIST[@]}"; do
            if [ "$dir_name" == "${WHITELIST[$i]}" ]; then
                is_whitelisted=true
                pipeline_name="${PIPELINE[$i]}"
                break 2 # Exit both the loop over WHITELIST and the while-loop
            fi
        done

        # Move up one directory level
        current_path=$(dirname "$current_path")
    done

    if [ "$is_whitelisted" = false ]; then
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

# Function to select a Git branch using fzf
select_branch() {
    echo "Fetching remote branches..."
    git fetch --all
    branch=$(git branch -r | awk -F'/' '{print $NF}' | sort -u | \
        awk -v cb=development 'BEGIN {print cb} $0 != cb' | \
        fzf --height=20)
    echo "Selected Branch: $branch"

    if [ -z "$branch" ]; then
        echo "Error: Branch not selected."
        exit 1
    fi
}

# Main script execution
check_directory_whitelist
check_install_fzf
select_branch

# Checkout and update local branch
git fetch
git checkout $branch
git pull origin $branch

# Deploy
~/Workspace/env-development/tools/deploy production
