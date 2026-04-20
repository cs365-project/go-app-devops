#!/usr/bin/env bash
set -euo pipefail

BUCKET_NAME="cs365-tf-state-bucket"
DYNAMODB_TABLE="cs365-tf-lock"
REGION="us-east-1"

echo "==> Creating S3 bucket: $BUCKET_NAME"
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION"

echo "==> Enabling versioning on S3 bucket"
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

echo "==> Enabling server-side encryption on S3 bucket"
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "==> Blocking public access on S3 bucket"
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "==> Creating DynamoDB table: $DYNAMODB_TABLE"
aws dynamodb create-table \
  --table-name "$DYNAMODB_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo "==> Waiting for DynamoDB table to become active..."
aws dynamodb wait table-exists \
  --table-name "$DYNAMODB_TABLE" \
  --region "$REGION"

echo ""
echo "Done! Remote state backend is ready."
echo "  S3 bucket : $BUCKET_NAME"
echo "  DynamoDB  : $DYNAMODB_TABLE"
echo ""
echo "Next: cd terraform/eks && terraform init"
