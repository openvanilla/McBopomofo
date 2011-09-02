#!/bin/bash
(
for myph in $(awk '{print $1}' 1-4w.list); do 
    echo -n "$myph	"
    awk -F "$myph" '{s=s+NF-1}END{print s}' textpool.utf8
done ) > /tmp/1-4w.occ
mv /tmp/1-4w.occ .
