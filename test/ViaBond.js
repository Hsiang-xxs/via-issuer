const assert = require("chai").assert;
const truffleAssert = require('truffle-assertions');

const Factory = artifacts.require('Factory');
const Bond = artifacts.require('Bond');
const stringutils = artifacts.require('stringutils');
const ABDKMathQuad = artifacts.require('ABDKMathQuad');
const ViaOracle = artifacts.require('ViaOracle');
const Token = artifacts.require('Token');

web3.setProvider("http://127.0.0.1:8545");

contract("BondContractSize", function(accounts) {
    it("get the size of the Bond contract", function() {
      return Bond.deployed().then(function(instance) {
        var bytecode = instance.constructor._json.bytecode;
        var deployed = instance.constructor._json.deployedBytecode;
        var sizeOfB  = bytecode.length / 2;
        var sizeOfD  = deployed.length / 2;
        console.log("size of bytecode in bytes = ", sizeOfB);
        console.log("size of deployed in bytes = ", sizeOfD);
        console.log("initialisation and constructor code in bytes = ", sizeOfB - sizeOfD);
      });  
    });
  });

contract("IssuingViaUSDBond", async (accounts) => {
    it("should send ether to Via-USD bond contract and then get some Via-USD bond tokens to sender (issuer)", async () => {
        var abdkMathQuad = await ABDKMathQuad.deployed();
        await Bond.link(abdkMathQuad);

        var factory = await Factory.deployed();
        var bond = await Bond.deployed();
        var oracle = await ViaOracle.deployed();  
        var token = await Token.deployed();  
        
        await factory.createIssuer(bond.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Bond"), oracle.address, token.address);
        
        var viausdBondAddress = await factory.tokens(0);
        var viausdBondName = await web3.utils.hexToUtf8(await factory.getName(viausdBondAddress));
        var viausdBondType = await web3.utils.hexToUtf8(await factory.getType(viausdBondAddress));
        var viausdBond = await Bond.at(viausdBondAddress);

        console.log(viausdBondName, viausdBondType, "token address:", viausdBondAddress);
        console.log(viausdBondName, viausdBondType, "token contract ether balance before sending ether:", await web3.eth.getBalance(viausdBondAddress));
        console.log("Account address:", accounts[0]);
        console.log("Account ether balance before sending ether:", await web3.eth.getBalance(accounts[0]));
        console.log("Account Via-USD bond token balance before sending ether:", await web3.utils.hexToNumberString(await web3.utils.toHex(await viausdBond.balanceOf(accounts[0]))));
        console.log();

        await viausdBond.sendTransaction({from:accounts[0], to:viausdBondAddress, value:1e18});
        console.log("Via-USD bond token contract ether balance after sending ether:", await web3.eth.getBalance(viausdBondAddress));
        console.log("Account ether balance after sending ether:", await web3.eth.getBalance(accounts[0]));  
        
        let callbackToViaOracle = await getFirstEvent(oracle.LogResult({fromBlock:'latest'}));
        await truffleAssert.createTransactionResult(oracle, callbackToViaOracle.transactionHash);

        console.log("Account Via-USD bond token balance after sending ether:", await web3.utils.hexToNumberString(await web3.utils.toHex(await viausdBond.balanceOf(accounts[0]))));
        
    });

    const getFirstEvent = (_event) => {
      return new Promise((resolve, reject) => {
        _event.once('data', resolve).once('error', reject)
      });
    }
});

contract("TransferViaUSDBond", async (accounts) => {
  it("should transfer Via-USD bond to another account", async () => {
      var abdkMathQuad = await ABDKMathQuad.deployed();
      await Bond.link(abdkMathQuad);

      var factory = await Factory.deployed();
      var bond = await Bond.deployed();
      var oracle = await ViaOracle.deployed(); 
      var token = await Token.deployed();   
      
      await factory.createIssuer(bond.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Bond"), oracle.address, token.address);
      
      var viausdBondAddress = await factory.tokens(0);
      var viausdBondName = await web3.utils.hexToUtf8(await factory.getName(viausdBondAddress));
      var viausdBondType = await web3.utils.hexToUtf8(await factory.getType(viausdBondAddress));
      var viausdBond = await Bond.at(viausdBondAddress);

      console.log(viausdBondName, viausdBondType, "token address:", viausdBondAddress);
      console.log(viausdBondName, viausdBondType, "token contract ether balance before sending ether:", await web3.eth.getBalance(viausdBondAddress));
      console.log("Account address:", accounts[0]);
      console.log("Account ether balance before sending ether:", await web3.eth.getBalance(accounts[0]));
      console.log("Account Via-USD bond token balance before sending ether:", await web3.utils.hexToNumberString(await web3.utils.toHex(await viausdBond.balanceOf(accounts[0]))));
      console.log();

      await viausdBond.sendTransaction({from:accounts[0], to:viausdBondAddress, value:1e18});
      console.log("Via-USD bond token contract ether balance after sending ether:", await web3.eth.getBalance(viausdBondAddress));
      console.log("Account ether balance after sending ether:", await web3.eth.getBalance(accounts[0]));  
      
      let callbackToViaOracle = await getFirstEvent(oracle.LogResult({fromBlock:'latest'}));
      await truffleAssert.createTransactionResult(oracle, callbackToViaOracle.transactionHash);

      console.log("Sender Via-USD bond token balance after sending ether and before transferring Via-USD bond:", await web3.utils.hexToNumberString(await web3.utils.toHex(await viausdBond.balanceOf(accounts[0]))));
      console.log("Receiver address:", accounts[1]);
      console.log("Receiver ether balance before Via-USD bond is transferred by sender:", await web3.eth.getBalance(accounts[1]));
      console.log("Receiver Via-USD bond token balance before receiving Via-USD bond:", await web3.utils.hexToNumberString(await web3.utils.toHex(await viausdBond.balanceOf(accounts[1]))));
      console.log();
      
      await viausdBond.transferFrom(accounts[0], accounts[1], 10);

      console.log("Sender ether balance after transferring Via-USD bond:", await web3.eth.getBalance(accounts[0]));
      console.log("Sender Via-USD bond token balance after transferring Via-USD bond:", await web3.utils.hexToNumberString(await web3.utils.toHex(await viausdBond.balanceOf(accounts[0]))));
      console.log("Receiver ether balance after Via-USD bond is transferred by sender:", await web3.eth.getBalance(accounts[1]));
      console.log("Receiver Via-USD bond token balance after receiving Via-USD bond:", await web3.utils.hexToNumberString(await web3.utils.toHex(await viausdBond.balanceOf(accounts[1]))));
  });

  const getFirstEvent = (_event) => {
    return new Promise((resolve, reject) => {
      _event.once('data', resolve).once('error', reject)
    });
  }
});

contract("ViaEURBondIssue", async (accounts) => {
  it("should send ether to Via-EUR bond contract and issue Via-EUR bonds to sender (issuer)", async () => {
    //this case is similar to the Via-USD Bond issue above
    //only difference is that this test requires two calls to the oracle instead of one in the Via-USD case
  });
});

contract("BondIssueForCashTokensOfDifferentCurrency", async (accounts) => {
  it("should send Via-USD cash tokens to Via-EUR bond contract and issue Via-EUR bonds to sender (purchaser)", async () => {
    //in this test cases, first ether should be sent from account[0] to Via-EUR bond contract to issue Via-EUR bonds to issuer
    //then, Via-USD cash tokens should be sent from account[1] to the Via-EUR bond contract which will transfer the issued Via-EUR bonds to the sender of the Via-USD cash tokens(purchaser)
  });
});

contract("BondIssueForCashTokensOfSameCurrency", async (accounts) => {
  it("should send Via-EUR cash tokens to Via-EUR bond contract and issue Via-EUR to sender (purchaser)", async () => {
    //in this test cases, first ether should be sent from account[0] to Via-EUR bond contract to issue Via-EUR bonds to issuer
    //then, Via-EUR cash tokens should be sent from account[1] to the Via-EUR bond contract which will transfer the issued Via-EUR bonds to the sender of the Via-EUR cash tokens(purchaser)
  });
});

contract("BondRedemptionByIssuerByReturningBonds", async (accounts) => {
  it("should send Via-EUR tokens to Via-EUR contract and get back ether paid in earlier", async () => {
    //in this test cases, first ether should be sent from account[0] to Via-EUR bond contract to issue Via-EUR bonds to issuer
    //then, the same Via-EUR bond tokens should be sent from account[0] to the Via-EUR bond contract which will transfer the ether paid in earlier to the sender of Via-EUR bond tokens (issuer)
  });
});

contract("BondRedemptionByIssuerByPayingCash", async (accounts) => {
  it("should send Via-USD cash tokens to Via-USD bond contract and pay out paid in ether and cash tokens by bond purchasers", async () => {
    //in this test cases, first ether should be sent from account[0] to Via-USD bond contract to issue Via-USD bonds to issuer
    //then, Via-EUR cash tokens should be sent from account[1] to the Via-USD bond contract to purchase Via-USD bond tokens issued
    //then, ether should be sent from account[2] to the Via-USD bond contract to purchase Via-USD bond contract to purchase Via-USD bond tokens issued
    //then, issuer of Via-USD bonds (account[0]) should send Via-USD cash tokens to the Via-USD bond contract which will return ether to account[2] and Via-EUR cash to account[1] paid in earlier
  });
});

contract("BondRedemptionByPurchasersWithIssuingCollateral", async (accounts) => {
  it("should send collateral for issuing bonds to purchasers if bond redemption is not done by issuer", async () => {
    //in this test cases, first ether should be sent from account[0] to Via-EUR bond contract to issue Via-EUR bonds to issuer
    //then, account[1] should send Via-USD cash tokens to the Via-EUR bond contract to purchase the issued Via-EUR bonds
    //then, account[1] should send the Via-EUR bond tokens back to the Via-EUR bond contract which should pay out the ether paid in for issue of the Via-EUR bonds to account[1] (the purchaser)
  });
});
