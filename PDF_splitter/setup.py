import os
from setuptools import setup, find_packages


with open("README.md", "r") as fh:
    long_description = fh.read()

setup(
    name='pdf-splitter',
    version='1.0.0',
    author='Faisal Ahmed Moshiur',
    author_email='faisalmoshiur+gitpy@gmail.com',
    description='A command-line tool to split PDF files into multiple parts based on specified page ranges.',
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/fam007e/fun007", 
    packages=find_packages(),
    install_requires=[
        'PyPDF2',
    ],
    entry_points={
        'console_scripts': [
            'pdf-split=pdf_splitter:main',
        ],
    },
    classifiers=[
        'Programming Language :: Python :: 3',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
    ],
    python_requires='>=3.6',
)
