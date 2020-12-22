.DEFAULT_GOAL := all

# General
PROJECT_NAME := enderscraft
BUILD_DIR    := $(PWD)
SCRIPT_DIR   := $(BUILD_DIR)/src

# Docker
BASE_IMAGE := $(BUILD_DIR)/docker
IMAGE_ROOT := $(BASE_IMAGE)/files
DATA_DIR   := /data

# Container
SERVICE_USER  := minecraft
SERVICE_GROUP := minecraft
SERVICE_HOME  := $(DATA_DIR)/$(SERVICE_USER)

# Java
JAVA_PACKAGE := java-15-amazon-corretto-jdk

# Minecraft
VERSION_MANIFEST_URL := https://launchermeta.mojang.com/mc/game/version_manifest.json
LATEST_TAG  := release
LISTEN_PORT := 25565
RCON_PORT   := 25575

.PHONY: all
all:
	make prepare-image-root
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


.PHONE: prepare-image-root
prepare-image-root:
	make download-minecraft-server
	make update-aws-apt-key


.PHONY: download-minecraft-server
download-minecraft-server:
	$(SCRIPT_DIR)/py/download-minecraft-server.py \
		--debug \
		--latest $(LATEST_TAG) \
			$(IMAGE_ROOT)$(SERVICE_HOME)


.PHONY: update-aws-apt-key
update-aws-apt-key:
	$(SCRIPT_DIR)/sh/update-aws-apt-key.sh

# .PHONY: help
# help:
