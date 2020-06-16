# Via Issuer for cash and zero coupon bond tokens
The objective of this project is to create a reference implementation for issue of the Via stablecoin on ethereum, so that developers can create similar implementations on other blockchain platforms. 

This implementation follows the ERC20 standard because we want the Via to be usable across currently used wallets and on crypto exchanges. 


## How does the Via stablecoin work ?
1. The Via stablecoin is NOT one cash token but multiple tokens for different fiat currencies (eg, Via-USD for US dollar, Via-EUR for the Euro, etc)

2. Users can purchase the Via cash tokens using ether and also fiat currencies. Currently, the implementation only allows ether as we need banking integration for paying in of fiat currencies for issue of Via.

3. Users can also redeem (return) Via cash tokens and they can choose to take ether in return or some other Via cash token in return. Eg, a user can choose to redeem Via-USD and take Via-EUR. Current implementation only redeems Via cash tokens for ether, but we need to change this so that users can redeem one Via cash token for another.

4. The price of the Via cash tokens are stabilized (so it is a stablecoin) by using a set of interest rates on the Via cash tokens. Interest rates regulate demand and supply and thus price of Via cash tokens. The current implementation supports borrowing and redemption of Via bonds. Bonds are simply loans. However, unlike regular loans that require the borrower to pay an interest at a periodic interval, the Via bonds for different fiat currencies are zero coupon bonds - these are bonds that are issued in such a way that the interest is paid upfront. So, if a user buys (borrows) a zero coupon bond whose face value is USD 100, the user may get a bond (loan) of only USD 80. 

5. Exchange rates between Via cash token pairs and Interest rates on Via bond tokens are calculated externally to this system (the Via oracle). The Via oracle captures events emitted by the issuer (eg, sold, lent, redeemed) and uses them in combination with prevailing interest and exchange rates between fiat currency pairs to price Via cash and bond tokens. This pricing is available to the issuer in turn using an Oracle contract.


## Things that need to be looked at 

1. we need wallet users to buy via cash tokens and via bond tokens. while we have got a payable buy() function, will this work in wallets ?

2. the buy() function only takes in ether now. How can we enable buyers of via cash tokens and bond tokens to use via cash tokens itself to make purchases of other cash and bond tokens ? Eg, using Via-USD to purchase Via-EUR.

3. whereas we have a sell() function for redemption which takes 'amount' and 'currency' to redeem (eg, redeem 100 Via-USD), how can we accept another parameter that specifies another currency to redeem in (eg, Via-USD to Via-EUR) ? Right now, all redemption is done in ether by default.

4. we want lenders to approve of loans (ie, issue of bonds from their balances) - currently, this is not happening.

5. we want to support 20 fiat currencies eventually atleast, going up from 3 now. The issuing, redemption, borrowing functions now are repeated for each cash and bond currency denomination. perhaps, we can avoid this ?


*NOTE:* Currently this reference implementation is under development and NOT FOR PRODUCTION.
