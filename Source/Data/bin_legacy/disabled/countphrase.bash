#!/bin/bash
(
for myph in $(awk '{print $1}' phrase.list); do 
    echo -n "$myph	"
    awk -F "$myph" '{s=s+NF-1}END{print s}' textpool.utf8
done ) > /tmp/phrase.occ
mv /tmp/phrase.occ .
