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
param storageNamePrefix string
param mqsharename string
param installerStorageAccountName string
param installerContainerName string
param installerSASToken string
param installScript string

var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetRef = '${vnetId}/subnets/${subnetName}'
var cloudInitData = '#cloud-config\n\nruncmd:\n - sudo yum update\n - sudo yum install -y nfs-utils\n - sudo mkdir /MQHA\n - sudo mount -t nfs ${storageNamePrefix}prm.file.core.windows.net:/${storageNamePrefix}prm/${mqsharename} /MQHA -o vers=4,minorversion=1,sec=sys\n - sudo mkdir /MQHA/logs\n - sudo mkdir /MQHA/qmgrs\n - sudo groupadd mqclient\n - sudo useradd app\n - sudo wget https://aka.ms/downloadazcopy-v10-linux -O /tmp/azcopy.tar.gz\n - sudo tar -xvf /tmp/azcopy.tar.gz -C /tmp\n - sudo mv /tmp/azcopy_linux* /tmp/azcopy\n - sudo /tmp/azcopy/azcopy copy  "https://${installerStorageAccountName}.blob.core.windows.net/${installerContainerName}/mqadv_dev925_linux_x86-64.tar.gz${installerSASToken}" /tmp/mq.tar.gz\n - sudo tar -xf /tmp/mq.tar.gz -C /mnt\n - sudo rm /tmp/mq.tar.gz\n - cd /mnt/MQServer\n - ./mqlicense.sh -accept\n - sudo rpm -ivh MQSeriesGSKit-* MQSeriesRuntime-*.rpm MQSeriesServer-*.rpm\n - sudo usermod -G azureuser mqm\n - sudo chown -R mqm:mqm /MQHA\n - sudo chmod -R ug+rwx /MQHA\n - sudo echo "${storageNamePrefix}prm.file.core.windows.net:/${storageNamePrefix}prm/${mqsharename} /MQHA nfs rw,hard,noatime,nolock,vers=4,tcp,_netdev 0 0" >> /etc/fstab\n - [ wget, -nv, "https://raw.githubusercontent.com/Azure/sterling/main/src/installers/${installScript}.sh", -O, /tmp/script.sh ]\n - chmod +x /tmp/script.sh\n - sudo -E /tmp/script.sh'


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
        sku: '8.2'
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
