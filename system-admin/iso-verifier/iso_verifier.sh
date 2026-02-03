#!/usr/bin/bash

function check_file_exists() {
    if [ ! -f "$1" ]; then
        echo "File $1 does not exist."
        exit 1
    fi
}

function verify_sha256sum() {
    read -p "Enter the SHA-256 checksum file: " sha256_file
    check_file_exists "$sha256_file"
    sha256sum -c "$sha256_file" --ignore-missing
}

function verify_b2sum() {
    read -p "Enter the BLAKE2 checksum file: " b2sum_file
    check_file_exists "$b2sum_file"
    b2sum -c "$b2sum_file" --ignore-missing
}

function verify_signature() {
    read -p "Enter the signature file: " sig_file
    check_file_exists "$sig_file"

    # Extract the key ID from the signature file
    key_id=$(gpg --list-packets "$sig_file" | grep -oP 'keyid \K[0-9A-F]{16}')

    if gpg --list-keys "$key_id" &>/dev/null; then
        echo "Signing key $key_id is already imported."
    else
        echo "Signing key $key_id not found. Please provide the signing key file."
        read -p "Enter the signing key file: " key_file
        check_file_exists "$key_file"
        gpg --import "$key_file"
    fi

    gpg --verify "$sig_file" "$1"
}

function main() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <iso-file>"
        exit 1
    fi

    iso_file="$1"
    check_file_exists "$iso_file"

    echo "Select verification methods (e.g., 1 2 for SHA-256 and BLAKE2):"
    echo "1. SHA-256 Checksum"
    echo "2. BLAKE2 Checksum"
    echo "3. GPG Signature"
    echo "4. All of the above"
    read -p "Enter your choices (space-separated): " -a choices

    for choice in "${choices[@]}"; do
        case $choice in
            1)
                verify_sha256sum "$iso_file"
                ;;
            2)
                verify_b2sum "$iso_file"
                ;;
            3)
                verify_signature "$iso_file"
                ;;
            4)
                verify_sha256sum "$iso_file"
                verify_b2sum "$iso_file"
                verify_signature "$iso_file"
                break
                ;;
            *)
                echo "Invalid choice: $choice"
                ;;
        esac
    done

    echo "Verification completed!"
}

main "$@"
