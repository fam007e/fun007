import string
import argparse
import random
import time

def generate_password(length, use_case_variance, use_numbers, use_special):
    characters = string.ascii_letters if use_case_variance else string.ascii_lowercase
    characters += string.digits if use_numbers else ''
    characters += string.punctuation if use_special else ''

    if not characters:
        print("Error: At least one character set (case variance, numbers, special) must be selected.")
        return None

    random.seed(int(time.time()))  # Seed based on current time
    password = ''.join(random.choice(characters) for _ in range(length))
    return password

def main():
    parser = argparse.ArgumentParser(description="Generate a random password.")

    parser.add_argument("length", type=int, help="Length of the password")

    parser.add_argument("-c", "--case-variance", action="store_true", help="Include both uppercase and lowercase letters")
    parser.add_argument("-n", "--numbers", action="store_true", help="Include numbers")
    parser.add_argument("-s", "--special", action="store_true", help="Include special characters")

    args = parser.parse_args()

    password = generate_password(args.length, args.case_variance, args.numbers, args.special)

    if password:
        print("Generated Password:", password)

if __name__ == "__main__":
    main()
