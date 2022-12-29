import pyttsx3, PyPDF2

pdfreader = PyPDF2.PdfFileReader(open('C:/Users/faisa/OneDrive/Documents/RLT/Study_Materialz/NRP/Slides/NRP_Lec_slides.pdf','rb'))
speaker = pyttsx3.init()

for page_num in range(pdfreader.numPages):
    text = pdfreader.getPage(page_num).extractText()
    clean_text = text.strip().replace('n','')
    print(clean_text)
    
speaker.save_to_file(clean_text,'NRP_slides.mp3')
speaker.runAndWait()

speaker.stop()