# salt-toaster

## Run tests in default docker image:
```bash
git clone https://github.com/dincamihai/salt-toaster.git
cd salt-toaster
make docker_run_unittests
make docker_run_integration_tests
```

## Examples

### Run docker shell in specific local image
```bash
make docker_shell DOCKER_IMAGE=toaster-sles12sp1
```

### Run docker shell in specific repository image
```bash
make docker_shell DOCKER_IMAGE=suma-docker-registry.suse.de/toaster-sles12sp1
```

### Run docker shell in repository image based on version
```bash
make docker_shell VERSION=sles12sp1
```