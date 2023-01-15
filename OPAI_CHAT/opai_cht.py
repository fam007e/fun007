import openai
import json

# Replace YOUR_API_KEY with your actual API key
openai.api_key = "sksk-dc3hgv732LPqOUF8eM7eT3BlbkFJu2rdpxLBhmzAZiLtbAHA-xAAWIChYZsK3ewEeXCaGT3BlbkFJSHeJovSMY1JP3deREnsL"

# conversation history
history = []

def chat():
    while True:
        # Get user input
        user_input = input("You: ")

        # exit or quit command
        if user_input.lower() in ["exit", "quit"]:
            print("Exiting chat...")
            break

        # command to view conversation history
        elif user_input.lower() == "history":
            for i, convo in enumerate(history):
                print(f"{i+1}. {convo}")
            continue
        # command to save conversation history
        elif user_input.lower() == "save":
            with open("conv_history.json", "w") as outfile:
                json.dump(history, outfile)
            print("Conversation history saved to conv_history.json")
            continue
        # command to change the prompt
        elif user_input.lower() == "change prompt":
            user_input = input("Enter new prompt: ")

        # Use the ChatGPT API to generate a response
        response = openai.Completion.create(
            engine="text-davinci-002",
            prompt=f"{user_input}",
            max_tokens=2048,
            temperature=0.3
        )

        # Print the response
        if response["choices"][0]["text"] != "":
            print("ChatGPT: ", response["choices"][0]["text"])
            history.append(response["choices"][0]["text"])
        else:
            print("ChatGPT: No response")


if __name__ == "__main__":
    chat()
