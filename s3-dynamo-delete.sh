#!/bin/bash

# Set your bucket, dynamodb name and region
bucket_name="ansible-discovery"
region="eu-west-1"
dynamodb_name="ansible-discovery-table"

#Delete S3 Bucket
aws s3 rb s3://$bucket_name --force


#Delete dynamodb table
aws dynamodb delete-table --table-name $dynamodb_name

if [ $? -eq 0 ]; then
  echo "S3 bucket $bucket_name and dynamodb $dynamodb_name deleted successfully."
else
  echo "Failed to delete S3 bucket $bucket_name and dynamodb $dynamodb_name."
fi
