# Compare ER to ER transit solutions

## Introduction

## Compare solutions

For ER to ER transit there are multiple solutions. Below is the list of the well known solutions:

1) ExpressRoute Global Reach
2) Single HUB using ER and IPSec VPN over ER Private or Microsoft Peering and allow VPN/ER transit using Azure Route Server.
3) Azure Route Server using NVA and route hairpinning.
4) Azure Virtual WAN with AzureFirewall (aka Secured vHUB) and routing Intent (currently in public preview)
5) Multi Hub with NVA+ARS

We can list some advantages and disadvantages of each solution:

|Solution| Pros | Cons| Hub/Spoke and vWAN | Notes |
|---|---|---|---|---|
| **1) ER Global Reach** |Easiest to implement |No suitable when inspection is required in the Cloud |Both |Traffic inspection can be done on either branch side or both |
| | |Global reach is not available in all locations |||
| | |Cannot be used on ER Local SKUs |||
| **2) ARS with NVA and Hairpinning** |Traffic can be inspected in the Cloud | UDR required to steer traffic to NVA| Hub/Spoke |Assessment of existing routing has to be done before implement solution
| | Can be used on ER Local SKUs |  |  | 
| | Support for 3rd Party NVAs |  |  | 
| **3) Secured vHUB and Routing Intent** (Preview) |Traffic can be inspected in the Cloud | No support for 3rd party NVAs at this time (Azure Firewall only)  | vWAN |  Assessment of existing routing has to be done before implement solution
| | Can be used on ER Local SKUs | |  |
| **4) ER and IPsec VPN over ER with ARS** |Traffic can be inspected in the Cloud | Require extra VPN devices to setup IPSec over ER private or Microsoft peering | Both | For traffic inspection Hub/Spoke can use Firewall/NVA in the Hub using UDRs, while vWAN can use Secured Hub + Routing Policies/Intent)
| | Can be used on ER Local SKUs | IPSec has limited throughput (around 1.2 Gbps per tunnel) |  | For Hub/Spoke deployments Azure Route Server will allow transit between ER and VPN
| | |||  vWAN deployments have built-in Route Service to allow route propagation and transit between ER and VPN
| **5) Multi Hub with NVAs+ARS** |Traffic can be inspected in the Cloud | Very complex to implement and maintain | Hub/Spoke |  |
| | Can be used on ER Local SKUs |  |


## Architecture Diagram

## Lab this solution
