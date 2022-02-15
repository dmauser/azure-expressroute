# ER to ER transit using NVAs/ARS and reverse hairpinning

## Concepts

On this post we're going to go over on how to allow two or more ExpressRoute (ER) circuits to transit traffic between them using Azure Route Server and reverse hairpinning traffic between them.

It is important to mention you can build your Azure network using two models: Hub and Spoke and Virtual WAN. This post will focus on the solution for Hub and Spoke by leveraging Azure Route Server and a network virtual appliance (NVA) to inject routes and create the conditions to the traffic hairpin over the NVA between two remote locations going over ER circuits.

### When to use this solution

This solution maybe not suitable for all scenarios but as an additional option to the other solutions listed below to accomplish the same. The other solutions already established maybe better suitable to your requirements and/or easier to implement.

### How this solution works

This solution relies on using summary routes and other routing techniques to allow the NVA attract unknown routes from each other side. Therefore, there's no direct route exchange between ER Circuits.

### Compare solutions

For ER to ER transit there are muiltiples options that can be taken in consideraion:

1) ExpressRoute Global Reach
2) Single HUB using ER and IPSec VPN over ER and allow VPN/ER transit.
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
| **3) Secured vHUB and Routing Intent** (Preview) |Traffic can be inspected in the Cloud | Azure Firewall is the only support solution at this time  | vWAN |  Assessment of existing routing has to be done before implement solution
| **4) ER and IPsec VPN over ER** |Traffic can be inspected in the Cloud | Require extra VPN devices to setup IPSec over ER private peering | Both | For traffic inspection Hub/Spoke can use Firewall/NVA in the Hub using UDRs, while vWAN can use Secured Hub + Routing Policies/Intent)
| | Can be used on ER Local SKUs ||  | For Hub/Spoke deployments Azure Route Server will allow transit between ER and VPN
| | |||  vWAN deployments have built-in Route Service to allow route propagation and transit between ER and VPN
| **5) Multi Hub with NVAs+ARS** |Traffic can be inspected in the Cloud | Very complex to implement and maintain | Hub/Spoke |  |
| | Can be used on ER Local SKUs |  |


## Architecture Diagram

## Lab this solution
