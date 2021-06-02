#!/bin/bash
# ##################################################
# NAME:
#   AWS Profile
# DESCRIPTION:
#   Allows to add and switch between multiple user profiles.
# AUTHOR:
#   bytebutcher
# ##################################################

VERSION="1.0.0"

function usage() {
	echo "AWS Profile allows to add and switch between multiple"    >&2
	echo "user profiles."                                           >&2
	echo ""                                                         >&2
	echo "Usage:"                                                   >&2
	echo "  aws-profile [command]"                                  >&2
	echo ""                                                         >&2
	echo "Available Commands:"                                      >&2
	echo "  add      Add an entry to a profile"                     >&2
	echo "  help     Shows this help"                               >&2
	echo "  ls       List profiles"                                 >&2 
	echo "  reload   Reload profile"                                >&2
	echo "  status   Show information about the current profile"    >&2
	echo "  use      Use a profile"                                 >&2
	echo "  version  Print version number of AWS Profile"           >&2
	echo ""                                                         >&2
	exit 1
}

function print_error() {
    local message="${1}"
    echo -e "\e[01;31m[ERROR] \e[0m${message}" >&2;
}

function do_require() {
	local required_command="${1}"
	command -v "${required_command}" >/dev/null 2>&1 || {
		print_error "Require ${required_command} but it's not installed. Aborting."
		exit 1;
	}
}

# Make sure that the aws-cli is installed
do_require "aws"

# Assert that aws-cli version is at least 2.0
if ! [[ "$(aws --version)" =~ ^aws-cli/2.* ]] ; then
	print_error "Require aws in version 2 but other version is installed. Aborting."
	exit 1
fi	

# Show usage if no parameter was specified
if [ $# -eq 0 ] ; then
	usage
	exit 1
fi

while [ "$1" != "" ]; do
	case $1 in
		add )
			shift
			profile="${1}"
			if [ -z "${profile}" ] ; then
				print_error "No profile name specified!"
				usage
				exit 1
			fi
			if aws configure list-profiles | grep -e "^${profile}$" > /dev/null; then 
				print_error "The profile named '${profile}' already exists!"
				exit 1
			fi
			aws configure --profile "${profile}"
			exit
			;;
		ls )		   
			aws configure list-profiles
			exit 0
			;;
		use )
			shift
			profile="${1}"
			if [ -z "${profile}" ] ; then
				print_error "No profile name specified!"
				usage
				exit 1
			fi
			if ! aws configure list-profiles | grep -e "^${profile}$" > /dev/null; then 
				print_error "There is no profile named '${profile}'!"
				exit 1
			fi
			echo "export AWS_PROFILE=${profile}"
			exit 0
			;;
		reload )
			# This function is implemented in ~/.aws-profile.bash
			exit 0
			;;
		status )
			aws configure list
			exit 0
			;;
		help )
 			usage
			exit 0
			;;
		version )
			echo "AWS Profile"
			echo "Version: ${VERSION}"
			exit 0
			;;
		* )
			usage
			exit 1
	esac
	shift
done
