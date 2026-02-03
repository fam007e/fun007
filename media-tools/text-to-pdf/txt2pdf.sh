#!/usr/bin/zsh

# Default values
default_font="Courier"
default_font_size="7.3"
default_font_type="10"
default_margins="36:36:36:36"  # 1/2 inch margins on A4 paper (1 inch = 72 points)

# Help message
usage() {
  echo "Usage: $0 [-f font] [-s size] [-t type] [-m margins] filename.txt"
  echo "  -f font       Font to use (default: $default_font)"
  echo "  -s size       Font size (default: $default_font_size)"
  echo "  -t type       Font type (e.g., 10, 12, etc.) (default: $default_font_type)"
  echo "  -m margins    Margins in the format left:right:top:bottom (default: $default_margins)"
  echo "  -l            List available fonts"
  echo "  -h            Display this help message"
  exit 1
}

# Parse flags
while getopts "f:s:t:m:lh" opt; do
  case $opt in
    f) font=$OPTARG ;;
    s) font_size=$OPTARG ;;
    t) font_type=$OPTARG ;;
    m) margins=$OPTARG ;;
    l) fc-list :family | sort | uniq; exit 0 ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Shift past the processed options
shift $((OPTIND - 1))

# Check if a file was provided
if [ -z "$1" ]; then
  usage
fi

# Get the input file and output file names
input_file="$1"
base_name=$(basename "$input_file" .txt)
output_file="$base_name.pdf"
temp_ps_file="$base_name.ps"

# Use default values if not provided
font=${font:-$default_font}
font_size=${font_size:-$default_font_size}
font_type=${font_type:-$default_font_type}
margins=${margins:-$default_margins}

# Convert the .txt file to a .ps file with the specified font, size, type, and margins
enscript -B --margins=$margins -o "$temp_ps_file" -f "$font@$font_size/$font_type" "$input_file"

# Convert the .ps file to a .pdf file
ps2pdfwr "$temp_ps_file" "$output_file"

# Remove the temporary .ps file
rm -f "$temp_ps_file"

echo "Converted $input_file to $output_file using font '$font@$font_size/$font_type' with margins '$margins'"
