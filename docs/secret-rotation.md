# Secrets Rotation Runbook

## 1. Overview

The Petclinic platform stores secrets in **AWS Secrets Manager** and syncs them to Kubernetes with the **External Secrets Operator (ESO)**. ESO uses the `aws-secrets-manager` `ClusterSecretStore` to authenticate to AWS and create Kubernetes `Secret` objects in the `petclinic-{env}` namespace.

This runbook describes how to rotate the two managed secret types safely.

## 2. Secrets Inventory

| Secret Type | AWS Secrets Manager Path | Keys | Kubernetes Secret | Namespace |
|---|---|---|---|---|
| RDS credentials | `petclinic/{env}/rds-credentials` | `username`, `password` | `rds-credentials` | `petclinic-{env}` |
| OpenAI API key | `petclinic/{env}/openai-api-key` | `api-key` | `openai-api-key` | `petclinic-{env}` |

## 3. Rotating RDS Credentials

1. Update the secret in AWS Secrets Manager:

   ```bash
   aws secretsmanager put-secret-value \
     --secret-id petclinic/{env}/rds-credentials \
     --secret-string '{"username":"<new-username>","password":"<new-password>"}'
   ```

2. Force ESO to resync the Kubernetes secret:

   ```bash
   kubectl annotate externalsecret rds-credentials \
     -n petclinic-{env} \
     force-sync=$(date +%s) --overwrite
   ```

3. Verify the Kubernetes secret reflects the new password:

   ```bash
   kubectl get secret rds-credentials -n petclinic-{env} \
     -o jsonpath='{.data.password}' | base64 -d
   ```

4. Restart dependent services so they pick up the new credentials (for example, the customers, visits, and vets services):

   ```bash
   kubectl rollout restart deployment/<service-name> -n petclinic-{env}
   ```

## 4. Rotating OpenAI API Key

1. Update the secret in AWS Secrets Manager:

   ```bash
   aws secretsmanager put-secret-value \
     --secret-id petclinic/{env}/openai-api-key \
     --secret-string '{"api-key":"<new-openai-api-key>"}'
   ```

2. Force ESO to resync the Kubernetes secret:

   ```bash
   kubectl annotate externalsecret openai-api-key \
     -n petclinic-{env} \
     force-sync=$(date +%s) --overwrite
   ```

3. Verify the Kubernetes secret reflects the new key:

   ```bash
   kubectl get secret openai-api-key -n petclinic-{env} \
     -o jsonpath='{.data.OPENAI_API_KEY}' | base64 -d
   ```

4. Restart `genai-service` so it loads the new key:

   ```bash
   kubectl rollout restart deployment/genai-service -n petclinic-{env}
   ```

## 5. Terraform/OpenAI Placeholder Secret

The `openai-api-key` secret is created with a placeholder value by Terraform in `terraform/modules/secrets/`. It must be overwritten with the real OpenAI API key before deploying `genai-service`. Use the rotation steps in section 4 to replace the placeholder with the production key.

## 6. Rollback / Safety

AWS Secrets Manager retains previous secret versions automatically. To retrieve a previous value, use `get-secret-value --version-id <version-id>`. If a rotation causes issues, retrieve the previous version and write it back with `put-secret-value`, then force a resync as shown above.

## 7. Verification Checklist

- [ ] RDS credentials updated in AWS: `aws secretsmanager get-secret-value --secret-id petclinic/{env}/rds-credentials`
- [ ] RDS credentials synced to Kubernetes:
  ```bash
  kubectl get secret rds-credentials -n petclinic-{env} \
    -o jsonpath='{.data.password}' | base64 -d
  ```
- [ ] OpenAI API key updated in AWS: `aws secretsmanager get-secret-value --secret-id petclinic/{env}/openai-api-key`
- [ ] OpenAI API key synced to Kubernetes:
  ```bash
  kubectl get secret openai-api-key -n petclinic-{env} \
    -o jsonpath='{.data.OPENAI_API_KEY}' | base64 -d
  ```
- [ ] Dependent workloads restarted and healthy after rotation.
