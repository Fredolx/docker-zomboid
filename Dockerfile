# syntax=docker/dockerfile:1
FROM docker.io/steamcmd/steamcmd:latest AS build

ARG STEAM_BRANCH=public

RUN steamcmd \
    +@sSteamCmdForcePlatformType linux \
    +force_install_dir /server \
    +login anonymous \
    +app_update 380870 -beta ${STEAM_BRANCH} validate \
    +quit

ADD --checksum=sha256:a6faf3d8b8259e88fd0a662dd6baff74a4226bafd96a9f578fcc3f4f534cadf2 \
    https://github.com/itzg/rcon-cli/releases/download/1.7.7/rcon-cli_1.7.7_linux_amd64.tar.gz /tmp/rcon-cli.tar.gz
RUN tar -xzf /tmp/rcon-cli.tar.gz -C /usr/local/bin rcon-cli

FROM docker.io/library/debian:13-slim

COPY --from=build /server /server
COPY --from=build /usr/local/bin/rcon-cli /usr/local/bin/rcon-cli
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY start.sh /start.sh

ENTRYPOINT ["/start.sh"]
