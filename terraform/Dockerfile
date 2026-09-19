################################################################################
# Base Image
################################################################################

FROM ubuntu:24.04


################################################################################
# Arguments
################################################################################

# terraform version
ARG terraform_version="1.16.3"
ARG terragrunt_version="1.1.5"


################################################################################
# Run commands
################################################################################

# Install tools
RUN apt update && \
  apt install --yes sudo make curl unzip git && \
  # Install terraform
  curl -O "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip" && \
  unzip ./terraform_${terraform_version}_linux_amd64.zip -d /usr/local/bin/ && \
  rm -rf ./terraform_${terraform_version}_linux_amd64.zip && \
  # Install terragrunt
  curl -L -o /usr/local/bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/v${terragrunt_version}/terragrunt_linux_amd64" && \
  chmod +x /usr/local/bin/terragrunt
