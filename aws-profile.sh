#!/bin/bash
# ##################################################
# NAME:
#   AWS Profile
# DESCRIPTION:
#   Allows to manage multiple aws user profiles.
# AUTHOR:
#   bytebutcher
# ##################################################

VERSION="1.4.0"

function usage() {
	echo "AWS Profile allows to manage multiple aws user profiles." >&2
	echo ""                                                         >&2
	echo "Usage:"                                                   >&2
	echo "  aws-profile [command]"                                  >&2
	echo ""                                                         >&2
	echo "Available Commands:"                                      >&2
	echo "  add      Add a profile"                                 >&2
	echo "  current  Show information about the current profile"    >&2
	echo "  export   Prints access key id and secret access key"    >&2
	echo "  help     Shows this help"                               >&2
	echo "  list     List profiles"                                 >&2 
	echo "  reload   Reload a profile"                              >&2
	echo "  remove   Remove a profile"                              >&2 
	echo "  show     Show information about a profile"              >&2
	echo "  update   Update a profile"                              >&2 
	echo "  use      Use a profile"                                 >&2
	echo "  version  Print version number of AWS Profile"           >&2
	echo ""                                                         >&2
	return 1
}


function print_info() {
    local message="${1}"
    echo -e "\e[01;32m[ INFO] \e[0m${message}" >&2;
}

function print_error() {
    local message="${1}"
    echo -e "\e[01;31m[ERROR] \e[0m${message}" >&2;
}

function do_require_command() {
	local required_command="${1}"
	command -v "${required_command}" >/dev/null 2>&1 || {
		print_error "Require ${required_command} but it's not installed. Aborting."
		exit 1;
	}
}

function do_require_file() {
	local file="${1}"
	if ! [ -f "${file}" ] ; then
		print_error "Could not find ${file}!"
		exit 1
	fi
	echo "${file}"
}

function do_require_aws_config_file() {
	do_require_file "${HOME}/.aws/config"
}

function do_require_aws_credentials_file() {
	do_require_file "${HOME}/.aws/credentials"
}

function remove_toml_section() {
	local section="${1}"
	local aws_credentials_file="$(do_require_aws_credentials_file)"
	local ignore=0
	while read line; do 
		if [[ "${line}" == "[${section}]" ]]; then 
			ignore=1
			continue 
		elif [[ "${line}" =~ ^\[[A-Za-z]+\]$ ]] ; then 
			ignore=0 
		fi
		if [[ ${ignore} == 1 ]]; then 
			continue
		else 
			echo "${line}"
		fi; 
	done< <(cat "${aws_credentials_file}")
}

function get_toml_section_value() {
	local section="${1}"
	local key="${2}"
	local aws_credentials_file="$(do_require_aws_credentials_file)"
	local section_found=false
	while read line; do
		if [[ ${line} == "[${section}]" ]] ; then
			section_found=true
			continue
		fi
		if [[ "${line}" =~ ^\[[A-Za-z]+\]$ ]] ; then
                        section_found=false
                fi
		if [[ ${section_found} == true ]] ; then
			_key=$(echo ${line} | awk -F' = ' '{ print $1 }')
			_value=$(echo ${line} | awk -F' = ' '{ print $2 }')
			if [[ "${_key}" == "${key}" ]] ; then
				echo "${_value}"
				break
			fi
		fi
	done< <(cat "${aws_credentials_file}")
}

function do_require_aws_profile_argument() {
	local profile="${1}"
	if [ -z "${profile}" ] ; then
		usage
		print_error "No profile name specified!"
		exit 1
	fi
}

function do_require_aws_profile_not_exists() {
	local profile="${1}"
	if aws configure list-profiles | grep -e "^${profile}$" > /dev/null; then 
		print_error "The profile named '${profile}' already exists!"
		exit 1
	fi
}

function do_require_aws_profile_exists() {
	local profile="${1}"
	if ! aws configure list-profiles | grep -e "^${profile}$" > /dev/null; then 
		print_error "The profile named '${profile}' does not exist!"
		exit 1
	fi
}

function aws_get_profile() {
	local profile="${1}"
	if [ -z "${profile}" ] && [ -n "${AWS_PROFILE}" ] ; then
		# If no profile was provided by the user use the one stored 
		# in the environment variable AWS_PROFILE, if available.
		profile="${AWS_PROFILE}"
	fi
	echo "${profile}"
}

function aws_delete_profile() {
	local profile="${1}"
	read -p "Are you sure you want to delete the profile '${profile}'? (y/N) " -n 1 -r -s
	echo >&2
	if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
		echo "Aborted." >&2
		return 1
	fi
	local aws_config_file="$(do_require_aws_config_file)"
	local aws_credentials_file="$(do_require_aws_credentials_file)"
	remove_toml_section "profile ${profile}" "${aws_config_file}" > "${aws_config_file}.bak"
	mv "${aws_config_file}.bak" "${aws_config_file}"
	
	remove_toml_section "${profile}" "${aws_credentials_file}" > "${aws_credentials_file}.bak"
	mv "${aws_credentials_file}.bak" "${aws_credentials_file}"
	
	print_info "Successfully removed profile ${profile}!"
}

# Make sure that the aws-cli is installed
do_require_command "aws"

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
			profile="$(aws_get_profile "${1}")"
			do_require_aws_profile_argument "${profile}"
			do_require_aws_profile_not_exists "${profile}"
			# Add aws profile.
			aws configure --profile "${profile}"
			exit
			;;
		list | ls )		   
			# List aws profiles.
			aws configure list-profiles
			exit 0
			;;
		use )
			shift
			profile="$(aws_get_profile "${1}")"
			do_require_aws_profile_argument "${profile}"
			do_require_aws_profile_exists "${profile}"
			# Use aws profile.
			echo "export AWS_PROFILE=${profile}"
			exit 0
			;;
		export)
			shift
			profile="$(aws_get_profile "${1}")"
			do_require_aws_profile_argument "${profile}"
			do_require_aws_profile_exists "${profile}"
			# Export aws credentials.
			aws_access_key_id=$(get_toml_section_value "${profile}" "aws_access_key_id")
			aws_secret_access_key=$(get_toml_section_value "${profile}" "aws_secret_access_key")
			echo "export AWS_ACCESS_KEY_ID='${aws_access_key_id}'"
			echo "export AWS_SECRET_ACCESS_KEY='${aws_secret_access_key}'"
			exit 0
			;;
		delete | remove | rm )
			shift
			profile="$(aws_get_profile "${1}")"
			do_require_aws_profile_argument "${profile}"
			do_require_aws_profile_exists "${profile}"
			aws_delete_profile "${profile}"
			exit 0
			;;
		update )
			shift
			profile="$(aws_get_profile "${1}")"
			do_require_aws_profile_argument "${profile}"
			do_require_aws_profile_exists "${profile}"
			# Update aws profile.
			aws configure --profile "${profile}"
			exit 0
			;;
		reload )
			# This function is implemented in ~/.aws-profile.bash.
			exit 0
			;;
		current )
			profile="$(aws_get_profile "")"
			if [ -z "${profile}" ] ; then
				usage
				print_error "No profile selected!"
				exit 1
			fi
			# Show currently active aws profile.
			aws configure list
			exit 0
			;;
		show )
			shift
			profile="$(aws_get_profile "${1}")"
			do_require_aws_profile_argument "${profile}"
			do_require_aws_profile_exists "${profile}"
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
