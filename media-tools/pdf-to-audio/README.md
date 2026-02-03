# PDF2MP3

**PDF Text-to-Speech Converter**

Converts PDF documents to MP3 audio files using text-to-speech synthesis, enabling audiobook-style consumption of written content.

## Features

- 📄 Extracts text from PDF documents
- 🔊 Converts text to speech audio
- 💾 Saves output as MP3 file

## Usage

1. Place your PDF file in the directory
2. Update the filename in `main.py`
3. Run:

```bash
python main.py
```

## Requirements

```bash
pip install pyttsx3 PyPDF2
```

## Notes

- Works best with text-based PDFs (not scanned images)
- Output quality depends on your system's TTS engine

## License

MIT License
