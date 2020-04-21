const HelloBlockchain = artifacts.require("HelloBlockchain");
contract('HelloBlockchain', (accounts) => {

    it('testing ResponseMessage of HelloBlockchain', async () => {
        const HelloBlockchainInstance = await HelloBlockchain.deployed();
        var returnValue1;
        returnValue1 = await HelloBlockchainInstance.ResponseMessage.call();

        // Write an assertion below to check the return value of ResponseMessage.
        assert.equal('something', 'something', 'A correctness property about ResponseMessage of HelloBlockchain');
    });

    it('testing Responder of HelloBlockchain', async () => {
        const HelloBlockchainInstance = await HelloBlockchain.deployed();
        var returnValue1;
        returnValue1 = await HelloBlockchainInstance.Responder.call();

        // Write an assertion below to check the return value of Responder.
        assert.equal('something', 'something', 'A correctness property about Responder of HelloBlockchain');
    });

    it('testing RequestMessage of HelloBlockchain', async () => {
        const HelloBlockchainInstance = await HelloBlockchain.deployed();
        var returnValue1;
        returnValue1 = await HelloBlockchainInstance.RequestMessage.call();

        // Write an assertion below to check the return value of RequestMessage.
        assert.equal('something', 'something', 'A correctness property about RequestMessage of HelloBlockchain');
    });

    it('testing State of HelloBlockchain', async () => {
        const HelloBlockchainInstance = await HelloBlockchain.deployed();
        var returnValue1;
        returnValue1 = await HelloBlockchainInstance.State.call();

        // Write an assertion below to check the return value of State.
        assert.equal('something', 'something', 'A correctness property about State of HelloBlockchain');
    });

    it('testing Requestor of HelloBlockchain', async () => {
        const HelloBlockchainInstance = await HelloBlockchain.deployed();
        var returnValue1;
        returnValue1 = await HelloBlockchainInstance.Requestor.call();

        // Write an assertion below to check the return value of Requestor.
        assert.equal('something', 'something', 'A correctness property about Requestor of HelloBlockchain');
    });

    it('testing SendRequest of HelloBlockchain', async () => {
        const HelloBlockchainInstance = await HelloBlockchain.deployed();
        var callerAccount = accounts[0];
        var requestMessage1 = "StringValue1";
        await HelloBlockchainInstance.SendRequest(requestMessage1, {from: callerAccount});

        // Because the function call can change the state of contract HelloBlockchain, please write assertions
        // below to check the contract state.
        assert.equal('something', 'something', 'A correctness property about SendRequest of HelloBlockchain');
    });

    it('testing SendResponse of HelloBlockchain', async () => {
        const HelloBlockchainInstance = await HelloBlockchain.deployed();
        var callerAccount = accounts[0];
        var responseMessage1 = "StringValue1";
        await HelloBlockchainInstance.SendResponse(responseMessage1, {from: callerAccount});

        // Because the function call can change the state of contract HelloBlockchain, please write assertions
        // below to check the contract state.
        assert.equal('something', 'something', 'A correctness property about SendResponse of HelloBlockchain');
    });

});