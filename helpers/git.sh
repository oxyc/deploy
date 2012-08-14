#!/bin/bash

getRemoteRepo() {
  echo "$(git remote -v | awk "/^$1/ { print \$2; exit; }")"
}
getRepoCheckout() {
  local path="$(getRemoteRepo "$1")"
  echo "${path/.git/}"
}

hasBranch() {
  [[ -n $(git branch | grep "^\([*| ]\) $1") ]]
}

hasRemote() {
  [[ -n $1 ]] && [[ -n $(git remote | grep "^$1") ]]
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

