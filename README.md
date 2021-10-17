# Docker IDE

A Debian-based docker container with my preferred development environment setup.

## Running
You may want to mount your `~/.ssh` and `~/.aws` directories as volumes.
You may also want to mount `/var/run/docker.sock` so Docker commands work from within the container.
```bash
docker run -e "TERM=xterm-256color" -v ~/.ssh:/home/brenden/.ssh -v ~/.aws:/home/brenden/.aws -v /var/run/docker.sock:/var/run/docker.sock --rm -it -h BrendenIDE docker-ide:latest zsh
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
             -t docker-ide .
```
