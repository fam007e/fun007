#!/usr/bin/env zsh

# Prompt for email address
read -p "Enter your GitHub email address: " email

# Prompt for SSH key type
echo "Choose your SSH key type:"
echo "1. Ed25519 (recommended)"
echo "2. RSA (legacy)"
read -p "Enter your choice (1 or 2): " key_type

case $key_type in
    1)
        key_algo="ed25519"
        ;;
    2)
        key_algo="rsa"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Prompt for custom key name
read -p "Enter a custom SSH key name (leave blank for default): " key_name

# Generate SSH key with specified type and email
if [ -z "$key_name" ]; then
    ssh-keygen -t $key_algo -C "$email"
else
    ssh-keygen -t $key_algo -C "$email" -f "$HOME/.ssh/$key_name"
fi

# Check if passphrase should be used
read -p "Do you want to use a passphrase? (y/n): " use_passphrase

if [ "$use_passphrase" == "y" ]; then
    ssh-add -l &>/dev/null
    if [ $? -eq 2 ]; then
        eval "$(ssh-agent -s)"
    fi
    ssh-add ~/.ssh/${key_name:-id_$key_algo}
else
    echo "Skipping passphrase setup."
fi

echo "SSH key generation and setup completed."

