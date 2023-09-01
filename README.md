# aws-profile
Allows to add and switch between multiple user profiles.

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

**Add profile:**
```
$ aws-profile add foo
AWS ACCESS KEY ID [None]: AKIAIOSFODNN7EXAMPLE
AWS SECRET ACCESS KEY [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-2
Default output format [None]: json
AWS SESSION TOKEN [None]: AQoEXAMPLEH4aoAH0gNCAPyJxz4BlCFFxWNE1OPTgk5TthT+FvwqnKwRcOIfrRh3c/LTo6UDdyJwOOvEVPvLXCrrrUtdnniCEXAMPLE/IvU1dYUg2RVAJBanLiHb4IgRmpRV3zrkuWJOgQs8IZZaIv2BXIa2R4Olgk
```

**List profiles:**
```
$ aws-profile list
foo
```

**Select profile:**
```
$ aws-profile use foo
      Name                    Value             Type    Location
      ----                    -----             ----    --------
   profile                      foo              env    ['AWS_PROFILE', 'AWS_DEFAULT_PROFILE']
access_key     ****************MPLE shared-credentials-file    
secret_key     ****************EKEY shared-credentials-file    
    region               eu-central      config-file    ~/.aws/config
```

**Show current profile:**
```
$ aws-profile use foo
      Name                    Value             Type    Location
      ----                    -----             ----    --------
   profile                      foo              env    ['AWS_PROFILE', 'AWS_DEFAULT_PROFILE']
access_key     ****************MPLE shared-credentials-file    
secret_key     ****************EKEY shared-credentials-file    
    region               eu-central      config-file    ~/.aws/config
```

**Update profile:**
```
aws-profile update foo
AWS ACCESS KEY ID [************MPLE]: 
AWS SECRET ACCESS KEY [************EKEY]: 
Default region name [eu-central]: 
Default output format [json]: 
AWS SESSION TOKEN [************Olgk]:
```

**Export profile:**
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

**Import profile:**
```
$ aws sts get-session-token > session.json
$ aws-profile import foo session.json
[ INFO] Successfully imported profile foo from session.json!
```

**Remove profile:**
```
$ aws-profile remove foo
Are you sure you want to delete the profile 'foo'? (y/N) 
[ INFO] Successfully removed profile foo!
```
