# Sterling Azure Bootstrap Resources

In this folder, you can find resources that can help you get up to speed quickly with the required resources for a successful deployment of Sterling OMS on Azure. There are several pre-requisites which are outlined in the main repository readme (link). However, these bicep files can aid you in getting an environment up and running

## Updating cloud init file(s) (Optional)

There are a series of cloud-init files in this repository that are used during different deployment steps to "stage" a virtual machine with different software packages, custom installers, and other steps. If you'd like to modify a particular VM's cloud init script, you can do the following:

1. Modify the relevant cloud-init-<name>.yaml file to include your requirements
2. From a Linux based host, run:

    ```bash
    awk -v ORS='\\n' '1' cloud-init.yaml
    ```
3. Take the resulting one-line output and replace it in the relevant .bicep file's ```cloudInitData``` line. NOTE: Make sure you eescape the apostrophes in the string with a preceding `\'` .

## Preparing to deploy

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

### Deploying from this repository

You will need a public DNS Zone that can be accessed by the OpenShift installer. During deployment, you will be prompted for the following:

- OpenShift Pull Secret
- Client Id
- Client Secret
- Cluster Name
- Administrator Password
- InstallerStorageAccountName
- InstallerContainerName 
- InstallerSASToken string
- Create DB2 VM? (Y/N)
- Create MQ VM? (Y/N)

The Domain Name must match the name of the DNS Zone that you will be using for OpenShift. During the deployment this DNS Zone will be updated with records to resolve to the cluster. If it is not accessible by the Client Id, the deployment will fail.

```bash
az group create --location "East US" --name <your resource group name>

az deployment group create --resource-group <your resource group name> --template-file bootstrap.bicep --parameters parameters.json
```

**Note**: If you choose to install MQ and/or DB2 VMs, **you MUST provide values for the InstallerStorageAccountName, InstallerContainerName, and InstallerSASToken values**; if you plan on running these services elsewhere (such as PostgreSQL or Oracle), then you can provide empty values. Please see the section "Preparing your installers" for more information.

Alternatively you can deploy straight from this repository:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fsterling%2Fmain%2Fazure%2Fbootstrap.bicep)

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