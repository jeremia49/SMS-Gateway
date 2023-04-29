#include <iostream>
#include <memory>
#ifndef UTIL_H
#define UTIL_H

struct response {
  char* memory;
  size_t size;
};

response getRequest(const std::string& url);

#endif