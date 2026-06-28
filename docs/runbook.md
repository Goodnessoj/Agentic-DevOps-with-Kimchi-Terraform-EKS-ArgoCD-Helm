# Petclinic Platform — Operations Runbook

> **Scope:** Day-2 operations for the Petclinic platform running on AWS EKS.
> For architecture and deployment setup, see `docs/architecture.md` and
> `docs/technical-spec.md`.

---

## Rollback Strategy

This project uses a **CI + GitOps** model. CI builds and pushes images; ArgoCD
watches `helm-values/` in this repo and syncs the cluster. Because the desired
state is always in Git, rollbacks are performed by reverting Git commits and
letting ArgoCD converge.

### Preferred method: GitOps rollback via Git revert

When a bad image is deployed:

1. Identify the commit that updated the image tag:

   ```bash
   cd /path/to/petclinic-platform
   git log --oneline helm-values/
   ```

2. Revert the bad commit:

   ```bash
   git revert --no-edit <commit-sha>
   git push origin main
   ```

3. ArgoCD detects the revert and syncs the previous image tag back to the
   cluster.

4. Verify the rollback:

   ```bash
   aws eks update-kubeconfig --name petclinic-dev --region us-east-2
   kubectl get pods -n petclinic-dev -l app.kubernetes.io/name=<service-name>
   kubectl describe pod -n petclinic-dev <pod-name>
   ```

### Method 2: ArgoCD rollback

If ArgoCD has sync history, use the ArgoCD UI or CLI to rollback to a previous
sync.

#### ArgoCD CLI

```bash
# List sync history for an application
argocd app history <service-name>-dev

# Rollback to a specific revision (use the history id)
argocd app rollback <service-name>-dev <history-id>
```

#### ArgoCD UI

1. Open the ArgoCD UI (`https://<argocd-server>`).
2. Select the application.
3. Go to **History and Rollback**.
4. Choose a previous sync and click **Rollback**.

### Emergency fallback: kubectl rollout undo

Use this only when Git/ArgoCD is unavailable or you need an immediate local
revert.

```bash
aws eks update-kubeconfig --name petclinic-dev --region us-east-2
kubectl rollout undo deployment/<service-name> -n petclinic-dev
kubectl rollout status deployment/<service-name> -n petclinic-dev
```

> **Caution:** `kubectl rollout undo` reverts the Deployment in the cluster but
> does **not** update Git. The next ArgoCD sync will re-apply the Git state,
> potentially re-deploying the bad image. Always follow up with a Git revert if
> the rollback should persist.

### Rollback verification checklist

- [ ] Previous pod image tag is running:
  `kubectl get pods -n petclinic-dev -o jsonpath='{.items[0].spec.containers[0].image}'`
- [ ] Service is healthy:
  `kubectl get pods -n petclinic-dev -l app.kubernetes.io/name=<service-name>`
- [ ] Application endpoints return expected responses.
- [ ] If GitOps rollback was used, `helm-values/` reflects the desired image tag.

---

## Other Operations

The following procedures will be expanded in future updates:

- Restart a service
- Scale a service
- Access logs
- Connect to RDS
- Rotate secrets
- Stop/start the dev environment (`./scripts/stop-env.sh`, `./scripts/start-env.sh`)
