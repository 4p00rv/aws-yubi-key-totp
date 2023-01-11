#!/bin/bash

# Usage:
# $0 profile_to_use temp_profile_name

set -x
set -e
# Use AWS_PROFILE env value to set profile
# or take the first argument. If that is not
# set too then fall back to default profile
PROFILE="${1:-$AWS_PROFILE}"
PROFILE="${PROFILE:-default}"
TEMP_NAME="${2:-temp}"

# Get user arn to be used to determine mfa device
ARN="$(aws sts get-caller-identity --profile $PROFILE | jq -r .Arn)"
# MFA device id
ACCOUNT="${ARN/user/mfa}"
# Assumtion is that the oath account name is same as the mfa device
TOKEN=$(ykman oath accounts code $ACCOUNT | awk -F" " '{print $2}')
# Retreive session token for the account and temp credentials
CREDS="$(aws sts get-session-token --serial-number $ACCOUNT --token $TOKEN --profile $PROFILE)"

ACCESS_KEY_ID="$(echo $CREDS | jq -r .Credentials.AccessKeyId)"
SECRET_ACCESS_KEY="$(echo $CREDS | jq -r .Credentials.SecretAccessKey)"
SESSION_TOKEN="$(echo $CREDS | jq -r .Credentials.SessionToken)"

aws configure --profile $TEMP_NAME set aws_access_key_id $ACCESS_KEY_ID 
aws configure --profile $TEMP_NAME set aws_secret_access_key $SECRET_ACCESS_KEY
aws configure --profile $TEMP_NAME set aws_session_token  $SESSION_TOKEN
