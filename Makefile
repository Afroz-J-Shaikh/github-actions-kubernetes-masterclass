TF_DIR           ?= terraform
TF_STATE_DIR     ?= state-backend
ARGOCD_MANIFEST  ?= argocd/application.yaml
ENV              ?= dev
VAR_FILE         ?= $(ENV).tfvars
SLEEP_TIME       ?= 90s

.PHONY: all help bootstrap init fmt validate workspace plan apply deploy destroy

# =========================================================
# Default workflow
# =========================================================

all: fmt init validate plan apply deploy ## Run full workflow

# =========================================================
# Help Menu
# =========================================================

help: ## Display available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; \
	{printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# =========================================================
# Bootstrap Remote Backend (RUN ONCE)
# Creates:
# - S3 bucket
# - DynamoDB lock table
# =========================================================

bootstrap: ## Create Terraform remote backend resources
	@echo "==> Initializing Terraform backend bootstrap..."
	terraform -chdir=$(TF_STATE_DIR) init

	@echo "==> Creating S3 bucket and DynamoDB lock table..."
	terraform -chdir=$(TF_STATE_DIR) fmt
	terraform -chdir=$(TF_STATE_DIR) apply -auto-approve

	@echo "==> Backend infrastructure created successfully."

# =========================================================
# Initialize Terraform
# =========================================================

init: ## Initialize Terraform and backend
	@echo "==> Initializing Terraform in '$(TF_DIR)'..."
	terraform -chdir=$(TF_DIR) init

# =========================================================
# Terraform Formatting
# =========================================================

fmt: ## Check Terraform formatting
	@echo "==> Checking Terraform formatting..."	
	terraform -chdir=$(TF_DIR) fmt -recursive

# =========================================================
# Workspace Handling
# =========================================================

workspace: init ## Select or create Terraform workspace
	@echo "==> Selecting workspace: $(ENV)"
	terraform -chdir=$(TF_DIR) workspace select $(ENV) || \
	terraform -chdir=$(TF_DIR) workspace new $(ENV)

# =========================================================
# Terraform Validation
# =========================================================

validate: workspace ## Validate Terraform configuration
	@echo "==> Validating Terraform configuration..."
	terraform -chdir=$(TF_DIR) validate

# =========================================================
# Terraform Plan
# =========================================================

plan: workspace ## Generate Terraform execution plan
	@echo "==> Generating execution plan..."
	terraform -chdir=$(TF_DIR) plan \
		-var-file=$(VAR_FILE)

# =========================================================
# Terraform Apply
# =========================================================

apply: workspace ## Apply Terraform infrastructure changes
	@echo "==> Applying infrastructure changes..."
	terraform -chdir=$(TF_DIR) apply \
		-var-file=$(VAR_FILE) \
		-auto-approve

	@echo "==> Infrastructure applied successfully."

# =========================================================
# ArgoCD Deployment
# =========================================================

deploy: ## Deploy ArgoCD application
	@echo "==> Waiting $(SLEEP_TIME) for cluster stabilization..."
	sleep $(SLEEP_TIME)

	@echo "==> Deploying ArgoCD application..."
	kubectl apply -f $(ARGOCD_MANIFEST)

	@echo "==> Application deployed successfully."

# =========================================================
# Terraform Destroy
# =========================================================

destroy:  ## Destroy Terraform-managed infrastructure
	@echo "==> Removing ArgoCD application..."
	kubectl delete -f argocd/application.yaml --cascade --ignore-not-found || true
	@echo "==> ArgoCD application removed."

	@echo "==> Destroying infrastructure..."
	terraform -chdir=$(TF_DIR) destroy \
		-var-file=$(VAR_FILE) \
		-auto-approve || true
	@echo "==> Infrastructure destroyed successfully."

	@echo "==> Destroying Terraform backend resources..."
	terraform -chdir=$(TF_STATE_DIR) init
	terraform -chdir=$(TF_STATE_DIR) destroy -auto-approve
	@echo "==> Backend infrastructure destroyed."
