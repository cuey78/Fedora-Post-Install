#!/bin/bash

Clone_Repo() {
  local repo_url="https://github.com/cuey78/fedora-post-install"
  local clone_dir="Fedora-post-install"

  if [ ! -d "$clone_dir" ]; then
    git clone $repo_url $clone_dir
  else
    cd $clone_dir
    git pull
    cd -
  fi
}

Run_Script() {
  local script_path="$1/main.sh"

  if [ -f "$script_path" ]; then
    sudo bash $script_path
  else
    echo "Script $script_path does not exist."
  fi
}

main() {
  Clone_Repo

  cd Fedora-post-install

  chmod +x main.sh

  ./main.sh
}

if [ "${0##*/}" == "/usr/bin/env" ]; then
  exec ${0:-/dev/null}
fi

main
