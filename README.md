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

