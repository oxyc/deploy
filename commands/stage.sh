#!/bin/bash
source $SCRIPT_DIR/helpers/deployment.sh

hasStaging() {
  [[ -d $DELPOY_ENV_STAGING/$1 ]]
}

addStaging() {
  local repo=$1; shift
  local path=$2

  if [[ ! $path ]] || [[ ! -d $path ]]; then
    path="$DEPLOY_ENV_STAGING/$repo"
  else
    # Path was specified, shift it off the parameters so one can pass flags.
    shift
  fi

  ! isGit "$path" && die "Staging area isnt a git repository: $path"

  addRemote $repo $path "$@"
  notify "Added staging area $repo at $path"
}

stage() {
  local src="$site_root"
  local staging_path="$DEPLOY_ENV_STAGING/$application"

  [[ ! -d $src ]] && die "Source doesn't exist: $1"

  LOCAL_PATH="$src"

  # Stage exists, push to ti
  if hasRemote "$remote_staging"; then
    pushRemote "$remote_staging" "$@"
    notify "Pushed to staging area"

  # Staging area exists but is not connected with this repo
  elif hasStaging "$application" && confirm "Do you want to add as staging area: $staging_path"; then
    addStaging "$remote_staging" "$@"

  # Prompt whether to create the default application stage
  else
    promptCreateDir "Do you want to create destination" "$staging_path" || die "Exiting"

    die "Missing integration"

    pushRemote "$DEPLOY_ENV_STAGING/$application" "$@"
  fi
}

[[ ! $1 ]] && stage
action=$1; shift
#args+=("$@")

case $action in
  create) createStaging "$@" ;;
  add) addStaging "$@" ;;
  *) stage "$action" "$@" ;;
esac
