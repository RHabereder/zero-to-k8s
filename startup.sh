#!/bin/bash
set -e

trap cleanup SIGINT

source .env 
source .functions

#Possible Single Values: tekton|rio|drone|concourse
CICD="tekton"

#Possible Single Values: traefik|traefik2|nginx|istio|none
INGRESS="traefik2"

#Possible values: (Spaced-Delimited Multiple possible): prometheus grafana jaeger alertmanager registry minio k8s-dashboard rio-dashboard istio
TOOLS="prometheus grafana jaeger alertmanager minio"

#Possible values: (Spaced-Delimited Multiple possible): cassandra
DB=""


prep_setup
install_binaries
prep_helm_repos

start_k3d_cluster
config_k3d_cluster

install_ingress
install_ci
install_tools
install_db

verify_binaries
notify_user
