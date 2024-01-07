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

const char *compose_part(const char *input,
        bool need_to_handle_zeros_at_start,
        bool waiting_for_zero_at_start,
        bool use_formal) {
    char *buffer = (char *) calloc (BUFFER_SIZE, 1);
    bool waiting_for_zero = waiting_for_zero_at_start;
    bool should_handle_zero_on_next_digit = need_to_handle_zeros_at_start;

    // 0 千 1 百 2 十 3 個
    for (int i = 0; i < 4; i++) {
        char c = input[i];
        if (c == '0') {
            // It is zero, just skip it. But we should add this
            // zero to the output when there is another non-zero
            // digit is coming.
            waiting_for_zero = true;
        } else {
            if (waiting_for_zero && should_handle_zero_on_next_digit) {
                strcat(buffer, use_formal ? upper_digits[0] : lower_digits[0]);
            }
            should_handle_zero_on_next_digit = true;
            waiting_for_zero = false;
            strcat(buffer, use_formal ? upper_digits[c - '0'] : lower_digits[c - '0']);
            strcat(buffer, use_formal ? upper_place[i] : lower_place[i]);
        }
    }

    return buffer;
}

const char *chinese_number(const char *int_part, const char *dec_part, bool use_formal) {
    const char *int_n = trim_zero (int_part, true);
    const char *dec_n = trim_zero (dec_part, false);

    size_t sec_count = (strlen (int_n) / 4);
    if (strlen (int_n) % 4 != 0) {
        sec_count++;
    }
    size_t target = sec_count * 4;
    const char *filled = left_padding_with_zero (int_n, target);
    char *str = calloc (2048, 1);
    size_t i = 0;
    bool need_to_compose_zero = false;
    while (i < strlen (filled)) {
        char part[5] = "";
        strncpy(part, filled + i, 4);
        if (part[0] == '0' && part[1] == '0' && part[2] == '0' && part[3] == '0') {
            i += 4;
            need_to_compose_zero = true;
            continue;
        }

        char *converted = (char *) compose_part (part, i > 0, need_to_compose_zero, use_formal);
        need_to_compose_zero = false;
        strcat(str, (const char *) converted);
        free ((void *) converted);
        strcat(str, (const char *) place_w[(strlen (filled) - i) / 4 - 1]);
        i += 4;
    }

    if (!strlen (str)) {
        strcat(str, use_formal ? upper_digits[0] : lower_digits[0]);
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
