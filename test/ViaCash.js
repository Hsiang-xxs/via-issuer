const Factory = artifacts.require('Factory');
const Cash = artifacts.require('Cash');
const stringutils = artifacts.require('stringutils');
const ABDKMathQuad = artifacts.require('ABDKMathQuad');
const ViaOracle = artifacts.require('ViaOracle');

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
        
        var oracle = await ViaOracle.deployed();
        ViaOracle.setProvider(web3.currentProvider);        
        
        await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Cash"), oracle.address);
        
        var viausdCashAddress = await factory.tokens(0);
        var viausdCashName = await web3.utils.hexToUtf8(await factory.getName(viausdCashAddress));
        var viausdCashType = await web3.utils.hexToUtf8(await factory.getType(viausdCashAddress));
        var viausdCash = await Cash.at(viausdCashAddress);

        console.log(viausdCashName, viausdCashType, "token address:", viausdCashAddress);
        console.log(viausdCashName, viausdCashType, "token contract ether balance before sending ether:", await web3.eth.getBalance(viausdCashAddress));
        console.log("Account address:", accounts[0]);
        console.log("Account ether balance before sending ether:", await web3.eth.getBalance(accounts[0]));
        console.log("Account Via-USD cash token balance before sending ether:", await viausdCash.balanceOf(accounts[0]));
        
        var txHash = await web3.eth.sendTransaction({from:accounts[0], to:viausdCashAddress, value:1e18});
        // await viausdCash.sendTransaction({from:accounts[0], to:viausdCashAddress, value:1e18});
        
        console.log("Transaction hash", txHash);
        console.log("Via-USD cash token contract ether balance after sending ether:", await web3.eth.getBalance(viausdCashAddress));
        console.log("Account ether balance after sending ether:", await web3.eth.getBalance(accounts[0]));
        console.log("Account Via-USD cash token balance after sending ether:", await viausdCash.balanceOf(accounts[0]));
        //to do : check Via-USD balance in sender account
    });
});
/*
contract("ViaUSDExchange", async (accounts) => {
  it("should send Via-USD to Via-EUR cash contract and then get some Via-EUR cash tokens", async () => {
    var abdkMathQuad = await ABDKMathQuad.deployed();
    await Cash.link(abdkMathQuad);

    var factory = await Factory.deployed();
    var cash = await Cash.deployed();
    
    await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Cash"), oracle.address);
    
    var viausdCashAddress = await factory.tokens(0);
    var viausdCashName = await web3.utils.hexToUtf8(await factory.getName(viausdCashAddress));
    var viausdCashType = await web3.utils.hexToUtf8(await factory.getType(viausdCashAddress));
    var viausdCash = await Cash.at(viausdCashAddress);

    var viaeurCashAddress = await factory.tokens(1);
    var viaeurCashName = await web3.utils.hexToUtf8(await factory.getName(viaeurCashAddress));
    var viaeurCashType = await web3.utils.hexToUtf8(await factory.getType(viaeurCashAddress));
    var viaeurCash = await Cash.at(viaeurCashAddress);

    console.log(viausdCashName, viausdCashType, "token address:", viausdCashAddress);
    console.log(viausdCashName, viausdCashType, "token contract ether balance before sending ether:", await web3.eth.getBalance(viausdCashAddress));
    console.log(viaeurCashName, viaeurCashType, "token address:", viaeurCashAddress);
    console.log(viaeurCashName, viaeurCashType, "token contract ether balance before sending ether:", await web3.eth.getBalance(viaeurCashAddress));
    console.log("Account address:", accounts[0]);
    console.log("Account ether balance before sending ether:", await web3.eth.getBalance(accounts[0]));
    console.log("Account Via-USD cash token balance before sending ether:", await viausdCash.balanceOf(accounts[0]));
    console.log("Account Via-EUR cash token balance before sending ether:", await viaeurCash.balanceOf(accounts[0]));
    
    var txHash = await web3.eth.sendTransaction({from:accounts[0], to:viausdCashAddress, value:1e18});
    // await viausdCash.sendTransaction({from:accounts[0], to:viausdCashAddress, value:1e18});
    
    console.log("Transaction hash", txHash);
    console.log("Via-USD cash token contract ether balance after sending ether and before sending Via-USD:", await web3.eth.getBalance(viausdCashAddress));
    console.log("Via-EUR cash token contract ether balance after sending ether and before sending Via-USD:", await web3.eth.getBalance(viaeurCashAddress));
    console.log("Account ether balance after sending ether and before sending Via-USD:", await web3.eth.getBalance(accounts[0]));
    console.log("Account Via-USD cash token balance after sending ether and before sending Via-USD:", await viausdCash.balanceOf(accounts[0]));
    console.log("Account Via-EUR cash token balance after sending ether and before sending Via-USD:", await viaeurCash.balanceOf(accounts[0]));
    
    await viausdCash.transferFrom(accounts[0], viaeurCashAddress, 10);

    console.log("Via-USD cash token contract ether balance after sending Via-USD:", await web3.eth.getBalance(viausdCashAddress));
    console.log("Via-EUR cash token contract ether balance after sending Via-USD:", await web3.eth.getBalance(viaeurCashAddress));
    console.log("Account ether balance after sending Via-USD:", await web3.eth.getBalance(accounts[0]));
    console.log("Account Via-USD cash token balance after sending Via-USD:", await viausdCash.balanceOf(accounts[0]));
    console.log("Account Via-EUR cash token balance after sending Via-USD:", await viaeurCash.balanceOf(accounts[0]));
  });
});

contract("ViaUSDRedemption", async (accounts) => {
  it("should send Via-USD to Via-USD cash contract and then get ether sent during issuing process", async () => {
    var abdkMathQuad = await ABDKMathQuad.deployed();
    await Cash.link(abdkMathQuad);

    var factory = await Factory.deployed();
    var cash = await Cash.deployed();
    
    await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Cash"), oracle.address);
    
    var viausdCashAddress = await factory.tokens(0);
    var viausdCashName = await web3.utils.hexToUtf8(await factory.getName(viausdCashAddress));
    var viausdCashType = await web3.utils.hexToUtf8(await factory.getType(viausdCashAddress));
    var viausdCash = await Cash.at(viausdCashAddress);

    console.log(viausdCashName, viausdCashType, "token address:", viausdCashAddress);
    console.log(viausdCashName, viausdCashType, "token contract ether balance before sending ether:", await web3.eth.getBalance(viausdCashAddress));
    console.log("Account address:", accounts[0]);
    console.log("Account ether balance before sending ether:", await web3.eth.getBalance(accounts[0]));
    console.log("Account Via-USD cash token balance before sending ether:", await viausdCash.balanceOf(accounts[0]));
    
    var txHash = await web3.eth.sendTransaction({from:accounts[0], to:viausdCashAddress, value:1e18});
    // await viausdCash.sendTransaction({from:accounts[0], to:viausdCashAddress, value:1e18});
    
    console.log("Transaction hash", txHash);
    console.log("Via-USD cash token contract ether balance after sending ether and before sending Via-USD:", await web3.eth.getBalance(viausdCashAddress));
    console.log("Account ether balance after sending ether and before sending Via-USD:", await web3.eth.getBalance(accounts[0]));
    console.log("Account Via-USD cash token balance after sending ether and before sending Via-USD:", await viausdCash.balanceOf(accounts[0]));
    
    await viausdCash.transferFrom(accounts[0], viausdCashAddress, 10);

    console.log("Via-USD cash token contract ether balance after sending Via-USD:", await web3.eth.getBalance(viausdCashAddress));
    console.log("Account ether balance after sending Via-USD:", await web3.eth.getBalance(accounts[0]));
    console.log("Account Via-USD cash token balance after sending Via-USD:", await viausdCash.balanceOf(accounts[0]));
  });
});*/

contract("TransferViaUSD", async (accounts) => {
  it("should transfer Via-USD to another account", async () => {
    var abdkMathQuad = await ABDKMathQuad.deployed();
    await Cash.link(abdkMathQuad);

    var factory = await Factory.deployed();
    var cash = await Cash.deployed();
    var oracle = await ViaOracle.deployed();
    
    await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Cash"), oracle.address);
    
    var viausdCashAddress = await factory.tokens(0);
    var viausdCashName = await web3.utils.hexToUtf8(await factory.getName(viausdCashAddress));
    var viausdCashType = await web3.utils.hexToUtf8(await factory.getType(viausdCashAddress));
    var viausdCash = await Cash.at(viausdCashAddress);

    console.log(viausdCashName, viausdCashType, "token address:", viausdCashAddress);
    console.log(viausdCashName, viausdCashType, "token contract ether balance before sending ether:", await web3.eth.getBalance(viausdCashAddress));
    console.log("Sender address:", accounts[0]);
    console.log("Sender ether balance before sending ether:", await web3.eth.getBalance(accounts[0]));
    console.log("Sender Via-USD cash token balance before sending ether:", await viausdCash.balanceOf(accounts[0]));
    
    var txHash = await web3.eth.sendTransaction({from:accounts[0], to:viausdCashAddress, value:1e18});
    // await viausdCash.sendTransaction({from:accounts[0], to:viausdCashAddress, value:1e18});
    
    console.log("Transaction hash", txHash);
    console.log("Via-USD cash token contract ether balance after sending ether:", await web3.eth.getBalance(viausdCashAddress));
    console.log("Sender ether balance after sending ether and before sending Via-USD:", await web3.eth.getBalance(accounts[0]));
    console.log("Sender Via-USD cash token balance after sending ether and before sending Via-USD:", await viausdCash.balanceOf(accounts[0]));
    console.log("Receiver address:", accounts[1]);
    console.log("Receiver ether balance before sending Via-USD:", await web3.eth.getBalance(accounts[1]));
    console.log("Receiver Via-USD cash token balance before sending Via-USD:", await viausdCash.balanceOf(accounts[1]));
    
    await viausdCash.transferFrom(accounts[0], accounts[1], 10);

    console.log("Sender ether balance after sending Via-USD:", await web3.eth.getBalance(accounts[0]));
    console.log("Sender Via-USD cash token balance after sending Via-USD:", await viausdCash.balanceOf(accounts[0]));
    console.log("Receiver ether balance after sending Via-USD:", await web3.eth.getBalance(accounts[1]));
    console.log("Receiver Via-USD cash token balance after sending Via-USD:", await viausdCash.balanceOf(accounts[1]));
  });
});
