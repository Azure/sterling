# IBM MQ - Azure Kubernetes Service Deployment Examaple

IBM Sterling Order Management (OMS) has a requirement for a JMS-compliant messaging system, and may customers opt to use IBM MQ as their backend messaging system. While there are many ways to run IBM MQ workloads in Azure, one appealing and highly-available way is to use Azure Kubernetes Service (AKS) to host your MQ instances. IBM has a Helm chart that enables HA-native deployments of IBM MQ, from which this sample draws: https://github.com/ibm-messaging/mq-helm

IBM MQ on AKS, backed with Azure Premium Files storage, provides a highly-scalble and resliant solution for your MQ workloads. While you can also opt to run IBM MQ in your OpenShift cluster, if there is a desire or need to run your workloads OUTSIDE of your OpenShift cluster, you may want to consider this option.

## Notice: Production Readiness

Please note: The example configuration and setup script in this repository is meant to illustrate and help you deploy your first IBM MQ AKS deployment. There are many other options that goes into planning your production deployment, 

## Azure Kubernetes Service (AKS) HA Cluster Example

### Requirements

To function correctly. your existing Azure deployment should contain the following:

* An AKS Cluster, sized appropriately. Pay special attention to VM sizes for your agent pools.
* An appropriately sized virtual network address space and subnet for your cluster nodes
* Kubernetes Command Line Tools (kubectl) with Helm 3 installed
* Azure CLI: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli

*Note* If you previously deployed the Sterling OMS deployment from this repository, you should already have all of these requirements/tools installed and available.

### Pre-Deployment Steps

Before you begin, you should make sure your target virtual network and subnet are sized approproately for your cluster. Microsoft has very specific and targeted guidance around properly sizing your network depending on which CNI provider you want to use with your cluster: 

 * kubenet: https://learn.microsoft.com/en-us/azure/aks/configure-kubenet
 * Azure CNI: https://learn.microsoft.com/en-us/azure/aks/configure-azure-cni

Once you have your address space and/or subnet configured you can proceed. The included sample deployment uses Azure CNI to help integrate your cluster into your existing infrastructure. In addition, the provided sample deployment also uses a private cluster configuration, meaning your API server will NOT be accessible publically, and only from sources with "visibility" to your virtual network.

### Deploy AKS

To deploy your cluster, you can either do so through the Azure Portal, or use the provided sample bicep file to quickly stand up your cluster. The provided bicep and parameters file contains everything you should need to get started, but you can certainly customize the template for your needs (such as initial node pool sizes, VM sizes, etc).

To deploy the provided example, simply use the Azure CLI's ```az deploy``` command:

```bash
az deployment group create --resource-group <resource group name> --name MQAKS --template-file ./aks-mq.bicep
```

You will be prompted for values for things like the cluter name, location, and more. When the deployment finishes, you can get the cluster credentials added to your local ```.kubecfg``` by using the following commands:

```bash
az aks get-credentials --resource-group <resource group name> --name <cluster name>
```

### Enable Cluster Managed Identity

Next, you need to make sure your recently-deployed AKS cluster has an identity assigned to it. Most often, this is a managed system identity, but you can use your own identity if you prefer. First, check to see if the cluster has an ID assigned:

```bash
az ad sp list --display-name <cluster name> -o json | jq '.[] | select(.displayName==<cluster name>) | .objectId'
```
If nothing comes back you can run the following command to assign one:

```bash

```
You will need the ObjectID of that identity for the next step of the process. More details about this process (including using your own identity) can be found here: https://learn.microsoft.com/en-us/azure/aks/use-managed-identity

### Grant Cluster Identity Permissions to Network Resource Group

For AKS to successfully manage and connect to your storage resources, the managed identity of your cluster control plane needs 'contributor' access to the resource group that contains the virtual network you connceted the cluster to. You can assign this permission by running the following command:

```bash
az role assignment create --assignee "<managed identity object ID>" --role "Contribtor" --scope "/subscriptions/<subscriptionId>/resourcegroups/<resourceGroupName>"
```

### Create NFS Storage Class

For persistent storage, IBM MQ requires NFS-backed shared storage. For this reason, it is reccomended to use Azure Premium File storage with NFS shares in your cluster. To enable this, you must first create an NFS storage class using the ```file.csi.azure.com``` provisioner. A sample .yaml file is available in this repository (```azurefile-premium-nfs-storagecass.yaml```) to help you.

```bash
kubectl apply -f ./azurefile-premium-nfs-storagecass.yaml
```

### Create Config Maps / Secrets

Before you deploy your helm chart, you can should specify and MQSC commands you want to run as part of your deployment. This will autoamtically take care of things like creating your queues and channels at the time of your deployment versus having to do this manually post-deployment. The ```mq-mqsc.yaml``` file contains a sample configmap that contains these commands. You should replace the commands in this sample file under the ```mq.mqsc``` property with your specific queue commands; the commands provided are for example purposes only.

The is also an ```mq.ini``` section that can be further customized for other MQ configuration options. More details can be found here: https://github.com/ibm-messaging/mq-helm/tree/main/charts/ibm-mq

### Set License Annotations

IBM MQ is licensed software, and should only be used for production purposes if properly licensed. As such, you should make sure you update your deployment settings with the correct values that meet your license(s). Without them, the containers will run in "developer" mode.

More details about the different licensing annotations can be found in the IBM Repository (https://github.com/ibm-messaging/mq-helm/tree/main/charts/ibm-mq#supplying-licensing-annotations) and also in the IBM Documentation (https://www.ibm.com/docs/en/ibm-mq/9.2?topic=sbyomcic-license-annotations-when-building-your-own-mq-container-image#ctr_license_annot__annot8)

### Clone mq-helm chart repository

To deploy the helm chart, it can be easiest to clone the existing repository to your local computer:

```bash
git clone https://github.com/ibm-messaging/mq-helm.git ~/
```

This will clone the existing IBM MQ Helm chart. Note the directory you clone into (above will clone into your local home folder) as you will need that path when you're ready to deploy MQ.

### Modify Values File & Deploy Helm Chart

Finally, set up your deployment values file. A sample has been provided in this repository to get you started and provides values for:

* Storage classes for your queue manager data and log storage PV/Cs
* How to expose your ports
* MQ.ini and MQSC values
* HA Configurations

And much more. A full set of values you can set are provided here: https://github.com/ibm-messaging/mq-helm/tree/main/charts/ibm-mq#configuration

The provided sample configuration value file (```mq-aks-values.yaml```) takes care of the basics like persistent storage and native HA for your cluster. Once you've reviewed the configurration file and made any adjustments, you can use Helm to deploy MQ into your AKS cluster with the following command:

```bash
helm install omsmq <path to ibm-messaging repo you cloned>/charts/ibm-mq -f mq-aks-values.yaml
```

In the above example, your queue manager name will be same name as your deployment. In otherwords, the queue manager name will be "omsmq."

### Create JMS Bindings File

Once the deployment finishes and your pods are running, the final step is to create your JMS Bindings file. One way to do so is to enter your running pod of your MQ deployment and use the ```JMSAdmin``` utility:

```bash
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
