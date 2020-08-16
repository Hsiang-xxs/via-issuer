const Factory = artifacts.require('Factory');
const Cash = artifacts.require('Cash');
const stringutils = artifacts.require('stringutils');
const ABDKMathQuad = artifacts.require('ABDKMathQuad');
//const cashABI = require('../build/Cash.json').abi;
//const cashBytecode = require('../build/contracts/Cash.json').bytecode;

web3.setProvider("http://127.0.0.1:8545");

contract("ViaUSDCash", async (accounts) => {
    it("should send ether to ViaUSDCash and then get some Via-USD cash tokens", async () => {
        var abdkMathQuad = await ABDKMathQuad.deployed();
        await Cash.link(abdkMathQuad);

        var factory = await Factory.deployed();
        var cash = await Cash.deployed();
        
        await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Cash"));
        
        var viausdCashAddress = await factory.tokens(0);
        var viausdCashName = await web3.utils.hexToUtf8(await factory.getName(viausdCashAddress));
        var viausdCashType = await web3.utils.hexToUtf8(await factory.getType(viausdCashAddress));
        var viausdCash = await Cash.at(viausdCashAddress);

        console.log(viausdCashName, viausdCashType, "token address:", viausdCashAddress);
        console.log(viausdCashName, viausdCashType, "token contract ether balacne before sending ether:", await web3.eth.getBalance(viausdCashAddress));
        console.log("Account address:", accounts[0]);
        console.log("Account ether balacne before sending ether:", await web3.eth.getBalance(accounts[0]));
        
        await viausdCash.sendTransaction({from:accounts[0], to:viausdCashAddress});
        
        console.log("Via-USD cash token contract ether balacne after sending ether:", await web3.eth.getBalance(viausdCashAddress));
        console.log("Account ether balacne after sending ether:", await web3.eth.getBalance(accounts[0]));
    });
});
