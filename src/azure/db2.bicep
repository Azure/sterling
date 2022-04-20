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


var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetRef = '${vnetId}/subnets/${subnetName}'
var cloudInitData = '#cloud-config\n\nruncmd:\n - sudo wget https://aka.ms/downloadazcopy-v10-linux -O /tmp/azcopy.tar.gz\n - sudo tar -xvf /tmp/azcopy.tar.gz -C /tmp\n - sudo mv /tmp/azcopy_linux* /tmp/azcopy\n - sudo sed -i \'s/enforcing/disabled/g\' /etc/selinux/config /etc/selinux/config\n - sudo /tmp/azcopy/azcopy copy "https://${installerStorageAccountName}.blob.core.windows.net/${installerContainerName}/v11.5.7_linuxx64_server_dec.tar.gz${installerSASToken}" /tmp/db2.tar.gz\n - sudo tar -xf /tmp/db2.tar.gz -C /mnt\n - sudo rm /tmp/db2.tar.gz\n - sudo yum -y install libstdc++.i686 libXmu.i686 libacl.i686 ncurses-libs.i686 ncurses-compat-libs.i686 motif.i686 xterm libmount.i686 libgcc.i686 libnsl.i686 libXdmcp.i686 libxcrypt.i686 libXdmcp libnsl psmisc elfutils-libelf-devel make\n - sudo yum -y install ksh mksh\n - sudo yum install -y java-1.8.0-openjdk\n - sudo /tmp/azcopy/azcopy copy "https://${installerStorageAccountName}.blob.core.windows.net/${installerContainerName}/install.rsp${installerSASToken}" /mnt/install.rsp\n - echo "inst1.PASSWORD = ${adminPassword}" >> /mnt/install.rsp\n - echo "inst1.FENCED_PASSWORD = ${adminPassword}" >> /mnt/install.rsp \n - sudo /mnt/server_dec/db2setup -r /mnt/install.rsp\n - sudo /var/ibm/db2/V11.5/bin/db2fmcu -u -p /var/ibm/db2/V11.5/bin/db2fmcd\n - sudo /var/ibm/db2/V11.5/bin/db2fm -i db2inst1 -U\n - sudo /var/ibm/db2/V11.5/bin/db2fm -i db2inst1 -u\n - sudo /var/ibm/db2/V11.5/bin/db2fm -i db2inst1 -f on\n - /home/db2inst1/sqllib/db2profile\n - sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm\n - sudo dnf install -y python3-dnf-plugin-versionlock\n - cd /mnt/server_dec/db2/linuxamd64/pcmk \n - sudo ./db2installPCMK -i\n - cd /var/ibm/db2/V11.5/install/pcmk\n - sudo sudo ./db2cppcmk -i\n - sudo parted /dev/sdc --script mklabel gpt mkpart xfspart xfs 0% 100%\n - sudo mkfs.xfs /dev/sdc1\n - sudo partprobe /dev/sdc1 \n - sudo mkdir /mnt/db2data\n - sudo mount /dev/sdc1 /mnt/db2data\n - FSTAB="$(blkid | grep sdc1 | awk \'$0=$2\' | sed \'s/"//g\')   /mnt/db2data   xfs   defaults,nofail   1   2"\n - sudo su -c "echo $FSTAB >> /etc/fstab"\n - sudo rm /mnt/install.rsp\n - sudo su db2inst1\n - ssh-keygen -q -t rsa -N \'\' -f ~/db2vm-instance\n - exit\n - sudo su -\n - ssh-keygen -q -t rsa -N \'\' -f /home/${adminUsername}/db2vm-root\n - cp /home/db2inst1/dbvm-instance* /home/${adminUsername}\n - chown -R ${adminUsername}:${adminUsername} /home/${adminUsername}/\n - exit\n - sudo firewall-cmd --permanent --zone=public --add-port=25000/tcp\n - sudo firewall-cmd --permanent --zone=public --add-port=25010/tcp\n\n'


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
          loadBalancerBackendAddressPools: [
          {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, '${loadBalancerName}-bep')
          }
        ]
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
