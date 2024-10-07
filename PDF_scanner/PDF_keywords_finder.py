import os
import PyPDF2
import re

def scan_pdfs(directory, keywords):
    matching_files = []
    keyword_data = {}

    for filename in os.listdir(directory):
        if filename.endswith('.pdf'):
            filepath = os.path.join(directory, filename)
            with open(filepath, 'rb') as file:
                pdf_reader = PyPDF2.PdfReader(file)
                text = ''
                for page in pdf_reader.pages:
                    text += page.extract_text()

                found_keywords = []
                for keyword in keywords:
                    if re.search(r'\b' + re.escape(keyword) + r'\b', text, re.IGNORECASE):
                        found_keywords.append(keyword)

                if found_keywords:
                    matching_files.append(filename)
                    keyword_data[filename] = found_keywords

    return matching_files, keyword_data

def main():
    directory = input("Enter the directory path containing PDF files: ")
    keywords = input("Enter keywords (separated by commas): ").split(',')
    keywords = [keyword.strip() for keyword in keywords]

    matching_files, keyword_data = scan_pdfs(directory, keywords)

    if matching_files:
        print("Matching PDF files:")
        print("{" + ", ".join(matching_files) + "}")

        with open('keyword_results.dat', 'w') as dat_file:
            for filename, found_keywords in keyword_data.items():
                dat_file.write(f"{filename} {' '.join(found_keywords)}\n")

        print("Results have been saved to 'keyword_results.dat'")
    else:
        print("No matching PDF files found.")

if __name__ == '__main__':
    main()
