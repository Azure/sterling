param location string
param networkInterfaceName string
param networkSecurityGroupName string
param networkSecurityGroupRules array
param subnetName string
param virtualNetworkName string
param virtualMachineName string
param osDiskType string
param virtualMachineSize string
param adminUsername string
@secure()
param adminPassword string
param zone string
param installdb2container string
param installmqcontainer string
param aroname string
param clientID string
param clientSecret string
param omsNamespace string


var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetRef = '${vnetId}/subnets/${subnetName}'
var subscriptionID = subscription().subscriptionId
var resourceGroupName = resourceGroup().name
var tenantID = tenant().tenantId
var cloudInitData = '#cloud-config\n\nruncmd:\n - sudo apt-get update -y \n - sudo apt-get install -y ca-certificates curl gnupg lsb-release\n - mkdir ~/.azure/\n - echo \'{"subscriptionId":"${subscriptionID}","clientId":"${clientID}","clientSecret":"${clientSecret}","tenantId":"${tenantID}"}\' > ~/.azure/osServicePrincipal.json\n - sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc\n - |\n    echo -e "[azure-cli]\n    name=Azure CLI\n    baseurl=https://packages.microsoft.com/yumrepos/azure-cli\n    enabled=1\n    gpgcheck=1\n    gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo\n - sudo dnf -y install azure-cli \n - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg\n - echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null\n - sudo apt-get update -y\n - sudo apt-get -y install docker-ce docker-ce-cli containerd.io\n - curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3\n - chmod 700 get_helm.sh\n - ./get_helm.sh\n - sudo usermod -aG docker $USER\n - mkdir /tmp/OCPInstall\n - [ wget, -nv, "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz", -O, /tmp/OCPInstall/openshift-client-linux.tar.gz ]\n - tar xvf /tmp/OCPInstall/openshift-client-linux.tar.gz -C /tmp/OCPInstall\n - sudo cp /tmp/OCPInstall/oc /usr/bin\n - export INSTALL_DB2_CONTAINER=${installdb2container}\n - export INSTALL_MQ_CONTAINER=${installmqcontainer}\n - az login --service-principal -u $(cat ~/.azure/osServicePrincipal.json | jq -r .clientId) -p $(cat ~/.azure/osServicePrincipal.json | jq -r .clientSecret) --tenant $(cat ~/.azure/osServicePrincipal.json | jq -r .tenantId) --output none && az account set -s $(cat ~/.azure/osServicePrincipal.json | jq -r .subscriptionId) --output none\n - apiServer=$(az aro show -g ${resourceGroupName} -n $CLUSTER --query apiserverProfile.url -o tsv)\n - az aro list-credentials --name ${aroname} --resource-group ${resourceGroupName}\n - #TODO Get Credentials and Log in Here\n - oc login $apiServer -u kubeadmin -p ""\n - |\n    if [ "$INSTALL_DB2_CONTAINER" == "Y" ] || [ "$INSTALL_DB2_CONTAINER" == "y" ]\n    then\n      echo "Installing DB2 Container in namespace ${omsNamespace}..."\n    fi\n - |\n    if [ "$INSTALL_MQ_CONTAINER" == "Y" ] || [ "$INSTALL_MQ_CONTAINER" == "y" ]\n    then\n      echo "Installing MQ Container in namespace ${omsNamespace}..."\n    fi    \n'


resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2018-10-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

// resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-11-01' = {
//   name: virtualNetworkName
//   location: location
//   properties: {
//     addressSpace: {
//       addressPrefixes: addressPrefixes
//     }
//     subnets: subnets
//   }
// }


resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '8_4'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_resource.id
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: base64(cloudInitData)
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  zones: [
    zone
  ]
}
