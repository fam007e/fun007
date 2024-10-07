# Random Name Generator

This Python script (`rand_name_gen.py`) renames files in a specified directory with random names. It supports renaming files based on the given file extensions.

## Features

- **Random Renaming**: Renames files with random UUIDs truncated to 8 characters.
- **Flexible Extension Handling**: Allows specifying multiple file extensions to process.
- **Error Handling**: Provides feedback on any issues encountered during renaming.

## Prerequisites

- **Python 3.x**: Ensure you have Python 3 installed on your system.

## Usage

1. Clone or download the `rand_name_gen.py` script to your local machine.
2. Run the script using Python:
   ```sh
   python rand_name_gen.py
   ```
3. Follow the prompts to enter the file extensions you wish to rename (comma-separated, e.g., `png`,`jpg`).

The script will rename all files in the current working directory with the specified extensions. 

## Example

```sh
$ python rand_name_gen.py
Enter file extensions to rename (comma-separated, e.g., png,jpg): png,jpg
Renamed 'example.png' to 'd4f7e6d8.png'
Renamed 'sample.jpg' to 'a3b2c1d0.jpg'
```

## License
This project is licensed under the [LICENSE](../LICENSE).
