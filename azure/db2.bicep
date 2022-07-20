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
param installerStorageAccountName string
param installerContainerName string
@secure()
param installerSASToken string
param loadBalancerName string
param db2InstallerArchiveName string
param branchName string
param db2DatabaseName string


//var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetRef = '${vnetId}/subnets/${subnetName}'
var cloudInitData = '#cloud-config\n\nruncmd:\n - export ADMIN_USERNAME=${adminUsername}\n - export DB2_ADMIN_PASSWORD=${adminPassword}\n - export DB2_FENCED_PASSWORD=${adminPassword}\n - export INSTALLER_STORAGEACCOUNT_NAME=${installerStorageAccountName}\n - export INSTALLER_STORAGECONTAINER_NAME=${installerContainerName}\n - export INSTALLER_SAS_TOKEN="${installerSASToken}"\n - export DB2_INSTALLER_ARCHIVE_FILENAME=${db2InstallerArchiveName}\n - export DB2_DATABASE_NAME=${db2DatabaseName}\n - export BRANCH_NAME=${branchName}\n - sudo yum -y install libstdc++.i686 libXmu.i686 libacl.i686 ncurses-libs.i686 ncurses-compat-libs.i686 motif.i686 xterm libmount.i686 libgcc.i686 libnsl.i686 libXdmcp.i686 libxcrypt.i686 libXdmcp libnsl psmisc elfutils-libelf-devel make pam-devel\n - sudo yum -y install ksh mksh\n - sudo yum install -y java-1.8.0-openjdk\n - sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm\n - sudo dnf install -y python3-dnf-plugin-versionlock\n - sudo wget https://aka.ms/downloadazcopy-v10-linux -O /tmp/azcopy.tar.gz\n - sudo tar -xvf /tmp/azcopy.tar.gz -C /tmp\n - sudo mv /tmp/azcopy_linux* /tmp/azcopy\n - sudo sed -i \'s/enforcing/disabled/g\' /etc/selinux/config /etc/selinux/config\n - sudo parted /dev/sdc --script mklabel gpt mkpart xfspart xfs 0% 100%\n - sudo mkfs.xfs /dev/sdc1\n - sudo partprobe /dev/sdc1 \n - sudo mkdir /db2data\n - sudo mount /dev/sdc1 /db2data\n - FSTAB="$(blkid | grep sdc1 | awk \'$0=$2\' | sed \'s/"//g\')   /db2data   xfs   defaults,nofail   1   2"\n - sudo su -c "echo $FSTAB >> /etc/fstab"\n - [ wget, -nv, "https://raw.githubusercontent.com/Azure/sterling/${branchName}/config/installers/install-db2-from-storageaccount.sh", -O, /tmp/install-db2-from-storageaccount.sh ]\n - chmod +x /tmp/install-db2-from-storageaccount.sh\n - sudo -E /tmp/install-db2-from-storageaccount.sh\n'


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
          //loadBalancerBackendAddressPools: [
          //{
          //  id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, '${loadBalancerName}-bep')
          //}
          //]
        }
      }
    ]
    /*
    networkSecurityGroup: {
      id: nsgId
    }
    */
  }
  /*
  dependsOn: [
    networkSecurityGroupName_resource
  ]
  */
}

resource datadisk_resource 'Microsoft.Compute/disks@2021-12-01' = {
  name: '${virtualMachineName}-db2data'
  location: location
  sku: {
    name: 'Premium_LRS'
  }
  zones: [
    zone
  ]
  properties: {
    creationData: {
        createOption: 'Empty'
    }
    diskSizeGB: 256
    diskIOPSReadWrite: 1100
    diskMBpsReadWrite: 125
    encryption: {
       type: 'EncryptionAtRestWithPlatformKey'
    }
    networkAccessPolicy: 'AllowAll'
    publicNetworkAccess: 'Enabled'
  }
}

/*
resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}
*/

resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      dataDisks: [
        {
          createOption: 'Attach'
          deleteOption: 'Detach'
          lun: 0
          managedDisk: {
            id: datadisk_resource.id
          }
          toBeDetached: false
          writeAcceleratorEnabled: false
        }
      ]
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
