
#include <stdio.h>
#include <curl/curl.h>
#include "util.h"
#include "server_api.h"
#include <iostream>
#include <cstring>

static size_t mem_cb(void *contents, size_t size, size_t nmemb, void *userp)
{
	size_t realsize = size * nmemb;
	struct response *mem = (struct response *)userp;

	char *ptr = (char *) realloc(mem->memory, mem->size + realsize + 1);
	if(!ptr) {
		/* out of memory! */
		printf("not enough memory (realloc returned NULL)\n");
		return 0;
	}

	mem->memory = ptr;
	memcpy(&(mem->memory[mem->size]), contents, realsize);
	mem->size += realsize;
	mem->memory[mem->size] = 0;

	return realsize;
}

response getRequest(const std::string& url)
{
	
	struct response chunk = {.memory = (char*)malloc(1), .size = 0};

	CURL *curl;
	CURLcode res;

	curl = curl_easy_init();
	if(curl) {
		curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
		
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, mem_cb);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);
		curl_easy_setopt(curl, CURLOPT_USERAGENT, "SMSGateway-Client/1.0");

		res = curl_easy_perform(curl);
		if(res != CURLE_OK){
			fprintf(stderr, "curl_easy_perform() failed: %s\n",curl_easy_strerror(res));
			return chunk;
		}
		curl_easy_cleanup(curl);    
	} else {
        fprintf(stderr, "Failed to create curl handle\n");
    }                        
	// free(chunk.memory);
	return chunk;
}