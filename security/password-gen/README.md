# Password Generator

A simple command-line tool to generate random passwords with customizable options such as length, case variance, numbers, and special characters.

## Features

- Generate passwords of any length.
- Option to include both uppercase and lowercase letters.
- Option to include numbers.
- Option to include special characters.

## Installation

To install the password generator script, first clone the repository and run the following command in the root directory:

```bash
pip install .
```

This will install the package and make the `passwd-gen` command available globally.

## Usage
To generate a password, use the `passwd-gen` command followed by the desired password length. You can also specify additional options for case variance, numbers, and special characters.

### Example Commands:

#### Generate a 12-character password with lowercase letters
```sh
passwd-gen 12
```

#### Generate a 16-character password with uppercase, lowercase letters, and numbers
```sh
passwd-gen 16 --case-variance --numbers
```

#### Generate a 20-character password with uppercase, lowercase letters, numbers, and special characters
```sh
passwd-gen 20 --case-variance --numbers --special
```

### Options:
- `-c`, `--case-variance`: Include both uppercase and lowercase letters.
- `-n`, `--numbers`: Include numbers.
- `-s`, `--special`: Include special characters.

### Example Output

```sh
Generated Password: 8sDk!z0Yq*1u
```

## License

This project is licensed under the [License](../LICENSE).
