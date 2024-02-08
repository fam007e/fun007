import os
import uuid
import random
import time

def rename_files(directory, extensions):
    # Change directory
    os.chdir(directory)
    
    # Get list of files with specified extensions
    files = [f for f in os.listdir() if os.path.isfile(f) and f.endswith(extensions)]
    
    # Rename files with random names
    for filename in files:
        if filename != 'rand_gen_name.py':
            ext = os.path.splitext(filename)[1]
            new_name = str(uuid.uuid4())[:8] + ext
            os.rename(filename, new_name)
            print(f"Renamed '{filename}' to '{new_name}'")

if __name__ == "__main__":
    # Get current working directory
    directory = os.getcwd()

    # Ask user for file extensions
    extensions = input("Enter file extensions to rename (comma-separated, e.g., png,jpg): ").split(',')

    # Remove spaces and convert to lowercase
    extensions = [ext.strip().lower() for ext in extensions]

    # Rename files
    rename_files(directory, tuple(extensions))
