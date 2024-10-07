import os
import uuid

def rename_files(directory, extensions):
    # Change directory
    os.chdir(directory)
    
    # Get list of files with specified extensions
    files = [f for f in os.listdir() if os.path.isfile(f) and f.lower().endswith(extensions)]
    
    # Rename files with random names
    for filename in files:
        if filename != 'rand_name_gen.py':
            ext = os.path.splitext(filename)[1]
            new_name = str(uuid.uuid4())[:8] + ext
            try:
                os.rename(filename, new_name)
                print(f"Renamed '{filename}' to '{new_name}'")
            except OSError as e:
                print(f"Error renaming '{filename}': {e}")

if __name__ == "__main__":
    # Get current working directory
    directory = os.getcwd()

    # Ask user for file extensions
    extensions_input = input("Enter file extensions to rename (comma-separated, e.g., png,jpg): ")
    extensions = [ext.strip().lower() for ext in extensions_input.split(',')]

    if not extensions:
        print("No extensions provided. Exiting.")
    else:
        # Rename files
        rename_files(directory, tuple(extensions))
