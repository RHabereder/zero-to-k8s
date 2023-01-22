#!/bin/bash
set -ex

trap cleanup SIGINT

source .env
source .functions

sudo apt install dialog -y
CICD=""
INGRESS=""
TOOLS=""
DB=""
HOSTS_FILE_LOCATION=""

prep_setup
install_binaries
prep_helm_repos

choose_ci
choose_ingress
choose_tools
choose_db

start_k3d_cluster
config_k3d_cluster

install_ingress
install_ci
install_tools
install_db

verify_binaries
notify_user
