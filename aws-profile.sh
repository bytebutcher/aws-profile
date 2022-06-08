#!/bin/bash
# ##################################################
# NAME:
#   AWS Profile
# DESCRIPTION:
#   Allows to manage multiple aws user profiles.
# AUTHOR:
#   bytebutcher
# ##################################################

VERSION="1.1.0"

function usage() {
	echo "AWS Profile allows to manage multiple aws user profiles." >&2
	echo ""                                                         >&2
	echo "Usage:"                                                   >&2
	echo "  aws-profile [command]"                                  >&2
	echo ""                                                         >&2
	echo "Available Commands:"                                      >&2
	echo "  add      Add an entry to a profile"                     >&2
	echo "  use      Use a profile"                                 >&2
	echo "  current  Show information about the current profile"    >&2
	echo "  show     Show information about a profile"              >&2
	echo "  list     List profiles"                                 >&2 
	echo "  remove   Remove a profile"                              >&2 
	echo "  update   Update a profile"                              >&2 
	echo "  reload   Reload profile"                                >&2
	echo "  version  Print version number of AWS Profile"           >&2
	echo "  help     Shows this help"                               >&2
	echo ""                                                         >&2
	exit 1
}


function print_info() {
    local message="${1}"
    echo -e "\e[01;32m[ INFO] \e[0m${message}" >&2;
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

function remove_toml_section() {
	local section="${1}"
	local file="${2}"
	while read line; do 
		if [[ $line == "[${section}]" ]]; then 
			ignore=1
			continue 
		fi
		if [[ "$line" =~ ^\[[A-Za-z]+\]$ ]] ; then 
			ignore=0 
		fi
		if [[ $ignore == 1 ]]; then 
			continue
		else 
			echo "${line}"
		fi; 
	done< <(cat "${file}")
}

function aws_require_profile_argument() {
	local profile="${1}"
	if [ -z "${profile}" ] ; then
		print_error "No profile name specified!"
		usage
		exit 1
	fi
}

function aws_require_profile_not_exists() {
	local profile="${1}"
	aws_require_profile_argument "${profile}"
	if aws configure list-profiles | grep -e "^${profile}$" > /dev/null; then 
		print_error "The profile named '${profile}' already exists!"
		exit 1
	fi
}

function aws_require_profile_exists() {
	local profile="${1}"
	aws_require_profile_argument "${profile}"
	if ! aws configure list-profiles | grep -e "^${profile}$" > /dev/null; then 
		print_error "The profile named '${profile}' does not exist!"
		exit 1
	fi
}

function aws_delete_profile() {
	local profile="${1}"
	aws_config_file="${HOME}/.aws/config"
	aws_credentials_file="${HOME}/.aws/credentials"
	if ! [ -f "${aws_config_file}" ] ; then
		print_error "Could not find aws config file at ${aws_config_file}!"
		exit 1
	fi
	if ! [ -f "${aws_credentials_file}" ] ; then
		print_error "Could not find aws config file at ${aws_credentials_file}!"
		exit 1
	fi
	remove_toml_section "profile ${profile}" "${aws_config_file}" > "${aws_config_file}.bak"
	mv "${aws_config_file}.bak" "${aws_config_file}"
	
	remove_toml_section "${profile}" "${aws_credentials_file}" > "${aws_credentials_file}.bak"
	mv "${aws_credentials_file}.bak" "${aws_credentials_file}"
	
	print_info "Successfully removed profile ${profile}!"
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
			aws_require_profile_not_exists "${profile}"
			# Add aws profile.
			aws configure --profile "${profile}"
			# Use aws profile right away after creation.
			echo "export AWS_PROFILE=${profile}"
			exit
			;;
		list | ls )		   
			# List aws profiles.
			aws configure list-profiles
			exit 0
			;;
		use )
			shift
			profile="${1}"
			aws_require_profile_exists "${profile}"
			# Use aws profile.
			echo "export AWS_PROFILE=${profile}"
			exit 0
			;;
		delete | remove | rm )
			shift
			profile="${1}"
			aws_require_profile_exists "${profile}"
			# At the moment there is no aws configure built-in function to
			# remove a profile.
			aws_delete_profile "${profile}"
			exit 0
			;;
		update )
			shift
			profile="${1}"
			aws_require_profile_exists "${profile}"
			# Update aws profile.
			aws configure --profile "${profile}"
			# Use aws profile right away after creation.
			echo "export AWS_PROFILE=${profile}"
			exit
			;;
		reload )
			# This function is implemented in ~/.aws-profile.bash.
			exit 0
			;;
		current )
			# Show currently active aws profile.
			aws configure list
			exit 0
			;;
		show )
			shift
			profile="${1}"
			aws_require_profile_exists "${profile}"
			# Show specified aws profile.
			aws configure list --profile "${profile}"
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
