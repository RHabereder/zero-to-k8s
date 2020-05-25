# Zero-To-k8s

This project tries to ease the creation of a local Kubernetes environment, including all the awesome devops tools you can possibly need. 
It should be as easy as a "./startup.sh" to get you up and running and a "k3d delete --name dev" to clean up again. 

If anything you like is missing, hit me up! I love learning new awesome tools!

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. 


### Prerequisites

What things you need to install the software and how to install them:

```
Docker 
Dialog (If you are lazy, like me)
```

What this script was tested on:

```
WSL (Frequently, since this is my main driver for development-stuff)
Ubuntu
```

What it hopefully runs on one day:

```
Git Bash/MinGW (This one is pretty hard to work with actually. It randomly dislikes rm'ing stuff and borks the permissions so a relog is needed)
```

### Installing

Edit startup.sh and add/remove stuff you need/want in

```
#Possible Single Values: tekton,rio,drone,concourse
CI="tekton"

#Possible Single Values: traefik,traefik2,nginx,istio,none
INGRESS="traefik2"

#Possible values: (Spaced-Delimited Multiple possible): prometheus grafana jaeger registry k8s-dashboard rio-dashboard istio
TOOLS="prometheus grafana jaeger registry k8s-dashboard"
```

And fire it up with 
```
./startup.sh
```

For new-comers to linux, or just lazy people like me, install dialog with the package-manager of your choice and run 
```
./startup_dialog.sh
```

After the installation your console should tell you the different URLs you should know about, if I didn't miss anything.


## Built With

* [k3d](https://github.com/rancher/k3d) - The Tool used to deploy kubernetes
* [rancher](https://rancher.com/) - Run Kubernetes Everywhere with Rancher
* [rancher rio](https://rio.io/) - The Rancher Application Deployment Engine for Kubernetes
* [TektonCD](https://github.com/tektoncd/pipeline) - The preferred tool to run your ci/cd
* [Tekton Dashboard](https://github.com/tektoncd/dashboard) - Dashboard for Tekton Pipelines
* [NGINX](https://www.nginx.com/products/nginx/kubernetes-ingress-controller/) - Production-Grade Ingress Controller for Kubernetes
* [Traefik](https://traefik.io/) - My favorite Ingress Controller and proxy
* [Grafana](https://maven.apache.org/) - Awesome Visualization of Prometheus Data
* [Prometheus](https://prometheus.io/) - The Standard Metric Collector
* [Jaeger](https://www.jaegertracing.io/) - An open source, end-to-end distributed tracing tool
* [Concourse CI](https://concourse-ci.org/) - An amazing Open Source continuous Thing-Doer
* [Istio](https://istio.io/) - The defacto standard in terms of Service-Mesh
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



