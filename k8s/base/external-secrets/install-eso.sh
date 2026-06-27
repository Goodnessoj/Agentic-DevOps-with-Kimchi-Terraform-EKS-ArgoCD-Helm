#!/usr/bin/env bash
set -euo pipefail

EKS_CLUSTER_NAME="petclinic-dev"
ESO_NAMESPACE="external-secrets"
ESO_RELEASE_NAME="external-secrets"
ESO_CHART_REPO="https://charts.external-secrets.io"
ESO_ROLE_NAME="petclinic-dev-eso-role"

echo "Adding External Secrets Operator Helm repository..."
helm repo add external-secrets "${ESO_CHART_REPO}" --force-update

echo "Updating Helm repositories..."
helm repo update

echo "Fetching ESO IAM role ARN..."
ESO_ROLE_ARN=$(aws iam get-role --role-name "${ESO_ROLE_NAME}" --query 'Role.Arn' --output text)

if [[ -z "${ESO_ROLE_ARN}" ]]; then
  echo "ERROR: Could not fetch ARN for IAM role ${ESO_ROLE_NAME}" >&2
  exit 1
fi

echo "Installing External Secrets Operator with IRSA role: ${ESO_ROLE_ARN}..."
helm upgrade --install "${ESO_RELEASE_NAME}" external-secrets/external-secrets \
  --namespace "${ESO_NAMESPACE}" \
  --create-namespace \
  --set serviceAccount.name=external-secrets-sa \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=${ESO_ROLE_ARN}" \
  --set installCRDs=true \
  --wait

echo "External Secrets Operator installed successfully."
