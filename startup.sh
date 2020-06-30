#!/bin/bash
set -e

trap cleanup SIGINT

#Possible Single Values: tekton|rio|drone|concourse
CI="tekton"

#Possible Single Values: traefik|traefik2|nginx|istio|none
INGRESS="traefik2"

#Possible values: (Spaced-Delimited Multiple possible): prometheus grafana jaeger registry minio k8s-dashboard rio-dashboard istio
TOOLS="prometheus grafana jaeger registry minio k8s-dashboard"

# If you want to mount some files through, K3D can bindmount a dir for you in $PWD/$K3D_MOUNT_DIR
# Currently used only for tekton pipelines
K3D_MOUNT_DIR="k3dshare"
HOSTS_FILE_LOCATION=""
ISTIO_VERSION=1.5.4
prep_setup() {
  echo "Preparing Setup"

  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if grep -q Microsoft /proc/version; then
      KUBECTL_URL="https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/windows/amd64/kubectl.exe"
      K3D_URL="https://github.com/rancher/k3d/releases/download/v1.7.0/k3d-windows-amd64.exe"
      TKN_URL="https://github.com/tektoncd/cli/releases/download/v0.8.0/tkn_0.8.0_Windows_x86_64.zip"
      RIO_URL="https://github.com/rancher/rio/releases/download/v0.7.0/rio-windows-amd64"
      HELM_URL="https://get.helm.sh/helm-v3.2.1-windows-amd64.zip"
      DRONE_URL=""
      SHELL="WSL"
    else
      SHELL="BASH"
      KUBECTL_URL="https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
      K3D_URL="https://github.com/rancher/k3d/releases/download/v1.7.0/k3d-linux-amd64"
      TKN_URL="https://github.com/tektoncd/cli/releases/download/v0.8.0/tkn_0.8.0_Linux_x86_64.tar.gz"
      RIO_URL="https://github.com/rancher/rio/releases/download/v0.7.1/rio-linux-amd64"
      HELM_URL="https://get.helm.sh/helm-v3.2.1-linux-amd64.tar.gz"
      DRONE_URL=""
    fi
  elif [[ $OSTYPE == "darwin"* ]]; then
    KUBECTL_URL="https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl"
    K3D_URL="https://github.com/rancher/k3d/releases/download/v1.7.0/k3d-darwin-amd64"
    TKN_URL="https://github.com/tektoncd/cli/releases/download/v0.8.0/tkn_0.8.0_Darwin_x86_64.tar.gz"
    RIO_URL="https://github.com/rancher/rio/releases/download/v0.7.0/rio-darwin-amd64"
    HELM_URL="https://get.helm.sh/helm-v3.2.1-darwin-amd64.tar.gz"
    DRONE_URL=""
    SHELL="ZSH"
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
    echo $KUBECTL_URL
    curl -L $KUBECTL_URL -o bin/kubectl
  fi
  if ! [[ -f bin/k3d ]]; then	  
    curl -L $K3D_URL -o bin/k3d
  fi
  if ! [[ -f bin/rio ]]; then	  
    curl -L $RIO_URL -o bin/rio
  fi

  if ! [[ -f bin/tkn ]]; then	  
    if [[ "$SHELL" == "BASH" || "$SHELL" == "ZSH" ]]; then
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
    if [[ "$SHELL" == "BASH" || $SHELL == "ZSH" ]]; then
      if [[ "$SHELL" == "ZSH" ]]; then
        DISTRI="darwin"
      elif [[ "$SHELL" == "ZSH" ]]; then 
        DISTRI="linux"
      fi
      curl -L $HELM_URL | tar xzv ${DISTRI}-amd64/helm
      mv ${DISTRI}-amd64/helm bin/
      rmdir ${DISTRI}-amd64
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
  kubectl apply -f ingress/nginx/mandatory.yaml 
}


install_tekton() {
  echo "Installing Tekton-CD"
  #Install Tekton
  kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

  #Install Dashboard
  kubectl apply -f https://github.com/tektoncd/dashboard/releases/download/v0.6.1/tekton-dashboard-release.yaml
  
  if [[ ! "$INGRESS" == "none" ]]; then
    kubectl apply -f cd/tekton/${INGRESS}-ingress.yaml
  fi

  kubectl apply -f cd/tekton/sample-pipeline/k8s/svc-account.yaml \
                -f cd/tekton/sample-pipeline/k8s/svc-credentials.yaml \
                -f cd/tekton/sample-pipeline/tekton/build-task.yaml \
                -f cd/tekton/sample-pipeline/tekton/deploy-task.yaml \
                -f cd/tekton/sample-pipeline/tekton/git-task.yaml \
                -f cd/tekton/sample-pipeline/tekton/pipeline.yaml
}


install_argocd() {
  kubectl create namespace argocd
  kubectl apply -n argocd -f cd/argocd/config.yaml \
                          -f cd/argocd/secrets.yaml \
                          -f cd/argocd/roles.yaml \
                          -f cd/argocd/deployment.yaml \
                          -f cd/argocd/service.yaml 
  if [[ ! "$INGRESS" == "none" ]]; then
    kubectl apply -f cd/argocd/${INGRESS}-ingress.yaml
  fi
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
  
  if [[ ! "$INGRESS" == "none" ]]; then
    kubectl apply -f cd/rio/${INGRESS}-ingress.yaml
  fi

}

install_rio_dashboard() {
  echo "Installing Rancher RIO Dashboard (this might take a while)"
  rio dashboard
}

install_istio() {
  
  curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
  $PWD/istio-${ISTIO_VERSION}/bin/istioctl manifest apply --set profile=demo
  cp $PWD/istio-${ISTIO_VERSION}/bin/istioctl $PWD/bin/
}

install_concourse() {
  helm repo add concourse https://concourse-charts.storage.googleapis.com
  helm install concourse concourse/concourse

  if [[ ! "$INGRESS" == "none" ]]; then
    kubectl apply -f cd/concourse/${INGRESS}-ingress.yaml
  fi
}

install_prometheus() {
  echo "Installing Prometheus"
  kubectl apply -f observability/prometheus/cluster-role.yaml \
                -f observability/prometheus/config-map.yaml \
                -f observability/prometheus/deployment.yaml \
                -f observability/prometheus/service.yaml \

  if [[ ! "$INGRESS" == "none" ]]; then
    kubectl apply -f observability/prometheus/${INGRESS}-ingress.yaml
  fi
}

install_grafana() {
  echo "Installing Grafana"
  kubectl apply -f observability/grafana/dashboard-cfgmap.yaml \
                -f observability/grafana/datasource-configMap.yaml \
                -f observability/grafana/deployment.yaml \
                -f observability/grafana/service.yaml \

  if [[ ! "$INGRESS" == "none" ]]; then
    kubectl apply -f observability/grafana/${INGRESS}-ingress.yaml
  fi
}

install_jaeger() {
  kubectl apply -f observability/jaeger/crd.yaml
  #Wait a sec, so you don't get "no matches for kind "Jaeger" in version "jaegertracing.io/v1"
  sleep 1
  kubectl apply -f observability/jaeger/service_account.yaml \
                -f observability/jaeger/role.yaml \
                -f observability/jaeger/role_binding.yaml \
                -f observability/jaeger/operator.yaml \
                -f observability/jaeger/cluster_role.yaml \
                -f observability/jaeger/cluster_role_binding.yaml \
                -f observability/jaeger/instance.yaml 

  if [[ ! "$INGRESS" == "none" ]]; then
    kubectl apply -f observability/jaeger/${INGRESS}-ingress.yaml
  fi
}

install_minio() {
  kubectl apply -f storage/minio/credentials-secret.yaml \
                -f storage/minio/operator.yaml \
                -f storage/minio/instance.yaml \
                -f storage/minio/service.yaml 
  if [[ ! "$INGRESS" == "none" ]]; then
    kubectl apply -f storage/minio/${INGRESS}-ingress.yaml
  fi
}

start_k3d_cluster() {

  if [[ $TOOLS == *"registry"* ]]; then
    K3D_ARGS="$K3D_ARGS --enable-registry"

    if [[ "$SHELL" == "BASH" || "$SHELL" == "ZSH" ]]; then
      HOSTS_FILE_LOCATION="/etc/hosts"
    elif [[ "$SHELL" == "WSL" || "$SHELL" == "MSYS" ]]; then
      HOSTS_FILE_LOCATION="C:\\Windows\\system32\\drivers\\etc\\hosts"
    fi
    echo "Things to do to use the local registry: "
    echo "1) Make sure to push your images to registry.local:5000/some/awesomeimage:tag"
    echo "2) Add \"127.0.0.1  registry.local\" to your hosts file at $HOSTS_FILE_LOCATION"
    echo "3) Add registry.local:5000 to your Docker Daemons insecure-registries array"
  fi
  if [[ $CICD == *"tekton"* ]]; then
    mkdir -p $PWD/$K3D_MOUNT_DIR
    K3D_ARGS="$K3D_ARGS --volume $PWD/$K3D_MOUNT_DIR:/var/k3dshare/"
  fi
  echo "Starting k3d Cluster with args: $K3D_ARGS"
  k3d create $K3D_ARGS  echo "wait a bit for k3d to start up"
  sleep 20
}

patch_coredns() {
  kubectl -n kube-system patch cm coredns --patch "$(sed "s/REGISTRY_IP/$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' /k3d-registry)/g" tools/registry/patch_coredns.yaml)"
}

config_k3d_cluster() {
  echo "Configuring k3d cluster"
  if [[ "$SHELL" == "WSL" ]]; then
    echo "Need to create %USERPROFILE%/.kube/config, because somehow kubectl is now broken"
    WINHOME=$(wslpath $(cmd.exe /c "<nul set /p=%UserProfile%" 2>/dev/null))
    mkdir -p $WINHOME/.kube
    cp $(wslpath -u $(k3d get-kubeconfig --name dev)) $WINHOME/.kube/config
    export KUBECONFIG=$WINHOME/.kube/config
  elif [[ "$SHELL" == "BASH" || "$SHELL" == "ZSH" ]]; then
    export KUBECONFIG=$(k3d get-kubeconfig --name dev)
  elif [[ "$SHELL" == "MSYS" ]]; then
    echo "Converting paths to POSIX, because derp"
    export KUBECONFIG=$(k3d get-kubeconfig --name dev | sed 's_\\_\/_g' | sed 's_C:_/c_')
  fi

  if [[ $TOOLS == *"registry"* ]]; then
    patch_coredns
  fi
}

install_k8s_dashboard() {
  kubectl apply -f k8s-dashboard/recommended.yaml
  kubectl apply -f k8s-dashboard/service-account.yaml
  kubectl apply -f k8s-dashboard/cluster-role-binding.yaml
  
  if [[ ! "$INGRESS" == "none" ]]; then
    kubectl apply -f k8s-dashboard/${INGRESS}-ingress.yaml
  fi
  kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
}

install_ci() {
  if [[ $CICD == "tekton" ]]; then
    install_tekton
  elif [[ $CICD == "rio" ]]; then
    install_rio
  elif [[ $CICD == "argocd" ]]; then
    install_argocd
  elif [[ $CICD == "drone" ]]; then
    install_drone
  elif [[ $CICD == "concourse" ]]; then
    install_concourse
  fi
}

install_ingress() {
  if [[ $INGRESS == "nginx" ]]; then
    install_nginx
  elif [[ $INGRESS == "traefik" ]]; then
    install_traefik
  elif [[ $INGRESS == "traefik2" ]]; then
    install_traefik2
  elif [[ $INGRESS == "istio" || $TOOLS == *"istio"* ]]; then
    install_istio
  fi
}

install_tools() {
  if [[ ! -z $TOOLS  ]]; then
    kubectl create namespace monitoring
  fi
  if [[ $TOOLS == *"grafana"* ]]; then
    install_grafana
  fi
  if [[ $TOOLS == *"prometheus"* ]]; then
    install_prometheus
  fi
  if [[ $TOOLS == *"jaeger"* ]]; then
    install_jaeger
  fi
  if [[ $TOOLS == *"minio"* ]]; then
    install_minio
  fi
  if [[ $TOOLS == *"k8s-dashboard"* ]]; then
    install_k8s_dashboard
  fi
  if [[ $TOOLS == *"rio-dashboard"* ]]; then
    install_rio_dashboard
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
  echo "Now export the following lines and you are good to go!"
  echo 'export PATH=$PATH:`pwd`/bin'
  echo 'source <(kubectl completion bash)'
  if [[ "$SHELL" == "BASH" ]]; then
    echo "export KUBECONFIG=$(k3d get-kubeconfig --name dev)"
  fi

  echo ""
  echo ""
  echo ""
  echo $'To access apps behind your ingress, run the following command: '
  if [[ $INGRESS == "nginx" ]]; then
  echo $'kubectl port-forward -n ingress-nginx `kubectl get pods -n ingress-nginx --template \'{{range .items}}{{.metadata.name}}{{\"\\n\"}}{{end}}\' | grep \"^nginx-ingress\"` 8080:80 8443:443 &'
  elif [[ $INGRESS == "traefik" ]]; then
  echo $'kubectl port-forward -n kube-system `kubectl get pods -n kube-system --template \'{{range .items}}{{.metadata.name}}{{\"\\n\"}}{{end}}\' | grep \"^traefik\"` 8080:80 8443:443 8081:8080 &'
  echo "Traefik Dashboard is available at http://localhost:8080/traefik"
  elif [[ $INGRESS == "traefik2" ]]; then
  echo $'kubectl port-forward -n kube-system `kubectl get pods -n kube-system --template \'{{range .items}}{{.metadata.name}}{{\"\\n\"}}{{end}}\' | grep \"^traefik\"` 8080:80 8443:443 8081:8080 &'
  echo "Traefik2 Dashboard is available at http://localhost:8081/dashboard/"
  elif [[ $INGRESS == "istio" ]]; then
  echo $'kubectl port-forward -n kube-system `kubectl get pods -n istio-system --template \'{{range .items}}{{.metadata.name}}{{\"\\n\"}}{{end}}\' | grep \"^istio-ingressgateway\"` 8080:80 8443:443 8081:8080 &'
  echo "To access the various Istio Dashboards, use $PWD/istio-${ISTIO_VERSION}/bin/istioctl dashboard, or kubectl port-forward like the following prometheus example."  
  fi

  echo "Tekton Dashboard is available at http://localhost:8080/tekton/"
  echo "K8S Dashboard is available at https://localhost:8081/dashboard/"
  echo ""
  echo "Concourse is not playing along right now, it seems to work only on a root path. Nothing another port-forward can't fix!"
  echo $'kubectl port-forward `kubectl get pods --template \'{{range .items}}{{.metadata.name}}{{\"\\n\"}}{{end}}\' | grep \"^concourse-web\"` <port>:8080 &'
  echo "The login for concourse is test:test"
}


cleanup() {
  echo "Caught CTRL+C, aborting and cleaning up"
  k3d delete --name dev
  if [[ -d $PWD/$K3D_MOUNT_DIR ]]; then
    rm -rf $PWD/$K3D_MOUNT_DIR
  fi
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