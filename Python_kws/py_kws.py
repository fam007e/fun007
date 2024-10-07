from keyword import kwlist, softkwlist

def display_keywords() -> None:
    """Display Python keywords and soft keywords."""
    print("Keywords:")
    for i, kw in enumerate(kwlist, start=1):
        print(f"{i:2}: {kw}")

    print("\nSoft keywords:")
    for i, skw in enumerate(softkwlist, start=1):
        print(f"{i:2}: {skw}")

def main() -> None:
    """Main function to display Python keywords."""
    display_keywords()

if __name__ == "__main__":
    main()
