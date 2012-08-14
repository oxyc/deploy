#!/bin/bash

isDatabase() {
  test -d "$DEPLOY_MYSQL_DIR/$1"
}

getDumpCommand() {
  echo "mysqldump --host=$db_hostname --user=$db_username --password=$db_password $db_name"
}

createRootDump() {
  local db="$1"
  if isDatabase "$db"; then
    die "Database doesn't exist: $db"
  fi
  sudo mysqldump -uroot -pmuxzjryh $db
}

importRootDump() {
  local db="$1"
  local file="$2"
  if isDatabase "$db"; then
    die "Database doesn't exist: $db"
  fi
  [[ ! -e $file ]] && die "Cant read dump: $file"
  sudo mysql -uroot -pmuxzjryh "$db" < $file
}

getRootDbCommand() {
  echo "mysql -uroot -pmuxzjryh"
}



createDump() {
  local dump_cmd="$(getDumpCommand)"
  [[ -n $1 ]] && local dest="$1" || local dest="$(mktemp)"
  runCmd "$dump_cmd > $dest"
  echo $dest
}

importDump() {
  local file="$1"
  [[ ! -e $file ]] && die "Can't find dump: $file"
  runCmd "$(getDbCommand) < $file"
}

#[[ ! $1 ]] && createDump
action=$1; shift
#args+=("$@")

case $action in
  dump) createDump "$@" ;;
  import) importDump "$@" ;;
  root-dump) createRootDump "$@" ;;
  root-import) importRootDump "$@" ;;
  cli) eval "$getDbCommand" ;;
esac
