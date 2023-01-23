# ER miscellaneous scripts

**Content**

- [ER Direct Ports bandwidth availability](#er-direct-ports-bandwidth-availability)
- [Dump ExpressRoute route table (Private Peering)](#dump-expressroute-route-table-private-peering)
- [Overprovisioning ER Circuits on top of ER Direct ports](#overprovisioning-er-circuits-on-top-of-er-direct-ports)

### ER Direct Ports bandwidth availability


List available bandwidths in all ER Direct locations:

**Note:** use Bash to run the scripts below. They will not work over PowerShell.
Alternatively, you can use [Azure Cloud Shell Bash](https://shell.azure.com/)

```Bash
#!/bin/bash
### ER Direct Ports bandwidth availability

# Validate AllowExpressRoutePorts feature
state=$(az feature show --name AllowExpressRoutePorts --namespace Microsoft.Network --query properties.state -o tsv)
if [ $state != Registered ]
then 
 az feature register --name AllowExpressRoutePorts --namespace Microsoft.Network --output none
 while [[ $prState != 'Registered' ]];
 do
    prState=$(az feature show --name AllowExpressRoutePorts --namespace Microsoft.Network --query properties.state -o tsv)
    echo "AllowExpressRoutePorts provisioningState="$prState
    sleep 5
done
fi

locations=($(az network express-route port location list --query "[].name" --output tsv))
for location in $locations
 do
 az network express-route port location show --location $location \
 --query "{name:name, availableBandwidths1:availableBandwidths[0].offerName, availableBandwidths2:availableBandwidths[1].offerName}" \
 -o tsv
done
```

Sample script [output](https://raw.githubusercontent.com/dmauser/azure-expressroute/main/er-misc/files/er-direct-output.txt).

### Dump ExpressRoute route table (Private Peering)

```Bash
# Dump ER Circuit routes
#ExpressRoute Circuit Route Table
rg=er-circuits # Set resource group
ercircuit=ER-DAL-Demo-Circuit1 #Set ER Circuit Name
# Primary Circuit
az network express-route list-route-tables --path primary -n $ercircuit -g $rg  --peering-name AzurePrivatePeering --query value -o table
# Secondary Circuit
az network express-route list-route-tables --path secondary -n $ercircuit -g $rg  --peering-name AzurePrivatePeering --query value -o table
```

### Overprovisioning ER Circuits on top of ER Direct ports

Before continuing, please review the official [ER Direct documentation](https://aka.ms/erdirect)

Here are some considerations:
- ExpressRoute Direct supports an overprovision factor of 2X. Customers can configure up to 20Gb of ExpressRoute circuits on a 10G ExpressRoute Direct and 200G of circuits on a 100G ExpressRoute Direct.

- Note that Azure Portal only allows you to create ExpressRoute circuits up to the ER Direct bandwidth interface. To overprovision beyond 10G or 100G circuits, you have to use CLI o PowerShell.

**Sample CLI Script**

The CLI script (Bash) below demonstrates how to overprovision ER circuits up to 17G on top of 10G ER Direct.

  1. Creates a 10G ER Direct port.
  2. Creates a 10G ER Circuit for Production.
  3. Creates a 5G ER Circuit for UAT.
  4. Creates a 2G ER Circuit for Dev.

   Note that 3G remains to get overprovisioned with either combination of two circuits (1G and 2G) or three circuits of 1G.

```Bash
#Variables
rg=er-circuits #Set Resource Group
location=centralus #Set Location
peeringlocation=Equinix-Dallas-DA3

#Create resource group
az group create --name $rg --location $location -o none

#Create 10G ER Direct Port
az network express-route port create \
 --name ER-Direct-Test \
 --resource-group $rg \
 --location $location \
 --peering-location $peeringlocation \
 --bandwidth 10 Gbps \
 --encapsulation Dot1Q

#Create 10G ExpressRoute Circuit for production
erdirectportid=$(az network express-route port list -g $rg --query [].id -o tsv)
az network express-route create \
 -g $rg \
 --name ER-Circuit-Production \
 --express-route-port $erdirectportid \
 --location $location \
 --sku-tier Standard \
 --bandwidth 10 Gbps \
 --peering-location $peeringlocation \
 --provider ''

#Create 5G ExpressRoute Circuit for UAT
erdirectportid=$(az network express-route port list -g $rg --query [].id -o tsv)
az network express-route create \
 -g $rg \
 --name ER-Circuit-UAT \
 --express-route-port $erdirectportid \
 --location $location \
 --sku-tier Standard \
 --bandwidth 5 Gbps \
 --peering-location $peeringlocation \
 --provider ''

#Create 5G ExpressRoute Circuit for DEV
erdirectportid=$(az network express-route port list -g $rg --query [].id -o tsv)
az network express-route create \
 -g $rg \
 --name ER-Circuit-DEV \
 --express-route-port $erdirectportid \
 --location $location \
 --sku-tier Standard \
 --bandwidth 2 Gbps \
 --peering-location $peeringlocation \
 --provider ''

#Validation:
az network express-route list \
--resource-group $rg \
--query '[].{name:name,Gbps:bandwidthInGbps,ErDirectPort:'expressRoutePort.id'}' \
--output table

#Sample output
Name                   Gbps    ErDirectPort
---------------------  ------  -------------------------------------------------------------------------------------------------------------------------------------------
ER-Circuit-DEV         2.0     /subscriptions/SubID/resourceGroups/er-circuits/providers/Microsoft.Network/expressRoutePorts/ER-Direct-Test
ER-Circuit-Production  10.0    /subscriptions/SubID/resourceGroups/er-circuits/providers/Microsoft.Network/expressRoutePorts/ER-Direct-Test
ER-Circuit-UAT         5.0     /subscriptions/SubID/resourceGroups/er-circuits/providers/Microsoft.Network/expressRoutePorts/ER-Direct-Test
```
