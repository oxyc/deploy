#!/bin/bash

__getRoot() {
  local file="wp-load.php"
  test -e "$PWD/$file" && echo "$PWD" && return
  getPath "$(upsearch "$file")"
}
CMS_CLI_CMD="wp --path=$(__getRoot)"
[[ -n $wp_blog ]] && CMS_CLI_CMD="$CMS_CLI_CMD --blog=$wp_blog"

# This has tun first so we can set the appropiate blog argument to wp cli.
site_root=$(__getRoot)
[[ -z $wp_blog ]] && CMS_CLI_CMD="$CMS_CLI_CMD --blog=$(getURI $site_root)"

wp_db_connect_string="$($CMS_CLI_CMD db connect)"
[[ -z $wp_db_connect_string ]] && die "Could not get a database connect string from wp cli"
if (($(echo "$wp_db_connect_string" | wc -l) > 1)); then
  log "$wp_db_connect_string"
  log "Ran $CMS_CLI_CMD"
  die "Could not generate a database connection string."
fi

getDbCommand() {
  echo "$wp_db_connect_string"
}

__getValue() {
  echo $wp_db_connect_string | awk "BEGIN { RS=\" \"; FS=\"=\"; } /--$1/ { print \$2; exit; }"
}

site_uri="http://$(getURI $site_root)"
db_hostname=$(__getValue "host")
db_username=$(__getValue "user")
db_password=$(__getValue "password")
db_name=$(__getValue "database")

cms_version=$($CMS_CLI_CMD core version)
site_path="wp-content"
file_path="wp-content/files_mf:wp-content/uploads"

log "
Wordpress Version: $cms_version
Site URI:          $site_uri
Site root:         $site_root
Site path:         $site_path
File dir path:     $file_path
DB connect:        $(getDbCommand)
"
