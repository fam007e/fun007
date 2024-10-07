"""
This module provides functionality to delete a specified file from the filesystem.

It prompts the user for the file path and deletes the file if it exists.
"""

import os

file_path = input(
    "Insert the path of the file to be deleted: e.g. /users/username/Downloads/file.pdf  "
)

print(file_path)

if os.path.isfile(file_path):
    os.remove(file_path)
    print("File has been successfully deleted!")
else:
    print('This file does NOT exist!!!')


