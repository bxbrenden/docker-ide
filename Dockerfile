FROM python:3.9.5
USER root

# Install basic utilities
RUN apt update && apt install --no-install-recommends -y zsh man sudo bc vim-nox telnet unzip\
				curl wget git less procps net-tools dnsutils netcat pwgen\
				openssh-client traceroute postgresql-client default-mysql-client

# Set to Pacific Time
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create non-root user
ARG USER
ARG PASSWD
RUN useradd -m -s /usr/bin/zsh -G sudo "$USER"
RUN /bin/bash -c "echo -e \"$PASSWD\n$PASSWD\" | passwd \"$USER\""
COPY files/sudoers /etc/sudoers

# Install top-level Python deps
RUN pip install pipenv requests ipython flake8 ansible yamllint

# Install and configure oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
COPY files/zshrc /root/.zshrc
COPY files/zshrc /home/$USER/.zshrc
RUN chmod 755 /root
RUN chown $USER:$USER /home/$USER/.zshrc

# Extra utilities
ENV SOFTWARE_DIR /home/$USER/Software
RUN mkdir $SOFTWARE_DIR
WORKDIR $SOFTWARE_DIR

## ccat
RUN wget https://github.com/jingweno/ccat/releases/download/v1.1.0/linux-amd64-1.1.0.tar.gz
RUN tar xvf linux-amd64-1.1.0.tar.gz
RUN ln -s "$SOFTWARE_DIR/linux-amd64-1.1.0/ccat" /usr/local/bin/ccat
RUN rm linux-amd64-1.1.0.tar.gz

## node.js
RUN wget https://nodejs.org/dist/v14.16.1/node-v14.16.1-linux-x64.tar.xz
RUN tar xvf node-v14.16.1-linux-x64.tar.xz
RUN ln -s $SOFTWARE_DIR/node-v14.16.1-linux-x64/bin/* /usr/local/bin

## Terraform
RUN wget https://releases.hashicorp.com/terraform/1.0.0/terraform_1.0.0_linux_amd64.zip
RUN unzip terraform_1.0.0_linux_amd64.zip
RUN ln -s $SOFTWARE_DIR/terraform /usr/local/bin/terraform

## lolcat
RUN wget https://github.com/busyloop/lolcat/archive/master.zip -O lolcat-master.zip
RUN unzip lolcat-master.zip
WORKDIR lolcat-master/bin
RUN gem install lolcat
WORKDIR $SOFTWARE_DIR

## Make the utilities usable
RUN chown -R $USER:$USER $SOFTWARE_DIR

# Configure vim
COPY files/vimrc /home/$USER/.vimrc
RUN mkdir /home/$USER/.vim
RUN git clone https://github.com/VundleVim/Vundle.vim.git /home/$USER/.vim/bundle/Vundle.vim
RUN chown -R $USER:$USER /home/$USER/.vim*

# Docker
RUN apt install -y apt-transport-https ca-certificates gnupg lsb-release
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt update && apt install -y docker-ce docker-ce-cli containerd.io
RUN usermod -aG docker $USER

# Docker-Compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

# AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# Do last few things as USER
USER $USER

# Configure git client
ARG GIT_EMAIL
ARG GIT_USER
RUN git config --global user.email "$GIT_EMAIL"
RUN git config --global user.name "$GIT_USER"
COPY files/ssh_config /home/$USER/.ssh/config
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
RUN sudo apt install -y git-lfs
RUN git lfs install

ENV VIMRC="/home/$USER/.vimrc"
RUN sudo update-alternatives --set editor /usr/bin/vim.nox
RUN vim +PluginInstall +qall
RUN echo "colorscheme medic_chalk" >> $VIMRC
RUN echo "set background=dark" >> $VIMRC
RUN echo '" show unnecessary whitespace as red' >> $VIMRC
RUN echo "highlight BadWhitespace ctermbg=red guibg=darkred" >> $VIMRC
RUN echo 'au BufRead,BufNewFile * match BadWhitespace /\s\+$/' >> $VIMRC
WORKDIR /home/$USER

RUN mkdir /home/$USER/.config
COPY files/flake8 /home/$USER/.config/flake8
