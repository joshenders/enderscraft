.DEFAULT_GOAL := all

# General
PROJECT_NAME := enderscraft
BUILD_DIR    := $(PWD)
SCRIPT_DIR   := $(BUILD_DIR)/src

# Docker
BASE_IMAGE := $(BUILD_DIR)/docker/debian
IMAGE_ROOT := $(BASE_IMAGE)/files
DATA_DIR   := /data

# Deployment
SHORT_COMMIT := $(shell git rev-parse --short HEAD)
LONG_COMMIT  := $(shell git rev-parse HEAD)

# Container
SERVICE_USER  := minecraft
SERVICE_GROUP := minecraft
SERVICE_HOME  := $(DATA_DIR)/$(SERVICE_USER)

# Java
JAVA_MAJOR_VERSION := 15
JAVA_DIR           := java-$(JAVA_MAJOR_VERSION)-amazon-corretto
JAVA_PACKAGE       := $(JAVA_DIR)-jdk
JAVA_HOME          := /usr/lib/jvm/$(JAVA_DIR)

# Minecraft
VERSION_MANIFEST_URL := https://launchermeta.mojang.com/mc/game/version_manifest.json
LATEST_TAG  := release
LISTEN_PORT := 25565
RCON_PORT   := 25575


.PHONY: all
all:
	make build-corretto-base
	make prepare-image-root
	make build-minecraft


.PHONY: build-corretto-base
build-corretto-base:
	docker build \
		--build-arg JAVA_PACKAGE=$(JAVA_PACKAGE) \
		--build-arg JAVA_DIR=$(JAVA_DIR) \
		--build-arg JAVA_HOME=$(JAVA_HOME) \
		--build-arg JAVA_PACKAGE=$(JAVA_PACKAGE) \
		--tag debian-corretto-base \
		--file "$(BASE_IMAGE)"/Dockerfile.corretto-base \
			"$(BASE_IMAGE)"


.PHONY: build-minecraft
build-minecraft:
	docker build \
		--build-arg DATA_DIR=$(DATA_DIR) \
		--build-arg SERVICE_USER=$(SERVICE_USER) \
		--build-arg SERVICE_GROUP=$(SERVICE_GROUP) \
		--build-arg SERVICE_HOME=$(SERVICE_HOME) \
		--build-arg LISTEN_PORT=$(LISTEN_PORT) \
		--build-arg RCON_PORT=$(RCON_PORT) \
		--tag enderscraft \
		--file "$(BASE_IMAGE)"/Dockerfile.minecraft \
			"$(BASE_IMAGE)"


.PHONY: prepare-image-root
prepare-image-root:
	make download-minecraft-server


.PHONY: download-minecraft-server
download-minecraft-server:
	$(SCRIPT_DIR)/download-minecraft-server.py \
		--debug \
		--latest $(LATEST_TAG) \
			"$(IMAGE_ROOT)$(SERVICE_HOME)"


# .PHONY: help
# help:

