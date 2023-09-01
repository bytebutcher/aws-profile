#!/bin/bash
# ##################################################
# NAME:
#   AWS Profile
# DESCRIPTION:
#   Allows to manage multiple aws user profiles.
# AUTHOR:
#   bytebutcher
# ##################################################

VERSION="1.6.0"

# ROADMAP
# -------
#
# - aws-profile import should ask for region and format
# - README.md should show examples
# - README.md should include build and license badge.

AWS_ENVIRONMENT_VARIABLES=(
	"AWS_ACCESS_KEY_ID"
	"AWS_SECRET_ACCESS_KEY"
	"AWS_DEFAULT_REGION"
	"AWS_DEFAULT_FORMAT"
	"AWS_SESSION_TOKEN"
)
STRING_MASK_MAX_LENGTH=16
TOML_SECTION_REGEX='^\[[[:space:]A-Za-z0-9_-]+\]$'

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
        echo "  import   Imports a profile from a given JSON file"      >&2
	echo "  list     List profiles"                                 >&2 
	echo "  reload   Reload a profile"                              >&2
	echo "  remove   Remove a profile"                              >&2 
	echo "  show     Show information about a profile"              >&2
	echo "  update   Update a profile"                              >&2 
	echo "  use      Use a profile"                                 >&2
	echo "  version  Print version number of AWS Profile"           >&2
	echo ""                                                         >&2
}


function print_info() {
    local message="${1}"
    echo -e "\e[01;32m[ INFO] \e[0m${message}" >&2;
}

function print_error() {
    local message="${1}"
    echo -e "\e[01;31m[ERROR] \e[0m${message}" >&2;
}

function print_warning() {
	local message="${1}"
	echo -e "\033[1;33m[WARNING] \033[0m${message}" >&2;
}

function handle_error() {
	print_error "Unknown error! Aborting..."
	exit 1 
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
		print_error "The file '${file}' does not exist!"
		exit 1
	fi
}

function mask_string() {
        local input_string="$@"
        local length="${#input_string}"
	local output_string=""

        if [ -z "${input_string}" ] ; then
		output_string="None"
	else
		if [[ ${length} -le 8 ]] ; then
			output_string="****************"
		else
			if [[ ${length} -gt ${STRING_MASK_MAX_LENGTH} ]] ; then
				length=${STRING_MASK_MAX_LENGTH}
			fi

			for (( i = 0; i < ${length} - 4; i++ )); do
				output_string+="*"
			done

                	output_string+="${input_string: -4}"
		fi
        fi
	echo "${output_string}"
}

function do_require_aws_config_file() {
	config_file="${HOME}/.aws/config"
	if ! [ -d ~/.aws ] ; then
		mkdir ~/.aws
	fi
	touch "${config_file}"
	echo "${config_file}"
}

function do_require_aws_credentials_file() {
	local credentials_file="${HOME}/.aws/credentials"
	if ! [ -d ~/.aws ] ; then
		mkdir ~/.aws
	fi
	touch "${credentials_file}"
	echo "${credentials_file}"
}

function remove_toml_section() {
	local section="${1}"
        local toml_file="${2}"
        local ignore=0
        while IFS= read -r line; do
                if [[ "${line}" == "[${section}]" ]]; then
                        ignore=1
                        continue
                elif [[ "${line}" =~ ${TOML_SECTION_REGEX} ]] ; then
                        ignore=0
                fi
                [[ ${ignore} == 0 ]] && echo "${line}"
        done < "${toml_file}"
}

function get_toml_section_value() {
	local section="${1}"
	local key="${2}"
	local toml_file="${3}"
	local section_found=false
	while read line; do
		if [[ ${line} == "[${section}]" ]] ; then
			section_found=true
			continue
		fi
		if [[ "${line}" =~ ${TOML_SECTION_REGEX} ]] ; then
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
	done< <(cat "${toml_file}")
}

function do_require_aws_profile_argument() {
	local profile="${1}"
	if [ -z "${profile}" ] ; then
		usage
		print_error "No profile name specified!"
		exit 1
	fi
}

function jq_get_value() {
        local file="${1}"
        local key="${2}"
        local value="$(cat "${file}" | jq -Mer "${key}")"
        [[ "${value}" != "null" ]] && echo $value
}

function aws_profile_exists() {
	local profile="${1}"
	aws configure list-profiles | grep -e "^${profile}$" > /dev/null
}

function do_require_aws_profile_not_exists() {
	local profile="${1}"
	if aws_profile_exists "${profile}"; then
		print_error "The profile named '${profile}' already exists!"
		exit 1
	fi
}

function do_require_aws_profile_exists() {
	local profile="${1}"
	if ! aws_profile_exists "${profile}"; then
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

function aws_add_profile() {
	read -p "AWS ACCESS KEY ID [None]: " aws_access_key_id
	read -p "AWS SECRET ACCESS KEY [None]: " aws_secret_access_key
	read -p "Default region name [None]: " aws_region
	read -p "Default output format [None]: " aws_output_format
	read -p "AWS SESSION TOKEN [None]: " aws_session_token
	if [ -n "${aws_access_key_id}" ] ; then
		aws configure --profile "${profile}" set aws_access_key_id "${aws_access_key_id}"
	fi
	if [ -n "${aws_secret_access_key}" ] ; then
		aws configure --profile "${profile}" set aws_secret_access_key "${aws_secret_access_key}"
	fi
	if [ -n "${aws_region}" ] ; then
		aws configure --profile "${profile}" set region "${aws_region}"
	fi
	if [ -n "${aws_output_format}" ] ; then
		aws configure --profile "${profile}" set output "${aws_output_format}"
	fi
	if [ -n "${aws_session_token}" ] ; then
		aws configure --profile "${profile}" set aws_session_token "${aws_session_token}"
	fi
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

function aws_export_profile_json() {
	local profile="$1"
	local aws_config_file="$(do_require_aws_config_file)"
	local aws_credentials_file="$(do_require_aws_credentials_file)"
	aws_access_key_id=$(get_toml_section_value "${profile}" "aws_access_key_id" "${aws_credentials_file}")

	aws_secret_access_key=$(get_toml_section_value "${profile}" "aws_secret_access_key" "${aws_credentials_file}")
	aws_session_token=$(get_toml_section_value "${profile}" "aws_session_token" "${aws_credentials_file}")
	aws_region=$(get_toml_section_value "profile ${profile}" "region" "${aws_config_file}")
	aws_output=$(get_toml_section_value "profile ${profile}" "output" "${aws_config_file}")

	result=""
	if [ -n "${aws_access_key_id}" ] || [ -n "${aws_secret_access_key}" ] || [ -n "${aws_session_token}" ] ; then
		declare -A credentials
		if [ -n "${aws_secret_access_key}" ] ; then
			credentials["AccessKeyId"]="${aws_secret_access_key}"
		fi
		if [ -n "${aws_secret_access_key}" ] ; then
			credentials["SecretAccessKey"]="${aws_secret_access_key}"
		fi
		if [ -n "${aws_session_token}" ] ; then
			credentials["SessionToken"]="${aws_session_token}"
		fi
		for key in "${!credentials[@]}"; do
			result+="\"$key\": \"${credentials[$key]}\","
		done
		result="\"Credentials\": { ${result%,} }"
	fi
	if [ -n "${aws_output}" ] || [ -n "${aws_region}" ] ; then
		if [ -n "${result}" ] ; then
			result+=","
		fi
		if [ -n "${aws_region}" ] ; then
			result+="\"Region\": \"${aws_region}\","
		fi
		if [ -n "${aws_output}" ] ; then
			result+="\"Output\": \"${aws_output}\","
		fi
		result="${result%,}"
	fi
	echo "{ ${result} }" | jq -M
}

function aws_export_profile_sh() {
	local profile="$1"
	local aws_config_file="$(do_require_aws_config_file)"
	local aws_credentials_file="$(do_require_aws_credentials_file)"
	aws_access_key_id=$(get_toml_section_value "${profile}" "aws_access_key_id" "${aws_credentials_file}")

	aws_secret_access_key=$(get_toml_section_value "${profile}" "aws_secret_access_key" "${aws_credentials_file}")
	aws_session_token=$(get_toml_section_value "${profile}" "aws_session_token" "${aws_credentials_file}")
	aws_region=$(get_toml_section_value "profile ${profile}" "region" "${aws_config_file}")
	aws_output=$(get_toml_section_value "profile ${profile}" "output" "${aws_config_file}")

	if [ -n "${aws_access_key_id}" ] ; then
		echo "export AWS_ACCESS_KEY_ID='${aws_access_key_id}'"
	fi
	if [ -n "${aws_secret_access_key}" ] ; then
		echo "export AWS_SECRET_ACCESS_KEY='${aws_secret_access_key}'"
	fi
	if [ -n "${aws_region}" ] ; then
		echo "export AWS_DEFAULT_REGION='${aws_region}'"
	fi
	if [ -n "${aws_output}" ] ; then
		echo "export AWS_DEFAULT_OUTPUT='${aws_output}'"
	fi
	if [ -n "${aws_session_token}" ] ; then
		echo "export AWS_SESSION_TOKEN='${aws_session_token}'"
	fi
}

function aws_export_profile() {
	local profile="${1}"
	local format="${2}"
	if [[ "${format}" == "bash" || "${format}" == "sh" ]] ; then
		aws_export_profile_sh "${profile}"
	elif [[ "${format}" == "json" ]] ; then
		aws_export_profile_json "${profile}"
	else
		print_error "Invalid format! Supported formats: json, sh, bash"
		return 1
	fi
	return 0
}

function aws_import_profile() {
	# Make sure that jq is installed for being able to parse the json file
	do_require_command "jq"

	local profile="${1}"
	if aws_profile_exists "${profile}"; then
		read -p "The profile '${profile}' already exists! Do you want to update the profile? (y/N) " -n 1 -r -s
		echo >&2
		if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
			echo "Aborted." >&2
			return 1
		fi
	fi

	local credentials_json="${2}"
	local aws_access_key_id="$(cat $credentials_json | jq_get_value ${credentials_json} .Credentials.AccessKeyId)"
	local aws_secret_access_key="$(cat $credentials_json | jq_get_value ${credentials_json} .Credentials.SecretAccessKey)"
	local aws_session_token="$(cat $credentials_json | jq_get_value ${credentials_json} .Credentials.SessionToken)"
	local aws_region="$(cat $credentials_json | jq_get_value ${credentials_json} .Region)"
	local aws_output_format="$(cat $credentials_json | jq_get_value ${credentials_json} .Output)"

	if [ -n "${aws_access_key_id}" ] ; then
		aws configure --profile "${profile}" set aws_access_key_id "${aws_access_key_id}"
	fi
	if [ -n "${aws_secret_access_key}" ] ; then
		aws configure --profile "${profile}" set aws_secret_access_key "${aws_secret_access_key}"
	fi
	if [ -n "${aws_region}" ] ; then
		aws configure --profile "${profile}" set region "${aws_region}"
	fi
	if [ -n "${aws_output_format}" ] ; then
		aws configure --profile "${profile}" set output "${aws_output_format}"
	fi
	if [ -n "${aws_session_token}" ] ; then
		aws configure --profile "${profile}" set aws_session_token "${aws_session_token}"
	fi
	aws configure list --profile "${profile}"
}

function aws_use_profile() {
	local profile="${1}"
	echo "export AWS_PROFILE=${profile}"
	override_warning=""
	for aws_environment_variable in "${AWS_ENVIRONMENT_VARIABLES[@]}"; do
		if [[ -v "$aws_environment_variable" ]]; then
			override_warning+="'${aws_environment_variable}'"
		fi
	done
	if [[ -n "${override_warning}" ]] ; then
		print_warning "The following variable(s) are set and might override the ones set in the profile: $override_warning"
	fi
}

function aws_update_profile() {
	local profile="${1}"

	default_value="$(mask_string "$(aws configure --profile "${profile}" get aws_access_key_id)")"
	read -p "AWS ACCESS KEY ID [$default_value]: " aws_access_key_id
	default_value="$(mask_string "$(aws configure --profile "${profile}" get aws_secret_access_key)")"
	read -p "AWS SECRET ACCESS KEY [$default_value]: " aws_secret_access_key
	default_value="$(aws configure --profile "${profile}" get region)"
	read -p "Default region name [$default_value]: " aws_region
	default_value="$(aws configure --profile "${profile}" get output)"
	read -p "Default output format [$default_value]: " aws_output_format
	default_value=$(mask_string "$(aws configure --profile "${profile}" get aws_session_token)")
	read -p "AWS SESSION TOKEN [$default_value]: " aws_session_token
	if [ -n "${aws_access_key_id}" ] ; then
		aws configure --profile "${profile}" set aws_access_key_id "${aws_access_key_id}"
	fi
	if [ -n "${aws_secret_access_key}" ] ; then
		aws configure --profile "${profile}" set aws_secret_access_key "${aws_secret_access_key}"
	fi
	if [ -n "${aws_region}" ] ; then
		aws configure --profile "${profile}" set region "${aws_region}"
	fi
	if [ -n "${aws_output_format}" ] ; then
		aws configure --profile "${profile}" set output "${aws_output_format}"
	fi
	if [ -n "${aws_session_token}" ] ; then
		aws configure --profile "${profile}" set aws_session_token "${aws_session_token}"
	fi
}

#trap 'handle_error' ERR

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
			profile="${1}"
			if [ -z "${profile}" ] ; then
                                echo "Usage: aws-profile add <profile-name>" >&2
                                exit 1
                        fi
			do_require_aws_profile_not_exists "${profile}"
			aws_add_profile "${profile}"
			exit
			;;
		list | ls )		   
			aws configure list-profiles
			exit 0
			;;
		use )
			shift
			profile="${1}"
			if [ -z "${profile}" ] ; then
                                echo "Usage: aws-profile use <profile-name>" >&2
                                exit 1
                        fi
			do_require_aws_profile_argument "${profile}"
			do_require_aws_profile_exists "${profile}"
			aws_use_profile "${profile}"
			exit 0
			;;
		export )
			shift
			profile="$(aws_get_profile "$3")"
			format="$2"
			if [[ "$1" != "--format" ]] ; then
				echo "Usage: aws-profile export --format <bash|json|sh> [profile name]" >&2
				exit 1
			fi
			do_require_aws_profile_argument "${profile}"
			do_require_aws_profile_exists "${profile}"
			aws_export_profile "${profile}" "${format}"
			exit $?
			;;
		import )
			shift
			profile="${1}"
			file="${2}"
			if [ -z "${file}" ] || [ -z "${profile}" ] ; then
				echo "Usage: aws-profile import <profile-name> <json-file>" >&2
				exit 1
			fi
			do_require_file "${file}"
			aws_import_profile "${profile}" "${file}"
			exit $?
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
			aws_update_profile "${profile}"
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
		test )
			if ! [ -f /.dockerenv ]; then
				echo "ERROR: To avoid side-effects tests can only be run inside a docker container!" >&2
				exit 1
			fi
			do_require_command "bats"
			script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
			if ! [ -f "${script_dir}/test_aws-profile.sh" ] ; then
				echo "ERROR: test_aws_profile.sh was not found!" >&2
				exit 1
			fi
			bats "${script_dir}/test_aws-profile.sh"
			exit
			;;
		* )
			usage
			exit 1
	esac
	shift
done
