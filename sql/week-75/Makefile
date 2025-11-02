help: ## Usage
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: build run clean

build: ## Build Docker image
	docker-compose build

run: build ## Run interactive shell
	docker-compose run --rm snowflake-native-app

clean: ## Clean up containers
	docker-compose down -v
