#!/bin/bash

for i in {1..15}
do
  diff_output=$(git diff --name-only HEAD~$i..HEAD -- .github/)

  if [ -n "$diff_output" ]; then
    echo "===== Commits in range HEAD~$i..HEAD ====="
    git log --oneline HEAD~$i..HEAD -- .github/
    echo "--- Modified files in .github/ ---"
    echo "$diff_output"
    echo
  fi
done
