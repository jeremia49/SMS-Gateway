#include <iostream>
#include <curl/curl.h>
#include "util.h"
#include <curl/curl.h>

int main(void)
{
    curl_global_init(CURL_GLOBAL_ALL);

    response gottt = getRequest("http://ip4.me/api/");
    printf("%s", gottt.memory);
    
    curl_global_cleanup();
    return 0;
}

