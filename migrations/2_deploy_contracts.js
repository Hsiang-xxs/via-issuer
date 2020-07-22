// (c) Kallol Borah, 2020
// deploying via tokens

const stringutils = artifacts.require('stringutils');
const Factory = artifacts.require('Factory');
const Bond = artifacts.require('Bond');
const Cash = artifacts.require('Cash');

module.exports = function(deployer) {

    deployer.deploy(stringutils);
    deployer.link(stringutils, [Bond, Cash]);

    deployer.deploy(Cash);
    deployer.deploy(Bond);

    deployer.deploy(Factory).then(async () => {
        const factory = await Factory.new();
        const cash = await Cash.new();
        const bond = await Bond.new();

        await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Cash"));
        await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-EUR"), web3.utils.utf8ToHex("Cash"));
        await factory.createToken(cash.address, web3.utils.utf8ToHex("Via-INR"), web3.utils.utf8ToHex("Cash"));

        await factory.createToken(bond.address, web3.utils.utf8ToHex("Via-USD"), web3.utils.utf8ToHex("Bond"));
        await factory.createToken(bond.address, web3.utils.utf8ToHex("Via-EUR"), web3.utils.utf8ToHex("Bond"));
        await factory.createToken(bond.address, web3.utils.utf8ToHex("Via-INR"), web3.utils.utf8ToHex("Bond"));
    });
}

