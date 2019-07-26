#!/usr/bin/env bash

INIT_DIR=$(pwd)
FILE_NAME=$(basename "$0"); ONLY_NAME=${FILE_NAME%.*}; LOG_FILE=/tmp/${ONLY_NAME}.log
CLONE_TO_DIR=
URL=

set -e
function cleanup {
	cd ${INIT_DIR} > /dev/null
}
trap cleanup EXIT

########################################
K_BR_GET="--branch-get"
K_TAGS_ALL="--tags-all"
K_PUSH_TO_REP="--push-to-rep"
K_BR_ALL="--branches-all"
K_BR_PULL_ALL="--branches-pull-all"
K_IGN_TOGZ="--ignored--to-gz"
K_MY_CMTS="--my-commits"
K_HLP="--help"
K_KWORDS="--keywords"
K_CLONE_TO="--clone-to"
K_CMPL_INS="--complete-install"
K_CMPL_UNINS="--complete-uninstall"
K_URL="--url"
ALL_KEYWORDS=("${K_BR_GET}" "${K_TAGS_ALL}" "${K_PUSH_TO_REP}=" "${K_BR_ALL}" "${K_BR_PULL_ALL}" "${K_IGN_TOGZ}" "${K_MY_CMTS}" "${K_KWORDS}" "${K_HLP}" "${K_CMPL_INS}" "${K_CMPL_UNINS}" "${K_CLONE_TO}=" "${K_URL}=")
########################################
showHelp() {
	cat << EOF
Usage: $(basename $0) <command>
Simple wrapper for git.

  ${K_BR_GET}           Get current branch
  ${K_TAGS_ALL}             List all tags
  ${K_PUSH_TO_REP}=URL      Add URL for the remote and push all
  ${K_BR_ALL}         List all branches
  ${K_BR_PULL_ALL}    Pull all remote branches
  ${K_IGN_TOGZ}       Pack ignored files to archive
  ${K_MY_CMTS}           Show user's commits ($(git config user.name))
  ${K_CLONE_TO}=PATH        Clone git repository with root directory PATH.
                         Expected argument ${K_URL}=URL with url to remote repository
  ${K_KWORDS}             Show available arguments
  ${K_CMPL_INS}     Configure auto completion for script
  ${K_CMPL_UNINS}   Remove auto completion for scrip
  ${K_HLP}                 Show this help and exit
EOF
}
########################################
get_current_branch() {
	git branch | grep \* | cut -d ' ' -f2
}
########################################
get_all_tags() {
	git log --tags --simplify-by-decoration --pretty="format:%ai %d" | grep "tag:"

}
########################################
push_to_rep() {
	URL=$1
	if [[ -z "$URL" ]]; then
		>&2 echo "Missing value URL"
		exit 1
	fi
	git remote set-url origin --add ${URL}
	git push -u origin --all
	git push -u origin --tags
}
########################################
get_all_branches() {
	git branch -r --format='%(authorname)|%(refname:short)|%(committerdate:iso)' | column -s\| -t
}
########################################
pull_all_branches() {
	git branch -r | grep -v '\->' | while read remote; do git branch --track "${remote#origin/}" "$remote"; done
	git fetch --all
	git pull --all
}
########################################
archive_ignored_files() {
	ARCHIVE_FILE_NAME=${PWD##*/}.tar.gz
	git ls-files --others --ignored --exclude-standard | tar -cf ${ARCHIVE_FILE_NAME} -I pigz -T -
	echo ${ARCHIVE_FILE_NAME}
}
########################################
show_my_commits() {
    git shortlog --author="$(git config user.name)"
}
########################################
show_keywords() {
	KEYWORDS=$(printf " %s" "${ALL_KEYWORDS[@]}")
	echo "${KEYWORDS:1}"
}
########################################
get_complete_file() {
	echo "/etc/bash_completion.d/${ONLY_NAME}"
}
########################################
complete_install() {
	FILE=$(get_complete_file)
	TMP_FILE=$(mktemp /tmp/${ONLY_NAME}.XXXXXX)
	echo '_git_tools()
{
  opts=$('$(realpath $0)' --keywords)
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
  return 0
}
complete -o nospace -F _git_tools '${FILE_NAME}'' > ${TMP_FILE}
    if [[ $(whoami) == "schumi" ]]; then
        echo "complete -o nospace -F _git_tools gt" >>"${TMP_FILE}"
    fi
	sudo mv ${TMP_FILE} ${FILE}
	sudo chown root:root ${FILE}
	sudo chmod 644 ${FILE}
}
########################################
complete_uninstall() {
	FILE=$(get_complete_file)
	sudo rm ${FILE}
}
clone_to() {
    DIR=$1
    URL=$2
    if [[ -z "${URL}" ]]; then
        2> echo "Missing argument --url=URL"
        exit 1
    fi
    if [[ ! -d "${DIR}" ]]; then
        2> echo "Directory ${CLONE_TO_DIR} doesn't exists."
        exit 1
	fi
	REP_DIR=$(basename "${URL}"); REP_DIR=${REP_DIR%.*};
	cd ${DIR}
	git clone ${URL} ${REP_DIR}
}
######################################## MAIN ########################################
if [[ "$@" == *"${K_HLP}"* ]] || [[ "$#" -eq 0 ]] ; then
	showHelp
	exit 0
fi

for arg in "$@"; do
	case ${arg} in
	    ${K_BR_GET})
	    	get_current_branch
	    	exit 0
	    	;;
	    ${K_TAGS_ALL})
	    	get_all_tags
	    	exit 0
	    	;;
	    ${K_PUSH_TO_REP}=*)
            	URL=${arg#*=}
            	push_to_rep ${URL}
            	exit 0
            	;;
	    ${K_BR_ALL})
	    	get_all_branches
	    	exit 0
	    	;;
	    ${K_BR_PULL_ALL})
		pull_all_branches
	    	exit 0
	    	;;
	    ${K_IGN_TOGZ})
	    	archive_ignored_files
	    	exit 0
	    	;;
            ${K_MY_CMTS})
	    	show_my_commits
	    	exit 0
	    	;;
	    ${K_KWORDS})
	    	show_keywords
	    	exit 0
	    	;;
	    ${K_CMPL_INS})
	    	complete_install
	    	exit 0
	    	;;
	    ${K_CMPL_UNINS})
	    	complete_uninstall
	    	exit 0
	    	;;
	    ${K_CLONE_TO}=*)
	        CLONE_TO_DIR=${arg#*=}
	    	;;
	    ${K_URL}=*)
	        URL=${arg#*=}
	        ;;
	    *)
	        >&2 echo "Unknown argument: $arg"
	        exit 1
	        ;;
	  esac
	done

if [[ -n "${CLONE_TO_DIR}" ]]; then
    clone_to ${CLONE_TO_DIR} ${URL}
    exit 0
fi