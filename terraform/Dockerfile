################################################################################
# Base Image
################################################################################

FROM ubuntu:24.04


################################################################################
# Arguments
################################################################################

# terraform version
ARG terraform_version="1.9.8"


################################################################################
# Run commands
################################################################################

# Install tools
RUN apt update && \
  apt install --yes sudo make curl unzip git && \
  # Install terraform
  curl -O "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip" && \
  unzip ./terraform_${terraform_version}_linux_amd64.zip -d /usr/local/bin/ && \
  rm -rf ./terraform_${terraform_version}_linux_amd64.zip
