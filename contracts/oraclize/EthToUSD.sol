//taken from Oraclize's examples, with minor modifications
//(c) Kallol Borah, 2020

pragma solidity >=0.5.0 <0.7.0;

import "../oraclize/provableAPI.sol";

//taken from Oraclize's examples, with minor modifications
contract EthToUSD is usingProvable {

    event LogNewProvableQuery(string description);
    event LogNewKrakenPriceTicker(string price);

    constructor()
        public
    {
        provable_setProof(proofType_Android | proofStorage_IPFS);
        update(); // Update price on contract creation...
    }

    function __callback(
        bytes32 _myid,
        string memory _result,
        bytes memory _proof
    )
        public returns (string)
    {
        require(msg.sender == provable_cbAddress());
        emit LogNewKrakenPriceTicker(_result);
        return _result;
    }

    function update()
        public
        payable
    {
        if (provable_getPrice("URL") > address(this).balance) {
            emit LogNewProvableQuery("Provable query was NOT sent, please add some ETH to cover for the query fee!");
        } else {
            emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
            provable_query(60, "URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHXUSD.c.0");
        }
    }
}