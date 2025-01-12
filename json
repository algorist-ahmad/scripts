#!/bin/bash

# Exit on error
set -e

# json --> help
# json -h --> help
# json -H --> jq help
# json <file> --> error
# json -q --> error
# json -u --> error
# json / --> pass to jq
# json <file> -q --> query
# json <file> -q <query> --> query <query>
# json <file> -u --> error
# json <file> -u key  --> error
# json <file> -u key =  --> error
# json <file> -u key = values  --> update


main() {
  case "$1" in
    '') help ;;
    -h) shift ; help ;;
    -H) shift ; jq --help ; exit 0 ;;
     /) shift ; jq "$@" ; exit $? ;;
    -q) shift ; echo "Error: missing file (json <file> -q)" ; exit 1 ;;
    -u) shift ; echo "Error: missing file (json <file> -u)" ; exit 1 ;;
  esac

  file="$1"
  shift
  
  case "$1" in
    '') echo "Error: missing option (-q or -u)" ;;
    -q) shift ; query "$file" "$@" ;;
    -u) shift ; update "$file" "$@" ;;
     *) echo "$1: unknown option, use jq instead"
  esac
}

help() {
  echo "Synopsis:"
  echo "  json <file> -q <query>           Queries a file"
  echo "  json <file> -u <key> = <value>   Update a key in a JSON file with a new value"
  echo "  json -h                          Display short help"
  echo "  json -H                          Get real help"
  exit 0
}

query() {
  file="$1"
  shift
  query=".$@"
  [[ -z "$query" ]] && query='.'
  jq -r $query $file
}

update(){

  # Ensure sufficient arguments are provided for -u
  if [ "$#" -lt 4 ]; then help ; exit 1 ; fi

  tmp_file=$(mktemp)
  json_file=$1
  key=$2
  shift 3;
  val="$*"

  echo "update $json_file: set $key = '$val'"

  # Ensure the file exists
  if [ ! -f "$json_file" ]; then
    echo "Error: File '$json_file' not found!"
    exit 1
  fi

  eval "jq '.$key = \"$val\"' $json_file > $tmp_file && mv $tmp_file $json_file"
}

delete() {
  :
}

main "$@"
