# ##############################################################################
# DEVENV (development testing environment)
# ##############################################################################
# Network with 3 miners/signers|seed node|api
up:
	# DOCKER_NETWORK=stacks docker compose -f docker/docker-compose.yml --profile default up -d
	docker compose -f docker/docker-compose.yml --profile default up -d
down:
	# DOCKER_NETWORK=stacks docker compose -f docker/docker-compose.yml --profile default down -t 0 -v
	docker compose -f docker/docker-compose.yml --profile default down -t 0 -v
# Network with 3 miners/signers|2 followre|seed node|api
up-follower:
	STACKS_FOLLOWER_REPLICAS=2 docker compose -f docker/docker-compose.yml --profile default up -d
down-follower:
	STACKS_FOLLOWER_REPLICAS=2 docker compose -f docker/docker-compose.yml --profile default down -t 0 -v

# Network with 5 miners/signers|seed node|api
up-five:
	docker compose -f docker/docker-compose.yml --profile --profile five-miners default up -d
down-five:
	docker compose -f docker/docker-compose.yml --profile --profile five-miners default down -t 0 -v
# Network with 5 miners/signers|2 followers|seed node|api
up-five-follower:
	STACKS_FOLLOWER_REPLICAS=2 docker compose -f docker/docker-compose.yml --profile default --profile five-miners --profile follower up -d
down-five-follower:
	STACKS_FOLLOWER_REPLICAS=2 docker compose -f docker/docker-compose.yml --profile default --profile five-miners --profile follower down -t 0 -v

# build images locally
build:
	docker compose -f docker/docker-compose.yml --profile default build
build-five:
	docker compose -f docker/docker-compose.yml --profile --profile five-miners default build
build-five-follower:
	docker compose -f docker/docker-compose.yml --profile default --profile five-miners --profile follower build

x: # down && build && up
	docker compose -f docker/docker-compose-three-miners.yml --profile default down -t 0 -v
	docker compose -f docker/docker-compose-three-miners.yml --profile default build
	docker compose -f docker/docker-compose-three-miners.yml --profile default up -d

.PHONY: up down build x
