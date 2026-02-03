# OPAI_CHAT

**OpenAI Chat CLI Client (C Implementation)**

A lightweight, C-based command-line client for interacting with OpenAI's GPT-3.5-turbo API. Demonstrates raw HTTP networking and JSON parsing in pure C.

## Features

- 💬 Interactive chat interface
- 🔐 Secure API key via environment variable
- 📦 JSON parsing with Parson library
- ⏱️ Request timeout handling

## Setup

1. Set your API key:
```bash
export OPENAI_API_KEY='your-api-key-here'
```

2. Compile:
```bash
gcc -o opai_cht opai_cht.c parson.c -lcurl
```

3. Run:
```bash
./opai_cht
```

## Usage

```
You: Hello, how are you?
ChatGPT: I'm doing well, thank you for asking! How can I help you today?
You: exit
Exiting chat...
```

## Dependencies

- `libcurl` - HTTP requests
- `parson` - JSON parsing (included)

## Build Requirements

```bash
# Debian/Ubuntu
sudo apt install libcurl4-openssl-dev

# Arch Linux
sudo pacman -S curl
```

## License

MIT License
