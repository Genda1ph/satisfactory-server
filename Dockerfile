FROM steamcmd/steamcmd:ubuntu-26

ARG GID=1000
ARG UID=1000

ENV AUTOSAVENUM="5" \
    DEBIAN_FRONTEND="noninteractive" \
    DEBUG="false" \
    DISABLESEASONALEVENTS="false" \
    GAMECONFIGDIR="/config/gamefiles/FactoryGame/Saved" \
    GAMESAVESDIR="/home/steam/.config/Epic/FactoryGame/Saved/SaveGames" \
    LOG="false" \
    MAXOBJECTS="2162688" \
    MAXPLAYERS="4" \
    MAXTICKRATE="30" \
    MULTIHOME="::" \
    PGID="1000" \
    PUID="1000" \
    SERVERGAMEPORT="7777" \
    SERVERMESSAGINGPORT="8888" \
    SERVERSTREAMING="true" \
    SKIPUPDATE="false" \
    STEAMAPPID="1690800" \
    STEAMBETA="false" \
    STEAMBETAID="" \
    STEAMBETAKEY="" \
    TIMEOUT="30" \
    VMOVERRIDE="false"

# hadolint ignore=DL3008
RUN set -x \
    && apt-get update --quiet --quiet \
    && apt-get install --yes --no-install-recommends gosu xdg-user-dirs curl jq tzdata
RUN rm --recursive --force /var/lib/apt/lists/*

# Remove existing user/group in case of UID/GID conflicts
RUN id --user --name $UID | xargs userdel --remove || true
RUN getent group $GID | cut --delimiter : --fields 1 | xargs groupdel || true

# Create steam user
RUN groupadd --gid ${GID} steam \
    && useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash steam
RUN mkdir --parents /home/steam/.local/share/Steam/ \
    && cp --recursive /root/.local/share/Steam/steamcmd/ /home/steam/.local/share/Steam/steamcmd/ \
    && chown --recursive ${UID}:${GID} /home/steam/.local/ \
    && gosu nobody true

RUN mkdir --parents /config \
    && chown steam:steam /config

COPY init.sh /
COPY --chown=steam:steam healthcheck.sh run.sh /home/steam/

RUN chmod +x /init.sh /home/steam/healthcheck.sh /home/steam/run.sh

HEALTHCHECK --timeout=30s --start-period=300s CMD bash /home/steam/healthcheck.sh

WORKDIR /config
ARG VERSION="DEV"
ENV VERSION=$VERSION
LABEL version=$VERSION
STOPSIGNAL SIGINT
EXPOSE 7777/udp 7777/tcp 8888/tcp

ENTRYPOINT ["/init.sh"]
