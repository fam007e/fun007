#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>

#define API_KEY "<Insert_Your_API-key>"
#define MAX_RESPONSE_SIZE 2048

struct Memory {
    char *response;
    size_t size;
};

static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    struct Memory *mem = (struct Memory *)userp;

    char *ptr = realloc(mem->response, mem->size + realsize + 1);
    if(ptr == NULL) {
        printf("Not enough memory (realloc returned NULL)\n");
        return 0;
    }

    mem->response = ptr;
    memcpy(&(mem->response[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->response[mem->size] = 0;

    return realsize;
}

void chat() {
    CURL *curl;
    CURLcode res;
    char user_input[256];
    struct Memory chunk;
    chunk.response = malloc(1);
    chunk.size = 0;

    curl = curl_easy_init();
    if(curl) {
        while(1) {
            printf("You: ");
            fgets(user_input, sizeof(user_input), stdin);
            user_input[strcspn(user_input, "\n")] = 0;  // Remove newline character

            if (strcasecmp(user_input, "exit") == 0 || strcasecmp(user_input, "quit") == 0) {
                printf("Exiting chat...\n");
                break;
            }

            chunk.size = 0;  // Reset response size for the new request

            curl_easy_setopt(curl, CURLOPT_URL, "https://api.openai.com/v1/completions");
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);

            struct curl_slist *headers = NULL;
            headers = curl_slist_append(headers, "Content-Type: application/json");
            headers = curl_slist_append(headers, "Authorization: Bearer " API_KEY);

            char json_data[1024];
            snprintf(json_data, sizeof(json_data),
                     "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"%s\"}], \"max_tokens\": 2048, \"temperature\": 0.3}",
                     user_input);

            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json_data);

            res = curl_easy_perform(curl);
            if(res != CURLE_OK)
                fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));

            printf("ChatGPT: %s\n", chunk.response);

            curl_slist_free_all(headers);
        }

        free(chunk.response);
        curl_easy_cleanup(curl);
    }
}

int main() {
    chat();
    return 0;
}
