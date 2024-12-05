help: ## Usage
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

log_file:="makefile.log"

build: ## docker image build
	docker buildx build --platform linux/amd64 . > $(log_file) 2>&1
	tail -n 5 $(log_file)

run: ## Run Docker service
	docker compose run --rm tf
