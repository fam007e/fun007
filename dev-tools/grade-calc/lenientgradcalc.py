import os
from decimal import Decimal, ROUND_HALF_UP

try:
    from art import text2art
except ImportError:
    print("Please install the 'art' library first:")
    print("   pip install art")
    import sys

    sys.exit(1)


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
        for b in sorted(LENIENCY_BOUNDS):
            if b - 2 <= rounded < b:
                rounded = b
                break
    return rounded, percentage


def get_grade(adjusted):
    return next(
        (grade for threshold, grade in GRADE_BOUNDS if adjusted >= threshold), "U"
    )


def get_positive_int(prompt):
    """Get a positive integer from user with validation"""
    while True:
        try:
            value = int(input(prompt))
            if value > 0:
                return value
        except ValueError:
            pass
        print("Total marks must be greater than 0.\n")


def pad_lines(lines, height):
    """Pad ASCII art lines to specified height"""
    return lines + [""] * (height - len(lines))


def combine_ascii_blocks(obtained, grade, percentage):
    """Combine marks obtained, arrow, and grade(percentage) into one ASCII art"""
    # Generate ASCII parts
    parts = [
        text2art(str(obtained), font="doom"),
        text2art(" --> ", font="doom"),
    ]

    # Handle A* specially with superscript asterisk
    if grade == "A*":
        a_lines = text2art("A", font="doom").splitlines()
        p_lines = text2art(f"({percentage}%)", font="doom").splitlines()
        max_h = max(len(a_lines), len(p_lines))
        a_lines = pad_lines(a_lines, max_h)
        p_lines = pad_lines(p_lines, max_h)
        # Add superscript asterisk to A
        if len(a_lines) >= 2:
            a_lines[1] = a_lines[1].rstrip() + "*"
        parts.append("\n".join(a_lines[i] + p_lines[i] for i in range(max_h)))
    else:
        parts.append(text2art(f"{grade}({percentage}%)", font="doom"))

    # Split all parts into lines and pad to same height
    part_lines = [part.splitlines() for part in parts]
    max_height = max(len(lines) for lines in part_lines)
    part_lines = [pad_lines(lines, max_height) for lines in part_lines]

    # Calculate widths and combine horizontally
    widths = [
        max((len(line) for line in lines), default=0) for lines in part_lines[:-1]
    ]
    return "\n".join(
        "".join(
            part_lines[i][j].ljust(widths[i]) if i < len(widths) else part_lines[i][j]
            for i in range(len(part_lines))
        )
        for j in range(max_height)
    )


def main():
    print("=== Grade Calculator ===\n")
    total = get_positive_int("Enter total marks for this test: ")
    print(f"\nTotal marks set to: {total}")
    print("Enter marks lost (or 'xx' to quit, 'change' to set new total marks)\n")

    while True:
        inp = input(f"Enter marks lost out of {total}: ").lower()

        if inp == "xx":
            print("Exiting... Goodbye!")
            break

        if inp == "change":
            total = get_positive_int("Enter new total marks: ")
            print(f"Total marks changed to: {total}\n")
            continue

        try:
            lost = Decimal(inp)
            if not (0 <= lost <= total):
                raise ValueError

            obtained = Decimal(total) - lost
            adjusted, raw = adjust_percentage(obtained, Decimal(total))
            grade = get_grade(adjusted)

            # Generate combined ASCII art
            big_art = combine_ascii_blocks(obtained, grade, adjusted)
            art_lines = big_art.splitlines()

            # Info lines
            results_lines = [
                f"Total Marks: {total}",
                f"Marks Obtained: {obtained}",
                f"Marks Lost: {lost}",
                f"Raw Percentage: {raw:.2f}%",
            ]

            # Vertical centering
            height_diff = len(art_lines) - len(results_lines)
            top_pad = max(0, height_diff // 2)
            padded_results = (
                [""] * top_pad + results_lines + [""] * max(0, height_diff - top_pad)
            )

            # Calculate layout widths
            left_width = max(len(line) for line in results_lines) + 5
            full_width = left_width + 4 + max(len(line) for line in art_lines)

            # Display results
            clear_screen()
            print("=" * full_width)
            for i in range(len(art_lines)):
                print(padded_results[i].ljust(left_width) + "  " + art_lines[i])
            print("=" * full_width)
            print()

        except ValueError:
            print(
                "Please enter a valid number (0 or more, not exceeding total marks).\n"
            )
        except Exception as e:
            print(f"An error occurred: {e}\n")


if __name__ == "__main__":
    main()
