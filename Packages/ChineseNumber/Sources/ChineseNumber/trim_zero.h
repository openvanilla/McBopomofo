#ifndef trim_zero_h
#define trim_zero_h

#include <stdio.h>
#include <stdbool.h>

const char *trim_zero(const char *input, bool from_start);
const char *left_padding_with_zero(const char *input, size_t target);

#endif /* trim_zero_h */
