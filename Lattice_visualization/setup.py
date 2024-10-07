import os
from setuptools import setup, find_packages

# Read the README file for the long description
with open("README.md", "r") as fh:
    long_description = fh.read()

setup(
    name="lattice_visualization",
    version="1.0.0",
    author="Faisal Ahmed Moshiur",
    author_email="faisalmoshiur+gitpy@gmail.com",
    description="A module for visualizing lattice structures and calculating Schmid factors",
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
    install_requires=[
        'numpy',
        'matplotlib',
    ],
    entry_points={
        'console_scripts': [
            'lattice_visualizer=main:main',
        ],
    },
)
