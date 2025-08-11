.PHONY: build run jupyter shell clean

# Build Docker image
build:
	docker-compose build

# Run interactive shell
run: build
	docker-compose run --rm snowflake-python

# Run Jupyter notebook
jupyter: build
	docker-compose up jupyter

# Quick shell access
shell:
	docker-compose exec snowflake-python /bin/bash

# Clean up containers
clean:
	docker-compose down -v