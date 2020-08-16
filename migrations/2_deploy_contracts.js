// (c) Kallol Borah, 2020
// deploying via tokens

const stringutils = artifacts.require('stringutils');
const ABDKMathQuad = artifacts.require('ABDKMathQuad');
const Factory = artifacts.require('Factory');
const Bond = artifacts.require('Bond');
const Cash = artifacts.require('Cash');
const ViaRate = artifacts.require('ViaRate');
const EthToUSD = artifacts.require('EthToUSD');
const usingProvable = artifacts.require('usingProvable');
const ERC20 = artifacts.require('ERC20');


module.exports = function(deployer) {

    deployer.deploy(stringutils);
    deployer.link(stringutils, [Bond, Cash, ViaRate, EthToUSD]);
    
    deployer.deploy(ABDKMathQuad);
    deployer.link(ABDKMathQuad,[Cash, Bond, ViaRate, EthToUSD, ERC20]);

    deployer.deploy(Cash);
    deployer.deploy(Bond);
    deployer.deploy(ViaRate);
    deployer.deploy(EthToUSD);
    deployer.deploy(usingProvable);
    deployer.deploy(ERC20);

    deployer.deploy(Factory).then(async () => {
        const factory = await Factory.deployed();
        const cash = await Cash.deployed();
        const bond = await Bond.deployed();
        
        
        await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Cash"));
        await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-EUR"), web3.utils.utf8ToHex("Cash"));
        await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-INR"), web3.utils.utf8ToHex("Cash"));

        await factory.createToken(bond.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Bond"));
        await factory.createToken(bond.address, web3.utils.utf8ToHex("Via-EUR"), web3.utils.utf8ToHex("Bond"));
        await factory.createToken(bond.address, web3.utils.utf8ToHex("Via-INR"), web3.utils.utf8ToHex("Bond"));

        for (let i = 0; i < 6; i++) {
            var factoryTokenAddress = await factory.tokens(i);
            console.log("Token address:", factoryTokenAddress);
            console.log("Token name:", web3.utils.hexToUtf8(await factory.getName(factoryTokenAddress)));
            console.log("Token type:", web3.utils.hexToUtf8(await factory.getType(factoryTokenAddress)));
            console.log();
        }
        

        /*
        for (let i=0; i<6; i++) {
            var factoryTokenAddress = await factory.tokens(i);
            if (i<3){
                var cashInstance = await Cash.at(factoryTokenAddress); 
            }
            else {
                var bondInstance = await Bond.at(factoryTokenAddress); 
            }
            console.log(factoryTokenAddress);
            console.log(await factory.token(factoryTokenAddress));
         }
         */
    });
    
}



