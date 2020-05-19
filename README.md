# Zero-To-k8s

This project tries to ease the creation of a local Kubernetes environment, including all the awesome devops tools you can possibly need. 
It should be as easy as a "./startup.sh" to get you up and running and a "k3d delete --name dev" to clean up again. 

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. 


### Prerequisites

What things you need to install the software and how to install them:

```
Docker 
If you are lazy, like me, dialog
```

### Installing

A step by step series of examples that tell you how to get a development env running

Look at startup.sh and comment stuff you don't need/want and fire it up

```
./startup.sh
```

For new-comers to linux, or just lazy people like me, install dialog and use startup_dialog.sh


After the installation your console should tell you the different URLs you should know about.


## Built With

* [k3d](https://github.com/rancher/k3d) - The Tool used to deploy kubernetes
* [rancher](https://rancher.com/) - Run Kubernetes Everywhere with Rancher
* [rancher rio](https://rio.io/) - The Rancher Application Deployment Engine for Kubernetes
* [TektonCD](https://github.com/tektoncd/pipeline) - The preferred tool to run your ci/cd
* [Tekton Dashboard](https://github.com/tektoncd/dashboard) - Dashboard for Tekton Pipelines
* [Traefik](https://traefik.io/) - The Ingress Controller used
* [Grafana](https://maven.apache.org/) - Awesome Visualization of Prometheus Data
* [Prometheus](https://prometheus.io/) - The Standard Metric Collector
* [Jaeger](https://www.jaegertracing.io/) - An open source, end-to-end distributed tracing tool
* [Concourse CI](https://concourse-ci.org/) - An amazing Open Source continuous Thing-Doer
* [Istio](https://istio.io/) - The defacto standard in terms of Service-Mesh

## Authors

* **Raphael Habereder** - *Initial work* - [RHabereder](https://github.com/RHabereder)

## License

This project is licensed under the Unlicense - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to Rancher for being awesome and developing awesome software and tools and anyone whose code was reused and changed!



