help: ## Usage
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

validate: ## terraform validate
	terragrunt run --all validate

init: ## terraform init(if .terraform not exists)
	terragrunt run --all init

fmt: ## terraform fmt
	terragrunt run --all -- fmt -recursive

plan: init fmt validate ## terraform plan
	terragrunt run --all plan -no-color > terraform_plan.log 2>&1
	tail -n 7 terraform_plan.log

apply: ## terraform apply
	terragrunt run --all --non-interactive -- apply -auto-approve -no-color > terraform_apply.log 2>&1
	tail -n 7 terraform_apply.log
