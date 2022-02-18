# Express Route to Express Route transit

This repo is dedicated to consolidate information about ExpressRoute (ER) to ExpressRoute transit scenarios:

## Articles in this repo

- Compare ER to ER transit solutions (coming soo)

**Hub and Spoke**
- [ER to ER transit using NVAs/ARS and reverse hairpin](https://github.com/dmauser/azure-expressroute/tree/main/er-to-er-transit/ars)
    - [LAB this solution](https://github.com/dmauser/azure-expressroute/tree/main/er-to-er-transit/ars/lab)

**Azure Virtual WAN**
- [ER to ER transit using vWAN + Azure Firewall with Routing Intent](https://github.com/dmauser/azure-expressroute/tree/main/er-to-er-transit/vwan)

## Microsoft Docs

- [ExpressRoute Global Reach](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-global-reach)
- [Azure Route Server](https://docs.microsoft.com/en-us/azure/route-server/overview)
- [Virtual WAN Hub routing intent and routing policies](https://docs.microsoft.com/en-us/azure/virtual-wan/how-to-routing-policies)
- [Azure VMWare Solutions - Scenario 2: Third-party NVA in Azure Virtual Network with Azure Route Server, with Global Reach disabled](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/azure-vmware/eslz-network-topology-connectivity#scenario-2-third-party-nva-in-azure-virtual-network-with-azure-route-server-with-global-reach-disabled)

## Recommended references

- [Enable Transit Between ExpressRoute Circuits without Using Global Reach](https://github.com/jocortems/azurehybridnetworking/tree/main/ExpressRoute-Transit-with-Azure-RouteServer)
- [Inspecting Traffic across ExpressRoute Circuits in Azure](https://github.com/jocortems/azurehybridnetworking/tree/main/Inspect-Traffic-Between-ExpressRoute-Circuits)
- [Connecting from On Premises to Azure VMware Solution](https://github.com/Azure/AzureCAT-AVS/tree/main/networking)
