# ISO Verifier

`iso_verifier.sh` is a Bash script designed to verify the integrity and authenticity of ISO files using multiple methods: SHA-256 checksum, BLAKE2 checksum, and GPG signature verification. This script can handle different combinations of verification methods based on user input.

## Features

- Verify ISO files using SHA-256 checksum.
- Verify ISO files using BLAKE2 checksum.
- Verify ISO files using GPG signature.
- Combine multiple verification methods.
- Automatically check for imported GPG keys and prompt for key files if necessary.

## Prerequisites

Make sure you have the following tools installed on your system:

- `sha256sum`
- `b2sum`
- `gpg`

These tools are typically available by default on most Linux distributions. If not, you can install them using your package manager. For example, on Debian-based systems:

```sh
sudo apt-get install coreutils gpg
```
## Usage

1. Make the script executable:

```sh
chmod +x iso_verifier.sh
```
2. Run the script with the ISO file you want to verify:

```sh
./iso_verifier.sh <iso-file>
```

Replace `<iso-file>` with the path to your ISO file.

3. Follow the prompts to select the verification methods and provide the necessary files.

```sh
❯ ./iso_verifier.sh archlinux-2024.05.01-x86_64.iso
Select verification methods (e.g., 1 2 for SHA-256 and BLAKE2):
1. SHA-256 Checksum
2. BLAKE2 Checksum
3. GPG Signature
4. All of the above
Enter your choices (space-separated): 1 3
Enter the SHA-256 checksum file: archlinux_sha256sums.txt
archlinux-2024.05.01-x86_64.iso: OK
Enter the signature file: archlinux-2024.05.01-x86_64.iso.sig
Signing key <key_id> is already imported.
gpg: Signature made <date>
gpg:                using RSA key <key_id>
gpg: Good signature from "<User> <email>"
```
## Script Details

`check_file_exists()`
This function checks if a specified file exists. If not, it prints an error message and exits the script.

`verify_sha256sum()`
This function prompts the user for the SHA-256 checksum file and verifies the ISO file against it using sha256sum.

`verify_b2sum()`
This function prompts the user for the BLAKE2 checksum file and verifies the ISO file against it using b2sum.

`verify_signature()`
This function prompts the user for the GPG signature file. It checks if the signing key is already imported. If not, it prompts the user for the signing key file and imports it. Finally, it verifies the ISO file's signature using gpg.

`main()`
The main function handles user input and calls the appropriate verification functions based on the user's choices.

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## Contributions

Contributions are welcome! Please feel free to submit a pull request or open an issue for any improvements or bug fixes.

## Acknowledgements

Thanks to the developers of the tools used in this script: `sha256sum`, `b2sum`, and `gpg`.

```css
This `README.md` file provides an overview of the script, its features, prerequisites, usage instructions, script details, license, and contribution guidelines. It should help users understand how to use the script and what to expect from it.
```
