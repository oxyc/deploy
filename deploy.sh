#!/bin/bash

getPath() {
  SOURCE=$1
  SCRIPT_DIR="$( dirname "$SOURCE" )"
  while [ -h "$SOURCE" ]; do 
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
    DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
  done
  echo "$( cd -P "$( dirname "$SOURCE" )" && pwd )"
}
SCRIPT_DIR="$(getPath ${BASH_SOURCE[0]})"
ORIG_DIR="$PWD"

# global var where scripts should run.
LOCAL_PATH="$ORIG_DIR"

CONFIG_FILE=".deploy-config"

# Allow environment variables
[[ -z $DEPLOY_ENV_STAGING ]] && DEPLOY_ENV_STAGING="/var/www/staging"
[[ -z $DEPLOY_ENV_USER ]] && DEPLOY_ENV_USER="/var/www/u"
[[ -z $DEPLOY_PROJECT_TYPES ]] && DEPLOY_PROJECT_TYPES=(drupal wordpress none)
[[ -z $DEPLOY_REPO_REMOTE ]] && DEPLOY_REPO_REMOTE="origin"

version="$0 v0.1"

# A list of all variables to prompt in interactive mode. These variables HAVE
# to be named exactly as the longname option definition in usage().
# interactive_opts=(username password)

# Print usage
usage() {
  echo -n "$0 [OPTION]... [command]

Deployment script.

 commands:
  init              Initialize a new project.
  build             Scaffold a new project within this project.
  deploy            Deploy the project
  stage             Stage the project
  db                Database tools
  ssh               Connect to remote through ssh
  lftp              Connect to remote through lftp
  sync              Sync tools
  status            Check project status
  scaffold          Scaffolding tools
  cli               Run the cms-specific cli command and delegate all arguments

 Options:
  -f, --force       Skip all user intercommand
  -i, --interactive Prompt for values
  -q, --quiet       Quiet (no output)
  -v, --verbose     Output more
  -h, --help        Display this help and exit
      --dry-run     Don't actually do anything
      --version     Output version information and exit
"
}

# Set a trap for cleaning up in case of errors or when script exits.
rollback() {
  cd "$ORIG_DEST"
  die "Unexpected failure a."
}

# Source the boilerplate stuff
source $SCRIPT_DIR/helpers/core.sh
source $SCRIPT_DIR/helpers/git.sh

# Functions {{{1

upsearch() {
  slashes=${PWD//[^\/]/}
  directory="$PWD"
  for (( n=${#slashes}; n>0; --n ))
  do
    test -e "$directory/$1" && echo "$(getPath "$directory/$1")/$1" && return
    directory="$directory/.."
  done
}

inArray() {
  [[ $(echo " ${@:2} " | grep -o " $1 ") ]]
}

isFunction() {
  type $1 | head -1 | egrep "^$1.*function\$" >/dev/null 2>&1;
  return;
}

getFirstParent() {
  local dir="$(dirname $1)"
  echo "${dir##*/}"
}

run_cmd() {
  eval "$CMS_CLI_CMD $@"
}

promptCreateDir() {
  local msg="$1"
  local dst="$2"
  [[ -d $dst ]] && return 0

  if confirm "$1: $dst"; then
    mkdir -p "$dst"
  else
    return 1
  fi
}

# }}}
# Parse flags {{{


while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; safe_exit ;;
    -V|--version) out "$version"; safe_exit ;;
    -v|--verbose) verbose=1 ;;
    -q|--quiet) quiet=1 ;;
    -i|--interactive) interactive=1 ;;
    -f|--force) force=1 ;;
    --dry-run) dry=1 ;;
    --endopts) shift; break ;;
    *) die "invalid option: $1" ;;
  esac
  shift
done

# Exit if no command is specifid
[[ $# -eq 0 ]] && { usage >&2; safe_exit; }

command=$1; shift
args+=("$@")

# }}}

# Scan parent directories for the config file.
config_path=$(upsearch "$CONFIG_FILE")
[[ -z $config_path ]] && die "Couldn't find a config file, are you within the correct path?"
source $config_path

# Make sure we're using a supported project type.
if ! inArray "$project" "${DEPLOY_PROJECT_TYPES[@]}"; then
  die "Invalid project type: $project\nKnown types: ${DEPLOY_PROJECT_TYPES[@]}"
fi

# Default application name to the parent directory of the config file
[[ -z $application ]] && application=$(getFirstParent "$config_path")
[[ -z $application ]] && die "Application name not specified."

# Default repository name to origin of current git working tree
[[ -z $repository ]] && repository="$(getRemoteRepo "$DEPLOY_REPO_REMOTE")"
[[ -z $repository ]] && die "Repository name not specified."

# Make sure the branch exists
[[ -z $branch ]] && die "You need to specify a branch."
if ! hasBranch "$branch"; then
  die "There is no $branch branch."
fi

log "Using settings:

Application:  $application
Repository:   $repository
Branch:       $branch
Project type: $project
"

# if ! confirm "Continue with these settings?" ]]; then
#   exit 0
# fi

case $project in
  drupal ) source $SCRIPT_DIR/projects/drupal.sh ;;
  wordpress ) source $SCRIPT_DIR/projects/wordpress.sh ;;
  none ) source $SCRIPT_DIR/projects/none.sh ;;
esac

# Delegate functionaliy {{{1

delegateCommand() {
  local file="$1"; shift
  set -- "$@"
  source $SCRIPT_DIR/commands/$file.sh
}

case $command in
  init|build|deploy|stage|db|ssh|lftp|sync|status|scaffold)
    delegateCommand "$command" "${args[@]}"
    ;;
  cli) run_cmd "${args[0]}" ;;
  *) die "invalid command: $command" ;;
esac


# }}}
