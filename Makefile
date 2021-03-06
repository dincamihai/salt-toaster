DEFAULT_REGISTRY      = registry.mgr.suse.de
DEFAULT_VERSION       = sles12sp1
DEFAULT_FLAVOR        = products
TOASTER_MOUNTPOINT    = /salt-toaster
ROOT_MOUNTPOINT       = /salt/src
SALT_REPO_MOUNTPOINT  = $(ROOT_MOUNTPOINT)/salt-devel
SALT_TESTS            = $(ROOT_MOUNTPOINT)/salt-*/tests
DOCKER_VOLUMES        = -v "$(CURDIR)/:$(TOASTER_MOUNTPOINT)"
EXPORTS += \
	-e "SALT_TESTS=$(SALT_TESTS)" \
	-e "VERSION=$(VERSION)" \
	-e "FLAVOR=$(FLAVOR)" \
	-e "MINION_VERSION=$(MINION_VERSION)" \
	-e "MINION_FLAVOR=$(MINION_FLAVOR)" \
	-e "ROOT_MOUNTPOINT=$(ROOT_MOUNTPOINT)" \
	-e "TOASTER_MOUNTPOINT=$(TOASTER_MOUNTPOINT)"

ifndef CMD
	CMD = /bin/bash
endif

ifndef DOCKER_IMAGE
	ifndef DOCKER_REGISTRY
		DOCKER_REGISTRY = $(DEFAULT_REGISTRY)
	endif
	ifndef VERSION
		VERSION = $(DEFAULT_VERSION)
	endif
	ifndef FLAVOR
		FLAVOR = $(DEFAULT_FLAVOR)
	endif
	DOCKER_IMAGE = $(DOCKER_REGISTRY)/toaster-$(VERSION)-$(FLAVOR)
endif

help:
	@echo "Salt Toaster: an ultimate test suite for Salt."
	@echo
	@echo "Commands:"
	@echo "  set_env              Create environment"
	@echo "  docker_shell         Start Docker shell"
	@echo "  build_image          Build Docker image"
	@echo "  salt_integration     Run Salt integration tests"
	@echo "  custom_integration   Run custom integration tests"
	@echo ""

default: help

set_env:
	bin/prepare_environment.sh --create sandbox


archive-salt:
ifeq ("$(FLAVOR)", "devel")
ifdef SALT_REPO
	tar --exclude=.git --exclude=.cache --exclude="*.pyc" -cvzf docker/salt.archive -C $(SALT_REPO) . > /dev/null
else
	curl -s https://codeload.github.com/saltstack/salt/zip/develop > docker/develop.zip
	rm -f docker/salt.archive
	unzip docker/develop.zip -d docker > /dev/null
	rm -f docker/develop.zip
	tar -cvzf docker/salt.archive -C docker/salt-develop . > /dev/null
	rm -rf docker/salt-develop
endif
endif

build_image: archive-salt
	@echo "Building images"
ifeq ("$(FLAVOR)", "devel")
	$(eval BUILD_OPTS:=--nopull)
	VERSION=$(VERSION) FLAVOR=products sandbox/bin/python -m build > $(VERSION).products.build.log
endif
	VERSION=$(VERSION) FLAVOR=$(FLAVOR) sandbox/bin/python -m build $(BUILD_OPTS) > $(VERSION).$(FLAVOR).build.log
	rm -f docker/salt.archive

pull_image:
ifndef NOPULL
	docker pull $(DOCKER_IMAGE)
endif

docker_shell :: pull_image
ifndef RPDB_PORT
	docker run -it $(EXPORTS) --rm $(DOCKER_VOLUMES) $(DOCKER_IMAGE)
else
	docker run -p $(RPDB_PORT):4444 -it $(EXPORTS) --rm $(DOCKER_VOLUMES) $(DOCKER_IMAGE)
endif

docker_run :: pull_image
	docker run $(EXPORTS) -e "CMD=$(CMD)" --rm $(DOCKER_VOLUMES) $(DOCKER_IMAGE) tests

run: pull_image
	$(CMD)
