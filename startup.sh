#!/bin/bash

prep_setup() {
  echo "Preparing Setup"
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    KUBECTL_URL="https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
    K3D_URL="https://github.com/rancher/k3d/releases/download/v1.7.0/k3d-linux-amd64"
    TKN_URL="https://github.com/tektoncd/cli/releases/download/v0.8.0/tkn_0.8.0_Linux_x86_64.tar.gz"
    RIO_URL="https://github.com/rancher/rio/releases/download/v0.7.0/rio-linux-amd64"
    DRONE_URL=""
    
    if grep -q Microsoft /proc/version; then
      SHELL="WSL"
    else
      SHELL="BASH"
    fi
  elif [[ "$OSTYPE" == "msys" ]]; then
    KUBECTL_URL="https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/windows/amd64/kubectl.exe"
    K3D_URL="https://github.com/rancher/k3d/releases/download/v1.7.0/k3d-windows-amd64.exe"
    TKN_URL="https://github.com/tektoncd/cli/releases/download/v0.8.0/tkn_0.8.0_Windows_x86_64.zip"
    RIO_URL="https://github.com/rancher/rio/releases/download/v0.7.0/rio-windows-amd64"
    DRONE_URL=""
    SHELL="MSYS"
  fi
  echo "Detected $SHELL on $OSTYPE"
}

install_binaries() {
  echo "Installing management binaries to `pwd`/bin"
  if ! [[ -d "bin" ]]; then
    mkdir bin
  fi
  export PATH=$PATH:`pwd`/bin
  if ! [[ -f bin/kubectl ]]; then	  
    curl -L $KUBECTL_URL -o bin/kubectl
  fi
  if ! [[ -f bin/k3d ]]; then	  
    curl -L $K3D_URL -o bin/k3d
  fi
  if ! [[ -f bin/rio ]]; then	  
    curl -L $RIO_URL -o bin/rio
  fi

  if ! [[ -f bin/tkn ]]; then	  
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
      curl -L $TKN_URL | tar xzv tkn
      mv tkn bin/
    elif [[ "$OSTYPE" == "msys" ]]; then
      curl -L $TKN_URL | unzip
      mv tkn.exe bin/tkn
      rm README LICENSE
    fi
  fi

  find . -type f -exec chmod +x {} +
}

install_traefik() {
  echo "Installing Traefik"
  #We could also use the k3d built-in traefik helm-chart by removing the --no-deploy=traefik server-arg
  #Upgrading traefik would be kind of a pain, since I don't know if they actually modified traefik in any way
  #So we manage the ingress completely outside of k3d 
  kubectl apply -f ingress/traefik/rbac.yaml -f ingress/traefik/deployment.yaml -f ingress/traefik/dashboard.yaml
}

install_nginx() {
  echo "Installing NGinX"
  kubetl apply -f ingress/nginx/mandatory.yaml 
}


install_tekton() {
  echo "Installing Tekton-CD"
  #Install Tekton
  kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

  #Install Dashboard
  kubectl apply -f https://github.com/tektoncd/dashboard/releases/download/v0.6.1/tekton-dashboard-release.yaml
  kubectl apply -f cd/tekton/basic-dashboard-ingress.yaml
}

install_drone() {
  echo "Installing Drone CI"
}

install_rio() {
  echo "Installing Rancher RIO"
  rio install
}

install_prometheus() {
  echo "Installing Prometheus"
  kubectl create namespace monitoring
  kubectl apply -f observability/prometheus/cluster-role.yaml
  kubectl apply -f observability/prometheus/config-map.yaml
  kubectl apply -f observability/prometheus/deployment.yaml
  kubectl apply -f observability/prometheus/service.yaml
  kubectl apply -f observability/prometheus/ingress.yaml
}

install_grafana() {
  echo "Installing Grafana"
  kubectl apply -f observability/grafana/dashboard-cfgmap.yaml
  kubectl apply -f observability/grafana/datasource-configMap.yaml
  kubectl apply -f observability/grafana/deployment.yaml
  kubectl apply -f observability/grafana/ingress.yaml
  kubectl apply -f observability/grafana/service.yaml
}

start_k3d_cluster() {
  echo "Starting k3d Cluster"
  k3d create --server-arg="--no-deploy=traefik" --name dev
  echo "wait a bit for k3d to start up"
  sleep 20
}

config_k3d_cluster() {
  echo "Configuring k3d cluster"
  if [[ "$SHELL" == "WSL" ]]; then
    echo "Converting paths to POSIX, because derp"
    export KUBECONFIG=$(k3d get-kubeconfig --name dev | sed 's_\\_\/_g' | sed 's_C:_/c_')
  elif [[ "$SHELL" == "BASH" ]]; then
    export KUBECONFIG=$(k3d get-kubeconfig --name dev)
  elif [[ "$SHELL" == "MSYS" ]]; then
    echo "Converting paths to POSIX, because derp"
    export KUBECONFIG=$(k3d get-kubeconfig --name dev | sed 's_\\_\/_g' | sed 's_C:_/c_')
  fi
}

verify_binaries() {
  echo "Verifying installed binaries"
  kubectl version
  tkn version
  k3d --version
  rio --version
}

notify_user() {
  echo "\nNow export the following lines and you are good to go!"
  echo 'export PATH=$PATH:`pwd`/bin'
  echo 'source <(kubectl completion bash)'
  if [[ "$SHELL" == "WSL" ]]; then
    echo "export KUBECONFIG=$(k3d get-kubeconfig --name dev | sed 's_\\_\/_g' | sed 's_C:_/c_')"
  elif [[ "$SHELL" == "BASH" ]]; then
    echo "export KUBECONFIG=$(k3d get-kubeconfig --name dev)"
  elif [[ "$SHELL" == "MSYS" ]]; then
    echo "export KUBECONFIG=$(k3d get-kubeconfig --name dev | sed 's_\\_\/_g' | sed 's_C:_/c_')"
  fi

  echo $'To access apps behind your ingress, run the following command: '
  echo $'kubectl port-forward -n kube-system `kubectl get pods -n kube-system --template \'{{range .items}}{{.metadata.name}}{{\"\\n\"}}{{end}}\' | grep \"^traefik-ingress\"` 8080:80 &'
  echo "Tekton Dashbaord is available at http://localhost:8080/tekton/"
  echo "Traefik Dashboard is available at http://localhost:8080/traefik"
  echo "Prometheus is kinda bugged, so if you want to use the graph UI, you need another port-forward like this:"
  echo $'kubectl port-forward -n monitoring `kubectl get pods -n monitoring --template \'{{range .items}}{{.metadata.name}}{{\"\\n\"}}{{end}}\' | grep \"^prometheus\"` 9090 &'
  echo "Afterwards you can look at prometheus via http://localhost:9090/graph"
}


prep_setup
install_binaries
start_k3d_cluster
config_k3d_cluster
install_traefik
install_prometheus
install_grafana
#install_nginx
#install_rio
#install_drone
install_tekton
verify_binaries
notify_user
