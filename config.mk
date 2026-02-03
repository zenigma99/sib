# ==========================================
# SIB Configuration Variables
# ==========================================
# Shared variables used throughout the Makefile
# ==========================================

# Terminal colors (using shell to generate actual escape sequences)
GREEN  := $(shell printf '\033[32m')
YELLOW := $(shell printf '\033[33m')
RED    := $(shell printf '\033[31m')
CYAN   := $(shell printf '\033[36m')
RESET  := $(shell printf '\033[0m')
BOLD   := $(shell printf '\033[1m')

# Docker compose command - include root .env file for all stacks
DOCKER_COMPOSE := docker compose --env-file $(CURDIR)/.env

# Ansible configuration (runs in Docker - no local installation needed)
ANSIBLE_IMAGE := sib-ansible:latest
ANSIBLE_RUN   := docker compose -f ansible/compose.yaml run --rm ansible
ANSIBLE_LIMIT := $(if $(LIMIT),--limit $(LIMIT),)
ANSIBLE_ARGS  := $(if $(ARGS),$(ARGS),)
