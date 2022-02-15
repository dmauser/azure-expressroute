# ER to ER transit using NVAs/ARS and reverse hairpinning

## Concepts

On this post we're going to go over on how to allow two or more ExpressRoute (ER) circuits to transit traffic between them using Azure Route Server and reverse hairpinning traffic between them.

It is important to mention you can build your Azure network using two models: Hub and Spoke and Virtual WAN. This post will focus on the solution for Hub and Spoke by leveraging Azure Route Server and a network virtual appliance (NVA) to inject routes and create the conditions to the traffic hairpin over the NVA between two remote locations going over ER circuits.

### When to use this solution

This solution maybe not suitable for all scenarios but should be used an additional option to the other solutions already validated. The other solutions that are already established maybe better suitable to your requirements and/or easier to implement. Therefore, it is recommended to take a look on pros and cons of each solution depending on your requirements.

This solution tries to address the following potential requirements:

- Global Reach is not available in my location or an ER circuit already Local SKU in place.
- Traffic inspection is required over Azure.

This solution can also be used for other scenarios that have connectivity using ExpressRoute such as Azure VMware Solutions (AVS), SAP Hana Large Instances (SAP HLI), or Skytap.

Fore more information about similar solution consult [Compare solutions to enable ER to ER transit]().

## Architecture Diagram

This solution uses a NVA and Azure Route Server using and "attracting" traffic by using route summaries and making the traffic to hairpin over the NVA to reach both side. 



### Components



###

This solution relies on using summary routes and other routing techniques to allow the NVA attract unknown routes from each other side. Therefore, there's no direct route exchange between ER Circuits.


## Lab this solution

