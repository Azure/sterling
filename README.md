# QuickStart Guide: Sterling Order Management on Azure

This repository provides deployument guidance and best practices for running IBM Sterling Order management (OMS) on Azure Redhat OpenShift (ARO) in the Azure public cloud. This guide was written and tested with Azure RedHat OpenShift 4.9.9 and OMS Version X.XX

> 🚧 **NOTE**: The scripts contained within this repo were written with the intention of testing various configurations and integrations on Azure. They allow you to quickly deploy the required infrastructure on Azure so that you migrate an existing OMS to Azure, or start fresh with new development.

> 🚧 **WARNING** this guide is currently under active development. If you would like to contribute or use this right now, please reach out so we can support you.

## Table of Contents:

- What's in this repository?
- Overview of Deployment
- Before You Begin
- Step 1: Preparing your Azure Environment
- Step 2: Install Azure Redhat OpenShift & Required Infastructure
  - Required Components
- Accessing your Cluster...
  - As an Adminstrator
  - As a Developer
- Post-Installation Considerations
  - Creating an OMS Namespace for your application
  - Authorizing your OMS Namespace to your Azure Container Registry
  - Pushing your containers to your Azure Container Registry
  - Creating required secrets
  - Configuring your Cluster's Storage Drivers for Azure File Shares
  - Licensing your DB2 and MQ Instances
  - SSL Connections and Keystore Configuration(s)


## What's in this repository?

- ./azure - Contains a series of .bicep files that can be used to boostrap a reference deployment of all the required Azure resources for your deployment
- ./installers - Contains scripting examples for automating the installation of applications like IBM MQ, IBM DB2, the OpenShift CLI Tool (oc), etc
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
* Access to license files for IBM DB2 and IBM MQ
* *TODO: Sterling OMS Licensing Information?*

Once you have access to your Azure subscription, you'll then need to set up an Application Registration (SPN) that has contributor access to the subscription you are are going to deploy to.

Finally, for managing and configuring Azure Redhat OpenShift, you'll also need the ```oc``` CLI tool. [You can download this tool from Red Hat at their official download site](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/). You should also download and install the Azure CLI.

## Step 1: Preparing Your Azure Environment

At a minimum, your Azure environment should contain the following a resource group that contains the following resources:

1. A Virtual Network: This virtual network will host the following subnets:
  * control: the control subnet is used by Azure RedHat OpenShift control nodes.
  * worker: the worker subnet is used by Azure RedHat OpenShift worker nodes.
  * data: this subnet holds the virtual machines running services related to data, such as IBM DB2 Virtual Machines and IBM MQ servers.
  * management: this subnet is used for your "Jump Box" virtual machine(s) that can be used to securely connect to all other resources inside this network
  * development: this subnet can be used to deploy developer virtual machines, if needed, to develop, test, and deploy OMS customized container images securely to the Azure Container Registry.
  * endpoints: this subnet exists for hosting private endpoints for Azure services such as storage accounts, container registries, and other services to provide private connectivity.
2. Azure Premium Files storage account: For hosting MQ Queue Manager data
3. Azure Virtual Machines:
    * At least one Virtual Machine to host IBM DB2. For production scenarios, you should consider configuring more than one host and using high availability for the instances. More information on this configuration can be found here:
    * At least one Virtual Machine to host IBM MQ. For production scenarios, you should consider configuring more than one host and using a shared storage location (aka Azure Premium Files) for the queue storage
4. A Jump Box VM: This machine should be deployed and configured with any management tools you'll need to administer your environment.
5. An Azure Container Registry for storing your custom Sterling OMS containers.

For a more detailed accounting of the suggsted Azure resources, check out this guide and for sample deployment scripts to help you get started, check out the ./azure folder in this repository for some .bicep files you can just to quick start your environment. In addition, for a more detailed explanation of the Azure resources, please review this guide.

## Step 2: Install Azure RedHat Openshift & Required Infrastructure

Once all of the networking requirements are met, you should install Azure RedHat OpenShift. This guide was written and tested with ARO 4.9.9. When configuring ARO, make sure you select the approproate subnets. You can also decide if you want your cluster to be available publically or not (note that if you choose to not make it public, you'll only be able to access the cluster from within the virtual network, from your Jump Box virtual machine). Your deployment may take a few minutes to complete.

## Acessing your ARO Cluster

After your deployment completes, you can retreive your portal URL and admin credentials by running the following commands:

```
az aro show --name <your clustername> --resource-group <your resource group name> --query "consoleProfile.url" -o tsv
az aro list-credentials --name <your clustername> --resource-group <your resource group name>
```

## Post-Azure Configuration Considerations:

## Deploying OMS

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
