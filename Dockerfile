FROM debian:bookworm-20230814
LABEL org.opencontainers.image.authors="brendenahyde@gmail.com"
USER root

# Get my base packages and delete the apt cache
RUN apt update && apt install --no-install-recommends -y \
  git bat curl wget zsh vim-nox net-tools procps less man file tree apt-file\
  ca-certificates telnet netcat-openbsd unzip xz-utils net-tools dnsutils pwgen \
  openssh-client traceroute iproute2 iputils-ping tmux screen sudo bc \
  && rm -rf /var/lib/apt/lists/*

# Create non-root user
ARG USER
ARG PASSWD
RUN useradd -u 501 -m -s /usr/bin/zsh -G sudo "$USER"
RUN /bin/bash -c "echo -e \"$PASSWD\n$PASSWD\" | passwd \"$USER\""
COPY files/sudoers /etc/sudoers

# Become non-root user for pyenv install and home dir config
USER $USER

# Install pyenv and set global python interpreter
ARG PYTHON_VERSION
RUN sudo apt update && sudo apt install --no-install-recommends -y \
  make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev \
  wget curl llvm libncursesw5-dev xz-utils tk-dev\
  libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
  && sudo rm -rf /var/lib/apt/lists/*

RUN curl https://pyenv.run | bash
RUN /home/$USER/.pyenv/bin/pyenv install $PYTHON_VERSION
RUN /home/$USER/.pyenv/bin/pyenv install $PYTHON_OLD_VERSION
RUN echo 'eval "$(pyenv init --path)"' >> /home/$USER/.zshrc
RUN echo 'eval "$(pyenv virtualenv-init -)"' >> /home/$USER/.zshrc
RUN /home/$USER/.pyenv/bin/pyenv global $PYTHON_VERSION

# Home directories
ENV USER_HOME /home/$USER/
RUN ["/bin/bash", "-c", "mkdir -p $USER_HOME/{Software,git,Downloads,Documents}"]

# Become root again to continue configuring
USER root

# Set to Pacific Time
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Docker
RUN apt update && apt install -y --no-install-recommends gnupg && rm -rf /var/lib/apt/lists/*
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN chmod a+r /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt update && apt install --no-install-recommends -y \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
  && rm -rf /var/lib/apt/lists/*
RUN usermod -aG docker $USER

# Docker-Compose
RUN curl -L "https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

USER $USER

# Configure git client
ARG GIT_EMAIL
ARG GIT_USER
RUN git config --global user.email "$GIT_EMAIL"
RUN git config --global user.name "$GIT_USER"
RUN git config --global init.defaultBranch main
RUN git config --global pull.rebase false
RUN sudo apt update && sudo apt install -y git-lfs && sudo rm -rf /var/lib/apt/lists/*
RUN git lfs install

# Configure vim
COPY files/vimrc /home/$USER/.vimrc
RUN mkdir /home/$USER/.vim
RUN git clone https://github.com/VundleVim/Vundle.vim.git /home/$USER/.vim/bundle/Vundle.vim
RUN sudo chown -R $USER:$USER /home/$USER/.vim*

ENV VIMRC="/home/$USER/.vimrc"
RUN sudo update-alternatives --set editor /usr/bin/vim.nox
RUN vim +PluginInstall +qall
RUN echo "colorscheme seoul256" >> $VIMRC
RUN echo "let g:seoul256_background = 233" >> $VIMRC
RUN echo "set background=dark" >> $VIMRC
# RUN echo '" show unnecessary whitespace as red' >> $VIMRC
# RUN echo "highlight BadWhitespace ctermbg=red guibg=darkred" >> $VIMRC
# RUN echo 'au BufRead,BufNewFile * match BadWhitespace /\s\+$/' >> $VIMRC
WORKDIR /home/$USER

# Install and configure oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
COPY files/zshrc /root/.zshrc
COPY files/zshrc /home/$USER/.zshrc
RUN sudo chown $USER:$USER /home/$USER/.zshrc

# Install some Python packages I use often and upgrade pip
RUN /home/$USER/.pyenv/versions/$PYTHON_VERSION/bin/pip install --upgrade pip
RUN /home/$USER/.pyenv/versions/$PYTHON_VERSION/bin/pip install ansible black ipython requests flake8 pipenv

# # Install Google Cloud CLI tool
# RUN sudo apt update && sudo apt install --no-install-recommends -y python3 apt-transport-https \
#   && sudo rm -rf /var/lib/apt/lists/*
# Run echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
# RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/cloud.google.gpg
# RUN sudo apt update && sudo apt install --no-install-recommends -y google-cloud-cli && sudo rm -rf /var/lib/apt/lists/*

# Install AWS CLI
RUN sudo apt update && sudo apt install -y awscli && sudo rm -rf /var/lib/apt/lists/*

# Install Pulumi
RUN curl -fsSL https://get.pulumi.com | sh
RUN echo "export PATH=\$PATH:/home/$USER/.pulumi/bin" >> /home/$USER/.zshrc

# Install kubectl
RUN sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
RUN sudo apt update && sudo apt install --no-install-recommends -y kubectl && sudo rm -rf /var/lib/apt/lists/*

# Install Helm
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
RUN sudo apt update && sudo apt install -y --no-install-recommends apt-transport-https \
  && sudo rm -rf /var/lib/apt/lists/*
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
RUN sudo apt update && sudo apt install -y --no-install-recommends helm && sudo rm -rf /var/lib/apt/lists/*

# Install HashiCorp Vault CLI
RUN wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
# First install consistently fails, see https://github.com/hashicorp/vault/issues/10924#issuecomment-846123151
RUN sudo apt update && sudo apt install -y vault && sudo apt install -y --reinstall vault && sudo rm -rf /var/lib/apt/lists/*

# Install Temporal CLI tool
RUN curl -sSf https://temporal.download/cli.sh | sh
RUN echo export PATH="\$PATH:/home/$USER/.temporalio/bin" >> ~/.zshrc
