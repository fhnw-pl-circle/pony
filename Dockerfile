FROM ubuntu:22.04

RUN apt-get update && apt-get install curl gcc build-essential libssl-dev gdb libcurl4-openssl-dev clang git -y

RUN useradd -ms /bin/bash pony
RUN mkdir /workspaces && chown pony /workspaces

USER pony

WORKDIR /home/pony

RUN bash -c "$(curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh)" || true
ENV PATH="${PATH}:/home/pony/.local/share/ponyup/bin"
# Install pony related tools
RUN ponyup default x86_64-linux-ubuntu22.04 && ponyup update ponyc release && ponyup update corral release
