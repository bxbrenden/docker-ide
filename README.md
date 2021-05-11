# Docker IDE

A Debian-based docker container with my preferred development environment setup.

## Running
If, for some reason, you are fine with being the user `brenden` with the password `dummy` (if not see the `Building` section below), you can pull the container image like this:
```bash
docker image pull bxbrenden/docker-ide:latest
```

Then, you can run it like so:
```bash
docker run -e "TERM=xterm-256color" --rm -it -h BrendenIDE bxbrenden/docker-ide zsh
```

## Building
The `Dockerfile` requires 4 runtime args when building:
- `USER`: the non-root user for the operating system
- `PASSWD`: the sudo password for the user
- `GIT_USER`: the firstname-lastname string for git user, e.g. "Brenden Hyde"
- `GIT_EMAIL`: the email address that'll be used in git commits for attribution

An example build command is:
```bash
docker build --build-arg "USER=brenden"\
             --build-arg "PASSWD=dummy"\
             --build-arg "GIT_EMAIL=brendenahyde@gmail.com"\
             --build-arg "GIT_USER='Brenden Hyde'"\
             -t bxbrenden/docker-ide .
```
