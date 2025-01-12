#!/bin/bash

# Exit on error
set -e

# json --> help
# json -h --> help
# json -H --> jq help
# json <file> --> error or query
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
    # '') echo "Error: missing option (-q or -u)" ;;
    '') query "$file" ;;
    -q) shift ; query "$file" "$@" ;;
    -u) shift ; update "$file" "$@" ;;
    -*) shift ; echo "$1: unknown option, use jq instead" ;;
     *) query "$file" "$@" ;;
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

# update(){

#   # Ensure sufficient arguments are provided for -u
#   if [ "$#" -lt 4 ]; then help ; exit 1 ; fi

#   tmp_file=$(mktemp)
#   json_file=$1
#   key=$2
#   shift 3;
#   val="$*"

#   # >&2 echo "update $json_file: set $key = '$val'"

#   # Ensure the file exists
#   [ ! -f "$json_file" ] && echo '{}' > "$json_file"

#   eval "jq '.$key = \"$val\"' $json_file > $tmp_file && mv $tmp_file $json_file"
# }

update() {
  # Ensure sufficient arguments are provided for -u
  if [ "$#" -lt 4 ]; then help ; exit 1 ; fi

  tmp_file=$(mktemp)
  json_file=$1
  key=$2
  shift 3
  val="$*"

  # Ensure the file exists
  [ ! -f "$json_file" ] && echo '{}' > "$json_file"

  # Determine the type of the value
  if [[ "$val" =~ ^[0-9]+$ ]]; then
    # Number
    jq ".$key = $val" "$json_file" > "$tmp_file"
  elif [[ "$val" =~ ^\[(.*)\]$ ]]; then
    # Array (must be in JSON format)
    jq --argjson val "$val" ".$key = \$val" "$json_file" > "$tmp_file"
  elif [[ "$val" =~ ^\{(.*)\}$ ]]; then
    # JSON Object (must be in JSON format)
    jq --argjson val "$val" ".$key = \$val" "$json_file" > "$tmp_file"
  elif [[ "$val" == "true" || "$val" == "false" ]]; then
    # Boolean
    jq ".$key = $val" "$json_file" > "$tmp_file"
  elif [[ "$val" == "null" ]]; then
    # Null
    jq ".$key = null" "$json_file" > "$tmp_file"
  else
    # String (default)
    jq ".$key = \"$val\"" "$json_file" > "$tmp_file"
  fi

  # Replace the original file with the updated one
  mv "$tmp_file" "$json_file"
}

delete() {
  :
}

main "$@"
