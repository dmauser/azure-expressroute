# Prerequisite - Install AZ and GCP CLI:
# Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# GCP CLI: https://cloud.google.com/sdk/docs/install#deb

# 1) Deploy Azure side: Hub and Spoke

az login
#List all your subscriptions
az account list -o table --query "[].{Name:name, IsDefault:isDefault}"
#List default Subscription being used
az account list --query "[?isDefault == \`true\`].{Name:name, IsDefault:isDefault}" -o table
# In case you want to do it separated Subscription change your active subscription as shown
az account set --subscription #Select your subscription

#Azure Variables
rg=lab-ars-er-transit #Define your resource group
location=centralus #Set Region
mypip=$(curl -4 ifconfig.io -s) #Captures your local Public IP and adds it to NSG to restrict access to SSH only for your Public IP.
EREnvironmentAddressSpace=10.154.0.0/22 #Emulated AVS
OnPremVnetAddressSpace=10.112.8.0/24 # Onpremises

#Define parameters for Azure Hub and Spokes:
AzurehubName=Az-Hub #Azure Hub Name
AzurehubaddressSpacePrefix=10.0.10.0/24 #Azure Hub VNET address space
AzurehubNamesubnetName=subnet1 #Azure Hub Subnet name where VM will be provisioned
Azurehubsubnet1Prefix=10.0.10.0/27 #Azure Hub Subnet address prefix
AzurehubgatewaySubnetPrefix=10.0.10.32/27 #Azure Hub Gateway Subnet address prefix
AzurehubrssubnetPrefix=10.0.10.64/27 #Azure Hub Route Server subnet address prefix
AzureFirewallPrefix=10.0.10.128/26 #NVAs Prefix
AzureHubTrustedSubnet=10.0.10.96/28 #NVA Trusted Subnet
AzureHubUntrustedSubnet=10.0.10.112/28 #NVA Untrusted Subnet
AzureHubRouteServerSubnet=10.0.10.142/27
Azurespoke1Name=Az-Spk1 #Azure Spoke 1 name
Azurespoke1AddressSpacePrefix=10.0.11.0/24 # Azure Spoke 1 VNET address space
Azurespoke1Subnet1Prefix=10.0.11.0/27 # Azure Spoke 1 Subnet1 address prefix
Azurespoke2Name=Az-Spk2 #Azure Spoke 1 name
Azurespoke2AddressSpacePrefix=10.0.12.0/24 # Azure Spoke 1 VNET address space
Azurespoke2Subnet1Prefix=10.0.12.0/27 # Azure Spoke 1 VNET address space

#Parsing parameters above in Json format (do not change)
JsonAzure={\"hubName\":\"$AzurehubName\",\"addressSpacePrefix\":\"$AzurehubaddressSpacePrefix\",\"subnetName\":\"$AzurehubNamesubnetName\",\"subnet1Prefix\":\"$Azurehubsubnet1Prefix\",\"AzureFirewallPrefix\":\"$AzureFirewallPrefix\",\"gatewaySubnetPrefix\":\"$AzurehubgatewaySubnetPrefix\",\"rssubnetPrefix\":\"$AzurehubrssubnetPrefix\",\"spoke1Name\":\"$Azurespoke1Name\",\"spoke1AddressSpacePrefix\":\"$Azurespoke1AddressSpacePrefix\",\"spoke1Subnet1Prefix\":\"$Azurespoke1Subnet1Prefix\",\"spoke2Name\":\"$Azurespoke2Name\",\"spoke2AddressSpacePrefix\":\"$Azurespoke2AddressSpacePrefix\",\"spoke2Subnet1Prefix\":\"$Azurespoke2Subnet1Prefix\"}

#Deploy base lab environment = Hub + VPN Gateway + VM and two Spokes with one VM on each.
echo "***  Note you will be prompted by username and password ***"
echo "*** It will take around 30 minutes to finish the deployment ***"
az group create --name $rg --location $location
az deployment group create --name HubSpokeBase--resource-group $rg \
--template-uri https://raw.githubusercontent.com/dmauser/azure-hub-spoke-base-lab/main/azuredeploy.json \
--parameters Restrict_SSH_VM_AccessByPublicIP=$mypip deployHubERGateway=true Azure=$JsonAzure deployAzureRouteServer=true RouteServerB2B=true \
--output none

#Deploy OPNSense NVA
# Removes AzureFirewall Subnet and adds untrusted/trusted subnets
# 
az network vnet subnet delete --name AzureFirewallSubnet --resource-group $rg --vnet-name $AzurehubName-vnet --output none
az network vnet subnet create --address-prefix $AzureHubTrustedSubnet --name trusted --resource-group $rg --vnet-name $AzurehubName-vnet --output none
az network vnet subnet create --address-prefix $AzureHubUntrustedSubnet --name untrusted --resource-group $rg --vnet-name $AzurehubName-vnet --output none

# Deploy OPNsense NVA1
az deployment group create --name $AzurehubName-nva1-$RANDOM --resource-group $rg \
--template-uri "https://raw.githubusercontent.com/dmauser/opnazure/master/ARM/main-two-nics.json" \
--parameters virtualMachineSize=Standard_B2s virtualMachineName=$AzurehubName-nva1 TempUsername=azureuser TempPassword=Msft123Msft123 existingVirtualNetworkName=$AzurehubName-vnet existingUntrustedSubnet=untrusted existingTrustedSubnet=trusted PublicIPAddressSku=Standard \
--no-wait

# Deploy OPNsense NVA2
az deployment group create --name $AzurehubName-nva2-$RANDOM --resource-group $rg \
--template-uri "https://raw.githubusercontent.com/dmauser/opnazure/master/ARM/main-two-nics.json" \
--parameters virtualMachineSize=Standard_B2s virtualMachineName=$AzurehubName-nva2 TempUsername=azureuser TempPassword=Msft123Msft123 existingVirtualNetworkName=$AzurehubName-vnet existingUntrustedSubnet=untrusted existingTrustedSubnet=trusted PublicIPAddressSku=Standard \
--no-wait

# Create Load Balancer
az network lb create -g $rg --name $AzurehubName-nvalb --sku Standard --frontend-ip-name frontendip1 --backend-pool-name nvabackend --vnet-name $AzurehubName-vnet --subnet=trusted --output none
az network lb probe create -g $rg --lb-name $AzurehubName-nvalb --name sshprobe --protocol tcp --port 22 --output none  
az network lb rule create -g $rg --lb-name $AzurehubName-nvalb --name haportrule --protocol all --frontend-ip-name frontendip1 --backend-pool-name nvabackend --probe-name sshprobe --frontend-port 0 --backend-port 0 --output none

# Attach NVAs to the Backends
array=($AzurehubName-nva1 $AzurehubName-nva2)
for vm in "${array[@]}"
  do
  az network nic ip-config address-pool add \
   --address-pool nvabackend \
   --ip-config-name ipconfig1 \
   --nic-name $vm-trusted-nic \
   --resource-group $rg \
   --lb-name $AzurehubName-nvalb
  done

#Build Route Server BGP Peering with NVA
az network routeserver peering create --resource-group $rg --routeserver $AzurehubName-routeserver --name $AzurehubName-nva1 --peer-asn 65002 \
--peer-ip $(az network nic show -g $rg --name $AzurehubName-nva1-trusted-nic --query "ipConfigurations[].privateIpAddress" -o tsv) 

az network routeserver peering create --resource-group $rg --routeserver $AzurehubName-routeserver --name $AzurehubName-nva2 --peer-asn 65002 \
--peer-ip $(az network nic show -g $rg --name $AzurehubName-nva2-trusted-nic --query "ipConfigurations[].privateIpAddress" -o tsv) 

#Create two ExpressRoute Circuits
# Dallas Repro AVS 
az deployment group create \
--resource-group $rg \
--template-uri https://raw.githubusercontent.com/dmauser/azure-hub-spoke-base-lab/main/linked/ercircuit.json \
--parameters ercircuitname=ER-DAL-AVS-Circuit asn=65154 primaryPeerAddressPrefix=172.100.154.0/30 secondaryPeerAddressPrefix=172.100.154.4/30 provider=Megaport peeringlocation="Dallas" bandwidthInMbps=50

# Chicago Repro OnPrem 
az deployment group create \
--resource-group $rg \
--template-uri https://raw.githubusercontent.com/dmauser/azure-hub-spoke-base-lab/main/linked/ercircuit.json \
--parameters ercircuitname=ER-CHI-OnPrem-Circuit asn=65112 primaryPeerAddressPrefix=172.100.112.0/30 secondaryPeerAddressPrefix=172.100.112.4/30 provider=Megaport peeringlocation="Chicago" bandwidthInMbps=50

### *** Provision ER with your Service Providers ***

#Connect both ER Circuit to Hub ExpressRoute Gateway

erid=$(az network express-route show -n ER-CHI-OnPrem-Circuit -g $rg --query id -o tsv) 
az network vpn-connection create --name Connection-to-CHI-OnPrem \
--resource-group $rg --vnet-gateway1 $AzurehubName-ergw \
--express-route-circuit2 $erid \
--routing-weight 0

erid=$(az network express-route show -n ER-DAL-AVS-Circuit -g $rg --query id -o tsv) 
az network vpn-connection create --name Connection-to-DAL-AVS \
--resource-group $rg --vnet-gateway1 $AzurehubName-ergw \
--express-route-circuit2 $erid \
--routing-weight 0

## Test UDR GatewaySubnet to send traffic to the NVA1 (adjust later to NVA)

#UDR for Hub traffic to Azure NVA (disables BGP propagation)
## Create UDR + Disable BGP Propagation
nva1=$(az network nic show -g $rg --name $AzurehubName-nva1-trusted-nic --query "ipConfigurations[].privateIpAddress" -o tsv)
nva2=$(az network nic show -g $rg --name $AzurehubName-nva2-trusted-nic --query "ipConfigurations[].privateIpAddress" -o tsv)
nvalb=$(az network lb show -g $rg --name $AzurehubName-nvalb --query "frontendIpConfigurations[].privateIpAddress" -o tsv)

az network route-table create --name RT-Hub-to-NVA --resource-group $rg --location $location --disable-bgp-route-propagation true
## Default route to NVA
az network route-table route create --resource-group $rg --name Default-to-NVA --route-table-name RT-Hub-to-NVA  \
--address-prefix 0.0.0.0/0 \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $nvalb
## Traffic to Spoke1 via NVA
az network route-table route create --resource-group $rg --name Spk1-to-NVA --route-table-name RT-Hub-to-NVA  \
--address-prefix $Azurespoke1AddressSpacePrefix \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $nvalb
## Traffic to Spoke2 via NVA
az network route-table route create --resource-group $rg --name Spk2-to-NVA --route-table-name RT-Hub-to-NVA  \
--address-prefix $Azurespoke2AddressSpacePrefix \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $nvalb
mypip=$(curl ifconfig.io -s) #adding Public IP allow access to the VMs after enable UDR.
az network route-table route create --resource-group $rg --name Exception --route-table-name RT-Hub-to-NVA  \
--address-prefix $mypip/32 \
--next-hop-type Internet
## Associating RT-Hub-to-NVA Hub Subnet1 (Hub and Spokes)
az network vnet subnet update -n subnet1 -g $rg --vnet-name $AzurehubName-vnet --route-table RT-Hub-to-NVA 

# Spoke 1 and 2 traffic to NVA
## Create UDR + Disable BGP Propagation
az network route-table create --name RT-Spoke-to-NVA  --resource-group $rg --location $location --disable-bgp-route-propagation true
## Default route to NVA
az network route-table route create --resource-group $rg --name Default-to-NVA --route-table-name RT-Spoke-to-NVA   \
--address-prefix 0.0.0.0/0 \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $nvalb
## Traffic to Hub to NVA
az network route-table route create --resource-group $rg --name Hub-to-NVA --route-table-name RT-Spoke-to-NVA   \
--address-prefix $AzurehubaddressSpacePrefix \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $nvalb
## Remote Public IP exception to remote SSH 
mypip=$(curl ifconfig.io -s) #adding Public IP allow access to the VMs after enable UDR.
az network route-table route create --resource-group $rg --name Exception --route-table-name RT-Spoke-to-NVA   \
--address-prefix $mypip/32 \
--next-hop-type Internet
## Associating RT-Hub-to-NVA to Spoke 1 and 2.
az network vnet subnet update -n subnet1 -g $rg --vnet-name $Azurespoke1Name-vnet --route-table RT-Spoke-to-NVA
az network vnet subnet update -n subnet1 -g $rg --vnet-name $Azurespoke2Name-vnet --route-table RT-Spoke-to-NVA

#UDR to send traffic between ExpressRoute environment and VPN Onprem and between Hub and spoke via NVAs
az network route-table create --name RT-GWSubnet-to-NVA --resource-group $rg --location $location 
## Azure Hub Subnet 1
az network route-table route create --resource-group $rg --name HubSubnet1-to-NVA --route-table-name RT-GWSubnet-to-NVA \
--address-prefix $Azurehubsubnet1Prefix \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $nvalb
## Azure Spoke 1
az network route-table route create --resource-group $rg --name Spoke1-to-NVA --route-table-name RT-GWSubnet-to-NVA \
--address-prefix $Azurespoke1AddressSpacePrefix \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $nvalb
## Azure Spoke 2
az network route-table route create --resource-group $rg --name Spok2-to-NVA --route-table-name RT-GWSubnet-to-NVA \
--address-prefix $Azurespoke2AddressSpacePrefix \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $nvalb
## OnPrem VPN
az network route-table route create --resource-group $rg --name OnPremVPN-to-NVA --route-table-name RT-GWSubnet-to-NVA \
--address-prefix $OnPremVnetAddressSpace \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $nvalb
## ExpressRoute Env
az network route-table route create --resource-group $rg --name EREvn-to-NVA --route-table-name RT-GWSubnet-to-NVA \
--address-prefix $EREnvironmentAddressSpace \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $nvalb
## Associating RT-to-GWSubnet to GatewaySubnet
az network vnet subnet update -n GatewaySubnet -g $rg --vnet-name $AzurehubName-vnet --route-table RT-GWSubnet-to-NVA


# 2) ****** Deploy GCP side Side ******

# Define your variables
project=angular-expanse-327722 #Set your project Name. Get your PROJECT_ID use command: gcloud projects list 
region=us-central1 #Set your region. Get Regions/Zones Use command: gcloud compute zones list
zone=us-central1-c # Set availability zone: a, b or c.
vpcrange=10.154.0.0/22
envname=avs-dal
vmname=vm1
mypip=$(curl -4 ifconfig.io -s) #Gets your Home Public IP or replace with that information. It will add it to the NVA Rule.

# Define your variables
project=angular-expanse-327722 #Set your project Name. Get your PROJECT_ID use command: gcloud projects list 
region=us-central1 #Set your region. Get Regions/Zones Use command: gcloud compute zones list
zone=us-central1-c # Set availability zone: a, b or c.
vpcrange=10.112.8.0/24
envname=onprem-chi
vmname=vm1
mypip=$(curl -4 ifconfig.io -s) #Gets your Home Public IP or replace with that information. It will add it to the NVA Rule.

### Ran the commands below two using the variables:

#Create VPC
sudo gcloud compute networks create $envname-vpc --project=$project --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional
sudo gcloud compute networks subnets create $envname-subnet --project=$project --range=$vpcrange --network=$envname-vpc --region=$region

#Create NVA Rule
sudo gcloud compute firewall-rules create $envname-allow-traffic-from-azure --network $envname-vpc --allow tcp,udp,icmp --source-ranges 192.168.0.0/16,10.0.0.0/8,172.16.0.0/16,35.235.240.0/20,$mypip/32

#Create Unbutu VM:
sudo gcloud compute instances create $envname-vm1 --project=$project --zone=$zone --machine-type=f1-micro --network-interface=subnet=$envname-subnet,network-tier=PREMIUM --image=ubuntu-1804-bionic-v20220126 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-balanced --boot-disk-device-name=$envname-vm1 

#Cloud Router: #***********Validate************
sudo gcloud compute routers create $envname-router --project=$project --region=$region --network=$envname-vpc --asn=16550

#DirectConnect via MegaPort:
sudo gcloud compute interconnects attachments partner create $envname-vlan --region $region --edge-availability-domain availability-domain-1 --router $envname-router --admin-enabled

# Get the pair key on the output above to setup connection with Megaport
sudo gcloud compute interconnects attachments describe $envname-vlan --region $region

## Validations

#IP info
az network nic show --resource-group $rg -n $AzurehubName-lxvm-nic --query "ipConfigurations[].privateIpAddress" -o tsv
az network nic show-effective-route-table --resource-group $rg -n $AzurehubName-lxvm-nic -o table

az network nic show --resource-group $rg -n $Azurespoke1Name-lxvm-nic --query "ipConfigurations[].privateIpAddress" -o tsv
az network nic show-effective-route-table --resource-group $rg -n $Azurespoke1Name-lxvm-nic -o table

az network nic show --resource-group $rg -n $Azurespoke2Name-lxvm-nic --query "ipConfigurations[].privateIpAddress" -o tsv
az network nic show-effective-route-table --resource-group $rg -n $Azurespoke2Name-lxvm-nic -o table

#VMs Public IPs
echo Hub-vm - $(az network public-ip show --name $AzurehubName-lxvm-pip --resource-group $rg --query "ipAddress" -o tsv) \
Spoke1-vm - $(az network public-ip show --name $Azurespoke1Name-lxvm-pip  --resource-group $rg -o tsv --query "ipAddress" -o tsv) \
Spoke2-vm - $(az network public-ip show --name $Azurespoke2Name-lxvm-pip --resource-group $rg -o tsv --query "ipAddress" -o tsv) \
opn-nva1 - $(az network public-ip show --name $AzurehubName-nva1-PublicIP --resource-group $rg -o tsv --query "ipAddress" -o tsv) \
opn-nva2 - $(az network public-ip show --name $AzurehubName-nva2-PublicIP --resource-group $rg -o tsv --query "ipAddress" -o tsv) 

# Check ER/VPN GW learned / advertised routes
# Azure ER
az network vnet-gateway list-bgp-peer-status -g $rg -n $AzurehubName-ergw -o table
ips=$(az network vnet-gateway list-bgp-peer-status -g $rg -n $AzurehubName-ergw --query 'value[].{ip:neighbor}' -o tsv)
array=($ips)
for ip in "${array[@]}"
  do
  echo Advertised routes to peer $ip
  az network vnet-gateway list-advertised-routes -g $rg -n $AzurehubName-ergw -o table --peer $(az network vnet-gateway list-bgp-peer-status -g $rg -n $AzurehubName-ergw --query 'value[1].{ip:neighbor}' -o tsv)
  done
az network vnet-gateway list-learned-routes -g $rg -n $AzurehubName-ergw -o table

#Route Server config
# RS instance IPs
az network routeserver list --resource-group $rg --query '{IPs:[].virtualRouterIps}' 
# RS BGP Peerings
az network routeserver peering list --resource-group $rg --routeserver $AzurehubName-routeserver -o table 
# RS advertised routes to NVA1 and NVA2
array=($AzurehubName-nva1 $AzurehubName-nva2)
for nva in "${array[@]}"
  do
  echo Advertised routes from RS $AzurehubName-routeserver to $nva
  az network routeserver peering list-advertised-routes --resource-group $rg \
  --name $nva \
  --routeserver $AzurehubName-routeserver 
  done

# RS learned routes
array=($nvalb $nva2)
for nva in "${array[@]}"
  do
  echo Learned routes on RS $AzurehubName-routeserver from $nva
  az network routeserver peering list-learned-routes --resource-group $rg \
  --name $nva \
  --routeserver $AzurehubName-routeserver 
  done

#ExpressRoute Circuit Route Table
# Primary Circuit
az network express-route list-route-tables --path primary -n $ercircuit -g $rg  --peering-name AzurePrivatePeering -o table
# Secondary Circuit
az network express-route list-route-tables --path secondary -n $ercircuit -g $rg  --peering-name AzurePrivatePeering -o table

# Dump GCP dump routes.

# Testing assymetric traffic
#from avs
netcat -v -z 10.112.8.2 22
x=1; while true; do echo test $(( x++)) && netcat -v -z 10.112.8.2 22; sleep 5; done

#from onprem
netcat -v -z 10.154.0.2 22
x=1; while true; do echo test $(( x++)) && netcat -v -z 10.154.0.2 22; sleep 5; done

#Log on Azure Hub VM.
ssh dmauser@40.113.206.197  #hubvm

# Packet Capture on NVAs:
tcpdump -qn -i hn1 host 10.112.8.2 or host 10.154.0.2 and port 22

# Logon on GCP instances
# AVS
sudo gcloud compute ssh avs-dal-vm1 --zone=$zone

# Onprem
sudo gcloud compute ssh onprem-chi-vm1 --zone=$zone

# Add traceroute to the GCP VMs
apt update -y && apt install inetutils-traceroute -y

# Ping test 
#AVS
hostname -I
ping 10.112.8.2 -O

#OnPrem
hostname -I
ping 10.154.0.2 -O

# Test HA
sudo hping3 10.112.8.2 -S -p 22 -c 6 # From AVS
sudo hping3 10.154.0.2 -S -p 22 -c 6 # From On-prem

# 6) Misc/Troubleshooting
# Disable UDRs ## Disable Route Tables (bypass Firewall) - It restores default behavior of the original LAB without the Firewall.
az network vnet subnet update -n subnet1 -g $rg --vnet-name $AzurehubName-vnet --route-table "" --output none
az network vnet subnet update -n subnet1 -g $rg --vnet-name $Azurespoke1Name-vnet --route-table "" --output none
az network vnet subnet update -n subnet1 -g $rg --vnet-name $Azurespoke2Name-vnet --route-table "" --output none
az network vnet subnet update -n GatewaySubnet -g $rg --vnet-name $AzurehubName-vnet --route-table "" --output none

## Associating RT-Hub-to-NVA Hub Subnet1 (Hub and Spokes)
az network vnet subnet update -n subnet1 -g $rg --vnet-name $AzurehubName-vnet --route-table RT-Hub-to-NVA --output none
## Associating RT-Hub-to-NVA to Spoke 1 and 2.
az network vnet subnet update -n subnet1 -g $rg --vnet-name $Azurespoke1Name-vnet --route-table RT-Spoke-to-NVA --output none
az network vnet subnet update -n subnet1 -g $rg --vnet-name $Azurespoke2Name-vnet --route-table RT-Spoke-to-NVA --output none
## Associating RT-to-GWSubnet to GatewaySubnet
az network vnet subnet update -n GatewaySubnet -g $rg --vnet-name $AzurehubName-vnet --route-table RT-GWSubnet-to-NVA --output none

#Cleanup

#GCP
# Note use the same variables above twice to delete each enviroment
gcloud compute interconnects attachments delete $envname-vlan --region $region --quiet 
gcloud compute routers delete $envname-router --project=$project --region=$region --quiet
gcloud compute instances delete $envname-vm1 --project=$project --zone=$zone --quiet
gcloud compute firewall-rules delete $envname-allow-traffic-from-azure --quiet
gcloud compute networks subnets delete $envname-subnet --project=$project --region=$region --quiet
gcloud compute networks delete $envname-vpc --project=$project --quiet

#Azure
az group delete -g $rg --no-wait --yes
