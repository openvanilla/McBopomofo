#!/bin/sh

# Initialze the git repository.
if [ ! -d .git ]; then
    git init -b master
fi
git checkout master

# Commit changed files.
git add .
PHRASE_TEXT=$1
git commit -m "Add ${PHRASE_TEXT}"

# Push to remote repository.
git pull --rebase origin master
git push origin master
