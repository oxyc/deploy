#!/bin/bash

runCmd() {
  [[ ! -d $LOCAL_PATH/.git ]] && die "This is not a git repository: $LOCAL_PATH"
  cd "$LOCAL_PATH"
  log "Running: $@"
  (( ! $dry )) && eval "$@"
  cd "$ORIG_DEST"
}

getRemoteRepo() {
  echo "$(git remote -v | awk "/^$1/ { print \$2; exit; }")"
}

hasBranch() {
  [[ -n $(git branch | grep "^\([*| ]\) $1") ]]
}

hasRemote() {
  [[ -n $(git remote | grep "^$1") ]]
}

isGit() {
  [[ -d "$1/.git" ]] || [[ -e "$1/HEAD" ]]
}

pushRemote() {
  runCmd "git push $@"
}

addRemote() {
  runCmd "git remote add $@"
}

