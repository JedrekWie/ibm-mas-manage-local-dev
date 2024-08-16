# Rapid Class Deployment in IBM MAS Manage Local Development Environment

Example local development for IBM MAS Manage with rapid Java classes deployment.

It reduces the time required to redeploy Java customization code changes to the absolute minimum, eliminating the need to rebuild the EAR file and recreate local container.

For more details refer to [Rapid Class Deployment in IBM MAS Manage Local Development Environment](https://www.linkedin.com/pulse/rapid-class-deployment-ibm-mas-manage-local-andrzej-wieclaw-oruaf) LinkedIn article.

## Customization

Refer to `FIXME` labels accross the files to adjust settings, like:
* [build.sh](build.sh) - location of the local host Maximo customization Java classes location
* [Dockerfile](Dockerfile) - extent of the Maximo EAR expansion and custom WebSphere Liberty Profile configuration
* [server-custom.xml](server-custom.xml) - additional WebSphere Liberty Profile configuration