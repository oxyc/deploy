#!/bin/bash

__getRoot() {
  local file="wp-load.php"
  test -e "$PWD/$file" && echo "$PWD" && return
  getPath "$(upsearch "$file")"
}
CMS_CLI_CMD="wp --path=$(__getRoot)"

getDbCommand() {
  local string="$($CMS_CLI_CMD db connect)"
  echo "$string"
}
__getValue() {
  getDbCommand | awk "BEGIN { RS=\" \"; FS=\"=\"; } /--$1/ { print \$2; exit; }"
}

db_hostname=$(__getValue "host")
db_username=$(__getValue "user")
db_password=$(__getValue "password")
db_name=$(__getValue "database")

cms_version=$($CMS_CLI_CMD core version)
site_uri="http://default"
site_root=$(__getRoot)
site_path="wp-content"
file_path="wp-content/files_mf:wp-content/uploads"

out "
Wordpress Version: $cms_version
Site URI:          $site_uri
Site root:         $site_root
Site path:         $site_path
File dir path:     $file_path
DB connect:        $(getDbCommand)
"
