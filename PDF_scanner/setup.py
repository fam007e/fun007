import os
from setuptools import setup, find_packages

with open("README.md", "r") as fh:
    long_description = fh.read()

setup(
    name='pdf-keyword-scanner',
    version='1.0.0',
    author='Faisal Ahmed Moshiur',
    author_email='faisalmoshiur+gitpy@gmail.com',
    description='A command-line tool to scan PDF files for specific keywords.',
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/fam007e/fun007", 
    packages=find_packages(),
    install_requires=[
        'PyPDF2',
    ],
    entry_points={
        'console_scripts': [
            'pdf-scan=pdf_keyword_scanner:main',
        ],
    },
    classifiers=[
        'Programming Language :: Python :: 3',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
    ],
    python_requires='>=3.6',
)
