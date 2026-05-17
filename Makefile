TF_DIR    ?= terraform
ARGOCD_MANIFEST ?= argocd/application.yaml
ENV ?= dev
VAR_FILE ?= dev.tfvars
SLEEP_TIME      ?= 90s

.PHONY: all help init fmt validate plan apply destroy 

all: ## Default: Format, initialize, validate, plan, and apply everything in sequence
	$(MAKE) fmt
	$(MAKE) init
	$(MAKE) validate
	$(MAKE) plan
	$(MAKE) apply

help: ## Display this help screen with available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## Initialize remote state backend and download provider plugins
	@echo "==> Initializing Terraform in '$(TF_DIR)'..."
	terraform -chdir=$(TF_DIR) init

fmt: ## Check if Terraform files match canonical formatting style
	@echo "==> Checking Terraform formatting..."
	terraform -chdir=$(TF_DIR) fmt

validate: init ## Validate the syntax and consistency of configuration files
	@echo "==> Validating Terraform configuration..."
	terraform -chdir=$(TF_DIR) workspace select $(ENV) || \
		terraform -chdir=$(TF_DIR) workspace new $(ENV)
	terraform -chdir=$(TF_DIR) validate

plan: init ## Generate and save a speculative execution plan
	@echo "==> Generating execution plan..."
	terraform -chdir=$(TF_DIR) workspace select $(ENV) || \
		terraform -chdir=$(TF_DIR) workspace new $(ENV)
	terraform -chdir=$(TF_DIR) plan -var-file=$(VAR_FILE)

apply: init ## Apply changes (uses saved tfplan if present, otherwise auto-approves)
	@echo "==> Applying infrastructure changes..."
	terraform -chdir=$(TF_DIR) workspace select $(ENV) || \
		terraform -chdir=$(TF_DIR) workspace new $(ENV)
	terraform -chdir=$(TF_DIR) apply -var-file=$(VAR_FILE) -auto-approve
	@echo "==> Infrastructure applied successfully."
	@echo "==> Pausing for $(SLEEP_TIME) to let remote cluster components stabilize..."
	sleep $(SLEEP_TIME)
	@echo "==> Applying ArgoCD Application manifest..."
	kubectl apply -f $(ARGOCD_MANIFEST)

destroy: ## Destroy all remote infrastructure managed by this configuration
	@echo "==> Destroying remote infrastructure..."
	terraform -chdir=$(TF_DIR) workspace select $(ENV) || \
		terraform -chdir=$(TF_DIR) workspace new $(ENV)
	terraform -chdir=$(TF_DIR) destroy -var-file=$(VAR_FILE) -auto-approve
