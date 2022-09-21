# ActiveMQ - Sterling OMS Bootstrap / Example

Sterling Order Management (OMS) has out-of-product requirements for data storage (IBM DB2) and messaging (IBM MQ).
This is detailed in the product specifications and requirements page found here: https://www.ibm.com/docs/en/order-management-sw/10.0?topic=operator-installation-prerequisites 

However, OMS *does* offer support for other JMS messaging systems, such as ActiveMQ: https://www.ibm.com/docs/en/order-management-sw/10.0?topic=systems-configuring-apache-activemq.
This provides a certain amount of flexibility around how you deploy your messaging systems, both in and outside of your OpenShift deployment of OMS.

The provided artifacts within this folder is designed to help you with a sample ActiveMQ container-based deployment to help you quickly stand-up the messaging requirement for your
Azure Sterling OMS deployment.

## Notice: Production Readiness

The example provided is designed to help you quickly bootstrap an ActiveMQ environment for your Sterling OMS deployment and/or testing. This example forgoes common production configurations, such as high availability and scale considerations, since it is only provided as a single pod configuration. While IBM does provide official support for ActiveMQ, please familiarize yourself with the requirements and your desired state of your deployment before going to production. There are also many other ActiveMQ (and ActiveMQ-like) alternatives you may want to look at, such as Red Hat's official AMQ Operator offering: https://access.redhat.com/documentation/en-us/red_hat_amq/7.7/html-single/deploying_amq_broker_on_openshift/index

## Dockerfile

While there are a few containers available that you can use to host ActiveMQ, the provided Dockerfile (./docker/Dockerfile) is designed to be a fresh, barebones deployment of Apache Active MQ 5.17.1, based 
on a an Docker Official Image of openjdk: https://hub.docker.com/_/openjdk. If you'd like to use this image, you will need to download this file, and build and tag the image to your Azure Container Registry:

```bash
## From the directory where you download/create your Dockerfile:
docker build -t <your repository name>.azurecr.io/active-mq-openjdk:1.0 .
docker push <your repository name>.azurecr.io/active-mq-openjdk:1.0
```

Once your container is built, you can test the functionality by running the container locally and accessing the dashboard (https://localhost:8161/admin)

```bash
docker run -p 8161:8161 <your repository name>.azurecr.io/active-mq-openjdk:1.0
```

## Option 1: Deploying your ActiveMQ Container to Azure Redhat OpenShift

Once you have a working ActiveMQ instance, your next step is to deploy it in your OpenShift environment. First, clone this repository (or copy all of the files in the ./deployment folder).

### Deployment Overview

The provided .yaml files are designed to deploy the following artifacts in your OpenShift cluster:

* ```active-mq``` namespace
* Persistent volume claim using Azure Files Premium storage class
* A deployment of one Active MQ container with persistent storage
* Service definitions for all applicable endpoints
* Route definition for the ActiveMQ dashboard

***Note*** The OMS configuration currently requires a formatted uri in the configuration of host:port, and since this deployment will be using ClusterIP as the deployed service configuration, we will need to use the assigned service port when configuring your OM Environment


### Prerequisites

This deployment assumes that you have a deployed OpenShift cluster, access to the cluster, the OpenShift command line tool installed, and the Azure Files storage drivers and storage classes installed (as provided as part of the Quick Start guide at the root of this repository). You will also need the Azure CLI () and be logged into your current subscription where your cluster is deployed to.

### Deployment Steps

First, make sure you clone (or download) the files in the ./Deployment folder of this repository directory Then, you'll need to specify a few environment variables:

```bash
##Can hard code these if you know them...
DOMAIN=$(az aro show  -n omsaro3 -g OMSDEMO --query "clusterProfile.domain" -o tsv)
LOCATION=$(az aro show  -n omsaro3 -g OMSDEMO --query "location" -o tsv)
ACR_NAME="<your Azure Container Registry Name>"
ACR_SECRET="<your primary or secondary access key for your registry>"
ACTIVEMQ_IMAGENAME="<the full name of your built and pushed Active MQ image"
```

Then, use ```envsubt``` to replace the values in the template(s) and deploy the target namespace (active-mq):

```bash
envsubst < "amq-deployment.yaml" > "amq-deployment-updated.yaml"
envsubst < "amq-route-dashboard.yaml" > "amq-route-dashboard-updated.yaml"
```

The provided ActiveMQ container in this example requires the service to run as a specified ID, so we must create a service account and scc policy in our new namespace:

```bash
oc create serviceaccount runasanyuid -n active-mq
oc adm policy add-scc-to-user anyuid -z runasanyuid --as system:admin -n active-mq
```

Next, you should create a series of secrets in your namespace: one for the image pull secret for your container registry where you pushed your ActiveMQ statement, and one for your user ID and passwords for the administrator dashboard:

```bash
oc create secret docker-registry azure-acr-credentials --docker-server=$ACRSERVER.azurecr.io  --docker-username=$ACR_NAME --docker-password=$ACR_SECRET -n active-mq
#Create a file called jetty-realm.properties
#Put your user credentials in there in username: password, role
#The below creates one admin user with username "admin" and password "admin" and one regular user named "guest" with password "mypassword"
#Please consider changing accordingly!
touch jetty-realm.properties
echo "admin: admin, admin" >> jetty-realm.properties
echo "guest: mypassword, user" >> jetty-realm.properties

oc create secret generic active-mq-credentials --from-file=jetty-realm.properties -n active-mq
```

With all the requirements in place, you can now complete the deployment:

```bash
oc apply -f amq-pvc.yaml
oc apply -f amq-deployment-updated.yaml
oc apply -f amq-service.yaml
oc apply -f amq-route-dashboard-updated.yaml
```

At this point, you should monitor the deployment by looking at both the OpenShift event logs and pod logs to make sure the container starts successfully. Once it does, you will need to get the service address for the pod as you will need it for your OMEnvironment configuration:

```bash
#Get Service IP
oc get endpoints -n active-mq -o json | jq '.items[].subsets[].addresses[].ip'
#Get Service Port
oc get endpoints -n active-mq -o json | jq '.items[].subsets[].ports[] | select(.name == "openwire") | .port'
```

## Option 2: Deploy ActiveMQ to Azure Container Instance



## Using ActiveMQ in your OMEnviroment deployment

IBM provides guidance around the required configuration of your OMEnvironment deployment using ActiveMQ which you can read about here: https://www.ibm.com/docs/en/order-management-sw/10.0?topic=activemq-configuring-sterling-order-management-software-use

The short version is that your yaml configuration file should replace the following values:

```bash
yfs.oms_provider_url: tcp:/<service ip address>:<openwire service port>
yfs.yfs.agent.override.providerurl: tcp:/<service ip address>:<openwire service port>
yfs.yfs.flow.override.providerurl: tcp:/<service ip address>:<openwire service port>
yfs.oms_qcf: ConnectionFactory
yfs.yfs.agent.override.qcf: ConnectionFactory
yfs.yfs.flow.override.qcf: ConnectionFactory
```

Likewise, you can (optionally) take advantage of dynamic queue creation if you like by changing your queue names in your OMEnvironment deployment .yaml file by prepending "dynamicQueues/" to each queue name, for instance:

```bash
#Previously: yfs.CREATE_SALES_ORDER: CREATE_SALES_ORDER
yfs.CREATE_SALES_ORDER: dynamicQueues/CREATE_SALES_ORDER
```

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
