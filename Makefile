# ##############################################################################
# DEVENV (development testing environment)
# ##############################################################################
up:
	docker compose -f docker/docker-compose-three-miners.yml --profile default up -d

down:
	docker compose -f docker/docker-compose-three-miners.yml --profile default down -t 0 -v

build:
	docker compose -f docker/docker-compose-three-miners.yml --profile default build

x: # down && build && up
	docker compose -f docker/docker-compose-three-miners.yml --profile default down -t 0 -v
	docker compose -f docker/docker-compose-three-miners.yml --profile default build
	docker compose -f docker/docker-compose-three-miners.yml --profile default up -d

.PHONY: up down build x
