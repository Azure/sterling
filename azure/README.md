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

You will need a public DNS Zone that can be accessed by the OpenShift installer. During deployment, you will be prompted for the following:

- OpenShift Pull Secret
- Client Id
- Client Secret
- Cluster Name
- Administrator Password
- Create DB2 VM? (Y/N)
- Create DB2 Container? (Y/N)
- Create MQ VM? (Y/N)
- Create DB2 Container? (Y/N)

The Domain Name must match the name of the DNS Zone that you will be using for OpenShift. During the deployment this DNS Zone will be updated with records to resolve to the cluster. If it is not accessible by the Client Id, the deployment will fail.

```bash
az group create --location "East US" --name OMS

az deployment group create --resource-group  OMS --template-file bootstrap.bicep --parameters parameters.json
```

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