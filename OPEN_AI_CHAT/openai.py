import argparse
import requests

def send_message(message):
    # Set the API endpoint and your API key
    endpoint = "https://api.openai.com/v1/images/generations"
    api_key = "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"

    # Set the message payload
    payload = {
        "model": "text-davinci-003",
        "prompt": message,
        "num_images": 1,
        "size": "1024x1024",
        "response_format": "url"
    }

    # Send the message to the OpenAI API
    try:
        with requests.post(endpoint, json=payload, headers={"Authorization": f"Bearer {api_key}"}) as response:
            # Get the response from the OpenAI API
            response_text = response.json()["data"][0]["url"]
    except requests.RequestException as e:
        print(f"An error occurred while sending the message: {e}")
        return

    return response_text

def print_response(response):
    print(response)

def get_input():
    return input("Enter a message: ")

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("message", help="The message to send to the chat feature")
    return parser.parse_args()

def main():
    # Send a message to the OpenAI chat feature
    args = parse_args()
    message = args.message if args.message else get_input()
    response = send_message(message)

    # Print the response from the OpenAI chat feature
    if response:
        print_response(response)

if __name__ == "__main__":
    main()
