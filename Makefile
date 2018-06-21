DOCKER          = docker
DOCKER_COMPOSE  = docker-compose

##
## ----------------------------------------------------------------------------
##   Setup
## ----------------------------------------------------------------------------
##

build: ## Build the environment
	$(DOCKER_COMPOSE) pull --parallel --ignore-pull-failures
	$(DOCKER_COMPOSE) build --pull

env: ## Configure the environment variables
	@if [[ ! -f docker-env ]]; then \
		cp docker-env.dist docker-env; \
	fi
	nano docker-env

start: ## Start the environment
	@if [[ ! -f docker-env ]]; then \
		echo 'The default configuration has been applied because the "docker-env" file was not configured.'; \
		cp docker-env.dist docker-env; \
	fi
	$(DOCKER_COMPOSE) up -d --remove-orphans

stop: ## Stop the environment
	$(DOCKER_COMPOSE) stop

restart: ## Restart the environment
restart: stop start

install: ## Install the environment
install: build start

uninstall: ## Uninstall the environment
	$(DOCKER_COMPOSE) kill
	$(DOCKER_COMPOSE) down --volumes --remove-orphans

.PHONY: build env start stop restart install uninstall

##
## ----------------------------------------------------------------------------
##   Usage
## ----------------------------------------------------------------------------
##

cache: ## Flush everything stored into the "redis" container
	$(DOCKER_COMPOSE) exec -T redis sh -c "redis-cli FLUSHALL"

logs: ## Follow logs generated by all containers
	$(DOCKER_COMPOSE) logs -f --tail=0

logs-full: ## Follow logs generated by all containers from the containers creation
	$(DOCKER_COMPOSE) logs -f

go-apache: ## Open a terminal in the "apache" container
	$(DOCKER_COMPOSE) exec apache sh -c "/bin/bash"

go-mysql: ## Open a terminal in the "mysql" container
	$(DOCKER_COMPOSE) exec mysql sh -c "/bin/bash"

go-php: ## Open a terminal in the "php" container
	$(DOCKER_COMPOSE) exec php sh -c "/bin/bash"

ps: ## List all containers managed by the environment
	$(DOCKER_COMPOSE) ps

stats: ## Print real-time statistics about containers ressources usage
	docker stats $(docker ps --format={{.Names}})

ssh: ## Copy all SSH keys from the host to the "php" container
	$(DOCKER_COMPOSE) exec -T php sh -c "mkdir -p /root/.ssh"
	$(DOCKER) cp $(HOME)/.ssh $(shell docker-compose ps -q php):/root/
	$(DOCKER_COMPOSE) exec -T php sh -c "echo 'eval \$$(ssh-agent) && ssh-add' >> /root/.bashrc"

.PHONY: cache logs logs-full go-apache go-mysql go-php ps stats ssh

.DEFAULT_GOAL := help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' \
		| sed -e 's/\[32m##/[33m/'
.PHONY: help
