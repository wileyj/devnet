# ##############################################################################
# DEVENV (development testing environment)
# ##############################################################################
# Network with 3 miners/signers|seed node|api
# If the first argument is "run"...
ifeq (log,$(firstword $(MAKECMDGOALS)))
	Arguments := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
endif

#   # use the rest as arguments for "run"
#   RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
#   # ...and turn them into do-nothing targets
#   $(eval $(RUN_ARGS):;@:)
# endif

# getent passwd $(whoami) | cut -d":" -f 3
#
# # $(eval UID=$(shell sh -c "getent passwd $(whoami) | cut -d":" -f 3"))
# HEADER = $(shell for file in `find . -name *.h`;do echo $$file; done)
export UID = $(shell getent passwd $$(whoami) | cut -d":" -f 3)
export GID = $(shell getent passwd $$(whoami) | cut -d":" -f 4)

up:
	# DOCKER_NETWORK=stacks docker compose -f docker/docker-compose.yml --profile default up -d
	# UID=$(UID) GID=$(GID) docker compose -f docker/docker-compose.yml --profile default up -d
	#sudo sudo rm -rf docker/persistent/*
	docker compose -f docker/docker-compose.yml --profile default up -d
down:
	# DOCKER_NETWORK=stacks docker compose -f docker/docker-compose.yml --profile default down -t 0 -v
	# docker compose -f docker/docker-compose-three-miners.yml --profile default down -t 0 -v
	docker compose -f docker/docker-compose.yml --profile default down

up-32:
	# DOCKER_NETWORK=stacks docker compose -f docker/docker-compose.yml --profile default up -d
	#sudo sudo rm -rf docker/persistent/*
	docker compose -f docker/docker-compose_32.yml --profile default up -d
down-32:
	# DOCKER_NETWORK=stacks docker compose -f docker/docker-compose.yml --profile default down -t 0 -v
	docker compose -f docker/docker-compose_32.yml --profile default down -v

log:
	docker compose -f docker/docker-compose.yml logs -t --no-log-prefix "$(Arguments)" -f #| grep neighbor
	# docker compose -f docker/docker-compose.yml logs -t --no-log-prefix "$(Arguments)" -f #| grep neighbor
log-all:
	docker compose -f docker/docker-compose.yml logs -t -f

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
	docker compose -f docker/docker-compose.yml --profile default build --progress=plain --no-cache
build-five:
	docker compose -f docker/docker-compose.yml --profile --profile five-miners default build --progress=plain --no-cache
build-five-follower:
	docker compose -f docker/docker-compose.yml --profile default --profile five-miners --profile follower build --progress --no-cache

x: # down && build && up
	docker compose -f docker/docker-compose-three-miners.yml --profile default down -t 0 -v
	docker compose -f docker/docker-compose-three-miners.yml --profile default build
	docker compose -f docker/docker-compose-three-miners.yml --profile default up -d

.PHONY: up down build x
