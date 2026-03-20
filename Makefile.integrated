.PHONY: up down status logs doctor sync-context sync-context-host-to-repo sync-context-repo-to-host worker-create worker-upload-config worker-connect worker-status worker-ready openclaw-start openclaw-status

# Docker Compose file
COMPOSE_FILE=compose.yaml

up:
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose -f $(COMPOSE_FILE) down

status:
	docker compose -f $(COMPOSE_FILE) ps

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

sync-context:
	./scripts/sync-context.sh

sync-context-host-to-repo:
	./scripts/sync-context.sh --host-to-repo

sync-context-repo-to-host:
	./scripts/sync-context.sh --repo-to-host

doctor:
	@echo "Checking Docker and Docker Compose..."
	@which docker >/dev/null 2>&1 || { echo "Error: docker not found"; exit 1; }
	@which docker compose >/dev/null 2>&1 || { echo "Error: docker compose not found"; exit 1; }
	@echo "Docker and Docker Compose are available."
	@echo "Checking OpenClaw binary..."
	@which openclaw >/dev/null 2>&1 || { echo "Error: openclaw binary not found"; exit 1; }
	@echo "OpenClaw binary found."
	@echo "Checking OpenShell binary..."
	@which openshell >/dev/null 2>&1 || { echo "Error: openshell binary not found"; exit 1; }
	@echo "OpenShell binary found."
	@echo "Checking OpenClaw gateway config on host..."
	@if [ -f $$HOME/.openclaw/openclaw.json ]; then \
		echo "OpenClaw config found."; \
	else \
		echo "Warning: OpenClaw config not found at $$HOME/.openclaw/openclaw.json"; \
	fi
	@echo "Checking ~/bmo-context exists..."
	@if [ -d $$HOME/bmo-context ]; then \
		echo "~/bmo-context exists."; \
	else \
		echo "Error: ~/bmo-context does not exist"; \
		exit 1; \
	fi
	@echo "Checking context files in repo..."
	@if [ -d ./context ] && [ -f ./context/BOOTSTRAP.md ]; then \
		echo "Context files present."; \
	else \
		echo "Error: Context files missing in repo."; \
		exit 1; \
	fi
	@echo "All checks passed."

# Worker sandbox management
worker-create:
	@if openshell sandbox list | grep -q bmo-tron; then \
		echo "Sandbox bmo-tron already exists."; \
	else \
		echo "Creating sandbox bmo-tron..."; \
		openshell sandbox create --name bmo-tron; \
	fi

worker-upload-config:
	@if [ ! -f $$HOME/.openclaw/openclaw.json ]; then \
		echo "Error: OpenClaw config not found at $$HOME/.openclaw/openclaw.json"; exit 1; \
	fi
	echo "Uploading OpenClaw config to sandbox..."
	openshell sandbox upload bmo-tron $$HOME/.openclaw/openclaw.json .openclaw/openclaw.json

worker-connect:
	openshell sandbox connect bmo-tron

worker-status:
	openshell sandbox list | grep bmo-tron || echo "Sandbox bmo-tron not found."

# New target: worker-ready creates the sandbox and uploads config in one go
worker-ready: worker-create worker-upload-config
	@echo "Worker sandbox bmo-tron is ready for use."

# OpenClaw gateway management (host)
openclaw-start:
	openclaw gateway start

openclaw-status:
	openclaw gateway status
