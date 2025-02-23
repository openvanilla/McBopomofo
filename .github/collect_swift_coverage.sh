#!/bin/bash

function convert_to_markdown_table() {
    local input="$1"

    echo "$input" | tr '-' '\n' | sed '/^$/d' | awk '
    BEGIN {
        table_border="| "
    }
    {
        if (NR == 1) {
            # Process the header, ensuring there is space between each column
            gsub(/  +/, " | ", $0)
            print table_border $0 " |"

            # Generate the separator line
            n = split($0, headers, /\|/)
            sep_line = "|"
            for (i = 1; i <= n; i++) {
                sep_line = sep_line " --- |"
            }
            print sep_line
        } else if ($0 !~ /^-+$/) {
            # Process data rows, ensuring there is space between each column
            gsub(/  +/, " | ", $0)
            print table_border $0 " |"
        }
    }'
}

XCTEST_PATH="$(find . -name '*.xctest')"

COMMENT_FILE="codecov_comment.md"

for path in $XCTEST_PATH; do
    filename=$(basename "$path")
    echo "## Test path: $filename" >>$COMMENT_FILE
    echo '' >>$COMMENT_FILE
    report=$(xcrun llvm-cov report ${path}/Contents/MacOS/*PackageTests -instr-profile ${path}/../codecov/default.profdata -ignore-filename-regex='.build/|Tests/')

    convert_to_markdown_table "$report" >>$COMMENT_FILE
    echo '' >>$COMMENT_FILE

done
