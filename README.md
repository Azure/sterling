# QuickStart Guide: Sterling Order Management on Azure

This repository provides deployument guidance and best practices for running IBM Sterling Order management (OMS) on Azure Redhat OpenShift (ARO) in the Azure public cloud. This guide was written and tested with Azure RedHat OpenShift 4.9.9 and OMS Version X.XX

> 🚧 **NOTE**: The scripts contained within this repo were written with the intention of testing various configurations and integrations on Azure. They allow you to quickly deploy the required infrastructure on Azure so that you migrate an existing OMS to Azure, or start fresh with new development.

> 🚧 **WARNING** this guide is currently under active development. If you would like to contribute or use this right now, please reach out so we can support you.

> 🐧 **bash ahead!** Most, if not all, of the example scripts in this repository were written to executed in a bash scripting environment on Linux. Consider using a Linux virtual machine, or [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install) to work with these examples.

## Table of Contents:

- [QuickStart Guide: Sterling Order Management on Azure](#quickstart-guide-sterling-order-management-on-azure)
  - [Table of Contents:](#table-of-contents)
  - [What's in this repository?](#whats-in-this-repository)
  - [Overview](#overview)
  - [Before You Begin](#before-you-begin)
  - [Step 1: Preparing Your Azure Environment](#step-1-preparing-your-azure-environment)
    - [Creating an Azure Application Registration](#creating-an-azure-application-registration)
    - [Creating a storage account for required IBM application installers](#creating-a-storage-account-for-required-ibm-application-installers)
  - [Step 2: Install Azure RedHat Openshift](#step-2-install-azure-redhat-openshift)
  - [Step 3: Accessing your ARO Cluster](#step-3-accessing-your-aro-cluster)
  - [Step 4: Post ARO Deployment Tasks](#step-4-post-azure-redhat-openshift-deployment-tasks)
    - [Private VM Outbound Internet Access](#private-vm-outbound-internet-access)
    - [Install and Configure IBM DB2 (if applicable)](#install-and-configure-ibm-db2-if-applicable)
    - [Install and Configure IBM MQ (if applicable)](#install-and-configure-ibm-mq-if-applicable)
    - [Install Tools](#install-tools)
  - [Step 5: Logging into your OpenShift Cluster with the OpenShift Command Line Tool](#step-5-logging-into-your-openshift-cluster-with-the-openshift-command-line-tool)
  - [Step 6: Deploy OMS Prerequisites & Artifacts](#step-6-deploy-oms-prerequisites--artifacts)
    - [Create OMS Namespace](#create-oms-namespace)
    - [Install Azure Files CSI Driver](#install-azure-files-csi-driver)
    - [Add Azure Container Registry Credentials to Namespace Docker Credential Secret](#add-azure-container-registry-credentials-to-namespace-docker-credential-secret)
    - [Install IBM Operator Catalog and the Sterling Operator](#install-ibm-operator-catalog-and-the-sterling-operator)
    - [Create OMS Secret](#create-oms-secret)
    - [Create Required PVC(s)](#create-required-pvcs)
    - [Create RBAC Role](#create-rbac-role)
    - [Update Container Pull Secret(s) for your Azure Container Registry](#update-container-pull-secrets-for-your-azure-container-registry)
    - [SSL Connections and Keystore Configuration](#ssl-connections-and-keystoretruststore-configuration)
  - [Step 7: Deploying OMS](#step-7-deploying-oms)
  - [Step 8: Post Deployment Tasks](#step-8-post-deployment-tasks)
    - [Licensing your DB2 and MQ Instances](#licensing-your-db2-and-mq-instances)
    - [Migrating Your Data](#migrating-your-data)
  - [Contributing](#contributing)
  - [Trademarks](#trademarks)

## What's in this repository?

This repository serves two purposes: first, it is designed to give you an idea of what sort of architecture you can consider deploying into your Azure subscription to support 
running your Sterling Order Management workload(s) as well as best practice considerations for scale, performance, and security.

Secondly, there are a series of sample deployment templates and configuration scripts designed to get you up and running with an environment ready for you to deploy your existing Sterling OMS resources into. These resources are broken out into the following directories within this repository:

- ./azure - Contains a series of .bicep files that can be used to bootstrap a reference deployment of all the required Azure resources for your deployment
- ./config - Contains files used by the installer examples or Azure automation scripts to configure services or other requirements of the platform

If you are interested in a bootstrap environment to deploy Sterling OMS into, please see this README that explains more: [Sterling Azure Bootstrap Resources](./azure/README.md)

## Overview

This repository is designed to help you plan your Sterling Order Management deployment on Microsoft Azure with a configuration similar to the below diagram:

![A Sample OMS Networking/Resource Diagram](/docs/images/SterlingNetworkDiagram.png)

To get started, you'll need to accomplish the following tasks:

1. Preparing and configuring your Azure environment for an Azure Redhat OpenShift deployment
2. Deploy all the required Azure resources (including Azure Redhat OpenShift)
3. Install and configure your message queue system as well as your backend database instance(s) (see below)
4. Configure Azure RedHat OpenShift, including:
   1. Required storage drivers
   2. Azure Container Registry Docker Secrets
   3. Create a secret for your IBM Entitlement Key / Pull Secret
5. Set your required OpenShift artifacts, such as your target namespace and any required secrets and persistent volumes
6. Configure the IBM OpenShift operator catalog, and install the Sterling OMS Operator on your cluster
7. Push your OMS containers to your Azure Container Registry
8. Deploy OMS via the Operator

## Before You Begin

To successfully install and configure OMS on Azure, you'll need to make sure you have all of the following requirements (or a plan for them):

* An active Azure subscription
 * A quota of at least 40 vCPU allowed for your VM type(s) of choice. Request a quota increase if needed.
 * You will need subscription owner permissions for the deployment.
* You will need to deploy a backend database as part of your environment. Depending on your chosen platform, you currently have the following options:
  * For IBM DB2:
    * You can obtain a licensed copy of DB2 from the IBM Passport Advantage Website: https://www-112.ibm.com/software/howtobuy/passportadvantage/paoreseller/LoginPage?abu=
    * IBM also offers a community edition of DB2 for testing and development purposes: https://www.ibm.com/products/db2-database/developers
    * You can place this installation media on an Azure Storage Account and download the images to your Virtual Machines to install the software
  * For Oracle:
    * IBM Provides guidance around configuring Oracle for Sterling OMS: https://www.ibm.com/products/db2-database/developers
    * The images provided for OMS do not include Oracle drivers; your images will need updated with these drivers. For more information, see this support document: 
  * For PostgreSQL (Preview):
    * IBM has preview support for PostgreSQL. As such, you can deploy Azure PostgreSQL Database Flexible Server or Hyperscale (Citus) in your Azure subscription.
* The Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

Once you have access to your Azure subscription, you'll then need to set up an Application Registration (SPN) that has contributor access to the subscription you are are going to deploy to.

Finally, for managing and configuring Azure Redhat OpenShift, you'll also need the ```oc``` CLI tool. [You can download this tool from Red Hat at their official download site](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/). You should also download and install the Azure CLI.


## Step 1: Preparing Your Azure Environment

At a minimum, your Azure environment should contain a resource group that contains the following resources:

1. A Virtual Network: This virtual network will host the following subnets (with recommended CIDR ranges*):
    - control (/24): the control subnet is used by Azure RedHat OpenShift control nodes.
    - worker (/24): the worker subnet is used by Azure RedHat OpenShift worker nodes.
    - data (/27): this delegated subnet can be used for PostgreSQL (if needed)
    - vms (/27): this subnet holds the virtual machines running services on IaaS virtual machines, such as IBM DB2 and IBM MQ servers.
    - management (/30): this subnet is used for your "Jump Box" virtual machine(s) that can be used to securely connect to all other resources inside this network
    - development (/28): this subnet can be used to deploy developer virtual machines, if needed, to develop, test, and deploy OMS customized container images securely to the Azure Container Registry.
    - endpoints (/25): this subnet exists for hosting private endpoints for Azure services such as storage accounts, container registries, and other services to provide private connectivity.
2. Azure Premium Files storage account: For hosting MQ Queue Manager data
3. Azure Virtual Machines:
    - (If needed) At least one Virtual Machine to host IBM DB2. For production scenarios, you should consider configuring more than one host and using high availability for the instances. More information on this configuration can be found here:
    - (If needed) At least one Virtual Machine to host IBM MQ. For production scenarios, you should consider configuring more than one host and using a shared storage location (aka Azure Premium Files) for the queue storage
    - A Jump Box VM: This machine should be deployed and configured with any management tools you'll need to administer your environment.
    - Development VM(s): Machines that can be used be developers for that can connect to any required cluster, data, or queue resources inside the virtual network
4. An Azure Container Registry for storing your custom Sterling OMS containers.

*Note:* Aside from the control and worker subnets, your CIDR ranges are completely up to you and should be sized appropriately for any additional growth you forsee.

For a more detailed accounting of the suggested Azure resources, check out this guide and for sample deployment scripts to help you get started, check out the ./azure folder in this repository for some .bicep files you can just to quick start your environment. In addition, for a more detailed explanation of the Azure resources, please review this guide.

### Creating an Azure Application Registration

You will need to [create an Azure Application Registration (SPN)](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal) and grant it `Contributor` permissions on the subscription you plan to deploy into. If granting permissions at the subscription level is not possible, you can also configure the permissions on this resource group instead. have issue with state when attempting to use a single resource group.

After creating the SPN and assigning its access, you will need to create a [secret](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#option-2-create-a-new-application-secret) that will be used during the OCP install process.

More details on [creating a service principal for Azure Redhat OpenShift can be found here](https://docs.microsoft.com/en-us/azure/openshift/howto-create-service-principal?pivots=aro-azurecli)

### Creating a storage account for required IBM application installers

IBM Sterling Order Management requires a database and MQ instance, and reccomends installing these services *outside* of your OpenShift cluster for scaling and performance purposes. As such, you will need to obtain setup files for each of these applications. You can obtain developer editions of these applications from the following links (IBM registration is required):

* DB2 Community Edition: https://www.ibm.com/products/db2-database/developers
* IBM MQ For Developers: https://developer.ibm.com/articles/mq-downloads/

Alternatively, for testing you can also consider container versions of these applications, but this is NOT recommended for production or production-like environments.

You can also acquire these applications via your Passport Advantage portal (which also should include your applicable licenses): https://www-112.ibm.com/software/howtobuy/passportadvantage/paoreseller/LoginPage?abu=

To make these files available during installation, it is recommended that you create a separate storage account and place the compressed archives into a storage container. Once you upload your files to the storage account, you can then install and use [```azcopy```](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10) to copy the archives to your virtual machine(s) and install them as necessary. The easiest way to do this is to [create a shared access signature (SAS) for the container](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/document-translation/create-sas-tokens?tabs=Containers). Then, from your virtual machines, you can download the files as follows:

```bash
azcopy copy "https://<storage account name with setup archive>.blob.core.windows.net/<storage container name with setup archive>/<name of db2 archive>?<sastoken>" /tmp/db2.tar.gz
azcopy copy "https://<storage account name with setup archive>.blob.core.windows.net/<storage container name with setup archive>/<name of mq archive>?<sastoken>" /tmp/mq.tar.gz
```

## Step 2: Install Azure RedHat Openshift

Once all of the networking requirements are met, you should install Azure RedHat OpenShift. This guide was written and tested with ARO 4.9.9. When configuring ARO, make sure you select the appropriate subnets. You can also decide if you want your cluster to be available publicly or not (note that if you choose to not make it public, you'll only be able to access the cluster from within the virtual network, from your Jump Box virtual machine). Your deployment may take a few minutes to complete.

You can create a new cluster through the Azure Portal, or from the Azure CLI:

```bash
az aro create --resource-group $RESOURCEGROUP --name $CLUSTER --vnet aro-vnet --master-subnet master-subnet --worker-subnet worker-subnet --client-id <your application client ID> --client-secret <your generated secret>
```

## Step 3: Accessing your ARO Cluster

After your deployment completes, you can retrieve your portal URL and admin credentials by running the following commands:

```bash
az aro show --name <your clustername> --resource-group <your resource group name> --query "consoleProfile.url" -o tsv
az aro list-credentials --name <your clustername> --resource-group <your resource group name>
```

## Step 4: Post Azure Redhat Openshift Deployment Tasks

Once you have all your resources deployed, you will need to complete the following steps:

### Private VM Outbound Internet Access

If you did not deploy your Azure VMs with a public IP address, and you need to download and install applications like IBM MQ and IBM DB2 from a publicly available source, you may need to add a NAT Gateway to provide outbound connectivity to the internet. Please see this link for more information: https://docs.microsoft.com/en-us/azure/virtual-network/nat-gateway/nat-gateway-resource

### Install and Configure IBM DB2 (if applicable)

After downloading and extracting the required setup files for DB2, install your IBM DB2 instance and make sure you add any required firewall openings on the Virtual Machines. In the config subfolder is a sample DB2 response file you can use to automate the installation.

To use this response file, first you need to add your desired password to the file (this sample file does not contain one). For example, assuming you extracted the DB2 setup files to the /mnt path on your virtual machine, you can do this by running the following commands (and supplying your DBPASSWORD and DBFENCED_PASSWORD as environment variables for substitution):

```bash
wget -nv https://raw.githubusercontent.com/Azure/sterling/main/config/db2/install.rsp -O /mnt/install.rsp
export DBPASSWORD=""
export DBFENCED_PASSWORD=""
envsubst < /mnt/install.rsp >/mnt/install.rsp
sudo /mnt/server_dec/db2setup -r /mnt/install.rsp
```

This will complete the DB2 install. Once the installation completes, you should remove the response file. You should repeat this process for each DB2 instance you plan on creating for high availability. This will require you to install the required Pacemaker components for DB2:

```bash
#Your DB2 Installer media should have come with local Pacemaker installer files. These files and setup are IBM's own approved installation
#More information, including how to complete this setup, can be found here: https://www.ibm.com/docs/en/db2/11.5?topic=feature-integrated-solution-using-pacemaker
cd /<install location>/db2/linuxamd64/pcmk
sudo ./db2installPCMK -i
cd /var/ibm/db2/V11.5/install/pcmk
sudo sudo ./db2cppcmk -i
```

For more information, please refer to this documentation about building a highly-available DB2 instance in Azure: https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/sap/high-availability-guide-rhel-ibm-db2-luw

### Install and Configure IBM MQ (if applicable)

For performance and high availability, it is recommended to configure your MQ Queue Manager to use Azure Files Premium NFS shares on your MQ Virtual Machines. To do this, first create a new NFS share on your storage account:

```bash
az storage share-rm create --resource-group <your resource group name> --storage-account <premium file storage account name> --name mq --quota 1024 --enabled-protocols NFS --output none
```

Then, on the MQ virtual machine(s), you can mount by running the following commands (as well as setting the default "mqm" user to have permissions on the share):

```bash
sudo mount -t nfs <your storage account name>.file.core.windows.net:/<your storage account name>/mq /MQHA -o vers=4,minorversion=1,sec=sys
sudo chown -R mqm:mqm /MQHA
sudo chmod -R ug+rwx /MQHA
```

Finally, to make sure this mount is persisted through reboots, add the mount information to your ```fstab``` file:

```bash
sudo echo "<your storage account name>prm.file.core.windows.net:/<your storage account name>/mq /MQHA nfs rw,hard,noatime,nolock,vers=4,tcp,_netdev 0 0" >> /etc/fstab
```

You can now create your queue managers and use this new, mounted storage as your queue storage location. Once your queues are created, you will need to capture your JMS ```.bindings``` file (which is needed by OMS). Copy this file to a location (or host) that is capable of using the ```oc``` command, and see the below section about creating your config map for your MQ bindings in the section [Creating MQ Bindings Config Map](#create-mq-bindings-config-map), below.

### Install Tools

To enable administration and deployment of Sterling OMS, you should make sure your jump box virtual machine has the following tools installed:

First, download and set up the ```oc``` command line too. You can download the OpenShift clients from Red Hat at their mirror. This will provide the oc CLI and also includes kubectl

```bash
mkdir /tmp/OCPInstall
wget -nv "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz" -O /tmp/OCPInstall/openshift-client-linux.tar.gz
tar xvf /tmp/OCPInstall/openshift-client-linux.tar.gz -C /tmp/OCPInstall
sudo cp /tmp/OCPInstall/oc /usr/bin
```

💡 TIP: Copy the oc and kubectl client to your /usr/bin directory to access the client from any directory. This will be required for some installing scripts.

## Step 5: Logging into your OpenShift Cluster with the OpenShift Command Line Tool

To use the command line tools, you'll need to log in to your cluster. You will need two pieces of information:

* Cluster API Server URL
  * To obtain the cluster API URL, you'll first need to log in with the Azure CLI:
    * ```az login```
    * Next, you'll need to set your active subscription to wherever your deployed your cluster: ```az account set --subscription "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"```
    * Finally, if you run the following command, you should get your API server (without the https://, which is not required for the login): ```az aro show -g <resource group name> -n <aro cluster name> --query apiserverProfile.url -o tsv | sed -e 's#^https://##; s#/##'```
* Default username and password
  * To get the default credentials for your cluster, run the following command: ```az aro list-credentials -g <resource group name> -n <aro cluster name>```

Once you have the API URL and default credentials, you can log in via ```oc```:

```bash
oc login <api server url> -u kubeadmin -p <password from az aro list-credentials>
```

If you receive any errors with those commands, verify that you successfully logged in with the Azure CLI, and that you are in the right subscription. Verify your resource group name and your ARO cluster name.

## Step 6: Deploy OMS Prerequisites & Artifacts

### Create OMS Namespace

You will need to create the namespace used for your OMS deployment:

```bash
export OMS_NAMESPACE="OMS"
oc create namespace $OMS_NAMESPACE
```

Note: The rest of this guide assumes the namespace in use is 'OMS', but you can adjust accordingly

### Install Azure Files CSI Driver

Sterling OMS requires some persistent volumes for configuration (certificates, secrets, etc), customizations (search indexes, etc), and logging. Therefore, it's required that you configure your Azure RedHat OpenShift cluster with the following storage configuration.

Note: You will need to [create a Azure Application Registration (service principal) that ARO will use](#creating-an-azure-application-registration) to interact with the storage account, if you have not already. This service principal will need, at a minimum, ```Contributor``` access to your resource group. Once you have created this service principal, you can then create a secret that your cluster will use to interact with provisioning storage accounts and file shares within the resource group.

This repository has scripts that can help you set up these drivers:

```bash
export deployRegion="eastus"
export resourceGroupName="myRG"
export tenantId="tenantId"
export subscriptionId="subscriptionId"
export clientId="clientId"
export clientSecret="clientSecret"

wget -nv https://raw.githubusercontent.com/Azure/sterling/main/config/azure-file-storage/configure-azurefiles-driver.sh -O /tmp/configure-azurefiles-driver.sh
chmod u+x /tmp/configure-azurefiles-driver.sh
/tmp/configure-azurefiles-driver.sh
```

For more detailed information on deploying Azure Files Storage Drivers to OpenShift, you can find more documentation here: 

### Add Azure Container Registry Credentials to Namespace Docker Credential Secret

To take advantage of your secure Azure Container Registry, you will need to provide a Docker pull secret for the repository. The most straightforward way to accomplish this is with your registry's access keys. You can use the Azure CLI to get your credentials, and then deploy the secret.

```bash
export ACR_NAME=<your azure container registry name>
export RESOURCE_GROUP_NAME=<your resource group name>
export ACR_LOGIN_SERVER=$(az acr show -n $ACR_NAME -g $RESOURCE_GROUP_NAME | jq -r .loginServer)
export ACR_PASSWORD=$(az acr credential show -n $ACR_NAME -g $RESOURCE_GROUP_NAME | jq -r '.passwords[0].value')
wget -nv https://raw.githubusercontent.com/Azure/sterling/main/config/oms/oms-pullsecret.json -O /tmp/oms-pullsecret.json
envsubst < /tmp/oms-pullsecret.json > /tmp/oms-pullsecret-updated.json
oc create secret generic $ACR_NAME-dockercfg --from-file=.dockercfg=/tmp/oms-pullsecret-updated.json --type=kubernetes.io/dockercfg
```

### Install IBM Operator Catalog and the Sterling Operator

As part of the environment preparation, the OMS Operator should show up under the OperatorHub inside of OpenShift. You can either manually install the operator from the GUI, or you can use the provided scripts to install the operator. Note: If using the scripts, be mindful of the version you're deploying. You need to set your OMS version, operator version name, and operator current CSV:

```bash
#Note: This example is for the PROFESSIONAL version of the OMS Operator
export OMS_VERSION="icr.io/cpopen/ibm-oms-pro-case-catalog:v1.0"
export OMS_NAMESPACE="OMS"
export OPERATOR_NAME="ibm-oms-pro"
export OPERATOR_CSV="ibm-oms-pro.v1.0.0"
wget -nv https://raw.githubusercontent.com/Azure/sterling/main/config/operators/install-oms-operator.yaml -O /tmp/install-oms-operator.yaml
envsubst < /tmp/install-oms-operator.yaml > /tmp/install-oms-operator-updated.yaml
oc apply -f /tmp/install-oms-operator-updated.yaml
```

For more information about installing the operator from the command line, please see this link: https://www.ibm.com/docs/en/order-management-sw/10.0?topic=operator-installing-updating-order-management-software-online

### Create OMS Secret

OMS Requires that a secret be created that contains relevant credentials for your database, your trust keystores, etc. A sample configuration file can be found in this repository under ./config/oms and can be modified to suit your needs (just supple the appropriate credentials to each variable):

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

### Create MQ Bindings ConfigMap

Users of IBM MQ for their messaging platform will need to create a configuration map in their OMS namespace that contains queue binding information. After you have configured your queue managers and created your JMS bindings, you need to obtain a copy of your ```.bindings``` file. Next, you'll create your configuration map with the following command:

```bash
export OMS_NAMESPACE="OMS"
oc create configmap oms-bindings --from-file=.bindings -n $OMS_NAMESPACE
```

Note: the file name is important, and should be named ```.bindings```!

This configmap will be referenced when your deploy OMS through the operator.

### Create Required PVC(s)

Your OMS pods will require a persistent storage layer for logging, and any additional components or customizations for your deployment. While these volumes *can* be created at deployment time via the Helm charts or Operator, IBM recommends you provision these prior to your deployment. As such, you should think about creating one (or more) PVCs as needed.

A sample PVC template is provided as part of this repository, and will use the Azure Files Standard storage class that was created earlier:

```bash
#Assumes you use the same storage class name from before; change as needed
export STORAGECLASSNAME="azurefiles-standard"
export SIZEINGB="20"
wget -nv https://raw.githubusercontent.com/Azure/sterling/main/config/oms-pvc.yaml -O oms-pvc.yaml
envsubst < oms-pvc.yaml > oms-pvc-updated.yaml
oc create -f oms-pvc-updated.yaml
```

Once this PVC is created, this share will be used by your deployment of your OMEnvironment, and you can stage files to this share via the Azure CLI or Azure Storage Explorer (for example, your keystore and truststore, see below)

### Create RBAC Role

There is a specialized RBAC role required for Sterling OMS. To deploy it, you can run the following commands:

```bash
export NAMESPACE="OMS"
wget -nv https://raw.githubusercontent.com/Azure/sterling/main/config/oms-rbac.yaml -O oms-rbac.yaml
envsubst < oms-rbac.yaml > oms-rbac-updated.yaml
oc create -f oms-rbac-updated.yaml
```

### Pushing your containers to your Azure Container Registry

TODO

### SSL Connections and Keystore/Truststore Configuration

To use SSL/TLS connections for both your user-facing applications and any required SSL communications, such as to your database, you will need to provide a keystore and truststore in PKCS12 format. These stores should then be placed onto the persistent volumes you created above. You can use OpenSSL to create these stores. 

While planning your SSL/TLS certificates and keys is a topic outside the scope of this document, you will need your keys to properly generate a PKCS12 format keystore.

To create a new self-signed certificate, key and trust store, you can execute the following commands; in your production environment this is not advised. This is only provided as an example:

```bash
#You will need access to your key that signed your certificate
#To create a self-signed certificate and key file, you can use the following command:
openssl req -newkey rsa:4096 -x509 -days 3650 -nodes -out selfsigned.crt -keyout self.key
#Once you have your key and certificate, combine the private and public key into one file
cat self.key selfsigned.crt > selfkeycert.txt
#You will be prompted for a keystore password; you should use the same value you used to create your OMS secret (KEYSTOREPW)
openssl pkcs12 -export -in selfkeycert.txt -out mykeystore.pkcs12 -name myKeystore -noiter -nomaciter
#Finally, create your truststore by importing your certificate(s) into a new file
keytool -import -file selfsigned.crt -alias selfsigned -keystore myTrustStore
```

Once you have your key and trust stores, you should copy them to the relevant locations on any of the persistent volumes that you created above for your deployment. For more information, please see this documentation: https://www.ibm.com/docs/en/control-center/5.4.2?topic=connections-configuring-keystore-truststore-files

## Step 7: Deploying OMS

Once you have your Azure environment built, you are now prepared to deploy your OMEnvironment using the IBM Sterling Order Management Operator. You'll first install the operator from the IBM Catalog, then use the operator to deploy your OMEnvironment.

## Deploying OMS Via the OpenShift Operator

Once the operator is deployed, you can now deploy your OMEnvironment provided you have met all the pre-requisites. For more information about the installation process and available options (as well as sample configuration files) please visit: https://www.ibm.com/docs/en/order-management-sw/10.0?topic=operator-installing-order-management-software-by-using

## Step 8: Post Deployment Tasks

Once your environment is set up and configured, please consider the following steps to complete your installation.

### Licensing your DB2 and MQ Instances

Post-installation, if you have not already (and you're using IBM DB2 and/or IBM MQ), please obtain your license files for DB2 and MQ and apply the licenses as specified by IBM in their documentation:

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
