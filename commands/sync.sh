#!/bin/bash

normalizeURI() {
  local domain="$(escapeSearch "$1")"
  local replace="$(escapeReplace "$2")"
  local file="$3"

  sed -i -e "s/$domain.[^.]*.$DEPLOY_DEV_DOMAIN/$replace/g" $file
  log "Running: sed -i -e \"s/$domain.[^.]*.$DEPLOY_DEV_DOMAIN/$replace/g\" $file"
}

syncDb() {
  # Default source to current site root
  if [[ -n $2 ]]; then
    local src="$1"
    local dest="$2"
  else
    local src="$site_root"
    local dest="$1"
  fi

  if inArray "$src" "this" "self" "local"; then
    src="$site_root"
  fi
  if inArray "$dest" "this" "self" "local"; then
    dest="$site_root"
  fi
  [[ -z $dest ]] && die "You did not specify a destination"

  # If source is specified as a git remote get the checkout path
  if hasRemote "$src"; then
    src="$(getRepoCheckout "$src")"
  fi
  [[ ! -d $src ]] && die "Not a git repository: $src"

  if hasRemote "$dest"; then
    dest="$(getRepoCheckout "$dest")"
  fi
  [[ ! -d $dest ]] && die "Not a git repository: $dest"

  log "Using:
  source:      $src
  destination: $dest
  "

  local tmp=
  source $SCRIPT_DIR/commands/db.sh

  # There's a deploy config, use it
  if [[ -e $src/$CONFIG_FILE ]] && [[ -d $src/.git ]]; then
    cd $src
    tmp=$(deploy db dump)

  elif [[ -n $staging_db_name ]]; then
    if confirm "Do you want to use $staging_db_name (staging db) as database source?"; then
      tmp=$(mktemp)
      createRootDump "$staging_db_name" > $tmp
    fi
  else
    die "Can not retrieve a source database"
  fi

  if isFunction "onSyncDump"; then
    log "Running hook: onSyncDump"
    onSyncDump "$tmp" "$src" "$dest"
  fi

  if [[ -e $dest/$CONFIG_FILE ]] && [[ -d $dest/.git ]]; then
    cd $dest
    log "Running: deploy db import $tmp"
    (( ! $dry )) && deploy -v db import "$tmp"
  elif [[ -n $staging_db_name ]]; then
    if confirm "Do you want to use $staging_db_name (staging db) as database destination?"; then
      [[ ! -e $tmp ]] && die "There is no database dump to import"
      log "Running sudo version of import $tmp into $staging_db_name"

      (( ! $dry )) && importRootDump "$staging_db_name" "$tmp"
    fi
  else
    rm -f $tmp
    die "Can not retrieve a destination database"
  fi
  rm -f $tmp
}

action=$1; shift

case $action in
  db) syncDb "$@" ;;
esac
