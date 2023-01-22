# Zero-To-k8s

This project tries to ease the creation of a local Kubernetes environment, including all the awesome devops tools you can possibly need. 
It should be as easy as a "./startup.sh" to get you up and running and a "k3d delete --name dev" to clean up again. 

If anything you like is missing, hit me up! I love learning new awesome tools!

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. 

### Prerequisites

What things you need to install the software and how to install them:


```none
Docker
Dialog (If you are lazy, like me)
```

What this script was tested on:

```none
WSL (Frequently, since this is my main driver for development-stuff)
Ubuntu
MacOS 10.15
```

What it hopefully runs on one day:

```none
Git Bash/MinGW (This one is pretty hard to work with actually. It randomly dislikes rm'ing stuff and borks the permissions so a relog is needed)
```

### Installing

Edit startup.sh and add/remove stuff you need/want in

```bash
#Possible Single Values: tekton|rio|drone|concourse|argocd
CI="tekton"

#Possible Single Values: traefik|traefik2|nginx|istio|none
INGRESS="traefik2"

#Possible values: (Spaced-Delimited Multiple possible): prometheus grafana jaeger registry k8s-dashboard rio-dashboard istio
TOOLS="prometheus grafana jaeger registry k8s-dashboard"
```

And fire it up with

```bash
./startup.sh
```

For new-comers to linux, or just lazy people like me, install dialog with the package-manager of your choice and run 

```bash
./startup_dialog.sh
```

After the installation your console should tell you the different URLs you should know about, if I didn't miss anything.

## What doesn't work yet / is incomplete or a todo

* Istio Gateway Stuff
    To be honest, I don't fully understand how the Istio Ingress works yet, it just seems much more complicated than traefik/nginx (it's still envoy) which would explain it's brutal amounts of configuration/documentation. 
    I will try to fix the istio ingresses as soon as I get a grasp on how it works
* Concourse
    I want to blame it on concourse, since they don't have an explicit option to configure a proxypath/context-path, but that could be on me too. Documentation get's tough to read after a few hours of struggling and I could have easily missed it too.
* Sample Pipelines for the CD Tools
    Not really a priority as of now, but it would be a nice to have if there were easy to copy files/descriptors for the various CD tools

## Built With

* Base:
  * [k3d](https://github.com/rancher/k3d) - The Tool used to deploy kubernetes
  * [rancher](https://rancher.com/) - Run Kubernetes Everywhere with Rancher
* CD:
  * [TektonCD](https://github.com/tektoncd/pipeline) - The preferred tool to run your ci/cd
  * [Tekton Dashboard](https://github.com/tektoncd/dashboard) - Dashboard for Tekton Pipelines
  * [Concourse CI](https://concourse-ci.org/) - An amazing Open Source continuous Thing-Doer
  * [rancher rio](https://rio.io/) - The Application Deployment Engine for Kubernetes
  * [argocd](https://argoproj.github.io/argo-cd/) - Declarative GitOps CD for Kubernetes
* Ingress:
  * [NGINX](https://www.nginx.com/products/nginx/kubernetes-ingress-controller/) - Production-Grade Ingress Controller for Kubernetes
  * [Traefik](https://traefik.io/) - My favorite Ingress Controller and proxy
  * [Istio](https://istio.io/) - The defacto standard in terms of Service-Mesh
* Tools:
  * [Grafana](https://maven.apache.org/) - Awesome Visualization of Prometheus Data
  * [Prometheus](https://prometheus.io/) - The Standard Metric Collector
  * [Jaeger](https://www.jaegertracing.io/) - An open source, end-to-end distributed tracing tool
  * [k8s-dashboard](https://github.com/kubernetes/dashboard) - A general purpose, web-based UI for Kubernetes clusters
  * [MinIO](https://min.io/) - High Performance, Kubernetes Native Object Storage
* DBs:
  * [Apache Cassandra](https://cassandra.apache.org/) -  Manage massive amounts of data, fast, without losing sleep
* Hopefully even more in the future!

## Authors

* **Raphael Habereder** - *Initial work* - [RHabereder](https://github.com/RHabereder)

## License

This project is licensed under the Unlicense - see the [LICENSE](LICENSE) file for details

## Acknowledgments

* Rancher for being awesome and developing awesome software
* The k8s ecosystem
* People that build Helm Charts
* Everyone that asked the questions I look up on stackoverflow
* Anyone whose code I reused/changed/used as inspiration!
