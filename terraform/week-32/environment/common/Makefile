help: ## Usage
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

validate: ## terraform validate
	terraform validate

.terraform:
	terraform init

init: .terraform ## terraform init(if .terraform not exists)

fmt: ## terraform fmt
	terraform fmt -recursive

plan: init fmt validate ## terraform plan
	terraform plan -no-color > terraform_plan.log 2>&1
	tail -n 7 terraform_plan.log

apply: ## terraform apply
	terraform apply --auto-approve -no-color > terraform_apply.log 2>&1
	tail -n 7 terraform_apply.log

destroy: ## terraform destroy
	terraform destroy -auto-approve -no-color > terraform_destroy.log 2>&1
	tail -n 7 terraform_destroy.log
