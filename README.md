# Docker IDE

A Debian-based docker container with my preferred development environment setup.

## Running
1. Pull the container image from Docker Hub:
```bash
docker image pull bxbrenden/docker-ide:latest
```

2. Run it interactively:
```bash
docker run -e "TERM=xterm-256color" --rm -it -h BrendenIDE bxbrenden/docker-ide zsh
```

NOTE: the default user is `brenden`, and the password is `dummy`.
However, the user has passwordless sudo, so the password shouldn't come up often.
If you want a different username and password, see the `Building` section below.

## Building
The `Dockerfile` requires the following build args:
- `USER`: the non-root user for the operating system
- `PASSWD`: the sudo password for the user
- `PYTHON_VERSION`: the python version that pyenv will install and make the global python for your user
- `GIT_USER`: the firstname-lastname string for git user, e.g. "Brenden Hyde"
- `GIT_EMAIL`: the email address that'll be used in git commits for attribution

Example set of build commands:
```bash
export DOCKER_IDE_PASS=dummy
docker build --build-arg "USER=brenden" \
             --build-arg "PASSWD=$DOCKER_IDE_PASS" \
             --build-arg "PYTHON_VERSION=3.11.5" \
             --build-arg "PYTHON_OLD_VERSION=2.7.18" \
             --build-arg "PYTHON_ADDITIONAL_VERSION=3.8.18" \
             --build-arg "GIT_EMAIL=brendenahyde@gmail.com" \
             --build-arg "GIT_USER='Brenden Hyde'" \
             -t bxbrenden/docker-ide:$(date --rfc-3339=date) .
```
Example set of build commands with no caching:
```bash
export DOCKER_IDE_PASS=dummy
docker build --no-cache \
             --build-arg "USER=brenden" \
             --build-arg "PASSWD=$DOCKER_IDE_PASS" \
             --build-arg "PYTHON_VERSION=3.11.5" \
             --build-arg "PYTHON_OLD_VERSION=2.7.18" \
             --build-arg "PYTHON_ADDITIONAL_VERSION=3.8.18" \
             --build-arg "GIT_EMAIL=brendenahyde@gmail.com" \
             --build-arg "GIT_USER='Brenden Hyde'" \
             -t bxbrenden/docker-ide:$(date --rfc-3339=date) .
```
