// (c) Kallol Borah, 2020
// initializing token proxies and testing if they are creating properly

const Factory = artifacts.require('Factory.sol');
const Bond = artifacts.require('Bond.sol');
const Cash = artifacts.require('Cash.sol');
const encodeCall = require('zos-lib/lib/helpers/encodeCall').default;

contract('Factory', function (accounts) {
  beforeEach(async function () {
    var cashToken = await Cash.new();
    var bondToken = await Bond.new();
    var proxyFactory = await Factory.new(bondToken.address, cashToken.address);
  });
  it('it should return cash and bond Contracts', async function () {
   const cashContractAddress = await proxyFactory.ViaCash.call();
   assert.equal(cashContractAddress, cashToken.address);
   const bondContractAddress = await proxyFactory.ViaBond.call();
   assert.equal(bondContractAddress, bondToken.address);
  });
  it('it should create token contract proxies', async function () {
    let initializeData = encodeCall(
      'initialize', 
      ['string', 'address'],   
      ['Via-USD', accounts[2]]
    );
    const transactionReceipt = await     
    proxyFactory.createToken
    (
      initializeData, {from : accounts[2]}
    );
    var proxyAddress = transactionReceipt.logs[0].args.proxy;
    const impl = await Cash.at(proxyAddress);
    const name = await impl.name.call();
    const owner = await impl.owner();
    assert.equal(name, 'Via-USD');
    assert.equal(owner, accounts[2]);
  });
});

