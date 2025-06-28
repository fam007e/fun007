import os
from setuptools import setup

# Read the README file for the long description
with open("README.md", "r") as fh:
    long_description = fh.read()

setup(
    name="rand_name_gen",
    version="1.0.0",
    author="Faisal Ahmed Moshiur",
    author_email="faisalmoshiur+gitpy@gmail.com",
    description="A script for renaming files with random names based on specified extensions",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/fam007e/fun007", 
    py_modules=["rand_name_gen"],
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
    entry_points={
        'console_scripts': [
            'rand_name_gen=rand_name_gen:main',
        ],
    },
)
