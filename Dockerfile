FROM python:3.9.5
USER root

# Install basic utilities
RUN apt update && apt install -y zsh man sudo bc vim-nox curl wget git less procps \
                                 net-tools dnsutils ansible openssh-client traceroute\
                                 postgresql-client default-mysql-client

# Create non-root user
ARG USER
ARG PASSWD
RUN useradd -m -s /usr/bin/zsh -G sudo "$USER"
RUN /bin/bash -c "echo -e \"$PASSWD\n$PASSWD\" | passwd \"$USER\""
COPY files/sudoers /etc/sudoers

# Configure git client
ARG GIT_EMAIL
ARG GIT_USER
RUN git config --global user.email $GIT_EMAIL
RUN git config --global user.name $GIT_USER

# Install top-level Python deps
RUN pip install pipenv requests ipython flake8

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

## Make the utilities usable
RUN chown -R $USER:$USER $SOFTWARE_DIR

# Configure vim
COPY files/vimrc /home/$USER/.vimrc
RUN mkdir /home/$USER/.vim
RUN git clone https://github.com/VundleVim/Vundle.vim.git /home/$USER/.vim/bundle/Vundle.vim
RUN chown -R $USER:$USER /home/$USER/.vim*

USER $USER
RUN sudo update-alternatives --set editor /usr/bin/vim.nox
RUN vim +PluginInstall +qall
RUN echo "colorscheme medic_chalk" >> /home/$USER/.vimrc
RUN echo "set background=dark" >> /home/$USER/.vimrc
WORKDIR /home/$USER
