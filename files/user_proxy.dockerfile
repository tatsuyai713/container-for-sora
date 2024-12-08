
FROM ghcr.io/tatsuyai713/sora-container:v0.02

ARG IN_LOCALE="JP"
ARG IN_TZ="Asia/Tokyo"
ARG IN_LANG="ja_JP.UTF-8"
ARG IN_LANGUAGE="ja_JP:ja"

ARG UID=9001
ARG GID=9001
ARG UNAME=nvidia
ARG HOSTNAME=docker

ARG NEW_HOSTNAME=${HOSTNAME}-Docker

ARG USERNAME=$UNAME
ARG HOME=/home/$USERNAME


ARG HTTP_PROXY
ARG HTTPS_PROXY

RUN : "apt Proxy" \
 && { \
  echo 'Acquire::http::proxy "'${HTTP_PROXY}'";'; \
  echo 'Acquire::https::proxy "'${HTTPS_PROXY}'";'; \
    } | tee /etc/apt/apt.conf
RUN : "apt Proxy" \
 && { \
  echo 'Acquire::http::proxy "'${HTTP_PROXY}'";'; \
  echo 'Acquire::https::proxy "'${HTTPS_PROXY}'";'; \
    } | tee /etc/apt/apt.conf.d/proxy.conf

RUN echo "http_proxy=${HTTP_PROXY}" >> /etc/environment && \
    echo "https_proxy=${HTTPS_PROXY}" >> /etc/environment

RUN useradd -u $UID -m $USERNAME && \
    echo "$USERNAME:$USERNAME" | chpasswd && \
    usermod --shell /bin/bash $USERNAME && \
    usermod -aG sudo $USERNAME && \
    mkdir /etc/sudoers.d -p && \
    usermod -a -G adm,audio,cdrom,dialout,dip,fax,floppy,input,lp,lpadmin,plugdev,scanner,sudo,tape,tty,video,voice $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    usermod  --uid $UID $USERNAME && \
    groupmod --gid $GID $USERNAME && \
    chown -R $USERNAME:$USERNAME $HOME

RUN ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone

ENV TZ ${IN_TZ}
ENV LANG ${IN_LANG}
ENV LANGUAGE ${IN_LANGUAGE}

USER $USERNAME

RUN sudo gpasswd -a $USERNAME ssl-cert

USER root

RUN sed -i "s/<user>/$USERNAME/g" /etc/entrypoint.sh
RUN sed -i "s/<user>/$USERNAME/g" /etc/supervisord.conf

RUN chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER $USERNAME
ENV SHELL /bin/bash
ENV USER $USERNAME
WORKDIR /home/$USERNAME

EXPOSE 80

ENTRYPOINT ["/usr/bin/supervisord"]
