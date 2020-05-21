#!/bin/bash

prep_setup() {
  echo "Preparing Setup"
  if [[ "$OSTYPE" == "linux-gnu" ]]; then    
    if grep -q Microsoft /proc/version; then
      SHELL="WSL"
      KUBECTL_URL="https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/windows/amd64/kubectl.exe"
      K3D_URL="https://github.com/rancher/k3d/releases/download/v1.7.0/k3d-windows-amd64.exe"
      TKN_URL="https://github.com/tektoncd/cli/releases/download/v0.8.0/tkn_0.8.0_Windows_x86_64.zip"
      RIO_URL="https://github.com/rancher/rio/releases/download/v0.7.0/rio-windows-amd64"
      HELM_URL="https://get.helm.sh/helm-v3.2.1-windows-amd64.zip"
      DRONE_URL=""
    else
      SHELL="BASH"
      KUBECTL_URL="https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
      K3D_URL="https://github.com/rancher/k3d/releases/download/v1.7.0/k3d-linux-amd64"
      TKN_URL="https://github.com/tektoncd/cli/releases/download/v0.8.0/tkn_0.8.0_Linux_x86_64.tar.gz"
      RIO_URL="https://github.com/rancher/rio/releases/download/v0.7.1/rio-linux-amd64"
      HELM_URL="https://get.helm.sh/helm-v3.2.1-linux-amd64.tar.gz"
      DRONE_URL=""
    fi
  fi

  if [[ "$OSTYPE" == "msys" ]]; then  
    SHELL="MSYS"
    KUBECTL_URL="https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/windows/amd64/kubectl.exe"
    K3D_URL="https://github.com/rancher/k3d/releases/download/v1.7.0/k3d-windows-amd64.exe"
    TKN_URL="https://github.com/tektoncd/cli/releases/download/v0.8.0/tkn_0.8.0_Windows_x86_64.zip"
    RIO_URL="https://github.com/rancher/rio/releases/download/v0.7.0/rio-windows-amd64"
    HELM_URL="https://get.helm.sh/helm-v3.2.1-windows-amd64.zip"
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
    if [[ "$SHELL" == "BASH" ]]; then
      curl -L $TKN_URL | tar xzv tkn
      mv tkn bin/
    elif [[ "$SHELL" == "WSL" || "$SHELL" == "MSYS" ]]; then
      curl -L $TKN_URL -o tkn.zip
      unzip tkn.zip tkn.exe 
      mv tkn.exe bin/tkn
      rm tkn.zip
    fi
  fi

  if ! [[ -f bin/helm ]]; then	 
    if [[ "$SHELL" == "BASH" ]]; then    
      curl -L $HELM_URL | tar xzv tkn
      mv tkn bin/
    elif [[ "$SHELL" == "WSL" || "$SHELL" == "MSYS" ]]; then
      curl -L $HELM_URL -o helm.zip
      unzip helm.zip windows-amd64/helm.exe 
      mv windows-amd64/helm.exe bin/helm
      rm -r helm.zip windows-amd64/
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

install_traefik2() {
  echo "Installing Traefik2" 
  kubectl apply -f ingress/traefik2/rbac.yaml -f ingress/traefik2/deployment.yaml -f ingress/traefik2/crd.yaml
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
  echo "stub"
}

install_rio() {
  localdomain=`dialog --inputbox "What local Domain do you want?" 0 0 "myrio" \
  3>&1 1>&2 2>&3`
  dialog --clear    
  echo "Generating cert and key for domain myrio"
  openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout ${localdomain}.key -out ${localdomain}.crt -subj "/C=DE/ST=Bavaria/L=Nuremberg/O=DevOps/OU=IT Department/CN=${localdomain}"

  echo "Installing Rancher RIO (without letsencrypt or rdns for local stuff)"
  rio install --disable-features rdns,letsencrypt,gloo

  echo "Create wildcard TLS secret for ${localdomain}"
  kubectl -n rio-system create secret tls ${localdomain}-tls --cert=${localdomain}.crt --key=${localdomain}.key

  sed "s/your.company.com/${localdomain}/g" cd/rio/clusterdomain.yaml | kubectl apply -f -
  kubectl apply -f cd/rio/ingress.yaml
  

}

install_rio_dashboard() {
  echo "Installing Rancher RIO Dashboard (this might take a while)"
  rio dashboard
}

install_istio() {

  curl -L https://istio.io/downloadIstio | sh -
  $PWD/istio-1.5.4/bin/istioctl manifest apply --set profile=demo
}

install_concourse() {
  helm repo add concourse https://concourse-charts.storage.googleapis.com
  helm install concourse concourse/concourse
  kubectl apply -f cd/concourse/ingressroute.yaml
}

install_prometheus() {
  echo "Installing Prometheus"
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

install_jaeger() {
  kubectl apply -f observability/jaeger/crd.yaml

  kubectl apply -f observability/jaeger/service_account.yaml \
                -f observability/jaeger/role.yaml \
                -f observability/jaeger/role_binding.yaml \
                -f observability/jaeger/operator.yaml \
                -f observability/jaeger/cluster_role.yaml \
                -f observability/jaeger/cluster_role_binding.yaml \
                -f observability/jaeger/instance.yaml \
                -f observability/jaeger/ingressroute.yaml
}

start_k3d_cluster() {
  echo "Starting k3d Cluster"
  k3d create --server-arg="--no-deploy=traefik" --name dev
  #k3d create --server-arg="--no-deploy=traefik" --name dev --api-port 6550 --publish 80:80 --publish 443:443 --publish 9443:9443 --publish 9080:9080
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

install_k8s_dashboard() {
  kubectl apply -f k8s-dashboard/recommended.yaml
  kubectl apply -f k8s-dashboard/service-account.yaml
  kubectl apply -f k8s-dashboard/cluster-role-binding.yaml
  kubectl apply -f k8s-dashboard/ingress.yaml
  kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
}

install_ci() {
    install_tekton
    install_rio
    install_drone
    install_concourse
}

install_ingress() {
    install_nginx
    install_traefik
    install_traefik2
    install_istio
}

install_tools() {
    kubectl create namespace monitoring

    install_grafana
    install_prometheus
    install_jaeger
    install_k8s_dashboard
    install_rio_dashboard
}

verify_binaries() {
  echo "Verifying installed binaries"
  kubectl version
  tkn version
  k3d --version
  rio --version
}

notify_user() {
  echo "Now export the following lines and you are good to go!"
  echo 'export PATH=$PATH:`pwd`/bin'
  echo 'source <(kubectl completion bash)'
  if [[ "$SHELL" == "WSL" ]]; then
    echo "export KUBECONFIG=$(k3d get-kubeconfig --name dev | sed 's_\\_\/_g' | sed 's_C:_/c_')"
  elif [[ "$SHELL" == "BASH" ]]; then
    echo "export KUBECONFIG=$(k3d get-kubeconfig --name dev)"
  elif [[ "$SHELL" == "MSYS" ]]; then
    echo "export KUBECONFIG=$(k3d get-kubeconfig --name dev | sed 's_\\_\/_g' | sed 's_C:_/c_')"
  fi

  echo ""
  echo ""
  echo ""
  echo $'To access apps behind your ingress, run the following command: '
  echo $'kubectl port-forward -n kube-system `kubectl get pods -n kube-system --template \'{{range .items}}{{.metadata.name}}{{\"\\n\"}}{{end}}\' | grep \"^traefik\"` 8080:80 8081:8080 &'
  echo ""
  echo "Tekton Dashbaord is available at http://localhost:8080/tekton/"
  echo "Traefik Dashboard is available at http://localhost:8080/traefik"
  echo "K8S Dashboard is available at https://localhost:8081/dashboard/"
  echo "To access the various Istio Dashboards, use $PWD/istio-1.5.4/bin/istioctl dashboard, or kubectl port-forward like the following prometheus example."  
  echo ""
  echo "Prometheus is kinda bugged right now, so if you want to use the graph UI, you need a port-forward like this:"
  echo $'kubectl port-forward -n monitoring `kubectl get pods -n monitoring --template \'{{range .items}}{{.metadata.name}}{{\"\\n\"}}{{end}}\' | grep \"^prometheus\"` 9090 &'
  echo "Afterwards you can look at prometheus via http://localhost:9090/graph"
  echo ""
  echo "Concourse is also not playing along, it seems to work only on a root path. Nothing another port-forward can't fix!"
  echo $'kubectl port-forward `kubectl get pods --template \'{{range .items}}{{.metadata.name}}{{\"\\n\"}}{{end}}\' | grep \"^concourse-web\"` <port>:8080 &'
  echo "The login for concourse is test:test"
}


prep_setup
install_binaries

start_k3d_cluster
config_k3d_cluster

install_ingress
install_ci
install_tools

verify_binaries
notify_user
