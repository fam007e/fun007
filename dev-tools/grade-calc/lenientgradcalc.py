import os
from decimal import Decimal, ROUND_HALF_UP


def clear_screen():
    os.system("cls" if os.name == "nt" else "clear")


GRADE_BOUNDS = [
    (90, "A*"),
    (80, "A"),
    (70, "B"),
    (60, "C"),
    (50, "D"),
    (40, "E"),
    (0, "U"),
]

LENIENCY_BOUNDS = {40, 50, 60, 70, 80}


def adjust_percentage(obtained, total):
    percentage = (obtained / total) * Decimal(100)

    rounded = int(percentage.quantize(0, rounding=ROUND_HALF_UP))

    if rounded < 80:
        for b in LENIENCY_BOUNDS:
            if b - 2 <= rounded < b:
                rounded = b
                break

    return rounded, percentage


def get_grade(adjusted):
    for threshold, grade in GRADE_BOUNDS:
        if adjusted >= threshold:
            return grade


def main():
    print("=== Grade Calculator ===\n")

    while True:
        try:
            total = int(input("Enter total marks for this test: "))
            if total > 0:
                break
        except ValueError:
            pass
        print("Total marks must be greater than 0.\n")

    print(f"\nTotal marks set to: {total}")
    print("Enter marks lost (or 'xx' to quit, 'change' to set new total marks)\n")

    while True:
        inp = input(f"Enter marks lost out of {total}: ").lower()

        if inp == "xx":
            print("Exiting... Goodbye!")
            break

        if inp == "change":
            while True:
                try:
                    total = int(input("Enter new total marks: "))
                    if total > 0:
                        print(f"Total marks changed to: {total}\n")
                        break
                except ValueError:
                    pass
                print("Total marks must be greater than 0.\n")
            continue

        try:
            lost = Decimal(inp)
            if not (0 <= lost <= total):
                raise ValueError

            obtained = Decimal(total) - lost
            adjusted, raw = adjust_percentage(obtained, Decimal(total))
            grade = get_grade(adjusted)

            clear_screen()

            print("=" * 50)
            print(f"Total Marks: {total}")
            print(f"Marks Obtained: {obtained}")
            print(f"Marks Lost: {lost}")
            print(f"Raw Percentage: {raw:.2f}%")
            print(f"Adjusted Percentage: {adjusted}%")
            print(f"Grade: {grade}")
            print("=" * 50)
            print()

        except:
            print("Please enter a valid number.\n")


if __name__ == "__main__":
    main()
