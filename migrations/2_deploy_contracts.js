// (c) Kallol Borah, 2020
// deploying via tokens

const stringutils = artifacts.require('stringutils');
const ABDKMathQuad = artifacts.require('ABDKMathQuad');
const Factory = artifacts.require('Factory');
const Bond = artifacts.require('Bond');
const Cash = artifacts.require('Cash');
const ViaOracle = artifacts.require('ViaOracle');
const usingProvable = artifacts.require('usingProvable');
const ERC20 = artifacts.require('ERC20');


module.exports = function(deployer) {

    deployer.deploy(stringutils);
    deployer.link(stringutils, [Bond, Cash, ViaOracle]);

    deployer.deploy(ABDKMathQuad);
    deployer.link(ABDKMathQuad,[Cash, Bond, ViaOracle, ERC20]);

    deployer.deploy(usingProvable);
    deployer.deploy(ViaOracle);
    deployer.deploy(ERC20);
    deployer.deploy(Cash);
    deployer.deploy(Bond);

    deployer.deploy(Factory).then(async () => {
        const factory = await Factory.deployed();
        const cash = await Cash.deployed();
        const bond = await Bond.deployed();
        const oracle = await ViaOracle.deployed();
        
        await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Cash"), oracle.address);
        await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-EUR"), web3.utils.utf8ToHex("Cash"), oracle.address);
        await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-INR"), web3.utils.utf8ToHex("Cash"), oracle.address);

        await factory.createToken(bond.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Bond"), oracle.address);
        await factory.createToken(bond.address, web3.utils.utf8ToHex("Via-EUR"), web3.utils.utf8ToHex("Bond"), oracle.address);
        await factory.createToken(bond.address, web3.utils.utf8ToHex("Via-INR"), web3.utils.utf8ToHex("Bond"), oracle.address);

        for (let i = 0; i < 6; i++) {
            var factoryTokenAddress = await factory.tokens(i);
            console.log("Token address:", factoryTokenAddress);
            console.log("Token name:", web3.utils.hexToUtf8(await factory.getName(factoryTokenAddress)));
            console.log("Token type:", web3.utils.hexToUtf8(await factory.getType(factoryTokenAddress)));
            console.log();
        }       
        
    });
    
}



