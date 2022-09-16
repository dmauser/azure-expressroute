- ER Direct Ports bandwidth availability:

 List available bandwidths in all ER Direct locations:

```Bash
locations=$(az network express-route port location list --query [].name --output tsv)
for location in $locations
 do
 az network express-route port location show --location $location \
 --query "{name:name, availableBandwidths1:availableBandwidths[0].offerName, availableBandwidths2:availableBandwidths[1].offerName}" \
 -o tsv
done
```

- Dump ExpressRoute route table (Private Peering):

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
