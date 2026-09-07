# Nordeus SRE Challenge

Solved Noredus's SRE challenge they gave for a job fair.
The challenge was to deploy a small Python game service to Google Kubernetes Engine (GKE). 
I've upgraded a solution a little bit with Terraform, Docker, Helm, and GitHub Actions.

## Repository Layout

```text
.
├── .github/workflows/ci.yaml       # CI, image build, push, and deployment
├── game-service/                   # FastAPI application and Dockerfile
├── k8s/
│   ├── helm/game-service/          # Helm chart for the game service
│   ├── namespace/                  # game-service namespace manifest
│   └── deployments/                # Optional load-test spammer manifest
└── terraform/                      # GCP infrastructure and IAM
```

## Architecture

- **Application:** FastAPI running on port `8000`
- **Container image:** Google Artifact Registry
- **Runtime:** Google Kubernetes Engine
- **Network:** Custom regional VPC and subnet in `europe-central2` by default
- **Service exposure:** Kubernetes `LoadBalancer`
- **Autoscaling:** Horizontal Pod Autoscaler from 1 to 8 replicas at 70% average CPU
- **CI/CD:** GitHub Actions with Workload Identity Federation

The application currently stores player data in memory. Data is lost when the process or pod restarts; this is intentional for the simple challenge service and is not a persistent database design.

## Application Endpoints

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET` | `/` | Welcome response |
| `GET` | `/health` | Health response |
| `GET` | `/player/{player_id}/stats` | Read player statistics |
| `POST` | `/player/update` | Update player statistics |

Example requests:

```bash
curl http://localhost:8000/health
curl http://localhost:8000/player/12345/stats
curl -X POST http://localhost:8000/player/update \
  -H "Content-Type: application/json" \
  -d '{"player_id":"12345","level":10,"score":2500}'
```

## Run Locally

Requirements:

- Python 3.12 or compatible Python version
- `pip`

```bash
cd game-service
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
python main.py
```

The service is available at `http://localhost:8000`. To run the same health check used by CI:

```bash
curl -f http://127.0.0.1:8000/health
```

## Build and Run with Docker

```bash
cd game-service
docker build -t game-service:local .
docker run --rm -p 8000:8000 game-service:local
```

Then open `http://localhost:8000/health`.

## Provision GCP Infrastructure

Terraform configuration is in [`terraform/`](terraform/). It creates or configures:

- A custom VPC and subnet
- A regional GKE cluster
- A default GKE node pool
- An Artifact Registry Docker repository
- A GKE node service account with Artifact Registry read access
- IAM permissions for the GitHub Actions service account

The default values are defined in [`terraform/variables.tf`](terraform/variables.tf):

- Project: `nordeus-sre-challenge`
- Region: `europe-central2`
- Subnet CIDR: `10.0.0.0/24`

Before applying Terraform:

1. Select or create the GCP project.
2. Configure billing for the project.
3. Authenticate locally with `gcloud auth login`, or configure another supported Google provider authentication method.
4. Ensure the required GCP APIs and permissions are available.
5. Confirm that the project ID and GitHub Actions service account match your environment.

Run Terraform from the terraform folder:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

To use different values without editing the files:

```bash
terraform plan \
  -var='project_id=YOUR_PROJECT_ID' \
  -var='region=europe-central2' \
  -var='github_actions_sa=github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com'
```

Useful outputs:

```bash
terraform output gke_cluster_endpoint
terraform output repository_url
```

Terraform state contains infrastructure details and must not be committed. The repository `.gitignore` excludes Terraform state files. For shared or production use, configure a remote, protected Terraform backend instead of relying on local state.

## Deploy with Helm

The chart is in [`k8s/helm/game-service/`](k8s/helm/game-service/). It deploys the game service and its `LoadBalancer` service.

After Terraform creates the cluster and local `kubectl` access is configured:

```bash
gcloud container clusters get-credentials \
  nordeus-sre-challenge-cluster \
  --region europe-central2 \
  --project nordeus-sre-challenge

kubectl apply -f k8s/namespace/namespace.yaml
helm lint k8s/helm/game-service
helm upgrade --install game-service \
  k8s/helm/game-service \
  --namespace game-service \
  --create-namespace
```

Check the rollout and external address:

```bash
kubectl -n game-service rollout status deployment/game-service
kubectl -n game-service get pods,service,hpa
```

The image repository and tag can be overridden at deployment time:

```bash
helm upgrade --install game-service k8s/helm/game-service \
  --namespace game-service \
  --set image.repository=REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/game-service \
  --set image.tag=IMAGE_TAG
```

## GitHub Actions

The workflow is [.github/workflows/ci.yaml](.github/workflows/ci.yaml).

### Pull requests targeting `main`

`BuildGameService` runs. It installs Python dependencies, starts the service in the background, and checks `/health`.

### Merges to `main`

Both jobs run:

1. `BuildGameService` validates the service.
2. `PushToGCP` authenticates to GCP using Workload Identity Federation.
3. The Docker image is built and pushed to Artifact Registry.
4. GKE credentials are loaded.
5. The Helm chart image tag is updated and linted.
6. Helm upgrades the `game-service` release.

Configure these **repository variables** in GitHub under **Settings > Secrets and variables > Actions > Variables**:

| Variable | Description |
| --- | --- |
| `GCP_PROJECT_ID` | GCP project ID |
| `GCP_PROJECT_NUMBER` | Numeric GCP project number |
| `GCP_REGION` | Artifact Registry and GKE region, for example `europe-central2` |
| `GCP_IMAGE_REPO` | Artifact Registry repository, for example `sre-challenge-images` |
| `GCP_IMAGE_NAME` | Image name, for example `game-service` |
| `GCP_SERVICE_ACCOUNT` | GitHub Actions service account email |
| `GCP_CLUSTER` | GKE cluster name |

The workflow uses OIDC and Workload Identity Federation. It does not require a long-lived `GCP_SA_KEY` JSON key. The identity provider referenced by the workflow must already exist and trust the GitHub repository or organization.

## Optional Load Test

[`k8s/deployments/spammer-deployment.yaml`](k8s/deployments/spammer-deployment.yaml) defines a separate spammer deployment. Before using it, update `SPAMMER_BASE_URL` to the current external address of the game-service `LoadBalancer`; the checked-in value is an example address.

```bash
kubectl apply -f k8s/deployments/spammer-deployment.yaml
kubectl get deployment spammer
```

## Cleanup

Remove the Helm release and optional test workload:

```bash
helm uninstall game-service --namespace game-service
kubectl delete -f k8s/deployments/spammer-deployment.yaml --ignore-not-found
```

Destroy Terraform-managed infrastructure only when you are sure it is no longer needed:

```bash
cd terraform
terraform destroy
```

## Security Notes

- Do not commit service account JSON keys, `.env` files, Terraform state, or Terraform variable files containing secrets.
- Prefer Workload Identity Federation for GitHub Actions over static GCP keys.
- Replace broad permissions and `cloud-platform` OAuth scopes with least-privilege settings before production use.
- Add persistent storage or an external database if player data must survive pod restarts.
