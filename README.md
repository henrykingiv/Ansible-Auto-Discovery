# Ansible-Auto-Discovery

# How the Project Works

I create an s3-bucket to store my tfstate file and dynamodb to lock the files, the script below shows how I created these resources using a bash script.
#!/bin/bash

#Set your bucket name and region
bucket_name="ansible-discovery-env"
region="eu-west-2"
dynamodb_name="ansible-discovery-table"

#Create the s3 bucket
aws s3api create-bucket --bucket $bucket_name --region $region --create-bucket-configuration LocationConstraint=$region

#Check if the bucket creation was successful
if [ $? -eq 0 ]; then
  echo "S3 bucket $bucket_name created successfully."
else
  echo "Failed to create S3 bucket $bucket_name."
fi

#Create dynamodb table
aws dynamodb create-table --table-name $dynamodb_name --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10 --region $region

#Check if table is created successfully
if [ $? -eq 0 ]; then
  echo "dynamodb table $dynamodb_name created successfully."
else
  echo "Failed to create S3 bucket $dynamodb_name."
fi

This Project made use of vault and AWS secret to store database credentials/NewRelic Credentials, the aws command below will either create or destroy aws secret manager.
#Create AWS secret manager
 aws secretsmanager create-secret --name MyDatabaseCredentials --secret-string '{"username":"xxxx","password":"xxxx"}' --description "My database credentials" --region eu-west-2 --tags Key=Environment,Value=Production
 aws secretsmanager create-secret --name MyNewRelicCredentials --secret-string '{"newrelicid":"xxxxx","newrelickey":"xxxx"}' --description "My newrelic credentials" --region eu-west-2 --tags Key=Environment,Value=Production

#Destroy aws secrets
 aws secretsmanager delete-secret --secret-id MyDatabaseCredentials --force-delete-without-recovery --region eu-west-2

I also wrote a script that was able to initialise my vault token, create the secret and store it as well.
#Set vault token/secret username and password
vault operator init > output.txt
grep -o 's\.[A-Za-z0-9]\{24\}' output.txt > token.txt
token_content=$(<token.txt)
vault login $token_content
vault secrets enable -path=secret/ kv
vault kv put secret/database username=admin password=admin123


