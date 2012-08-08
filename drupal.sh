#!/bin/bash

CMS_CLI_CMD="drush"
drush_status="$($CMS_CLI_CMD core-status --show-passwords)"

__getValue() {
  echo "$drush_status" | awk -F ' : ' "/^ $1/ { gsub(/ /, \"\", \$2); print \$2; exit; }"
}

cms_version=$(__getValue "Drupal version")
site_uri=$(__getValue "Site URI")
site_root=$(__getValue "Drupal root")
site_path=$(__getValue "Site path")
file_path=$(__getValue "File directory path")

db_hostname=$(__getValue "Database hostname")
db_username=$(__getValue "Database username")
db_password=$(__getValue "Database password")
db_name=$(__getValue "Database name")

# Return all db information separated with a whitespace
getDbCommand() {
  echo "mysql --host=$db_hostname --user=$db_username --password=$db_password --database=$db_name"
}

out "
Drupal Version: $cms_version
Site URI:       $site_uri
Site root:      $site_root
Site path:      $site_path
File dir path:  $file_path
DB connect:     $(getDbCommand)
"
