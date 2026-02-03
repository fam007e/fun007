import os
import subprocess
from setuptools import setup, find_packages
from setuptools.command.install import install

# Custom install command to install exiftool if not present
class CustomInstallCommand(install):
    def run(self):
        # Check if exiftool is installed
        try:
            subprocess.check_output(["exiftool", "-ver"])
            print("Exiftool is already installed.")
        except subprocess.CalledProcessError:
            print("Failed to check exiftool version.")
            raise
        except FileNotFoundError:
            # If exiftool is not found, try to install it
            print("Exiftool not found. Installing...")
            if os.name == 'posix':  # For Linux and Unix-like systems
                try:
                    if subprocess.call(["which", "apt"], stdout=subprocess.DEVNULL) == 0:
                        subprocess.check_call(["sudo", "apt", "update"])
                        subprocess.check_call(["sudo", "apt", "install", "-y", "exiftool"])
                    elif subprocess.call(["which", "dnf"], stdout=subprocess.DEVNULL) == 0:
                        subprocess.check_call(["sudo", "dnf", "install", "-y", "perl-Image-ExifTool"])
                    elif subprocess.call(["which", "pacman"], stdout=subprocess.DEVNULL) == 0:
                        subprocess.check_call(["sudo", "pacman", "-S", "--noconfirm", "exiftool"])
                    elif subprocess.call(["which", "brew"], stdout=subprocess.DEVNULL) == 0:
                        subprocess.check_call(["brew", "install", "exiftool"])
                    else:
                        print("Unsupported package manager. Please install ExifTool manually from https://exiftool.org/")
                except subprocess.CalledProcessError as e:
                    print(f"Error installing ExifTool: {e}")
                    raise
            else:
                print("Unsupported OS. Please install ExifTool manually from https://exiftool.org/")

        # Continue with the regular installation
        install.run(self)

# Read the README file for the long description
with open("README.md", "r") as fh:
    long_description = fh.read()

setup(
    name="wp_cleaner",
    version="1.0.0",
    author="Faisal Ahmed Moshiur",
    author_email="faisalmoshiur+gitpy@gmail.com",
    description="A tool for cleaning wallpapers based on dimensions and removing metadata",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/fam007e/fun007", 
    packages=find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
    install_requires=[],
    cmdclass={
        'install': CustomInstallCommand,
    },
    entry_points={
        'console_scripts': [
            'wp_cleaner=wp_cleaner:main',
        ],
    },
)
