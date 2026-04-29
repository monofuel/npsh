.PHONY: test unit-test integration-test docker-up docker-down

test: unit-test integration-test

unit-test:
	nimble test -y

docker-up:
	@test -f tests/docker/id_ed25519 || ssh-keygen -t ed25519 -f tests/docker/id_ed25519 -N "" -C "npsh-test-key" -q
	docker compose -f tests/docker/docker-compose.yml up -d --build
	@echo "Waiting for SSH to be ready..."
	@for port in 2220 2221 2222; do \
		for i in $$(seq 1 30); do \
			ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
				-o IdentityFile=tests/docker/id_ed25519 \
				-p $$port root@127.0.0.1 true 2>/dev/null && break; \
			sleep 1; \
		done; \
	done

docker-down:
	docker compose -f tests/docker/docker-compose.yml down -v

integration-test: docker-up
	NPSH_CONFIG=tests/docker/test_npsh_config \
	NPSH_SSH_OPTS="-o IdentityFile=tests/docker/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR" \
	nim r tests/docker/test_integration.nim; \
	EXIT_CODE=$$?; \
	$(MAKE) docker-down; \
	exit $$EXIT_CODE
