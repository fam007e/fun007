#!/usr/bin/env python3

import PyPDF2
import argparse
from pathlib import Path

def parse_ranges(ranges):
    """
    Parse a range string into a list of pages.
    For example, '1-3,5,7-9' -> [1, 2, 3, 5, 7, 8, 9]
    """
    result = []
    for part in ranges.split(','):
        if '-' in part:
            start, end = part.split('-')
            result.extend(range(int(start), int(end) + 1))
        else:
            result.append(int(part))
    return result

def get_output_file_path(base_path, base_name, index=None):
    if index is None:
        output_pdf = base_path / f"{base_name}.pdf"
    else:
        output_pdf = base_path / f"{base_name}_{index + 1}.pdf"
    
    if output_pdf.exists():
        while True:
            overwrite = input(f"File {output_pdf} already exists. Do you want to overwrite it? (yes/no): ").lower()
            if overwrite == 'yes':
                return output_pdf
            elif overwrite == 'no':
                new_name = input("Enter a new base name for the split PDF files: ")
                return get_output_file_path(base_path, new_name, index)
            else:
                print("Please answer 'yes' or 'no'.")
    return output_pdf

def split_pdf(input_pdf, page_ranges, base_name):
    """
    Split the input PDF into multiple PDFs based on the page_ranges and save them to the same directory as input_pdf.
    Each new PDF file will be named based on the provided base_name.
    """
    pdf_reader = PyPDF2.PdfReader(input_pdf)
    input_pdf_path = Path(input_pdf)
    output_dir = input_pdf_path.parent

    for idx, pages in enumerate(page_ranges):
        pdf_writer = PyPDF2.PdfWriter()
        for page_num in pages:
            pdf_writer.add_page(pdf_reader.pages[page_num - 1])
        output_pdf = get_output_file_path(output_dir, base_name, idx if len(page_ranges) > 1 else None)
        with open(output_pdf, 'wb') as output_file:
            pdf_writer.write(output_file)
        print(f"Created: {output_pdf}")

def main():
    parser = argparse.ArgumentParser(description="Split a PDF file into multiple PDFs based on specified page ranges.")
    parser.add_argument("input_pdf", help="Path to the input PDF file.")

    args = parser.parse_args()

    # Prompt for page ranges and base name
    page_ranges_input = input("Enter the page ranges (e.g., '1-20,22,25-30'): ")
    base_name = input("Enter the base name for the split PDF files: ")

    # Parse the page ranges
    page_ranges = [parse_ranges(r) for r in page_ranges_input.split(',')]
    split_pdf(args.input_pdf, page_ranges, base_name)

if __name__ == "__main__":
    main()
