- ER Direct Ports bandwidth availability:

 List available bandwidths in all ER Direct locations:

 ```Bash
 locations=$(az network express-route port location list --query [].name --output tsv)
 for location in $locations
  do
  az network express-route port location show --location $location --query "{name:name, availableBandwidths1:availableBandwidths[0].offerName, availableBandwidths2:availableBandwidths[1].offerName}" -o tsv
 done
 ```
