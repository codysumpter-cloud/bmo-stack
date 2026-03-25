.PHONY: up down status logs doctor sync-context sync-context-host-to-repo sync-context-repo-to-host worker-create worker-upload-config worker-connect worker-status openclaw-start openclaw-status recover-session worker-ready health-check doctor-plus checkpoint omni-sync omni-doctor omni-launch recover-bmo update-all runtime-doctor runtime-profile-dev runtime-profile-snappy runtime-profile-robust runtime-face-idle runtime-loop runtime-router runtime-profile2-dev runtime-profile2-snappy runtime-profile2-robust runtime-stt-once runtime-face-rich-idle runtime-launch runtime-launch-dry runtime-cloud-once runtime-cloud-dry workspace-sync site-caretaker site-route-report site-work-report site-route-scaffold site-route-update site-page-checklist launchd-install

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

# Enhanced doctor target with more comprehensive checks
doctor-plus: doctor
	@echo "Running extended health checks..."
	@./scripts/bot-health.sh || echo "Some health checks failed (see above)"
	@echo "Extended health checks completed."

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

# Session recovery
recover-session:
	@./scripts/recover-session.sh

# Checkpoint target
checkpoint:
	@./scripts/checkpoint.sh $(if $(ARGS),$(ARGS))

# Health check target
health-check:
	@echo "Running BMO health check..."
	@./scripts/bot-health.sh

# BMO recovery target
recover-bmo:
	@echo "Running BMO recovery..."
	@./scripts/bot-recover.sh

# Multi-repo update target
update-all:
	@echo "Updating local BMO repos..."
	@./scripts/update-all.sh

# BMO native runtime targets
runtime-doctor:
	@bash ./scripts/bmo-runtime-doctor.sh

runtime-profile-dev:
	@python3 ./scripts/apply-bmo-runtime-profile.py dev

runtime-profile-snappy:
	@python3 ./scripts/apply-bmo-runtime-profile.py snappy

runtime-profile-robust:
	@python3 ./scripts/apply-bmo-runtime-profile.py robust

runtime-profile2-dev:
	@python3 ./scripts/apply-bmo-runtime-profile-v2.py dev

runtime-profile2-snappy:
	@python3 ./scripts/apply-bmo-runtime-profile-v2.py snappy

runtime-profile2-robust:
	@python3 ./scripts/apply-bmo-runtime-profile-v2.py robust

runtime-face-idle:
	@bash ./scripts/bmo-face.sh idle

runtime-face-rich-idle:
	@python3 ./scripts/bmo-face-rich.py idle

runtime-loop:
	@python3 ./scripts/bmo_voice_loop.py

runtime-router:
	@python3 ./scripts/bmo-model-router.py --task "$(if $(ARGS),$(ARGS),hello bmo)"

runtime-stt-once:
	@python3 ./scripts/bmo-stt-listen.py --once "$(if $(ARGS),$(ARGS),hello bmo)"

runtime-launch:
	@python3 ./scripts/bmo-runtime-launch.py $(if $(ARGS),$(ARGS))

runtime-launch-dry:
	@python3 ./scripts/bmo-runtime-launch.py --dry-run $(if $(ARGS),$(ARGS))

runtime-cloud-once:
	@python3 ./scripts/bmo-runtime-launch.py --force-route cloud --once "$(if $(ARGS),$(ARGS),hello bmo)"

runtime-cloud-dry:
	@python3 ./scripts/bmo-runtime-launch.py --dry-run --force-route cloud --once "$(if $(ARGS),$(ARGS),hello bmo)"

workspace-sync:
	@python3 ./scripts/bmo-workspace-sync.py $(if $(ARGS),$(ARGS))

site-caretaker:
	@python3 ./scripts/bmo-site-caretaker.py $(if $(ARGS),$(ARGS))

site-route-report:
	@python3 ./scripts/prismtek_site_route_report.py

site-work-report:
	@python3 ./scripts/prismtek_site_work_report.py

site-route-scaffold:
	@python3 ./scripts/prismtek_site_route_scaffold.py $(if $(ARGS),$(ARGS))

site-route-update:
	@python3 ./scripts/prismtek_site_route_update.py $(if $(ARGS),$(ARGS))

site-page-checklist:
	@cat ./context/council/NEPTR_WEBSITE_CHECKLIST.md

launchd-install:
	@python3 ./scripts/bmo-launchd-install.py $(if $(ARGS),$(ARGS))

# omni-bmo bridge targets
omni-sync:
	@bash ./scripts/sync-omni-bmo.sh

omni-doctor:
	@bash ./scripts/bmo-omni-doctor.sh

omni-launch:
	@bash ./scripts/bmo-omni-launch.sh
