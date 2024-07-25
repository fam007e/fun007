# `txt2pdf` - Convert Text Files to PDF

## Overview
`txt2pdf` is a binary made from z-shell script that converts plain text files to PDF format. The script allows you to specify fonts, font sizes, 
font types, and margins for customization. It uses `enscript`, and `ps2pdfwr` from `ghostscript` for the conversion process.

## Dependencies
- `enscript`: Converts text files to PostScript.
- `ps2pdfwr`: Converts PostScript files to PDF.
- `shc` (optional): To compile the script into a binary executable.

## Installing Dependencies
On Arch Linux, you can install the required dependencies using:

```sh
sudo pacman -S enscript ghostscript && yay -S shc
```

On Debian-based systems, use:

```sh
sudo apt-get install enscript ghostscript shc
```

## Usage

### Syntax

```sh
txt2pdf [-f font] [-s size] [-t type] [-m margins] filename.txt
```

### Options
- `-f` font: Specify the font to use. Default is "Courier".
- `-s` size: Specify the font size. Default is "7.3".
- `-t` type: Specify the font type (e.g., 10, 12). Default is "10".
- `-m` margins: Specify margins in the format left:right:top. Default is "36:36:36:36" (1/2 inch margins).
- `-l`: List available fonts on the system.
- `-h`: Display help message.

### Example Usage
1. Convert text file to PDF with default settings:

```sh
txt2pdf filename.txt
```

2. Specify font and font size:

```sh
txt2pdf -f "FiraMono Nerd Font Mono" -s "10" -t "12" filename.txt
```

3. List available fonts:

```sh
txt2pdf -l
```

## Creating a Binary with `shc`

To compile the z-shell script into a `txt2pdf` binary executable:

```sh
shc -f txt2pdf.sh -o txt2pdf
```
This command generates a binary file named `txt2pdf` that you can use as shown above. You can execute the original 
script `txt2pdf.sh` in place of the aforementioned binary.


## License

This script is licensed under the MIT License. See the [LICENSE](../LICENSE) file for more details.


