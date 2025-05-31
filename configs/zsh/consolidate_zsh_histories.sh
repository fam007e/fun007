#!/usr/bin/zsh

# Backup existing .zsh_history
cp ~/.zsh_history ~/.zsh_history.bak

# Create a temporary file to store the combined history
combined_history=$(mktemp)

# Add the contents of all .zsh_history* files to the temporary file
for history_file in ~/.zsh_history*; do
    cat "$history_file" >> "$combined_history"
done

# Remove duplicate entries and save to a new .zsh_history
awk '!seen[$0]++' "$combined_history" > ~/.zsh_history

# Clean up
rm "$combined_history"

echo "Histories have been consolidated into ~/.zsh_history with duplicates removed."

