# ##############################################################################
# DEVENV (development testing environment)
# ##############################################################################
up:
	docker compose -f docker/docker-compose-three-miners.yml --profile default --profile bitcoin-mempool up -d

down:
	docker compose -f docker/docker-compose-three-miners.yml --profile default --profile bitcoin-mempool down -t 0 -v

build:
	docker compose -f docker/docker-compose.yml --profile default --profile bitcoin-mempool build

x: # down && build && up
	docker compose -f docker/docker-compose-three-miners.yml --profile default --profile bitcoin-mempool down -t 0 -v
	docker compose -f docker/docker-compose-three-miners.yml --profile default --profile bitcoin-mempool build
	docker compose -f docker/docker-compose-three-miners.yml --profile default --profile bitcoin-mempool up -d

.PHONY: up down build x
