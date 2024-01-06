#include "trim_zero.h"
#include <stdlib.h>
#include <string.h>

#define BUFFER_SIZE 80

const char *trim_zero(const char *input, bool from_start) {
    char *rtn = calloc (BUFFER_SIZE, 1);
    memset(rtn, 0, BUFFER_SIZE);
    bool non_zero_found = false;
    if (from_start) {
        size_t n = 0;
        for (size_t i = 0; i < strlen (input); i++) {
            char c = input[i];
            if (non_zero_found) {
                rtn[n++] = c;
            } else if (c != '0') {
                non_zero_found = true;
                rtn[n++] = c;
            }
        }
    } else {
        char reversed[BUFFER_SIZE] = "";
        size_t n = 0;
        for (size_t i = strlen (input) - 1; i >= 0; i--) {
            char c = input[i];
            if (non_zero_found) {
                reversed[n++] = c;
            } else if (c != '0') {
                non_zero_found = true;
                reversed[n++] = c;
            }
        }
        n = 0;
        for (size_t i = strlen (reversed) - 1; i >= 0; i--) {
            rtn[n] = reversed[i];
            n++;
        }
    }
    return rtn;
}

const char *left_padding_with_zero(const char *input, size_t target) {
    char *buffer = (char *) calloc (BUFFER_SIZE, 1);
    size_t len = strlen (input);
    if (len >= target) {
        memcpy(buffer, (char *) input, sizeof (input));
        return buffer;
    }
    memset(buffer, '0', target - len);
    memcpy(buffer + target - len, input, strlen (input));
    return buffer;
}

