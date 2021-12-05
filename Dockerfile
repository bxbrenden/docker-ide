FROM debian:bullseye-20211011
USER root

#Install basic utilities
RUN apt update && apt install --no-install-recommends -y zsh man file sudo bc vim-nox telnet unzip xz-utils\
				curl wget git less procps net-tools dnsutils netcat pwgen openjdk-11-jdk\
				openssh-client traceroute postgresql-client default-mysql-client zip units\
                                wait-for-it redis tmux screen tree iproute2 iputils-ping

#Set to Pacific Time
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#Create non-root user
ARG USER
ARG PASSWD
RUN useradd -m -s /usr/bin/zsh -G sudo "$USER"
RUN /bin/bash -c "echo -e \"$PASSWD\n$PASSWD\" | passwd \"$USER\""
COPY files/sudoers /etc/sudoers

# Become non-root user for pyenv install only
USER $USER

#Install pyenv and set global python interpreter
RUN sudo apt install --no-install-recommends -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev\
                                                libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev\
                                                libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
RUN curl https://pyenv.run | bash
RUN /home/$USER/.pyenv/bin/pyenv install 3.8.12
RUN /home/$USER/.pyenv/bin/pyenv install 3.9.8
RUN /home/$USER/.pyenv/bin/pyenv global 3.8.12
RUN echo 'eval "$(pyenv init --path)"' >> /home/$USER/.zshrc
RUN echo 'eval "$(pyenv virtualenv-init -)"' >> /home/$USER/.zshrc

#Install top-level Python 3.8 deps and packages that are just easiest to manage via pip
RUN /home/$USER/.pyenv/shims/pip3 install pipenv black imgcat requests ipython flake8 ansible\
                                          yamllint redis jupyter "ansible-lint[community,yamllint]"
#Install top-level Python 3.9 deps and packages that are just easiest to manage via pip
RUN /home/$USER/.pyenv/bin/pyenv global 3.9.8
RUN /home/$USER/.pyenv/shims/pip3  install pipenv black imgcat requests ipython flake8 ansible\
                                          yamllint redis jupyter "ansible-lint[community,yamllint]"

# Ensure Python3.9.8 as the default version
RUN /home/$USER/.pyenv/bin/pyenv global 3.9.8

# switch back to root for a while
USER root

#Extra utilities
ENV SOFTWARE_DIR /home/$USER/Software
RUN mkdir $SOFTWARE_DIR
WORKDIR $SOFTWARE_DIR

##ccat
RUN wget https://github.com/jingweno/ccat/releases/download/v1.1.0/linux-amd64-1.1.0.tar.gz
RUN tar xvf linux-amd64-1.1.0.tar.gz
RUN ln -s "$SOFTWARE_DIR/linux-amd64-1.1.0/ccat" /usr/local/bin/ccat
RUN rm linux-amd64-1.1.0.tar.gz

##node.js
RUN wget https://nodejs.org/dist/v14.18.1/node-v14.18.1-linux-x64.tar.xz
RUN tar xvf $SOFTWARE_DIR/node-v14.18.1-linux-x64.tar.xz
RUN ln -s $SOFTWARE_DIR/node-v14.18.1-linux-x64/bin/* /usr/local/bin

##Terraform
RUN wget https://releases.hashicorp.com/terraform/1.0.8/terraform_1.0.8_linux_amd64.zip
RUN unzip terraform_1.0.8_linux_amd64.zip
RUN ln -s $SOFTWARE_DIR/terraform /usr/local/bin/terraform

#Docker
RUN apt install -y --no-install-recommends apt-transport-https ca-certificates gnupg lsb-release
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt update && apt install -y --no-install-recommends docker-ce docker-ce-cli containerd.io
RUN usermod -aG docker $USER

#Docker-Compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

#AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

#AWS CDK (CloudFormation Development Kit)
RUN npm install -g aws-cdk

#Terragrunt
RUN wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.35.4/terragrunt_linux_amd64
RUN chmod a+x $SOFTWARE_DIR/terragrunt_linux_amd64
RUN ln -s $SOFTWARE_DIR/terragrunt_linux_amd64 /usr/local/bin/terragrunt

##Make the utilities usable
RUN chown -R $USER:$USER $SOFTWARE_DIR

#Do last few things as USER
USER $USER

#Install Angular
RUN npm install -g @angular/cli

#Configure git client
ARG GIT_EMAIL
ARG GIT_USER
RUN git config --global user.email "$GIT_EMAIL"
RUN git config --global user.name "$GIT_USER"
RUN git config --global init.defaultBranch main
RUN git config --global pull.rebase false
COPY files/ssh_config /home/$USER/.ssh/config
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
RUN sudo apt install -y git-lfs
RUN git lfs install

#Set up flake8
RUN mkdir -p /home/$USER/.config
COPY files/flake8 /home/$USER/.config/flake8

#Configure vim
COPY files/vimrc /home/$USER/.vimrc
RUN mkdir /home/$USER/.vim
RUN git clone https://github.com/VundleVim/Vundle.vim.git /home/$USER/.vim/bundle/Vundle.vim
RUN sudo chown -R $USER:$USER /home/$USER/.vim*

ENV VIMRC="/home/$USER/.vimrc"
RUN sudo update-alternatives --set editor /usr/bin/vim.nox
RUN vim +PluginInstall +qall
RUN echo "colorscheme medic_chalk" >> $VIMRC
RUN echo "set background=dark" >> $VIMRC
RUN echo '" show unnecessary whitespace as red' >> $VIMRC
RUN echo "highlight BadWhitespace ctermbg=red guibg=darkred" >> $VIMRC
RUN echo 'au BufRead,BufNewFile * match BadWhitespace /\s\+$/' >> $VIMRC
WORKDIR /home/$USER

#Install and configure oh-my-zsh
RUN sudo sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
COPY files/zshrc /root/.zshrc
COPY files/zshrc /home/$USER/.zshrc
RUN sudo chown $USER:$USER /home/$USER/.zshrc
# node.js in path
RUN echo "export PATH=\$PATH:/home/$USER/Software/node-v16.9.0-linux-x64/bin" >> /home/$USER/.zshrc
# pyenv in path
RUN echo "export PATH=\$PATH:/home/$USER/.pyenv/bin/" >> /home/$USER/.zshrc
RUN sudo chmod 755 /root
