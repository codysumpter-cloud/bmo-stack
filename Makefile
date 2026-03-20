.PHONY: up down status logs doctor sync-context

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

doctor:
	@echo "Checking Docker and Docker Compose..."
	@which docker >/dev/null 2>&1 || { echo "Error: docker not found"; exit 1; }
	@which docker compose >/dev/null 2>&1 || { echo "Error: docker compose not found"; exit 1; }
	@echo "Docker and Docker Compose are available."
	@echo "Checking OpenClaw gateway on host..."
	@if [ -f $$HOME/.openclaw/openclaw.json ]; then \
		echo "OpenClaw config found."; \
	else \
		echo "Warning: OpenClaw config not found at $$HOME/.openclaw/openclaw.json"; \
	fi
	@echo "Checking OpenShell..."
	@which openshell >/dev/null 2>&1 || { echo "Error: openshell not found"; exit 1; }
	@echo "OpenShell is available."
	@echo "Checking context files..."
	@if [ -d ./context ] && [ -f ./context/BOOTSTRAP.md ]; then \
		echo "Context files present."; \
	else \
		echo "Error: Context files missing."; \
		exit 1; \
	fi
	@echo "All checks passed."