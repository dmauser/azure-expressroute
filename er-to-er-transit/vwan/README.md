# ER to ER transit using vWAN + Azure Firewall with Routing Intent

## _Coming soon..._

## Architecture diagram

![ER to ER Transit using Routing Intent](./media/vwan-routing-intent.png)

### Consideration onboarding ER on AVS deployments

Ensure ExpressRoute Circuit is onboarded after you convert you vHub to Secured-vHub + Routing Intent. Otherwise when you select Internet traffic all connections will get default propagation enabled and that can have implication in case On-premises expressroute has is also connected to other Hub.

After you onboard both ExpressRoute circuits (On-Prem and AVS), make sure only AVS will have Internet Traffic Secured by Azure Firewall.

