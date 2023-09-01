<br/><br/>
<div align="center">
    <img src="https://github.com/bytebutcher/pydfql/raw/main/images/aws-profile.png" alt="aws-profile Logo"/>
    <h1 align="center" style="margin-top: 0px;">aws-profile</h1>

 ![Version: 1.6.0](https://img.shields.io/badge/Version-1.6.0-green)
 [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
</div>
<br/>


**aws-profile** is a CLI utility designed to simplify the management of multiple AWS profiles. 
It offers a user-friendly interface for operations like adding, updating, and switching between 
AWS profiles, making it easy to manage your AWS configurations.

## Features

* **Simplified Management:** Intuitive commands for creating, deleting, and modifying AWS profiles.
* **Visibility:** View all profiles and their configurations at a glance.
* **Import/Export:** Import profiles directly from AWS STS or export them for sharing.

## Setup

To install aws-profile just execute the following commands:
```
sudo apt update && apt-get install -y git python3 python3-pip jq
pip3 install git+https://github.com/aws/aws-cli.git@v2
bash <(curl -s https://raw.githubusercontent.com/bytebutcher/aws-profile/master/install)
```

## Usage

```
AWS Profile allows to manage multiple aws user profiles.

Usage:
  aws-profile [command]

Available Commands:
  add      Add a profile
  current  Show information about the current profile
  export   Prints access key id and secret access key
  help     Shows this help
  import   Imports a profile from a given JSON file
  list     List profiles
  reload   Reload a profile
  remove   Remove a profile
  show     Show information about a profile
  update   Update a profile
  use      Use a profile
  version  Print version number of AWS Profile

```

### Add a New Profile
Run the **add** command to create a new profile. You'll be prompted for AWS credentials and configurations.
```
$ aws-profile add foo
AWS ACCESS KEY ID [None]: AKIAIOSFODNN7EXAMPLE
AWS SECRET ACCESS KEY [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-2
Default output format [None]: json
AWS SESSION TOKEN [None]: AQoEXAMPLEH4aoAH0gNCAPyJxz4BlCFFxWNE1OPTgk5TthT+FvwqnKwRcOIfrRh3c/LTo6UDdyJwOOvEVPvLXCrrrUtdnniCEXAMPLE/IvU1dYUg2RVAJBanLiHb4IgRmpRV3zrkuWJOgQs8IZZaIv2BXIa2R4Olgk
```

### List existing Profiles
Run the **list** command to view all existing profiles.
```
$ aws-profile list
foo
```

### Select an Active Profile
Run the **use** command to set an existing profile as active. This changes the environment variables for the AWS CLI.
```
$ aws-profile use foo
      Name                    Value             Type    Location
      ----                    -----             ----    --------
   profile                      foo              env    ['AWS_PROFILE', 'AWS_DEFAULT_PROFILE']
access_key     ****************MPLE shared-credentials-file    
secret_key     ****************EKEY shared-credentials-file    
    region               eu-central      config-file    ~/.aws/config
```

### Show Current Active Profile
Run the **show** command to display the currently active profile along with its configurations.
```
$ aws-profile show
      Name                    Value             Type    Location
      ----                    -----             ----    --------
   profile                      foo              env    ['AWS_PROFILE', 'AWS_DEFAULT_PROFILE']
access_key     ****************MPLE shared-credentials-file    
secret_key     ****************EKEY shared-credentials-file    
    region               eu-central      config-file    ~/.aws/config
```

### Update an Existing Profile
Run the **update** command to change the credentials and configurations of an existing profile.
```
aws-profile update foo
AWS ACCESS KEY ID [************MPLE]: 
AWS SECRET ACCESS KEY [************EKEY]: 
Default region name [eu-central]: 
Default output format [json]: 
AWS SESSION TOKEN [************Olgk]:
```

### Export a Profile
Run the **export** command to export the profile's environment variables. The output can be in **sh** or **json** formats.
```
$ aws-profile export --format sh
export AWS_ACCESS_KEY_ID='AKIAIOSFODNN7EXAMPLE'
export AWS_SECRET_ACCESS_KEY='wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
export AWS_DEFAULT_REGION='eu-central'
export AWS_DEFAULT_OUTPUT='json'
export AWS_SESSION_TOKEN='AQoEXAMPLEH4aoAH0gNCAPyJxz4BlCFFxWNE1OPTgk5TthT+FvwqnKwRcOIfrRh3c/LTo6UDdyJwOOvEVPvLXCrrrUtdnniCEXAMPLE/IvU1dYUg2RVAJBanLiHb4IgRmpRV3zrkuWJOgQs8IZZaIv2BXIa2R4Olgk'

$ aws-profile export --format json
{
  "Credentials": {
    "SessionToken": "AQoEXAMPLEH4aoAH0gNCAPyJxz4BlCFFxWNE1OPTgk5TthT+FvwqnKwRcOIfrRh3c/LTo6UDdyJwOOvEVPvLXCrrrUtdnniCEXAMPLE/IvU1dYUg2RVAJBanLiHb4IgRmpRV3zrkuWJOgQs8IZZaIv2BXIa2R4Olgk",
    "AccessKeyId": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
    "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  },
  "Region": "eu-central",
  "Output": "json"
}
```

### Import a Profile
You can import a profile using a session token obtained from AWS STS.
```
$ aws sts get-session-token > session.json
$ aws-profile import foo session.json
[ INFO] Successfully imported profile foo from session.json!
```

### Remove a Profile
Run the **remove** command to delete an existing profile. You will be prompted to confirm the deletion.
```
$ aws-profile remove foo
Are you sure you want to delete the profile 'foo'? (y/N) 
[ INFO] Successfully removed profile foo!
```

# Contributing

Feel free to open an issue or submit a pull request. All contributions are welcome!

# License

This project is licensed under the GPLv3 License - see the LICENSE.md file for details.


