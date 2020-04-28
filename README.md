# Zero-To-k8s

This project tries to ease the creation of a local Kubernetes environment, including all the awesome devops tools you can possibly need. 
It should be as easy as a "./startup.sh" to get you up and running and a "k3d delete --name dev" to clean up again. 

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. 


### Prerequisites

What things you need to install the software and how to install them

```
Docker
```

### Installing

A step by step series of examples that tell you how to get a development env running

Fire up the script and you are ready roll

```
./startup.sh
```

After the installation you should get prompts to the Dashboards of Tekton, Taraefik, Grafana and more tools.


## Built With

* [k3d](https://github.com/rancher/k3d) - The Tool used to deploy kubernetes
* [TektonCD](https://github.com/tektoncd/pipeline) - The preferred tool to run your ci/cd
* [Tekton Dashboard](https://github.com/tektoncd/dashboard) - Dashboard for Tekton Pipelines
* [Traefik](https://traefik.io/) - The Ingress Controller used
* [Grafana](https://maven.apache.org/) - Awesome Visualization of Prometheus Data
* [Prometheus](https://rometools.github.io/rome/) - The Standard Metric Collector

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **Raphael Habereder** - *Initial work* - [RHabereder](https://github.com/RHabereder)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the Unlicense - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to Rancher for being awesome and developing awesome software and tools and anyone whose code was reused and changed!



