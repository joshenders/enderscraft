.DEFAULT_GOAL := all

# General
PROJECT_NAME := enderscraft
BUILD_DIR    := $(PWD)
SCRIPT_DIR   := $(BUILD_DIR)/src
DEPENDENCIES := aws black docker fargate find git grep python3 sed shellcheck tee xargs

# Docker
BASE_IMAGE         := $(BUILD_DIR)/docker/debian/base-corretto
BASE_IMAGE_ROOT    := $(BASE_IMAGE)/files
SERVICE_IMAGE      := $(BUILD_DIR)/docker/debian/enderscraft
SERVICE_IMAGE_ROOT := $(SERVICE_IMAGE)/files
DATA_DIR           := /data

# Deployment
SHORT_COMMIT := $(shell git rev-parse --short HEAD)
LONG_COMMIT  := $(shell git rev-parse HEAD)

# AWS
AWS_REGION     := $(shell aws configure get region --profile $(PROJECT_NAME))
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --profile 'default' --output 'text' --query 'Account')
AWS_VPC_ID     := $(shell aws ec2 describe-vpcs --profile 'default' --output 'text' --filters 'Name=tag:aws:cloudformation:stack-name,Values=${PROJECT_NAME}' --query 'Vpcs[0].VpcId')
AWS_SUBNET_ID  := $(shell aws ec2 describe-subnets --profile 'default' --output 'text' --filters "Name=tag:Name,Values=${PROJECT_NAME}-SubnetPublic" --query 'Subnets[0].SubnetId')
AWS_SG_ID      := $(shell aws ec2 describe-security-groups --profile 'default' --output 'text' --filters "Name=tag:Name,Values=${PROJECT_NAME}-SecurityGroupFargateTasks" --query 'SecurityGroups[0].GroupId')

# Container
MINECRAFT_USER  := minecraft
MINECRAFT_GROUP := minecraft
MINECRAFT_HOME  := $(DATA_DIR)/$(MINECRAFT_USER)

# Java
JAVA_MAJOR_VERSION := 15
JAVA_DIR           := java-$(JAVA_MAJOR_VERSION)-amazon-corretto
JAVA_PACKAGE       := $(JAVA_DIR)-jdk
JAVA_HOME          := /usr/lib/jvm/$(JAVA_DIR)

# Minecraft
VERSION_MANIFEST_URL := https://launchermeta.mojang.com/mc/game/version_manifest.json
LATEST_TAG           := release
MINECRAFT_PORT       := 25565
RCON_PORT            := 25575


.PHONY: all
all: ## A meaningful description
	@make check
	@make _build-base-corretto
	@make _prepare-image-root
	@make _build-enderscraft


.PHONY: _build-base-corretto
_build-base-corretto: ## A meaningful description
	docker build \
		--build-arg JAVA_DIR=$(JAVA_DIR) \
		--build-arg JAVA_HOME=$(JAVA_HOME) \
		--build-arg JAVA_PACKAGE=$(JAVA_PACKAGE) \
		--build-arg JAVA_PACKAGE=$(JAVA_PACKAGE) \
		--tag debian-base-corretto \
			"$(BASE_IMAGE)"


.PHONY: _build-enderscraft
_build-enderscraft: ## A meaningful description
	docker build \
		--build-arg DATA_DIR=$(DATA_DIR) \
		--build-arg RCON_PORT=$(RCON_PORT) \
		--build-arg MINECRAFT_GROUP=$(MINECRAFT_GROUP) \
		--build-arg MINECRAFT_HOME=$(MINECRAFT_HOME) \
		--build-arg MINECRAFT_PORT=$(MINECRAFT_PORT) \
		--build-arg MINECRAFT_USER=$(MINECRAFT_USER) \
		--tag $(PROJECT_NAME) \
			"$(SERVICE_IMAGE)"


.PHONY: check
check: ## Check if dependencies are installed
	@$(SCRIPT_DIR)/dependency-check.sh $(DEPENDENCIES)


.PHONY: clean
clean: ## Remove files generated by this Makefile
	@find . \
		-type f \
		\(\
			-name "minecraft_server-*.jar" \
		\)\
		-print \
		-delete


.PHONY: _download-minecraft-server
_download-minecraft-server: ## Download minecraft server to $$(SERVICE_IMAGE_ROOT)
	$(SCRIPT_DIR)/download-minecraft-server.py \
		--debug \
		--latest $(LATEST_TAG) \
			"$(SERVICE_IMAGE_ROOT)$(MINECRAFT_HOME)"


.PHONY: help
help: ## Display this helpful message
	@IFS=$$'\n'; \
	help_lines=(`grep -h "[#]#" $(MAKEFILE_LIST) | grep -v "^_" | sed -e 's/\\$$//'`); \
	for help_line in $${help_lines[@]}; do \
		IFS=$$'#'; \
		help_split=($$help_line); \
		help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'`; \
		help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'`; \
		printf "%-20s %s\n" $$help_command $$help_info; \
	done


.PHONY: _prepare-image-root
_prepare-image-root: ## A meaningful description
	@make _download-minecraft-server


.PHONY: push
push: ## Login to ECR, tag latest image, upload latest image to ECR
	aws ecr get-login-password \
		--region "${AWS_REGION}" \
	| docker login \
		--username "AWS" \
		--password-stdin \
			"${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
	docker tag \
		"${PROJECT_NAME}:latest" \
		"${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}:latest"
	docker push \
		"${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}:latest"


.PHONY: task
task: ## A meaningful description
	fargate task run \
		--subnet-id "${AWS_SUBNET_ID}" \
		--security-group-id "${AWS_SG_ID}" \
		--env "ACCEPT_EULA=yes" \
		--cpu "2048" \
		--memory "4096" \
		--image "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/enderscraft:latest" \
			"$(PROJECT_NAME)"
