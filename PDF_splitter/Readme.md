# PDF Splitter

This Python script allows you to split a PDF file into multiple PDFs based on specified page ranges. The output files will be saved in the same directory as the input file with specified base names.

## Features

- Split a PDF into multiple parts by specifying page ranges.
- Save the split PDF files with a custom base name.
- Handle existing files by prompting for overwrite or renaming.

## Requirements

- Python 3
- PyPDF2

## Installation

1. Clone this repository:
    ```sh
    git clone https://github.com/yourusername/pdf-splitter.git
    cd pdf-splitter
    ```

2. Create a virtual environment and activate it:
    ```sh
    python3 -m venv venv
    source venv/bin/activate
    ```

3. Install the required packages:
    ```sh
    pip install PyPDF2
    ```

## Usage

1. Run the script with the PDF file you want to split:
    ```sh
    python split_pdf.py yourfile.pdf
    ```

2. Follow the prompts to enter the page ranges and the base name for the output files:
    ```
    Enter the page ranges (e.g., '1-20,22,25-30'): 1-5,7-10
    Enter the base name for the split PDF files: SplitFile
    ```

3. If a file with the same name already exists, you will be prompted to overwrite it or provide a new name.

## Example

Assume you have a PDF file named `document.pdf` and you want to split it into two parts:
- Part 1: Pages 1 to 5
- Part 2: Pages 7 to 10

Run the script:
```sh
python split_pdf.py document.pdf
```
Enter the page ranges and base name when prompted:
```sh
Enter the page ranges (e.g., '1-20,22,25-30'): 1-5,7-10
Enter the base name for the split PDF files: DocumentPart
```
The script will create two files:
- DocumentPart_1.pdf (containing pages 1 to 5)
- DocumentPart_2.pdf (containing pages 7 to 10)

## Contributing

Feel free to open issues or submit pull requests with improvements or bug fixes.

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.
