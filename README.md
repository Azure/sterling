# QuickStart Guide: Sterling Order Management on Azure

This repository provides deployument guidance and best practices for running IBM Sterling Order management (OMS) on Azure Redhat OpenShift (ARO) in the Azure public cloud. This guide was written and tested with Azure RedHat OpenShift 4.9.9 and OMS Version X.XX

> 🚧 **NOTE**: The scripts contained within this repo were written with the intention of testing various configurations and integrations on Azure. They allow you to quickly deploy the required infrastructure on Azure so that you migrate an existing OMS to Azure, or start fresh with new development.

> 🚧 **WARNING** this guide is currently under active development. If you would like to contribute or use this right now, please reach out so we can support you.

## Table of Contents:

- [QuickStart Guide: Sterling Order Management on Azure](#quickstart-guide-sterling-order-management-on-azure)
  - [Table of Contents:](#table-of-contents)
  - [What's in this repository?](#whats-in-this-repository)
  - [Overview](#overview)
  - [Before You Begin](#before-you-begin)
  - [Step 1: Preparing Your Azure Environment](#step-1-preparing-your-azure-environment)
    - [Creating a storage account for required IBM application installers](#creating-a-storage-account-for-required-ibm-application-installers)
  - [Step 2: Install Azure RedHat Openshift](#step-2-install-azure-redhat-openshift)
  - [Step 3: Accessing your ARO Cluster](#step-3-accessing-your-aro-cluster)
  - [Step 4: Post Azure Deployment Tasks](#step-4-post-azure-deployment-tasks)
    - [Private VM Outbound Internet Access](#private-vm-outbound-internet-access)
    - [Install and Configure IBM DB2](#install-and-configure-ibm-db2)
    - [Install and Configure IBM MQ:](#install-and-configure-ibm-mq)
    - [Install Tools and Helm Charts](#install-tools-and-helm-charts)
  - [Step 5: Deploy OMS Prerequisites](#step-5-deploy-oms-prerequisites)
    - [Install Azure Files CSI Driver](#install-azure-files-csi-driver)
    - [Create OMS Namespace](#create-oms-namespace)
    - [Add Azure Container Registry Credentials to Namespace Docker Credential Secret](#add-azure-container-registry-credentials-to-namespace-docker-credential-secret)
    - [Create OMS Secret](#create-oms-secret)
    - [Create Required PVC(s)](#create-required-pvcs)
    - [Create RBAC Role](#create-rbac-role)
    - [Set up development VM(s)](#set-up-development-vms)
  - [Step 6: Deploying OMS](#step-6-deploying-oms)
    - [Pushing your containers to your Azure Container Registry](#pushing-your-containers-to-your-azure-container-registry)
    - [SSL Connections and Keystore Configuration](#ssl-connections-and-keystore-configuration)
    - [Deploying OMS Via Helm Charts](#deploying-oms-via-helm-charts)
    - [Deploying OMS Via the OpenShift Operator](#deploying-oms-via-the-openshift-operator)
  - [Step 7: Post Deployment Tasks](#step-7-post-deployment-tasks)
    - [Licensing your DB2 and MQ Instances](#licensing-your-db2-and-mq-instances)
    - [Migrating Your Data](#migrating-your-data)
    - [Other Best Practices and Considerations](#other-best-practices-and-considerations)
  - [Deploying OMS](#deploying-oms)
  - [Contributing](#contributing)
  - [Trademarks](#trademarks)

## What's in this repository?

- ./azure - Contains a series of .bicep files that can be used to boostrap a reference deployment of all the required Azure resources for your deployment
- ./config - Contains files used by the installer examples or Azure automation scripts to configure services
- ./examples - Contains example files as references for your deployments, such as a sample OMS secrets file 

## Overview

This repository is designed to help you plan your Sterling Order Management deployment on Microsoft Azure with a configuration simialar to the below diagram:

![A Sample OMS Networking/Resource Digram](/docs/images/SterlingNetworkDiagram.png)

To get started, you'll need to accomplish the following tasks:

1. Preparing and configuring your Azure environment for an Azure Redhat Openshift deployment
2. Deploy all the required Azure resources (including Azure Redhat OpenShift)
3. Install and configure IBM MQ and IBM DB2 on one or more virtual machines (and configure high-availability if neccessary)
4. Configure storage drivers for Azure RedHat OpenShift
5. Set your required OpenShift artifacts, such as your target namespace and any required secrets and persistent volumes
6. Configure the IBM Helm Charts repository for Sterling Order Management (or configure the OpenShift Operator, when available)
7. Push your OMS containers to your Azure Container Registry
8. Deploy OMS

## Before You Begin

To sucessfully install and configure OMS on Azure, you'll need to make sure you have all of the following:

* An active Azure subscription
 * A quota of at least 40 vCPU allowed for your VM type(s) of choice. Request a quota increase if needed.
 * You will need subscription owner permissions for the deployment.
* A copy of IBM MQ and IBM DB2. You can obtain these installers in one of two ways:
  * For testing and development, IBM provides free versions of both DB2 and MQ you can use for evaluation purposes:
    * DB2 Community Edition: https://www.ibm.com/products/db2-database/developers
    * IBM MQ For Developers: https://developer.ibm.com/articles/mq-downloads/
  * For a licensed version that may be included in your OMS agreement, please obtain a version from Passport Advantage: https://www-112.ibm.com/software/howtobuy/passportadvantage/paoreseller/LoginPage?abu=
* The Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
* *TODO: Sterling OMS Licensing Information?*

Once you have access to your Azure subscription, you'll then need to set up an Application Registration (SPN) that has contributor access to the subscription you are are going to deploy to.

Finally, for managing and configuring Azure Redhat OpenShift, you'll also need the ```oc``` CLI tool. [You can download this tool from Red Hat at their official download site](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/). You should also download and install the Azure CLI.


## Step 1: Preparing Your Azure Environment

At a minimum, your Azure environment should contain a resource group that contains the following resources:

1. A Virtual Network: This virtual network will host the following subnets (with reccomended CIDR ranges*):
    - control (/24): the control subnet is used by Azure RedHat OpenShift control nodes.
    - worker (/24): the worker subnet is used by Azure RedHat OpenShift worker nodes.
    - data (/27): this subnet holds the virtual machines running services related to data, such as IBM DB2 Virtual Machines and IBM MQ servers.
    - management (/30): this subnet is used for your "Jump Box" virtual machine(s) that can be used to securely connect to all other resources inside this network
    - development (/28): this subnet can be used to deploy developer virtual machines, if needed, to develop, test, and deploy OMS customized container images securely to the Azure Container Registry.
    - endpoints (/25): this subnet exists for hosting private endpoints for Azure services such as storage accounts, container registries, and other services to provide private connectivity.
2. Azure Premium Files storage account: For hosting MQ Queue Manager data
3. Azure Virtual Machines:
    - At least one Virtual Machine to host IBM DB2. For production scenarios, you should consider configuring more than one host and using high availability for the instances. More information on this configuration can be found here:
    - At least one Virtual Machine to host IBM MQ. For production scenarios, you should consider configuring more than one host and using a shared storage location (aka Azure Premium Files) for the queue storage
    - A Jump Box VM: This machine should be deployed and configured with any management tools you'll need to administer your environment.
    - Development VM(s): Machines that can be used be developers for that can connect to any required cluster, data, or queue resources inside the virtual network
5. An Azure Container Registry for storing your custom Sterling OMS containers.

*Note:* Aside from the control and worker subnets, your CIDR ranges are completely up to you and should be sized appropriatley for any additional growth you forsee.

For a more detailed accounting of the suggsted Azure resources, check out this guide and for sample deployment scripts to help you get started, check out the ./azure folder in this repository for some .bicep files you can just to quick start your environment. In addition, for a more detailed explanation of the Azure resources, please review this guide.

### Creating a storage account for required IBM application installers

IBM Sterling Order Management requires a database and MQ instance, and reccomends installing these services *outside* of your OpenShift cluster for scaling and performance purposes. As such, you will need to obtain setup files for each of these applications. You can obtain developer editions of these applications from the following links (IBM registration is required):

* DB2 Commmunity Edition: https://www.ibm.com/products/db2-database/developers
* IBM MQ For Developers: https://developer.ibm.com/articles/mq-downloads/

Alternativly, for testing you can also consider container versions of these applications, but this is NOT reccomended for production or production-like environemnets.

You can also acquire these applications via your Passport Advantage portal (which also should include your applicable licenses): https://www-112.ibm.com/software/howtobuy/passportadvantage/paoreseller/LoginPage?abu=

To make these files available during installation, it is reccomended that you create a seperate storage account and place the compressed archives into a storage container. Once you upload your files to the storage account, you can then install and use [```azcopy```](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10) to copy the archives to your virtual machine(s) and install them as neccessary. The easiest way to do this is to [create a shared access signature (SAS) for the container](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/document-translation/create-sas-tokens?tabs=Containers). Then, from your virtual machines, you can download the files as follows:

```bash
azcopy copy "https://<storage account name with setup archive>.blob.core.windows.net/<storage container name with setup archive>/<name of db2 archive>?<sastoken>" /tmp/db2.tar.gz
azcopy copy "https://<storage account name with setup archive>.blob.core.windows.net/<storage container name with setup archive>/<name of mq archive>?<sastoken>" /tmp/mq.tar.gz
```

## Step 2: Install Azure RedHat Openshift

Once all of the networking requirements are met, you should install Azure RedHat OpenShift. This guide was written and tested with ARO 4.9.9. When configuring ARO, make sure you select the approproate subnets. You can also decide if you want your cluster to be available publically or not (note that if you choose to not make it public, you'll only be able to access the cluster from within the virtual network, from your Jump Box virtual machine). Your deployment may take a few minutes to complete.

You can create a new cluster through the Azure Portal, or from the Azure CLI:

```bash
az aro create --resource-group $RESOURCEGROUP --name $CLUSTER --vnet aro-vnet --master-subnet master-subnet --worker-subnet worker-subnet
```

## Step 3: Accessing your ARO Cluster

After your deployment completes, you can retreive your portal URL and admin credentials by running the following commands:

```bash
az aro show --name <your clustername> --resource-group <your resource group name> --query "consoleProfile.url" -o tsv
az aro list-credentials --name <your clustername> --resource-group <your resource group name>
```

## Step 4: Post Azure Deployment Tasks

Once you have all your resources deployed, you will need to complete the following steps:

### Private VM Outbound Internet Access

If you did not deploy your Azure VMs with a public IP address, and you need to download and install applications like IBM MQ and IBM DB2 from a publicly available source, you may need to add a NAT Gateway to provide outbound connectivity to the internet. Please see this link for more information.

### Install and Configure IBM DB2

After downloading and extracting the required setup files for DB2, install your IBM DB2 instance and make sure you add any required firewall openings on the Virtual Machines. In the config subfolder is a sample DB2 response file you can use to automate the installation.

To use this response file, first you need to add your desired password to the file (this sample file does not contain one). For example, assuming you extracted the DB2 setup files to the /mnt path on your virtual machine, you can do this by running the following commands (replacing ```<your password>``` with your desired admin and fenced user password):

```bash
 wget -nv https://raw.githubusercontent.com/Azure/sterling/main/config/db2/install.rsp -O /mnt/install.rsp
export DBPASSWORD=""
export DBFENCED_PASSWORD=""
envsubst < /mnt/install.rsp >/mnt/install.rsp
sudo /mnt/server_dec/db2setup -r /mnt/install.rsp
```

This will complete the DB2 install. Once the installation completes, you should remove the response file. You should repeat this process for each DB2 instance you plan on creating for high availability.

### Install and Configure IBM MQ:

For performance and high availability, it is reccomended to configure your MQ Queue Manager to use Azure Files Premium NFS shares on your MQ Virtual Machines. To do this, first create a new NFS share on your storage account:

```bash
az storage share-rm create --resource-group <your resource gorup name> --storage-account <premium file storage account name> --name mq --quota 1024 --enabled-protocols NFS --output none
```

Then, on the MQ virtual machine(s), you can mount by running the following commands (as well as seting the default "mqm" user to have permissions on the share):

```bash
sudo mount -t nfs <your storage account name>.file.core.windows.net:/<your storage account name>/mq /MQHA -o vers=4,minorversion=1,sec=sys
sudo chown -R mqm:mqm /MQHA
sudo chmod -R ug+rwx /MQHA
```

Finally, to make sure this mount is persisten through reboots, add the mount information to your ```fstab``` file:

```bash
sudo echo "<your storage account name>prm.file.core.windows.net:/<your storage account name>/mq /MQHA nfs rw,hard,noatime,nolock,vers=4,tcp,_netdev 0 0" >> /etc/fstab
```

### Install Tools and Helm Charts

To enable administration and deployment of Sterling OMS, you should make sure your jump box virtual machine has the follwing tools installed:

First, download and set up the ```oc``` command line too. You can download the OpenShift clients from Red Hat at their mirror. This will provide the oc CLI and also includes kubectl.

💡 TIP: Copy the oc and kubectl client to your /usr/bin directory to access the client from any directory. This will be required for some installing scripts.

Next, install [Helm](https://helm.sh/):

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

Then, install the latest Helm charts for Sterling OMS. For information how to download the approproate chart, see this documentation from IBM: https://www.ibm.com/docs/en/order-management-sw/10.0?topic=container-downloading-helm-charts 


## Step 5: Deploy OMS Prerequisites

### Install Azure Files CSI Driver

Sterling OMS requires some persistent volumes for configuration (certifcates, secrets, etc), customizations (search indexes, etc), and logging. Therefore, it's required that you configure your Azure RedHat OpenShift cluster with the following storage configuration.

Note: You will need to create a Azure Application Registration (service principal) that ARO will use to interact with the storage account, if you have not already. This service principal will need, at a minimum, ```Contributor``` access to your resource group. Once you have created this service principal, you can then create a secret that your cluster will use to interact with provisioning storage accounts and file shares within the resource group.

This repository has scripts that can help you set up these drivers:

```bash
export deployRegion="eastus"
export resourceGroupName="myRG"
export tenantId="tenantId"
export subscriptionId="subscriptionId"
export clientId="clientId" #This account will be used by OCP to access azure files to create shares within Azure Storage.
export clientSecret="clientSecret"

#Configure Azure Files Standard
wget -nv https://raw.githubusercontent.com/Azure/maximo/$branchName/src/storageclasses/azurefiles-standard.yaml -O azurefiles-standard.yaml
envsubst < azurefiles-standard.yaml > azurefiles-standard.yaml
oc apply -f azurefiles-standard.yaml
```

### Create OMS Namespace

You will need to create the namespace used for your OMS deployment:

```bash
oc create namespace <your namespace name>
```

### Add Azure Container Registry Credentials to Namespace Docker Credential Secret

TODO

### Create OMS Secret

OMS Requires that a secret be created that contains relevant credentials for your database, your trust keystores, etc. A sample configuration file can be found in this repository under ./config/oms and can be modified to suit your needs (just supple the appropriate credentails to each variable):

```bash
export NAMESPACE=""
export CONSOLEADMINPW=""
export CONSOLENONADMINPW=""
export DBPASSWORD=""
export TLSSTOREPW=""
export TRUSTSTOREPW=""
export KEYSTOREPW=""
wget -nv https://raw.githubusercontent.com/Azure/sterling/main/config/oms-secret.yaml -O oms-secret.yaml
envsubst < oms-secret.yaml > oms-secret.yaml
oc create -f oms-secret.yaml
```

### Create Required PVC(s)

Your OMS pods will require a persistent storage layer for logging, and any additional components or customizations for your deployment. While these volumes *can* be created at deployment time via the Helm charts or Operator, IBM reccomeneds you provision these prior to your deployment. As such, you should think about creating one (or more) PVCs as needed.

A sample PVC template is provided as part of this repository, and will use the Azure Files Standard storage class that was created earlier:

```bash
#Assumes you use the same storage class name from before; change as needed
export STORAGECLASSNAME="azurefiles-standard"
export SIZEINGB="10"
wget -nv https://raw.githubusercontent.com/Azure/sterling/main/config/oms-pvc.yaml -O oms-pvc.yaml
envsubst < oms-pvc.yaml > oms-pvc.yaml
oc create -f oms-pvc.yaml
```

### Create RBAC Role

```bash
export NAMESPACE=""
wget -nv https://raw.githubusercontent.com/Azure/sterling/main/config/oms-rbac.yaml -O oms-rbac.yaml
envsubst < oms-rbac.yaml > oms-rbac.yaml
oc create -f oms-rbac.yaml
```

### Set up development VM(s)

TODO


## Step 6: Deploying OMS

TODO

### Pushing your containers to your Azure Container Registry

TODO

### SSL Connections and Keystore Configuration

TODO

### Deploying OMS Via Helm Charts

TODO

### Deploying OMS Via the OpenShift Operator

TODO

## Step 7: Post Deployment Tasks

TODO

### Licensing your DB2 and MQ Instances

TODO

### Migrating Your Data

TODO

### Other Best Practices and Considerations

TODO

## Deploying OMS

TODO

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
