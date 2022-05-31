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

./azure - Contains a series of .bicep files that can be used to boostrap a reference deployment of all the required Azure resources for your deployment
./installers - Contains scripting examples for automating the installation of applications like IBM MQ, IBM DB2, the OpenShift CLI Tool (oc), etc
./config - Contains files used by the installer examples or Azure automation scripts to configure services
./examples - Contains example files as references for your deployments, such as a sample OMS secrets file 

## Overview of Deployment

## Before You Begin

## Step 1: Preparing Your Azure Environment

## Step 2: Install Azure RedHat Openshift & Required Infrastructure

## Acessing your ARO Cluster

### As an Administrator

### As a Developer

### Post-Installation Considerations

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
