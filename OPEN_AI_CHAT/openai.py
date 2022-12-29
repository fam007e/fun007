import requests

def send_message(message):
    # Set the API endpoint and your API key
    endpoint = "https://api.openai.com/v1/images/generations"
    api_key = "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"
#org-eO050d5HxeeaRMzrnAmcfZGL
    # Set the message payload
    payload = {
        "model": "text-davinci-003",
        "prompt": message,
        "num_images": 1,
        "size": "1024x1024",
        "response_format": "url"
    }

    # Send the message to the OpenAI API
    response = requests.post(endpoint, json=payload, headers={"Authorization": f"Bearer {api_key}"})
    
    # Print the JSON response from the OpenAI API
    print(response.json())
    
    # Get the response from the OpenAI API
    response_text = response.json()["data"][0]["url"]

    return response_text

def main():
    # Send a message to the OpenAI chat feature
    message = input("Enter a message: ")
    response = send_message(message)

    # Print the response from the OpenAI chat feature
    print(response)

if __name__ == "__main__":
    main()