# Sterling Azure Bootstrap Resources

In this folder, you can find resources that can help you get up to speed quickly with the required resources for a successful deployment of Sterling OMS on Azure. There are several pre-requisites which are outlined in the main repository readme (link). However, these bicep files can aid you in getting an environment up and running

## Updating cloud init file(s) (Optional)

There are a series of cloud-init files in this repository that are used during different deployment steps to "stage" a virtual machine with different software packages, custom installers, and other steps. If you'd like to modify a particular VM's cloud init script, you can do the following:

1. Modify the relevant cloud-init-*.yaml file to include your requirements
2. From a Linux based host, run:
    ```bash
    awk -v ORS='\\n' '1' cloud-init-<vm name>.yaml
    ```
3. Take the resulting one-line output and replace it in the relevant .bicep file's ```cloudInitData``` line. NOTE: Make sure you escape the apostrophes in the string with a preceding `\'` .

## Preparing to deploy

### Service Principal

You will need to [create an Azure Application Registration (SPN)](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal) and grant it `Contributor` permissions on the subscription you plan to deploy into. If granting permissions at the subscription level is not possible, you can also configure the permissions on this resource group instead. have issue with state when attempting to use a single resource group.

After creating the SPN and assigning its access, you will need to create a [secret](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#option-2-create-a-new-application-secret) that will be used during the OCP install process.

More details on [creating a service principal for Azure Redhat OpenShift can be found here](https://docs.microsoft.com/en-us/azure/openshift/howto-create-service-principal?pivots=aro-azurecli)

Once you have created your service principal and secret, you will need both the client ID (application ID) of your service principal *and* your associated application object ID as well. To get these values, you can run the following two commands:

```bash
#Getting the application registration ID
az ad app list --display-name ocp-test --query "[].appId" -o tsv
#Getting the associated enterprise application ID
az ad app show --id <value from previous command>
```

Those values, along with your generated secret, will be used in this deployment. Both the application registration ID and enterprise application are needed for the ARO install and associated role permissions required.

### Preparing your installers

If you plan to use IBM MQ and/or IBM DB2, you will need to stage your installer images on a storage account. The easiest way to do this is to create a new storage account, create an empty blob container, then upload your installer images to this new container and generate a SAS token:

```bash
az storage account create --name omsinstallers --resource-group <your resource group name> --sku Standard_LRS
az storage container create --name installers --account-name omsinstallers  --resource-group <your resource group name>
```

Once you have your storage account, upload your MQ and/or DB2 images to this storage account. Note their file names, as you will need them during the install process. Finally, generate a SAS token for the storage account, and note the full value as the installer will need it:

```bash
end=`date -u -d "1 day" '+%Y-%m-%dT%H:%MZ'`
az storage container generate-sas --account-name ominstaller --name installers --permissions lr --auth-mode login --as-user --expiry $end
```
Note the full SAS token (string)

Finally, update your parameters file with the EXACT name of the archives for DB2 and/or MQ

## Deployment Parameters

This repository contains a parameters file that contains most of the default values you can use to deploy your environment. You can adjust these as you see fit, however, there are a few you should be aware before you deploy:

* aroVisibility: This is set to ```"Public"``` in the parameters file. If set to ```"Private"``` your WebUI and APIServer endpoints will ONLY be accessible from your JumpBox and/or any resources that can reach your virtual network. The current parameters file has this set to ```Public```.
* whichOMS: Which version of OMS you want to deploy. This should correspond to the Operator image name. The parameters file is set to use the "Professional Edition." More information about which image to use for the version you want can be found here: https://www.ibm.com/docs/en/order-management-sw/10.0?topic=operator-installing-updating-order-management-software-online
* ibmEntitlementKey: Please set this to your current IBM entitlement key if you need to connect to or pull any images from any IBM repository
* omsNamespace: The namespace to deploy all relevant OMS artifacts into. Defaults to ```OMS``` but can be changed to whatever you like.
* db2InstallerArchiveName: The file name of the tar.gz file containing the setup files for IBM DB2 (if installing a DB2 VM as part of your deployment)
* mqInstallerArchiveName: The file name of the tar.gz file containing the setup files for IBM MQ (if installing a MQ VM as part of your deployment)

## Deploying from this repository

You will need a public DNS Zone that can be accessed by the OpenShift installer. During deployment, you will be prompted for the following:

- OpenShift Pull Secret - If your cluster needs to pull containers from any Red Hat registry, you can provide this. If not, it can left empty
- Application Registration Client Id - The client ID of your Service Principal
- Enterprise Application Object Id - The Object ID of your Enterprise Application (that matches the name of your service principal)
- Application Registration Client Secret - Your generated service principal secret 
- ARO Cluster Name - Your ARO cluster name
- ARO Domain Name - A custom domain to use for your cluster
- Administrator Password - The main password that will be used to create and access any virtual machines, databases, etc in your deployment.
- InstallerStorageAccountName - If installing DB2 or MQ, the storage account name where the installers are located (note: just the storage account name, not FQDN)
- InstallerContainerName - If installing DB2 or MQ, the name of the container on the storage account where the installers are located.
- InstallerSASToken string - If installing DB2 or MQ, the SAS token you generated that provides READ and LIST permissions on the storage container. Do not include any question marks (?) in the token
- Create DB2 VM? (Y/N) - Select "Y" to create a new virtual machine in your deployment that will install OBM DB2, create an emtpty database, and a new schema.
- Create MQ VM? (Y/N) = Select "Y" to create a new virtual machine in your deployment that will install IBM MQ

**Note**: If you choose to install MQ and/or DB2 VMs, **you MUST provide values for the InstallerStorageAccountName, InstallerContainerName, and InstallerSASToken values**; if you plan on running these services elsewhere (such as PostgreSQL or Oracle), then you can provide empty values. Please see the section "Preparing your installers" for more information. The installers will then attempt to connect to these storage accounts during deployment to download the binaries to perform the install. Please all so the "Parameters" section of this guide for more configuration options.

To deploy this environment, clone this repository and change to the ```./azure``` folder and run the following Azure CLI command:

```bash
az group create --location "East US" --name <your resource group name>

az deployment group create --resource-group <your resource group name> --template-file bootstrap.bicep --parameters parameters.json
```

## Post-Deployment

Once this deployment completes, you should have a functional environment that will support deploying Sterling Order Management. However, this deployment is only a starting point. Please make sure you:

### Connecting to your Azure VM(s) / Jumpbox for Administration

This repository will deploy all associated resource* into a private virtual network which means resources (such as virtual machines, storage accounts, etc) will not be accessible from outside the virtual network. You can access these resources by using Azure Bastion to connect to a virtual machine and access your resources from there. This repository deploys a "jump box" RHEL virtual machine you can use for this purpose. You can also extend this network into other networks as you see fit.

For help or getting started information with Azure Bastion, please reference this link: https://docs.microsoft.com/en-us/azure/bastion/bastion-connect-vm-rdp-windows

**Note**: You can control your ARO "visibility" with the "aroVisibility" parameter (See [Deployment Parameters](#deployment-parameters) for more information)

### Considerations

* **Change any appropriate administrator passwords**: This installer uses the "admin password" parameter to set the administrator passwords for the following services:
 * VM Admin Accounts
 * PostgreSQL Databases
 * DB2 Instance Accounts
 Once the install completes, you should go through and change this passwords as required.
* **Enable HA/DR where appropriate**: This installer is designed to be a starting point for your environment, and if you plan to use this deployment as a template for non-development environments, you should make sure you:
 * Ensure availability of your database tier: If using DB2, consider configuring HA for your DB2 VMS. More information from IBM can be found here: https://www.ibm.com/support/pages/setting-two-node-db2-hadr-pacemaker-cluster-virtual-ip-microsoft-azure (Note: this deployment does install required Pacemaker components; you'll just need to add nodes and your additional Azure infrastructures)
 * For IBM MQ, consider adding more nodes and sharing the Premium Files storage among your nodes

### Preparing to deploy your OMEnvironment from the Sterling Operator

For more detailed information about post-deployment steps (and creating required secrets, persistent volumes, SSL information, etc) be sure to check the Quickstart Guide documentation at the root of this repository in the [Quickstart Guide](../README.md#create-oms-secret) starting at the "Creating an OMS Secret" step (as everything else should be prepared upt to that point if you deployed from this repository)

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