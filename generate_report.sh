#!/bin/bash

# Output file name
output_file="complete_project_report.txt"

# Config file name
config_file=".project_report_config"

# Script name (assuming this script is named generate_report.sh)
script_name=$(basename "$0")

# Function to check and install dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for tree command
    if ! command -v tree &> /dev/null; then
        missing_deps+=("tree")
    fi
    
    # Check for zip command
    if ! command -v zip &> /dev/null; then
        missing_deps+=("zip")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "The following dependencies are missing: ${missing_deps[*]}"
        read -p "Would you like to install them now? (Y/N): " install_choice
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            # Detect package manager and install
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y "${missing_deps[@]}"
            elif command -v yum &> /dev/null; then
                sudo yum install -y "${missing_deps[@]}"
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y "${missing_deps[@]}"
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm "${missing_deps[@]}"
            else
                echo "Unsupported package manager. Please install ${missing_deps[*]} manually."
                exit 1
            fi
        else
            echo "Required dependencies are missing. The script might not work as expected."
        fi
    fi
}

# Function to load config if exists, or create it
load_or_create_config() {
    if [ -f "$config_file" ]; then
        source "$config_file"
    else
        # Create default config file
        cat << EOF > "$config_file"
DEV_NAME="John Doe"
DEV_EMAIL="johndoe@example.com"
EXCLUDED_DIRS=""
EXCLUDED_FILES=""
ADDITIONAL_INFO=""
EOF
        source "$config_file"
    fi
}

# Function to save config
save_config() {
    cat << EOF > "$config_file"
DEV_NAME="$dev_name"
DEV_EMAIL="$dev_email"
EXCLUDED_DIRS="$excluded_dirs_input"
EXCLUDED_FILES="$excluded_files_input"
ADDITIONAL_INFO="$additional_info"
EOF
}

# Check dependencies at start
check_dependencies

# Load existing config or create new
load_or_create_config

# Prompt for developer information with config defaults
read -p "Enter developer name (Enter for '$DEV_NAME'): " input_dev_name
read -p "Enter developer email (Enter for '$DEV_EMAIL'): " input_dev_email

# Use config defaults if input is empty
dev_name=${input_dev_name:-"$DEV_NAME"}
dev_email=${input_dev_email:-"$DEV_EMAIL"}

# Write prompt at the beginning of the file
cat << EOF > "$output_file"
This file contains complete information about the project structure and content of files required for operation. 
Generation date: $(date '+%Y-%m-%d %H:%M:%S'). 
Excluded directories and files: see list below.
Developer: $dev_name <$dev_email>
EOF

# Prompt for additional information with config default
read -p "Enter additional information for inclusion in the report (Enter for '$ADDITIONAL_INFO'): " input_additional_info
if [ -n "$input_additional_info" ] && [ "$(echo "$input_additional_info" | sed 's/^[[:space:]]*$//')" ]; then
    additional_info="$input_additional_info"
else
    additional_info="$ADDITIONAL_INFO"
fi
if [ -n "$additional_info" ]; then
    echo -e "$additional_info\n---" >> "$output_file"
else
    echo -e "---" >> "$output_file"
fi

# Input for additional excluded directories with config default
read -p "Enter names of additional directories to exclude (comma-separated, Enter for '$EXCLUDED_DIRS'): " input_excluded_dirs
excluded_dirs_input=${input_excluded_dirs:-"$EXCLUDED_DIRS"}
excluded_dirs_input=$(echo "$excluded_dirs_input" | sed -e 's/ *, */,/g' -e 's/^ *//g' -e 's/ *$//g')

# Input for additional excluded files with config default
read -p "Enter full file names or masks to exclude (e.g., index.pug, *.pug, comma-separated, Enter for '$EXCLUDED_FILES'): " input_excluded_files
excluded_files_input=${input_excluded_files:-"$EXCLUDED_FILES"}
excluded_files_input=$(echo "$excluded_files_input" | sed -e 's/ *, */|/g' -e 's/^ *//g' -e 's/ *$//g')

# Save updated config
save_config

# Default excluded directories
default_excluded_dirs=(
    "node_modules" ".git" ".idea" ".vscode" ".gradle" ".svn" ".hg" "build" "dist" "out" 
    "vendor" ".next" "target" "bin" "obj" ".cache" ".nuxt" ".pytest_cache" "__pycache__"
    ".dart_tool" ".flutter-plugins" ".pub-cache" "coverage" "logs" ".sass-cache"
)

# Default excluded file types
default_excluded_file_types=(
    ".lock" ".tmp" ".log" ".debug" ".apk" ".exe" ".bin" ".iso" ".zip" ".tar" ".gz" ".rar" 
    ".bak" ".swp" ".DS_Store" ".jpg" ".jpeg" ".png" ".gif" ".svg" ".ico" ".mp3" ".wav" 
    ".mp4" ".mov" ".pdf" ".class" ".o" ".so" ".dll" ".pyc" ".pyo" ".pyd" ".db" ".sqlite"
    ".jar" ".war" ".ear" ".dex" ".aar"
)

# Convert user input into an array
IFS=',' read -r -a user_excluded_dirs <<< "$excluded_dirs_input"
IFS=',' read -r -a user_excluded_files <<< "$excluded_files_input"

# Combine default and user-defined exclusions
all_excluded_dirs=("${default_excluded_dirs[@]}" "${user_excluded_dirs[@]}")
all_excluded_files=("${default_excluded_file_types[@]}" "${user_excluded_files[@]}")

# Form exclusion patterns
exclude_dir_pattern=$(printf ".*/%s/.*|" "${all_excluded_dirs[@]}" | sed 's/|$//')
exclude_file_pattern=$(printf "%s|" "${all_excluded_files[@]}" | sed 's/|$//')
full_exclude_pattern="$exclude_dir_pattern|$exclude_file_pattern"

# Project structure
echo "Project structure (in tree format):" >> "$output_file"
if command -v tree &> /dev/null; then
    tree --dirsfirst -I "$(printf "%s|" "${all_excluded_dirs[@]}" | sed 's/|$//')" >> "$output_file"
else
    find . -type d | grep -v -E "$exclude_dir_pattern" >> "$output_file"
fi

# File contents section
echo -e "\n---\nFile details and their content:" >> "$output_file"

# Get all files, filter out exclusions, including script itself, config, and output
files=($(find . -type f | grep -v -E "$full_exclude_pattern" | grep -v -E "$output_file|$config_file|$script_name"))

total_files=0
text_files=()

# Check if the file is a text file
for file in "${files[@]}"; do
    if [ -z "$file" ]; then
        continue
    fi
    if file "$file" | grep -q "text"; then
        text_files+=("$file")
        total_files=$((total_files + 1))
    fi
done

if [ $total_files -eq 0 ]; then
    echo "No text files found for processing." > /dev/tty
    exit 1
fi

# Progress bar function
show_progress() {
    local progress=$((processed_files * 100 / total_files))
    local bar="["
    for ((i = 0; i < 50; i++)); do
        if ((i < progress / 2)); then
            bar+="="
        else
            bar+=" "
        fi
    done
    bar+="] $progress% ($processed_files/$total_files files, $(du -h "$output_file" | cut -f1))"
    echo -ne "\r$bar"
}

# Process text files
processed_files=0
for file in "${text_files[@]}"; do
    if [ -z "$file" ]; then
        continue
    fi
    
    file_name=$(basename "$file")
    relative_path="./$(realpath --relative-to=. "$file")"
    
    echo -e "\nFile name: $file_name" >> "$output_file"
    echo "Path: $relative_path" >> "$output_file"
    echo -e "File content:\n" >> "$output_file"
    cat "$file" >> "$output_file"
    echo -e "\n---\n" >> "$output_file"

    processed_files=$((processed_files + 1))
    show_progress
done

echo -e "\n\nDone! All information has been written to file $output_file" > /dev/tty

# Prompt to create ZIP archive
read -p "Would you like to create a ZIP archive of the report? (Y/N): " zip_choice
if [[ "$zip_choice" =~ ^[Yy]$ ]]; then
    zip_file="project_report_$(date '+%Y%m%d_%H%M%S').zip"
    zip "$zip_file" "$output_file"
    if [ $? -eq 0 ]; then
        echo "ZIP archive created successfully: $zip_file" > /dev/tty
    else
        echo "Failed to create ZIP archive" > /dev/tty
    fi
fi