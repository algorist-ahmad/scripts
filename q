#!/bin/bash

QDB=$QDB
query=

while [[ $# -gt 0 ]]; do
  case "$1" in
    -db) QDB="$2" ; shift 2 ;;
    *) query+=" $1" ; shift ;;
  esac
done

[[ -z "$QDB" ]] && echo '$QDB not set' && exit 1
[[ ! -f "$QDB" ]] && echo "file $QDB not exists. Do QDB=/db/file.sqlite" && exit 2
[[ -z "$query" ]] && echo 'empty query' && exit 3

query=$(echo "$query" | sed -E 's/\bsel\b/select/g; s/\badd\b/insert/g; s/\bmod\b/update/g')
query=$(echo "$query" | sed -E 's/\ball\b/SELECT * FROM /g')
query=$(echo "$query" | xargs)

echo "\"$QDB\" '.mode tab' '.header on' \"$query\""
tsv=$(sqlite3 "$QDB" '.mode tab' '.header on' "$query")

# Extract the header and style it (bold + magenta + underline)
header=$(echo -e "$tsv" | head -n 1 | awk -F$'\t' '{for (i=1; i<=NF; i++) printf "\033[1;35;4m%s\033[0m\t", $i; print ""}')
# Extract the rest of the TSV data (without the header)
body=$(echo -e "$tsv" | tail -n +2)

# Combine the styled header with the body, then render
echo -e "$header\n$body" | column -t -s$'\t' | less --RAW-CONTROL-CHARS --chop-long-lines --shift=4 --quit-if-one-screen --no-init --tilde --LONG-PROMPT
