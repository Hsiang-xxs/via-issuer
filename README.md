# Via Issuer for cash and zero coupon bond tokens
The objective of this project is to create a reference implementation for issue of the Via stablecoin on ethereum, so that developers can create similar implementations on other blockchain platforms. 

This implementation follows the ERC20 standard because we want the Via to be usable across currently used wallets and on crypto exchanges. 


## How does the Via stablecoin work ?
1. The Via stablecoin is NOT one cash token but multiple tokens for different fiat currencies (eg, Via-USD for US dollar, Via-EUR for the Euro, etc)

2. Users can purchase the Via cash tokens using ether and also fiat currencies. Currently, the implementation only allows ether as we need banking integration for paying in of fiat currencies for issue of Via.

3. Users can also redeem (return) Via cash tokens and they can choose to take ether in return or some other Via cash token in return. Eg, a user can choose to redeem Via-USD and take Via-EUR. Current implementation only redeems Via cash tokens for ether, but we need to change this so that users can redeem one Via cash token for another.

4. The price of the Via cash tokens are stabilized (so it is a stablecoin) by using a set of interest rates on the Via cash tokens. Interest rates regulate demand and supply and thus price of Via cash tokens. The current implementation supports borrowing and redemption of Via bonds. Bonds are simply loans. However, unlike regular loans that require the borrower to pay an interest at a periodic interval, the Via bonds for different fiat currencies are zero coupon bonds - these are bonds that are issued in such a way that the interest is paid upfront. So, if a user buys (borrows) a zero coupon bond whose face value is USD 100, the user may get a bond (loan) of only USD 80. 


## Things that need to be looked at 

1. we need wallet users to buy via cash tokens and via bond tokens. while we have got a buy() function, will this work ?

2. whereas we have a sell() function for redemption which takes 'amount' and 'currency' to redeem (eg, redeem 100 Via-USD), how can we accept another parameter that specifies another currency to redeem in (eg, Via-USD to Via-EUR) ? Right now, all redemption is done in ether by default.

3. we want lenders to approve of loans (ie, issue of bonds from their balances) - currently, this is not happening.


*NOTE:* Currently this reference implementation is under development NOT FOR PRODUCTION.
