const Factory = artifacts.require('Factory');
const Cash = artifacts.require('Cash');
const stringutils = artifacts.require('stringutils');
const ABDKMathQuad = artifacts.require('ABDKMathQuad');
const oracle = artifacts.require('ViaOracle');

web3.setProvider("http://127.0.0.1:8545");

contract("CashContractSize", function(accounts) {
    it("get the size of the Cash contract", function() {
      return Cash.deployed().then(function(instance) {
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

contract("IssuingViaUSD", async (accounts) => {
    it("should send ether to Via-USD cash contract and then get some Via-USD cash tokens", async () => {
        var abdkMathQuad = await ABDKMathQuad.deployed();
        await Cash.link(abdkMathQuad);

        var factory = await Factory.deployed();
        var cash = await Cash.deployed();
        
        await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Cash"), oracle.address);
        
        var viausdCashAddress = await factory.tokens(0);
        var viausdCashName = await web3.utils.hexToUtf8(await factory.getName(viausdCashAddress));
        var viausdCashType = await web3.utils.hexToUtf8(await factory.getType(viausdCashAddress));

        console.log(viausdCashName, viausdCashType, "token address:", viausdCashAddress);
        console.log(viausdCashName, viausdCashType, "token contract ether balance before sending ether:", await web3.eth.getBalance(viausdCashAddress));
        console.log("Account address:", accounts[0]);
        console.log("Account ether balance before sending ether:", await web3.eth.getBalance(accounts[0]));
        
        var txHash = await web3.eth.sendTransaction({from:accounts[0], to:viausdCashAddress, value:1});
        
        console.log("Transaction hash", txHash);
        console.log("Via-USD cash token contract ether balance after sending ether:", await web3.eth.getBalance(viausdCashAddress));
        console.log("Account ether balance after sending ether:", await web3.eth.getBalance(accounts[0]));
        //to do : check Via-USD balance in sender account
    });
});

//to do :
contract("ViaUSDExchange", async (accounts) => {
  it("should send Via-USD to Via-EUR cash contract and then get some Via-EUR cash tokens", async () => {

  });
});

//to do :
contract("ViaUSDRedemption", async (accounts) => {
  it("should send Via-USD to Via-USD cash contract and then get ether sent during issuing process", async () => {

  });
});

// to do :
contract("TransferViaUSD", async (accounts) => {
  it("should transfer Via-USD to another account", async () => {

  });
});
