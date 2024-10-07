# PDF Splitter

This Python package allows you to split a PDF file into multiple PDFs based on specified page ranges. The output files will be saved in the same directory as the input file with specified base names.

## Features

- Split a PDF into multiple parts by specifying page ranges.
- Save the split PDF files with a custom base name.
- Handle existing files by prompting for overwrite or renaming.
- Supports multiple page ranges for flexible splitting.

## Requirements

- Python 3.x
- PyPDF2

## Installation

1. Clone this repository:
    ```sh
    git clone https://github.com/yourusername/pdf-splitter.git
    cd pdf-splitter
    ```

2. Install the package using `setup.py`:
    ```sh
    pip install .
    ```

3. Alternatively, you can install the package in development mode:
   ```sh
   pip install -e .
   ```

This will make the `pdf-splitter` package available in your Python environment, and you can use it directly as a command-line tool.

## Usage
Once installed, you can use the tool by running the following command:

```sh
pdf-splitter <input_pdf>
```

### Example:

```sh
pdf-splitter document.pdf
```
You will then be prompted to enter the page ranges and the base name for the output files:

```sh
Enter the page ranges (e.g., '1-20,22,25-30'): 1-5,7-10
Enter the base name for the split PDF files: DocumentPart
```

This will create two split files:

- DocumentPart_1.pdf (containing pages 1 to 5)
- DocumentPart_2.pdf (containing pages 7 to 10)

## License

This project is licensed under the [LICENSE](../LICENSE) file.
