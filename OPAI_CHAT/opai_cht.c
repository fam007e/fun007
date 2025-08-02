#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>
#include "parson.h" // Include Parson for JSON parsing

#define MAX_RESPONSE_SIZE 4096 // Increased for potentially larger responses
#define API_ENDPOINT "https://api.openai.com/v1/chat/completions"

// Structure to hold the API response
struct Memory {
    char *response;
    size_t size;
};

// Callback function for CURL to write received data into Memory struct
static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    struct Memory *mem = (struct Memory *)userp;

    char *ptr = realloc(mem->response, mem->size + realsize + 1);
    if(ptr == NULL) {
        fprintf(stderr, "Not enough memory (realloc returned NULL)\n");
        return 0;
    }

    mem->response = ptr;
    memcpy(&(mem->response[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->response[mem->size] = 0; // Null-terminate the string

    return realsize;
}

void chat() {
    CURL *curl;
    CURLcode res;
    char user_input[512]; // Increased input buffer size
    struct Memory chunk;
    char *api_key = getenv("OPENAI_API_KEY"); // Get API key from environment variable

    if (!api_key) {
        fprintf(stderr, "Error: OPENAI_API_KEY environment variable not set.\n");
        fprintf(stderr, "Please set it using: export OPENAI_API_KEY='<YOUR_API_KEY>'\n");
        return;
    }

    chunk.response = malloc(1); // Initialize with a small buffer
    chunk.size = 0;

    curl_global_init(CURL_GLOBAL_DEFAULT); // Initialize libcurl
    curl = curl_easy_init();
    if(curl) {
        while(1) {
            printf("You: ");
            if (fgets(user_input, sizeof(user_input), stdin) == NULL) {
                fprintf(stderr, "Error reading input.\n");
                break;
            }
            user_input[strcspn(user_input, "\n")] = 0; // Remove newline character

            if (strcasecmp(user_input, "exit") == 0 || strcasecmp(user_input, "quit") == 0) {
                printf("Exiting chat...\n");
                break;
            }

            // Reset response buffer for the new request
            free(chunk.response);
            chunk.response = malloc(1);
            chunk.size = 0;
            if (chunk.response == NULL) {
                fprintf(stderr, "Memory allocation failed for response buffer.\n");
                break;
            }

            curl_easy_setopt(curl, CURLOPT_URL, API_ENDPOINT);
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);
            curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L); // Set a timeout for the request

            struct curl_slist *headers = NULL;
            headers = curl_slist_append(headers, "Content-Type: application/json");
            char auth_header[256];
            snprintf(auth_header, sizeof(auth_header), "Authorization: Bearer %s", api_key);
            headers = curl_slist_append(headers, auth_header);
            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

            char json_data[MAX_RESPONSE_SIZE]; // Use MAX_RESPONSE_SIZE for JSON data to be safe
            snprintf(json_data, sizeof(json_data),
                     "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"%s\"}], \"max_tokens\": 1024, \"temperature\": 0.7}", // Adjusted max_tokens and temperature
                     user_input);
            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json_data);

            res = curl_easy_perform(curl);
            if(res != CURLE_OK) {
                fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
            } else {
                // Parse JSON response
                JSON_Value *root_value = json_parse_string(chunk.response);
                if (json_value_get_type(root_value) == JSONObject) {
                    JSON_Object *root_object = json_value_get_object(root_value);
                    JSON_Array *choices = json_object_get_array(root_object, "choices");
                    if (choices && json_array_get_count(choices) > 0) {
                        JSON_Object *first_choice = json_array_get_object(choices, 0);
                        JSON_Object *message = json_object_get_object(first_choice, "message");
                        const char *content = json_object_get_string(message, "content");
                        if (content) {
                            printf("ChatGPT: %s\n", content);
                        } else {
                            fprintf(stderr, "Error: Could not find 'content' in message.\n");
                        }
                    } else {
                        // Check for API error message
                        JSON_Object *error_obj = json_object_get_object(root_object, "error");
                        if (error_obj) {
                            const char *error_message = json_object_get_string(error_obj, "message");
                            if (error_message) {
                                fprintf(stderr, "API Error: %s\n", error_message);
                            } else {
                                fprintf(stderr, "Unknown API Error.\n");
                            }
                        } else {
                            fprintf(stderr, "Error: 'choices' array is empty or not found.\n");
                        }
                    }
                } else {
                    fprintf(stderr, "Error: Invalid JSON response or empty response.\nResponse: %s\n", chunk.response);
                }
                json_value_free(root_value); // Free JSON resources
            }
            curl_slist_free_all(headers); // Free headers
        }

        free(chunk.response); // Free final response buffer
        curl_easy_cleanup(curl); // Cleanup curl session
    }
    curl_global_cleanup(); // Cleanup libcurl
}

int main() {
    chat();
    return 0;
}