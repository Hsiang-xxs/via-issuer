// (c) Kallol Borah, 2020
// deploying via tokens

const Factory = artifacts.require('Factory.sol');
const Bond = artifacts.require('Bond.sol');
const Cash = artifacts.require('Cash.sol');

const factory = await Factory.new();
const cash = await Cash.new();
const bond = await Bond.new();

//to do : should get them from oracle to set values dynamically
await factory.createToken(cash.address, "Via-USD", "Cash");
await factory.createToken(cash.address, "Via-EUR", "Cash");
await factory.createToken(cash.address, "Via-INR", "Cash");

await factory.createToken(bond.address, "Via-USD", "Bond");
await factory.createToken(bond.address, "Via-EUR", "Bond");
await factory.createToken(bond.address, "Via-INR", "Bond");


