#include <string.h>
#include <stdlib.h>
#include "trim_zero.h"

#define BUFFER_SIZE 80

static char *lower_digits[10] = {"〇", "一", "二", "三", "四",
        "五", "六", "七", "八", "九"};
static char *upper_digits[10] = {"零", "壹", "貳", "參", "肆",
        "伍", "陸", "柒", "捌", "玖"};
static char *lower_places[4] = {"千", "百", "十", ""};
static char *upper_places[4] = {"仟", "佰", "拾", ""};
static char *higher_place_names[10] = {"", "萬", "億", "兆", "京", "垓", "秭", "穰"};

const char *convert_4_four_digits_to_chinese(const char *input,
        bool skip_initial_zeros,
        bool zero_already_happened,
        bool is_uppercase) {
    char *buffer = (char *) calloc (BUFFER_SIZE, 1);
    bool zero_happened = zero_already_happened;
    bool handle_zero_on_next_digit = !skip_initial_zeros;

    // 0 千 1 百 2 十 3 個
    for (int i = 0; i < 4; i++) {
        char c = input[i];
        if (c == '0') {
            // It is zero, just skip it. But we should add this
            // zero to the output when there is another non-zero
            // digit is coming.
            zero_happened = true;
        } else {
            if (zero_happened && handle_zero_on_next_digit) {
                strcat(buffer, is_uppercase ? upper_digits[0] : lower_digits[0]);
            }
            handle_zero_on_next_digit = true;
            zero_happened = false;
            strcat(buffer, is_uppercase ? upper_digits[c - '0'] : lower_digits[c - '0']);
            strcat(buffer, is_uppercase ? upper_places[i] : lower_places[i]);
        }
    }

    return buffer;
}

const char *chinese_number(const char *int_part, const char *dec_part, bool use_formal) {
    const char *trimmed_int_part = trim_zero (int_part, true);
    const char *trimmed_dec_part = trim_zero (dec_part, false);

    size_t four_digits_sets_count = (strlen (trimmed_int_part) / 4);
    if (strlen (trimmed_int_part) % 4 != 0) {
        four_digits_sets_count++;
    }
    size_t filled_length = four_digits_sets_count * 4;
    const char *filled_int_part = left_padding_with_zero (trimmed_int_part, filled_length);
    char *output = calloc (2048, 1);
    size_t i = 0;
    bool zero_happened = false;
    while (i < strlen (filled_int_part)) {
        char part[5] = "";
        strncpy(part, filled_int_part + i, 4);
        if (part[0] == '0' && part[1] == '0' && part[2] == '0' && part[3] == '0') {
            i += 4;
            zero_happened = true;
            continue;
        }

        char *converted = (char *) convert_4_four_digits_to_chinese (part, i == 0, zero_happened, use_formal);
        zero_happened = false;
        strcat(output, (const char *) converted);
        free ((void *) converted);
        strcat(output, (const char *) higher_place_names[(strlen (filled_int_part) - i) / 4 - 1]);
        i += 4;
    }

    if (!strlen (output)) {
        strcat(output, use_formal ? upper_digits[0] : lower_digits[0]);
    }

    if (strlen (trimmed_dec_part)) {
        strcat(output, "點");
        for (size_t i = 0; i < strlen (trimmed_dec_part); i++) {
            char c = trimmed_dec_part[i];
            strcat(output, use_formal ? upper_digits[c - '0'] : lower_digits[c - '0']);
        }
    }

    free ((void *) trimmed_int_part);
    free ((void *) trimmed_dec_part);
    free ((void *) filled_int_part);

    return output;
}
