#!/usr/bin/env bats -v
# 
# Tests for aws-profile.
#
# Usage:
# 	./test_aws-profile.bats
# 	bats ./test_aws-profile.bats
#
# Requirements:
#
# 	apt install bats jq python3 python3-pip
#	pip3 install awscli
#	source install
#

#
# Helper functions
# 

function run_aws_profile_add() {
	run bash -c "aws-profile add $1 << EOF
$2
$3
$4
$5
$6
EOF
"
	
}

function clean_profiles() {
	export AWS_PROFILE=""
	rm -rf ~/.aws/
	return 0
}

#
# Test setup and teardown
#

setup() {
	clean_profiles
}

teardown() {
	clean_profiles
}

#
# Test aws-profile use
#

@test "Test command usage: aws-profile use without profile-name" {
	run aws-profile use
	[ "$status" -eq 1 ]
	[[ "${lines[@]}" == *"Usage"* ]]
}

@test "Test command usage: aws-profile use" {
	run aws-profile use non-existing
	[ "${status}" -eq 1 ]
	[[ "${lines[@]}" == *"does not exist!"* ]]
}


@test "Test command usage: aws-profile use existing" {
	run_aws_profile_add default AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	run aws-profile use default
	[ "${status}" -eq 0 ]
	[[ "${lines[@]}" == *"profile"*"default"* ]]
	[[ "${lines[@]}" == *"access_key"* ]]
	[[ "${lines[@]}" == *"secret_key"* ]]
	[[ "${lines[@]}" == *"region"* ]]
}

@test "Test command usage: aws-profile use existing shows override warning" {
	run_aws_profile_add default AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	export AWS_DEFAULT_REGION=TEST
	run aws-profile use default
	[ "${status}" -eq 0 ]
	[[ "${lines[@]}" == *"The following variable(s) are set and might override the ones set in the profile: 'AWS_DEFAULT_REGION'"* ]]
	[[ "${lines[@]}" == *"profile"*"default"* ]]
	[[ "${lines[@]}" == *"access_key"* ]]
	[[ "${lines[@]}" == *"secret_key"* ]]
	[[ "${lines[@]}" == *"region"* ]]
}
#
# Test aws-profile help
#

@test "Test command usage: aws-profile help" {
	run aws-profile help
	[ "${status}" -eq 0 ]
	[[ "${lines[@]}" == *"Usage"* ]]
}

#
# Test aws-profile add
#

@test "Test command usage: aws-profile add without profile name" {
	run aws-profile add
	[ "${status}" -eq 1 ]
}

@test "Test command usage: aws-profile add with profile name" {
	run_aws_profile_add default AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	[ "${status}" -eq 0 ]

	# Test whether aws config file has correct content
	expected_aws_config="[default]
region = REGION
output = FORMAT"
	actual_content=$(cat ~/.aws/config)
	[ "$actual_content" == "$expected_aws_config" ]

	# Test whether aws credentials file has correct content
	actual_content=$(cat ~/.aws/credentials)
	expected_aws_credentials="[default]
aws_access_key_id = AWS_ACCESS_KEY_ID
aws_secret_access_key = AWS_SECRET_ACCESS_KEY
aws_session_token = AWS_SESSION_TOKEN"
	[ "$actual_content" == "$expected_aws_credentials" ]
}

@test "Test command usage: aws-profile add multiple" {
	run_aws_profile_add p1 AAKI1 ASAK1 R1 F1 S1
	run_aws_profile_add p2 AAKI2 ASAK2 R2 F2 S2
	run_aws_profile_add p3 AAKI3 ASAK3 R3 F3 S3

	# Test whether aws config file has correct content
	expected_content="[profile p1]
region = R1
output = F1
[profile p2]
region = R2
output = F2
[profile p3]
region = R3
output = F3"
	actual_content=$(cat ~/.aws/config)
	[ "$actual_content" == "$expected_content" ]

	# Test whether aws credentials file has correct content
	actual_content=$(cat ~/.aws/credentials)
	expected_content="[p1]
aws_access_key_id = AAKI1
aws_secret_access_key = ASAK1
aws_session_token = S1
[p2]
aws_access_key_id = AAKI2
aws_secret_access_key = ASAK2
aws_session_token = S2
[p3]
aws_access_key_id = AAKI3
aws_secret_access_key = ASAK3
aws_session_token = S3"
	[ "$actual_content" == "$expected_content" ]
}

@test "Test command usage: aws-profile add with already existing profile name" {
	run_aws_profile_add default AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	run_aws_profile_add default AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	[ "${status}" -eq 1 ]
	[[ "${lines[@]}" == *"already exists!"* ]]
}

# TODO: add without session token

#
# Test aws-profile current
#

@test "Test command usage: aws-profile current without profile selected" {
	run aws-profile current
	[ "${status}" -eq 1 ]
	[[ "${lines[@]}" == *"No profile selected"* ]]
}

@test "Test command usage: aws-profile current after profile selected" {
	run_aws_profile_add default AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	aws-profile use default
	aws-profile current
	[[ -f ~/.aws-profile/current ]]
	[ "$?" -eq 0 ]
	[ "${AWS_PROFILE}" == "default" ]
}

#
# Test aws-profile export
#

@test "Test command usage: aws-profile export not existing profile" {
	run aws-profile export --format bash not-existing
	[ "${status}" -eq 1 ]
	[[ "${lines[@]}" == *"does not exist!"* ]]
}

@test "Test command usage: aws-profile export invalid format" {
	run_aws_profile_add default AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	run aws-profile export --format invalid-format default
	[ "${status}" -eq 1 ]
	[[ "${lines[@]}" == *"Invalid format!"* ]]
}

@test "Test command usage: aws-profile export without profile selected" {
	run_aws_profile_add default AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	run aws-profile export --format bash
	[ "${status}" -eq 1 ]
	[[ "${lines[@]}" == *"No profile name specified!"* ]]
}

@test "Test command usage: aws-profile export currently used profile" {
	run_aws_profile_add p1 AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	aws-profile use p1 &>/dev/null
	actual_content=$(aws-profile export --format bash)
	expected_output="export AWS_ACCESS_KEY_ID='AWS_ACCESS_KEY_ID'
export AWS_SECRET_ACCESS_KEY='AWS_SECRET_ACCESS_KEY'
export AWS_DEFAULT_REGION='REGION'
export AWS_DEFAULT_OUTPUT='FORMAT'
export AWS_SESSION_TOKEN='AWS_SESSION_TOKEN'"
	[ "$actual_content" == "$expected_output" ]
}

@test "Test command usage: aws-profile export specified profile" {
	run_aws_profile_add p1 AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	actual_content=$(aws-profile export --format bash p1)
	expected_output="export AWS_ACCESS_KEY_ID='AWS_ACCESS_KEY_ID'
export AWS_SECRET_ACCESS_KEY='AWS_SECRET_ACCESS_KEY'
export AWS_DEFAULT_REGION='REGION'
export AWS_DEFAULT_OUTPUT='FORMAT'
export AWS_SESSION_TOKEN='AWS_SESSION_TOKEN'"
	[ "$actual_content" == "$expected_output" ]
}

@test "Test command usage: aws-profile export json" {
	run_aws_profile_add p1 AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	actual_content=$(aws-profile export --format json p1)
	expected_output='{
  "Credentials": {
    "SessionToken": "AWS_SESSION_TOKEN",
    "AccessKeyId": "AWS_SECRET_ACCESS_KEY",
    "SecretAccessKey": "AWS_SECRET_ACCESS_KEY"
  },
  "Region": "REGION",
  "Output": "FORMAT"
}'
	[ "$actual_content" == "$expected_output" ]
}

#
# Test aws-profile import
#

@test "Test command usage: aws-profile import usage" {
	run aws-profile import
	[ "${status}" -eq 1 ]
	[[ "${lines[@]}" == *"Usage"* ]]
}

@test "Test command usage: aws-profile import no file" {
	run aws-profile import default
	[ "${status}" -eq 1 ]
	[[ "${lines[@]}" == *"Usage"* ]]
}

@test "Test command usage: aws-profile import not existing file" {
	credentials_file=/tmp/not-existing.json
	run aws-profile import default "${credentials_file}"
	[ "${status}" -eq 1 ]
	[[ "${lines[@]}" == *"does not exist!"* ]]
}

@test "Test command usage: aws-profile import abort when existing profile" {
	run_aws_profile_add default AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	credentials_file=/tmp/dummy.json
	echo '{
  "Credentials": {
    "SessionToken": "AWS_SESSION_TOKEN",
    "AccessKeyId": "AWS_ACCESS_KEY_ID",
    "SecretAccessKey": "AWS_SECRET_ACCESS_KEY"
  },
  "Region": "REGION",
  "Output": "FORMAT"
}' > "${credentials_file}"
	run aws-profile import default "${credentials_file}" < <(echo 'n')
	[ "${status}" -eq 1 ]
	[[ "${lines[@]}" == *"Aborted"* ]]
}

@test "Test command usage: aws-profile import existing profile" {
	run_aws_profile_add default AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	credentials_file=/tmp/dummy.json
	echo '{
  "Credentials": {
    "SessionToken": "SessionToken",
    "AccessKeyId": "AccessKeyId",
    "SecretAccessKey": "SecretAccessKey"
  },
  "Region": "Region",
  "Output": "Output"
}' > "${credentials_file}"
	run aws-profile import default "${credentials_file}" < <(echo 'y')
	# Test whether aws config file has correct content
	expected_aws_config="[default]
region = Region
output = Output"
	actual_content=$(cat ~/.aws/config)
	[ "$actual_content" == "$expected_aws_config" ]

	# Test whether aws credentials file has correct content
	actual_content=$(cat ~/.aws/credentials)
	expected_aws_credentials="[default]
aws_access_key_id = AccessKeyId
aws_secret_access_key = SecretAccessKey
aws_session_token = SessionToken"
	rm -f "${credentials_file}"
}

@test "Test command usage: aws-profile import" {
	credentials_file=/tmp/aws-credentials.json
	echo '{
  "Credentials": {
    "SessionToken": "AWS_SESSION_TOKEN",
    "AccessKeyId": "AWS_ACCESS_KEY_ID",
    "SecretAccessKey": "AWS_SECRET_ACCESS_KEY"
  },
  "Region": "REGION",
  "Output": "FORMAT"
}' > "${credentials_file}"
	run aws-profile import default "${credentials_file}"

	# Test whether aws config file has correct content
	expected_aws_config="[default]
region = REGION
output = FORMAT"
	actual_content=$(cat ~/.aws/config)
	[ "$actual_content" == "$expected_aws_config" ]

	# Test whether aws credentials file has correct content
	actual_content=$(cat ~/.aws/credentials)
	expected_aws_credentials="[default]
aws_access_key_id = AWS_ACCESS_KEY_ID
aws_secret_access_key = AWS_SECRET_ACCESS_KEY
aws_session_token = AWS_SESSION_TOKEN"
	rm -f "${credentials_file}"
}

# TODO:
# - file can not be parsed

#
# Test aws-profile list
#

@test "Test command usage: aws-profile list empty" {
	run aws-profile list
	[ "${status}" -eq 0 ]
	[ -z "${lines[@]}" ]
}

@test "Test command usage: aws-profile list multiple" {
	run_aws_profile_add p1 AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	run_aws_profile_add p2 AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY REGION FORMAT AWS_SESSION_TOKEN
	actual_content=$(aws-profile list)
	[ "${status}" -eq 0 ]
	expected_content="p1
p2"
	[ "$actual_content" == "$expected_content" ]
}

#
# Test aws-profile reload
#

@test "Test command usage: aws-profile reload" {
	mkdir -p ~/.aws
	echo "[default]" > ~/.aws/config
	echo "[default]
aws_access_key_id = AWS_ACCESS_KEY_ID
aws_secret_access_key = AWS_SECRET_ACCESS_KEY" > ~/.aws/credentials
	aws-profile reload
	actual_content=$(aws-profile list)
	expected_content="default"
	[ "$actual_content" == "$expected_content" ]

}

#
# Test aws-profile remove
#

@test "Test command usage: aws-profile remove first" {
	run_aws_profile_add p1 AAKI1 ASAK1 R1 F1 S1
	run_aws_profile_add p2 AAKI2 ASAK2 R2 F2 S2
	run_aws_profile_add p3 AAKI3 ASAK3 R3 F3 S3

	run aws-profile remove p1 << EOF
Y
EOF

	# Test whether aws config file has correct content
	expected_content="[profile p2]
region = R2
output = F2
[profile p3]
region = R3
output = F3"
	actual_content=$(cat ~/.aws/config)
	[ "$actual_content" == "$expected_content" ]

	# Test whether aws credentials file has correct content
	actual_content=$(cat ~/.aws/credentials)
	expected_content="[p2]
aws_access_key_id = AAKI2
aws_secret_access_key = ASAK2
aws_session_token = S2
[p3]
aws_access_key_id = AAKI3
aws_secret_access_key = ASAK3
aws_session_token = S3"
	[ "$actual_content" == "$expected_content" ]
}

@test "Test command usage: aws-profile remove not existing profile" {
        run aws-profile remove default 
        [ "${status}" -eq 1 ]
        [[ "${lines[@]}" == *"does not exist!"* ]]
}

@test "Test command usage: aws-profile remove middle" {
	run_aws_profile_add p1 AAKI1 ASAK1 R1 F1 S1
	run_aws_profile_add p2 AAKI2 ASAK2 R2 F2 S2
	run_aws_profile_add p3 AAKI3 ASAK3 R3 F3 S3

	run aws-profile remove p2 << EOF
Y
EOF

	# Test whether aws config file has correct content
	expected_content="[profile p1]
region = R1
output = F1
[profile p3]
region = R3
output = F3"
	actual_content=$(cat ~/.aws/config)
	[ "$actual_content" == "$expected_content" ]

	# Test whether aws credentials file has correct content
	actual_content=$(cat ~/.aws/credentials)
	expected_content="[p1]
aws_access_key_id = AAKI1
aws_secret_access_key = ASAK1
aws_session_token = S1
[p3]
aws_access_key_id = AAKI3
aws_secret_access_key = ASAK3
aws_session_token = S3"
	[ "$actual_content" == "$expected_content" ]
}

@test "Test command usage: aws-profile remove last" {
	run_aws_profile_add p1 AAKI1 ASAK1 R1 F1 S1
	run_aws_profile_add p2 AAKI2 ASAK2 R2 F2 S2
	run_aws_profile_add p3 AAKI3 ASAK3 R3 F3 S3

	run aws-profile remove p3 << EOF
Y
EOF

	# Test whether aws config file has correct content
	expected_content="[profile p1]
region = R1
output = F1
[profile p2]
region = R2
output = F2"
	actual_content=$(cat ~/.aws/config)
	[ "$actual_content" == "$expected_content" ]

	# Test whether aws credentials file has correct content
	actual_content=$(cat ~/.aws/credentials)
	expected_content="[p1]
aws_access_key_id = AAKI1
aws_secret_access_key = ASAK1
aws_session_token = S1
[p2]
aws_access_key_id = AAKI2
aws_secret_access_key = ASAK2
aws_session_token = S2"
	[ "$actual_content" == "$expected_content" ]
}

#
# Test aws-profile show
#

@test "Test command usage: aws-profile show not existing" {
	run aws-profile show not-existing
	[ "${status}" -eq 1 ]
	[[ "${lines[@]}" == *"does not exist!"* ]]
}

@test "Test command usage: aws-profile show existing" {
	run_aws_profile_add p1 AAKI1 ASAK1 R1 F1 S1
	run aws-profile show p1
	[ "${status}" -eq 0 ]
	[[ "${lines[@]}" == *"profile"*"p1"* ]]
	[[ "${lines[@]}" == *"access_key"* ]]
	[[ "${lines[@]}" == *"secret_key"* ]]
	[[ "${lines[@]}" == *"region"* ]]
}

@test "Test command usage: aws-profile show current" {
	run_aws_profile_add p1 AAKI1 ASAK1 R1 F1 S1
	run_aws_profile_add p2 AAKI2 ASAK2 R2 F2 S2
	run_aws_profile_add p3 AAKI3 ASAK3 R3 F3 S3
	aws-profile use p2
	run aws-profile show
	[ "${status}" -eq 0 ]
	[[ "${lines[@]}" == *"profile"*"p2"* ]]
	[[ "${lines[@]}" == *"access_key"* ]]
	[[ "${lines[@]}" == *"secret_key"* ]]
	[[ "${lines[@]}" == *"region"* ]]
}

#
# Test aws-profile update
#

@test "Test command usage: aws-profile update" {
        run_aws_profile_add p1 1a 1b 1c 1d 1e
	run_aws_profile_add p2 2a 2b 2c 2d 2e
	run_aws_profile_add p3 3a 3b 3c 3d 3e

	run aws-profile update p2 << EOF
2f
2g
2h
2i
2j
EOF

        # Test whether aws config file has correct content
        expected_content="[profile p1]
region = 1c
output = 1d
[profile p2]
region = 2h
output = 2i
[profile p3]
region = 3c
output = 3d"
        actual_content=$(cat ~/.aws/config)
        [ "$actual_content" == "$expected_content" ]

        # Test whether aws credentials file has correct content
        actual_content=$(cat ~/.aws/credentials)
        expected_content="[p1]
aws_access_key_id = 1a
aws_secret_access_key = 1b
aws_session_token = 1e
[p2]
aws_access_key_id = 2f
aws_secret_access_key = 2g
aws_session_token = 2j
[p3]
aws_access_key_id = 3a
aws_secret_access_key = 3b
aws_session_token = 3e"
        [ "$actual_content" == "$expected_content" ]
}

