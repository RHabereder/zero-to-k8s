#!/bin/bash

prep() {
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

install() {
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

start_cluster() {
  k3d create --server-arg="--no-deploy=traefik" --name dev
  echo "wait a bit for k3d to start up"
  sleep 20
}

config_cluster() {

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

install_rio() {
  rio install
}

verify() {
  kubectl version
  tkn version
  k3d --version
  rio --version
}

notify_user() {
  echo "Now export the following lines and you are good to go!"
  echo "export PATH=$PATH:`pwd`/bin"
  if [[ "$SHELL" == "WSL" ]]; then
    echo "export KUBECONFIG=$(k3d get-kubeconfig --name dev | sed 's_\\_\/_g' | sed 's_C:_/c_')"
  elif [[ "$SHELL" == "BASH" ]]; then
    echo "export KUBECONFIG=$(k3d get-kubeconfig --name dev)"
  elif [[ "$SHELL" == "MSYS" ]]; then
    echo "export KUBECONFIG=$(k3d get-kubeconfig --name dev | sed 's_\\_\/_g' | sed 's_C:_/c_')"
  fi
}



prep
install
start_cluster
config_cluster
install_rio
verify
run
notify_user
