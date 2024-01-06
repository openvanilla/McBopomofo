#include <string.h>
#include <stdlib.h>
#include "trim_zero.h"

#define BUFFER_SIZE 80

static char *lower_digits[10] = {"〇", "一", "二", "三", "四",
        "五", "六", "七", "八", "九"};
static char *upper_digits[10] = {"零", "壹", "貳", "參", "肆",
        "伍", "陸", "柒", "捌", "玖"};
static char *lower_place[4] = {"千", "百", "十", ""};
static char *upper_place[4] = {"仟", "佰", "拾", ""};
static char *place_w[10] = {"", "萬", "億", "兆", "京", "垓", "秭", "穰"};

const char *compose_part(const char *input, bool need_padding, bool use_formal) {
    char *buffer = (char *) calloc (BUFFER_SIZE, 1);
    bool wait_for_padding = false;
    bool should_do_padding = need_padding;

    for (int i = 0; i < 4; i++) {
        char c = input[i];
        if (c == '0') {
            wait_for_padding = true;
        } else {
            if (wait_for_padding && should_do_padding) {
                strcat(buffer, use_formal ? upper_digits[0] : lower_digits[0]);
                wait_for_padding = false;
            }
            should_do_padding = true;
            strcat(buffer, use_formal ? upper_digits[c - '0'] : lower_digits[c - '0']);
            strcat(buffer, use_formal ? upper_place[i] : lower_place[i]);
        }
    }

    return buffer;
}

const char *chinese_number(const char *int_part, const char *dec_part, bool use_formal, const char *unit) {
    const char *int_n = trim_zero (int_part, true);
    const char *dec_n = trim_zero (dec_part, false);

    size_t sec_count = (strlen (int_n) / 4);
    if (strlen (int_n) % 4 != 0) {
        sec_count++;
    }
    const char *filled = left_padding_with_zero (int_n, sec_count * 4);
    char *str = calloc (1024, 1);

    size_t i = 0;
    while (i < strlen (filled)) {
        char part[5] = "";
        strncpy(part, filled + i, 4);
        char *converted = (char *) compose_part (part, i > 0, use_formal);
        strcat(str, (const char *) converted);
        free ((void *) converted);
        strcat(str, (const char *) place_w[(strlen (filled) - i) / 4 - 1]);
        i += 4;
    }

    if (strlen (dec_n)) {
        strcat(str, "點");
        for (size_t i = 0; i < strlen (dec_n); i++) {
            char c = dec_n[i];
            strcat(str, use_formal ? upper_digits[c - '0'] : lower_digits[c - '0']);
        }
    }


    free ((void *) int_n);
    free ((void *) dec_n);
    free ((void *) filled);

    return str;
}
