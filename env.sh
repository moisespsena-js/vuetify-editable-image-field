#!/bin/bash
sourced=0

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  DIR=$(dirname "$0")
else
  DIR=$(dirname "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}")
  sourced=1
fi

DIR=$(realpath "$DIR")

[ "$NVM_DIR" = '' ] && {
  if [ -e ~/.nvm ]; then
    export NVM_DIR=~/.nvm
  else
    echo "NVM_DIR env is empty. See https://github.com/nvm-sh/nvm for install nvm instructions"

    [ $sourced -eq 1 ] && return  1 || exit 1
  fi
}

set -e

. "$NVM_DIR/nvm.sh"

node_version=$(grep FROM "$DIR/Dockerfile" | perl -pe 's/^FROM node:(\d+)-.+$/\1/')

nvm ls | grep $node_version >/dev/null || nvm install $node_version

nvm use $node_version >&2
export NODE_CONTAINER_NAME="node:${node_version}-latest-pnpm"

export PS1="(node `node --version`) \[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "

function docker_image_build() {
  ( cd "$DIR" && \
    docker build --tag $NODE_CONTAINER_NAME .
  )
  return $?
}

function docker_image_rm() {
  docker image rm $NODE_CONTAINER_NAME
  return $?
}

function docker_image_check() {
  echo INFO: checking build image >&2
  docker inspect --type image $NODE_CONTAINER_NAME 2>/dev/null >&2 || \
    docker_image_build >&2
  return $?
}

docker_image_check

function build_pj() {
  cd "$DIR"
  pnpm install && pnpm format && pnpm run build
  return $?
}

function docker_exec() {
  cd "$DIR"

  docker run -it --rm \
    --user $(id -u):$(id -g) \
    -e HOME=/home/node \
    -v .:/home/node/src \
    -v ~/.cache/pnpm:/home/node/.cache/pnpm \
    -v ~/.npm:/home/node/.npm \
    -v ~/.npmrc:/home/node/.npmrc \
    -v $(dirname $(pnpm store path)):/home/node/src/.pnpm-store \
    -w /home/node/src \
    "$NODE_CONTAINER_NAME" "$@" || return $?

  [ -e .pnpm-store ] && rmdir .pnpm-store
  return $?
}

function docker_build_pj() {
  cd "$DIR"
  [ -e ./dist ] && rm -vrf ./dist

  docker run -it --rm \
    --user $(id -u):$(id -g) \
    -e HOME=/home/node \
    -v .:/home/node/src \
    -v ~/.cache/pnpm:/home/node/.cache/pnpm \
    -v $(dirname $(pnpm store path)):/home/node/src/.pnpm-store \
    -w /home/node/src \
    "$NODE_CONTAINER_NAME" bash -c 'pnpm install && pnpm format && pnpm run build' || return $?

  [ -e .pnpm-store ] && rmdir .pnpm-store
  return $?
}

function pj_exec() {
  cd "$DIR"

  if [ $# -lt 1 ]; then
    echo "usage: pj_exec CMD ..." >&2
    return 1
  fi

  "$@"
  return $?
}

function pj_pnpm() {
  cd "$DIR"

  if [ $# -lt 1 ]; then
    echo "usage: pj_pnpm PNPM_ARGS..." >&2
    return 1
  fi

  pj_exec pnpm install || return $?
  pj_exec pnpm "$@"
  return $?
}

if [ $sourced -eq 0 ]; then
  if [ $# -eq 0 ]; then
    exec bash --norc
  else
    "$@"
  fi
fi