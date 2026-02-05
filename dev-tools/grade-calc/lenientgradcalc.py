import os
import math


def clear_screen():
    # Works on Windows, Mac, Linux
    os.system("cls" if os.name == "nt" else "clear")


def get_grade(percentage):
    """
    Determine grade based on percentage with leniency for borderline cases.
    If percentage is within 2% of the next grade boundary and < 80%, round up.
    """
    # Grade boundaries: (threshold, grade)
    grade_boundaries = [
        (90, "A*"),
        (80, "A"),
        (70, "B"),
        (60, "C"),
        (50, "D"),
        (40, "E"),
        (0, "U"),
    ]

    # Round the percentage to whole number (0.5 always rounds up)
    rounded_percentage = int(percentage + 0.5)

    # Apply leniency: if within 2% of next boundary and below 80%
    # Check against the rounded percentage
    if rounded_percentage < 80:
        for threshold in [40, 50, 60, 70, 80]:
            if threshold - 2 <= rounded_percentage < threshold:
                rounded_percentage = threshold
                break

    # Determine grade based on rounded percentage
    for threshold, grade in grade_boundaries:
        if rounded_percentage >= threshold:
            return grade, rounded_percentage


def main():
    print("=== Grade Calculator ===\n")

    # Get total marks once at the start
    while True:
        total_marks_input = input("Enter total marks for this test: ")
        try:
            total_marks = int(total_marks_input)
            if total_marks <= 0:
                print("Total marks must be greater than 0.\n")
                continue
            break
        except ValueError:
            print("Please enter a valid number.\n")

    print(f"\nTotal marks set to: {total_marks}")
    print("Enter marks lost (or 'xx' to quit, 'change' to set new total marks)\n")

    # Loop for entering multiple marks
    while True:
        marks_input = input(f"Enter marks lost out of {total_marks}: ")

        if marks_input.lower() == "xx":
            print("Exiting... Goodbye!")
            break

        if marks_input.lower() == "change":
            # Allow changing total marks
            while True:
                total_marks_input = input("Enter new total marks: ")
                try:
                    total_marks = int(total_marks_input)
                    if total_marks <= 0:
                        print("Total marks must be greater than 0.\n")
                        continue
                    print(f"Total marks changed to: {total_marks}\n")
                    break
                except ValueError:
                    print("Please enter a valid number.\n")
            continue

        try:
            marks_lost = float(marks_input)
            if marks_lost < 0 or marks_lost > total_marks:
                print(f"Marks lost must be between 0 and {total_marks}.\n")
                continue

            # Calculate result
            marks_obtained = total_marks - marks_lost
            percentage = (marks_obtained / total_marks) * 100
            grade, adjusted_percentage = get_grade(percentage)

            # Clear screen before printing result
            clear_screen()

            # Display results
            print("=" * 50)
            print(f"Total Marks: {total_marks}")
            print(f"Marks Obtained: {marks_obtained}")
            print(f"Marks Lost: {marks_lost}")
            print(f"Raw Percentage: {percentage:.2f}%")
            print(f"Adjusted Percentage: {adjusted_percentage}%")
            print(f"Grade: {grade}")
            print("=" * 50)
            print()

        except ValueError:
            print("Please enter a valid number.\n")


if __name__ == "__main__":
    main()
