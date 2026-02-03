import string
import argparse
import secrets
import math

def calculate_entropy(length, character_set_size):
    """Calculate the entropy of a password in bits."""
    return length * math.log2(character_set_size)

def generate_password(length, use_case_variance, use_numbers, use_special):
    # Enforce minimum length
    if length < 12:
        print("Error: Password length must be at least 12 characters.")
        return None

    # Define character sets
    characters = string.ascii_lowercase
    required_chars = [secrets.choice(string.ascii_lowercase)]  # At least one lowercase

    if use_case_variance:
        characters += string.ascii_uppercase
        required_chars.append(secrets.choice(string.ascii_uppercase))  # At least one uppercase
    if use_numbers:
        characters += string.digits
        required_chars.append(secrets.choice(string.digits))  # At least one number
    if use_special:
        characters += string.punctuation
        required_chars.append(secrets.choice(string.punctuation))  # At least one special

    # Check if at least one character set is selected
    if not characters:
        print("Error: At least one character set (case variance, numbers, special) must be selected.")
        return None

    # Check if length is sufficient for required characters
    remaining_length = length - len(required_chars)
    if remaining_length < 0:
        print("Error: Password length too short for required character types.")
        return None

    # Generate remaining characters
    password = required_chars + [secrets.choice(characters) for _ in range(remaining_length)]

    # Shuffle the password to randomize character positions
    secrets.SystemRandom().shuffle(password)

    # Calculate and display entropy
    entropy = calculate_entropy(length, len(characters))
    print(f"Password Entropy: {entropy:.2f} bits (Higher is stronger)")

    return ''.join(password)

def main():
    parser = argparse.ArgumentParser(description="Generate a cryptographically secure random password.")
    parser.add_argument("length", type=int, help="Length of the password (minimum 12)")
    parser.add_argument("-c", "--case-variance", action="store_true", help="Include both uppercase and lowercase letters")
    parser.add_argument("-n", "--numbers", action="store_true", help="Include numbers")
    parser.add_argument("-s", "--special", action="store_true", help="Include special characters")

    args = parser.parse_args()

    password = generate_password(args.length, args.case_variance, args.numbers, args.special)

    if password:
        print("Generated Password:", password)

if __name__ == "__main__":
    main()
