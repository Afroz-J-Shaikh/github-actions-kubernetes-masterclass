TF_DIR    ?= terraform
PLAN_FILE ?= tfplan
ARGOCD_MANIFEST ?= argocd/application.yaml
SLEEP_TIME      ?= 90s

.PHONY: all help init fmt validate plan apply destroy clean

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
	terraform -chdir=$(TF_DIR) validate

plan: init ## Generate and save a speculative execution plan
	@echo "==> Generating execution plan..."
	terraform -chdir=$(TF_DIR) plan -out=$(PLAN_FILE)

apply: init ## Apply changes (uses saved tfplan if present, otherwise auto-approves)
	@echo "==> Applying infrastructure changes..."
	@if [ -f $(TF_DIR)/$(PLAN_FILE) ]; then \
		terraform -chdir=$(TF_DIR) apply $(PLAN_FILE) && rm -f $(TF_DIR)/$(PLAN_FILE); \
	else \
		terraform -chdir=$(TF_DIR) apply -auto-approve; \
	fi
	@echo "==> Infrastructure applied successfully."
	@echo "==> Pausing for $(SLEEP_TIME) to let remote cluster components stabilize..."
	sleep $(SLEEP_TIME)
	@echo "==> Applying ArgoCD Application manifest..."
	kubectl apply -f $(ARGOCD_MANIFEST)

destroy: ## Destroy all remote infrastructure managed by this configuration
	@echo "==> Destroying remote infrastructure..."
	terraform -chdir=$(TF_DIR) destroy

clean: ## Remove locally generated plan files
	@echo "==> Cleaning local plan files..."
	rm -f $(TF_DIR)/$(PLAN_FILE)