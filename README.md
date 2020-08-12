# Via Issuer for cash and zero coupon bond tokens
The objective of this project is to create a reference implementation for issue of the Via stablecoin on ethereum, so that developers can create similar implementations on other blockchain platforms. 

This implementation follows the ERC20 standard because we want the Via to be usable across currently used wallets and on crypto exchanges. 


## How does the Via stablecoin work ?
1. The Via stablecoin is NOT one cash token but multiple tokens for different fiat currencies (eg, Via-USD for US dollar, Via-EUR for the Euro, etc)

2. Users can purchase the Via cash tokens using ether and also fiat currencies. Currently, the implementation only allows ether as we need banking integration for paying in of fiat currencies for issue of Via. Ether should be able to be paid in using commonly available wallets.

3. Users can also redeem (return) Via cash tokens and they can choose to take ether in return or some other Via cash token in return. Eg, a user can choose to redeem Via-USD and take Via-EUR. 

4. The price of the Via cash tokens are stabilized (so it is a stablecoin) by using a set of interest rates on the Via cash tokens. Interest rates regulate demand and supply and thus price of Via cash tokens. The current implementation supports buying of Via bonds denominated in multiple currencies with cash tokens denominated in corresponding currencies. Bonds are simply loans. However, unlike regular loans that require the borrower to pay an interest at a periodic interval, the Via bonds for different fiat currencies are zero coupon bonds - these are bonds that are issued in such a way that the interest is paid upfront. So, if a user buys (borrows) a zero coupon bond whose face value is USD 100, the user may get a bond (loan) of only USD 80. Like cash tokens, bonds can be redeemed back into cash tokens. 

5. Exchange rates between Via cash token pairs and Interest rates on Via bond tokens are calculated externally to this system (the Via oracle). The Via oracle captures events emitted by the issuer (eg, sold, lent, redeemed) and uses them in combination with prevailing interest and exchange rates between fiat currency pairs to price Via cash and bond tokens. This pricing is available to the issuer in turn using an Oracle contract.

## Steps

### To build and deploy locally:
1.  To compile the project, change to the root of the directory where the project is located:\
``` cd <the root of the directory where the project is located> ```

2.  ``` truffle compile ```

3.  For local testing make sure to have a test blockchain such as Ganache or [Ganache Cli] installed and running before executing migrate:

If you use Ganache, please directly open the Ganache and create *NEW WORKSPACE*, and then add the truffle-config.js or truffle.js file to this workspace, note to set the *PORT NUMBER*.

If you use the [Ganache Cli] for the test. please open the new terminal window and run the ganache-cli first:\
``` ganache-cli --allowUnlimitedContractSize ```

4.  ``` truffle migrate ```

### To compile and deploy to the Ropsten testnet:

*Note: We have provided an account for test. The account and the mnemonic just for test, please don’t use on mainnet.*

1.  Install HDWalletProvider
Truffle's HDWalletProvider is a separate npm package. Please install it first:\
``` npm install @truffle/hdwallet-provider ```

2.  To compile the project, change to the root of the directory where the project is located:\
``` cd <the root of the directory where the project is located> ```

3.  ``` truffle compile ```

4.  Deploy to the Ropsten network:\
``` truffle migrate --network ropsten ```


[Ganache Cli]: https://github.com/trufflesuite/ganache-cli



*NOTE:* Currently this reference implementation is under development and NOT FOR PRODUCTION.
