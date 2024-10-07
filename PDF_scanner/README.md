# PDF Keyword Scanner

A command-line tool to scan PDF files in a directory for specific keywords and output the results to a file.

## Features

- Scans all PDF files in a given directory.
- Searches for user-specified keywords (case-insensitive).
- Saves the results to a `.dat` file showing which files contain which keywords.

## Installation

To install the tool, clone the repository and install the package:

```bash
pip install .
```

This will install the package and provide the `pdf-scan` command.

## Usage
To scan PDF files for specific keywords, use the `pdf-scan` command.

### Example:

```sh
pdf-scan
```

After running the command, you will be prompted to enter the directory path and the keywords you want to search for, separated by commas.

### Output:

```sh
The tool will output the names of the matching files and save the results to a `keyword_results.dat` file.
```

## License

This project is licensed under the [License](../LICENSE).
