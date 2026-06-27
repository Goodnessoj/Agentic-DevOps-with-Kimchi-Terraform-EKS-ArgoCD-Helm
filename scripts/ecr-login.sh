#!/usr/bin/env bash
set -euo pipefail

# Authenticate Docker to the AWS ECR registry.
# Usage: ./scripts/ecr-login.sh [--region REGION]
# Default region: us-east-2

REGION="us-east-2"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)
      REGION="${2:-}"
      if [[ -z "$REGION" ]]; then
        echo "Error: --region requires a value." >&2
        exit 1
      fi
      shift 2
      ;;
    *)
      echo "Usage: $0 [--region REGION]" >&2
      exit 1
      ;;
  esac
done

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [[ -z "$ACCOUNT_ID" ]]; then
  echo "Error: unable to determine AWS account ID." >&2
  exit 1
fi

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
