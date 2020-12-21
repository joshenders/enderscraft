.DEFAULT_GOAL := all

# General
PROJECT_NAME := enderscraft
BUILD_DIR    := $(PWD)
SCRIPT_DIR   := $(BUILD_DIR)/src

# Docker
BASE_IMAGE := $(BUILD_DIR)/docker
DATA_DIR   := /data

# Container
SERVICE_USER  := minecraft
SERVICE_GROUP := minecraft
SERVICE_HOME  := $(DATA_DIR)/$(SERVICE_USER)

# Java
JAVA_PACKAGE := java-15-amazon-corretto-jdk

# Minecraft
LISTEN_PORT := 25565
RCON_PORT   := 25575

.PHONY: all
all:
	make update-aws-apt-key
	make build

.PHONY: build
build:
	docker build \
		--build-arg DATA_DIR=$(DATA_DIR) \
		--build-arg SERVICE_USER=$(SERVICE_USER) \
		--build-arg SERVICE_GROUP=$(SERVICE_GROUP) \
		--build-arg SERVICE_HOME=$(SERVICE_HOME) \
		--build-arg JAVA_PACKAGE=$(JAVA_PACKAGE) \
		--build-arg LISTEN_PORT=$(LISTEN_PORT) \
		--build-arg RCON_PORT=$(RCON_PORT) \
			$(BASE_IMAGE)


.PHONY: update-aws-apt-key
update-aws-apt-key:
	$(SCRIPT_DIR)/update-aws-apt-key.sh

# .PHONY: help
# help: