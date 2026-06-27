#!/usr/bin/env bash
set -euo pipefail

#
# bootstrap-state.sh — Idempotently provision the Terraform remote state backend
#
# Creates an S3 bucket for state storage (with versioning, encryption, public
# access blocking, and lifecycle cleanup) and a DynamoDB table for state locking.
#
# Usage:
#   ./scripts/bootstrap-state.sh [options]
#
# Options:
#   --region <region>   AWS region (default: us-east-2)
#   --bucket <name>     S3 bucket name (default: petclinic-terraform-state-{account_id}-{region})
#   --table <name>      DynamoDB table name (default: petclinic-terraform-locks)
#   --help              Show this usage message
#
# Examples:
#   ./scripts/bootstrap-state.sh
#   ./scripts/bootstrap-state.sh --region us-west-2
#   ./scripts/bootstrap-state.sh --bucket my-custom-state-bucket --table my-custom-locks
#

DEFAULT_REGION="us-east-2"
DEFAULT_TABLE="petclinic-terraform-locks"

usage() {
  sed -n '5,22p' "$0"
  exit 0
}

REGION="${DEFAULT_REGION}"
TABLE="${DEFAULT_TABLE}"
BUCKET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)
      REGION="$2"
      shift 2
      ;;
    --bucket)
      BUCKET="$2"
      shift 2
      ;;
    --table)
      TABLE="$2"
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
      echo "Error: unknown argument '$1'" >&2
      usage
      ;;
  esac
done

# --- Validate dependencies ---
if ! command -v aws >/dev/null 2>&1; then
  echo "Error: AWS CLI is required but not installed." >&2
  exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [[ -z "${AWS_ACCOUNT_ID}" || "${AWS_ACCOUNT_ID}" == "None" ]]; then
  echo "Error: unable to determine AWS account ID. Check your AWS credentials." >&2
  exit 1
fi

if [[ -z "${BUCKET}" ]]; then
  BUCKET="petclinic-terraform-state-${AWS_ACCOUNT_ID}-${REGION}"
fi

echo "============================================"
echo "  Bootstrapping Terraform remote state"
echo "  Region: ${REGION}"
echo "  Account: ${AWS_ACCOUNT_ID}"
echo "  Bucket: ${BUCKET}"
echo "  Table: ${TABLE}"
echo "============================================"
echo ""

# --- S3 bucket ---
echo "[1/2] Ensuring S3 bucket exists: ${BUCKET}"

if aws s3api head-bucket --bucket "${BUCKET}" --region "${REGION}" 2>/dev/null; then
  echo "  -> Bucket already exists. No action needed."
else
  CREATE_ARGS=(
    --bucket "${BUCKET}"
    --region "${REGION}"
  )
  if [[ "${REGION}" != "us-east-1" ]]; then
    CREATE_ARGS+=(--create-bucket-configuration LocationConstraint="${REGION}")
  fi

  aws s3api create-bucket "${CREATE_ARGS[@]}"
  echo "  -> Bucket created."
fi

echo "  -> Enabling server-side encryption (SSE-S3 / AES256)..."
aws s3api put-bucket-encryption \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }
    ]
  }'

echo "  -> Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --versioning-configuration Status=Enabled

echo "  -> Blocking all public access..."
aws s3api put-public-access-block \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

echo "  -> Applying lifecycle rule for old noncurrent versions (30 days)..."
aws s3api put-bucket-lifecycle-configuration \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --lifecycle-configuration '{
    "Rules": [
      {
        "ID": "delete-old-noncurrent-versions",
        "Status": "Enabled",
        "Filter": {
          "Prefix": ""
        },
        "NoncurrentVersionExpiration": {
          "NoncurrentDays": 30
        }
      }
    ]
  }'

echo ""

# --- DynamoDB table ---
echo "[2/2] Ensuring DynamoDB table exists: ${TABLE}"

if aws dynamodb describe-table --table-name "${TABLE}" --region "${REGION}" >/dev/null 2>&1; then
  echo "  -> Table already exists. No action needed."
else
  aws dynamodb create-table \
    --table-name "${TABLE}" \
    --region "${REGION}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
  echo "  -> Table created."
fi

echo ""
echo "============================================"
echo "  Terraform backend bootstrapped"
echo ""
echo "  Bucket: ${BUCKET}"
echo "  Table:  ${TABLE}"
echo "  Region: ${REGION}"
echo "============================================"
