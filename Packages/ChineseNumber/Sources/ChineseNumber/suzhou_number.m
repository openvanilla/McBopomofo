#include <string.h>
#include <stdlib.h>
#include "trim_zero.h"

#define BUFFER_SIZE 80

struct suzhou_number_struct
{
    const char *int_part;
    size_t int_trimmed_zero_count;
    const char *dec_part;
};

static struct suzhou_number_struct build_struct(const char *int_part, const char *dec_part) {
    const char *initial_int_part = trim_zero (int_part, true);
    const char *initial_dec_part = trim_zero (dec_part, false);
    const char *trimmed_int_part = trim_zero (initial_int_part, false);
    size_t int_trimmed_zero_count = 0;
    if (!strlen (initial_dec_part)) {
        int_trimmed_zero_count = strlen (initial_int_part) - strlen (trimmed_int_part);
    } else {
        free ((void *) trimmed_int_part);
        trimmed_int_part = initial_int_part;
    }

    if (!strlen (trimmed_int_part)) {
        memcpy((void *) trimmed_int_part, (void *) "0", 2);
    }

    struct suzhou_number_struct rtn = {
            .int_part = trimmed_int_part,
            .int_trimmed_zero_count = int_trimmed_zero_count,
            .dec_part = initial_dec_part
    };
    return rtn;
}

const char *suzhou_number(const char *int_part, const char *dec_part, bool vertical_digit_at_start, const char *unit) {
    char *vertical_digits[10] = {
            "〇", "〡", "〢", "〣", "〤",
            "〥", "〦", "〧", "〨", "〩"
    };
    char *horizontal_digits[4] = {
            "〇", "一", "二", "三"
    };
    char *place_name[32] = {
            "", "十", "百", "千",
            "万", "十万", "百万", "千万",
            "億", "十億", "百億", "千億",
            "兆", "十兆", "百兆", "千兆",
            "京", "十京", "百京", "千京",
            "垓", "十垓", "百垓", "千垓",
            "秭", "十秭", "百秭", "千秭",
            "穰", "十穰", "百穰", "千穰",
    };
    struct suzhou_number_struct data = build_struct (int_part, dec_part);
    char *output = calloc (1024, 1);
    memset((void *) output, 0, BUFFER_SIZE);
    char joined[BUFFER_SIZE] = "";
    strcat(joined, data.int_part);
    strcat(joined, data.dec_part);

    bool use_vertical = vertical_digit_at_start;
    size_t code_point_count = 0;
    for (size_t i = 0; i < strlen (joined); i++) {
        char c = (char) (joined[i] - '0');
        if (c >= 1 && c <= 3) {
            if (use_vertical) {
                use_vertical = false;
                strcat(output, vertical_digits[c]);
                code_point_count++;
            } else {
                use_vertical = true;
                strcat(output, horizontal_digits[c]);
                code_point_count++;
            }
        } else {
            use_vertical = vertical_digit_at_start;
            strcat(output, vertical_digits[c]);
            code_point_count++;
        }
    }

    if (code_point_count < 2 && data.int_trimmed_zero_count == 0) {
        strcat(output, unit);
    } else if (code_point_count < 2 && data.int_trimmed_zero_count == 1 && data.int_part[0] <= '3') {
        memset((void *) output, 0, sizeof (output));
        switch (data.int_part[0]) {
            case '1':
                strcat(output, "〸");
                break;
            case '2':
                strcat(output, "〹");
                break;
            case '3':
                strcat(output, "〺");
                break;
            default:
                break;
        }
        strcat(output, unit);
    } else {
        strcat(output, "\n");
        size_t place = strlen (data.int_part) - 1 + data.int_trimmed_zero_count;
        strcat(output, place_name[place]);
        strcat(output, unit);
    }
    free ((void *) data.int_part);
    free ((void *) data.dec_part);
    return output;
}
