# Azure ExpressRoute

## Articles and Labs in this repo

- [Transit between ExpressRoute circuits](https://github.com/dmauser/azure-expressroute/tree/main/er-to-er-transit) - It includes a lab.
- [Deploying Local SKU ExpressRoute Circuits](https://github.com/dmauser/Lab/tree/master/ExpressRoute-local)
- **LAB**: [Azure VPN/ER Coexistence using GCP as On-premises](https://github.com/dmauser/azure-er-vpn-coexistence)
- **LAB**: [Verify BGP information on Azure VPN and ExpressRoute Gateways](https://github.com/dmauser/Lab/tree/master/ER-and-VPN-Gateway-BGP-info)

## Resources list

There's a mix of Microsoft official Docs and other relevant information outside of the official Docs. You may see notes in some of the links with important points based on my experience interacting with customers.

### Overview

1. [ExpressRoute FAQ](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-faqs)
2. [ExpressRoute Partners and Locations](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-locations)
3. [ExpressRoute Pricing Details](https://azure.microsoft.com/en-us/pricing/details/expressroute/)
4. [ExpressRoute SLAs](https://azure.microsoft.com/en-us/support/legal/sla/expressroute/v1_3/)
5. [ExpressRoute Technical Overview](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-introduction)
6. [ExpressRoute Gateway Overview](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-about-virtual-network-gateways)
7. [ExpressRoute Circuit vs Peerings](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-circuit-peerings)

### Prepare for your ExpressRoute Deployment

1. [ExpressRoute Prerequisites](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-prerequisites)
2. [Workflows for Configuring ExpressRoute](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-workflows)
3. [Prepare your Routing for ExpressRoute Peerings](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-routing)
4. [Route Optimization](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-optimize-routing)

### Create your ExpressRoute Circuit

1. [Create and Modify an ER Circuit](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-circuit-portal-resource-manager)
2. [Create and Modify Routing for an ER Circuit](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-routing-portal-resource-manager)

### Private Peering configuration

1. [Create the Azure Private Peering](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-routing-portal-resource-manager#private)
2. [Create an ExpressRoute Virtual Gateway](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-add-gateway-portal-resource-manager)
3. [Link a Virtual Network to an ER Circuit](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-linkvnet-portal-resource-manager)

### Microsoft Peering configuration

1. [ExpressRoute NAT Requirements](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-nat)
2. [Create the MSFT Peering](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-routing-portal-resource-manager#msft)
3. [Create and Apply a Route Filter](https://docs.microsoft.com/en-us/azure/expressroute/how-to-routefilter-portal)

### Disaster Recovery, High Availability, and Route Optimization

1. [Designing for Disaster Recovery with the Private Peering](https://docs.microsoft.com/en-us/azure/expressroute/designing-for-disaster-recovery-with-expressroute-privatepeering)
2. [Designing for High Availability](https://docs.microsoft.com/en-us/azure/expressroute/designing-for-high-availability-with-expressroute)
3. [VPN Backup for ExpressRoute using the Azure VPN Gateway](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-coexist-resource-manager)

### ExpressRoute Direct

1. [About ExpressRoute Direct](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-erdirect-about)
2. [How to Configure ExpressRoute Direct](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-erdirect)

### ExpressRoute Encryption options

1. [ExpressRoute encryption](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-about-encryption)

    **[DM comment]** There are two options: IPsec (end-to-end) encryption versus MACsec (poin-to-point) encryption. IPSec can be used in any Circuit type (with Provider provisioning Model or Direct) but MACSec can only be used in Direct model. Keep in mind single IPSec tunnel throughput is limited to 1.2 Gbps (workaround is to build multiple IPSec tunnels).

2. [Configure a site-to-site VPN over ExpressRoute Microsoft peering](https://docs.microsoft.com/en-us/azure/expressroute/site-to-site-vpn-over-microsoft-peering)
3. [Configure a Site-to-Site VPN connection over ExpressRoute private peering](https://docs.microsoft.com/en-us/azure/vpn-gateway/site-to-site-vpn-private-peering?toc=/azure/expressroute/toc.json)
4. [Configure IPsec transport mode for ExpressRoute private peering](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-ipsec-transport-private-windows)
5. [Configure MACsec on ExpressRoute Direct ports](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-macsec)

### ExpressRoute Global Reach

1. [ExpressRoute Global Reach](https://docs.microsoft.com/en-us/azure/expressroute/expressroute-global-reach)

### Monitoring