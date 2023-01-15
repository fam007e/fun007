import openai

# Replace YOUR_API_KEY with your actual API key
openai.api_key = "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"

def chat():
    while True:
        # Get user input
        user_input = input("You: ")
        # Use the ChatGPT API to generate a response
        response = openai.Completion.create(
            engine="text-davinci-002",
            prompt=f"{user_input}"
        )
        # Print the response
        print("ChatGPT: ", response["choices"][0]["text"])

if __name__ == "__main__":
    chat()
