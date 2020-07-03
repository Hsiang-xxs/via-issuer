//taken from Oraclize's examples, with minor modifications
//(c) Kallol Borah, 2020

pragma solidity >=0.5.0 <0.7.0;

import "../oraclize/provableAPI.sol";

contract ViaRate is usingProvable {

    event LogNewProvableQuery(string description);
    event LogResult(string result);

    bytes32 currency;
    bytes32 url;

    constructor(bytes32 _currency, bytes32 _ratetype)
        public
    {
        provable_setProof(proofType_Android | proofStorage_IPFS);
        currency = _currency;
    }

    function __callback(
        bytes32 _myid,
        string memory _result,
        bytes memory _proof
    )
        public returns(string memory)
    {
        require(msg.sender == provable_cbAddress());
        emit LogResult(_result);
        return _result;
    }

    function request(
        string memory _query,
        string memory _method,
        string memory _url,
        string memory _kwargs
    )
        public
        payable
    {
        if (provable_getPrice("computation") > address(this).balance) {
            emit LogNewProvableQuery("Provable query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
            provable_query("computation",
                [_query,
                _method,
                _url,
                _kwargs]
            );
        }
    }
    
    //uses the processing engine for via exchange rates
    function requestPost(bytes32 _ratetype)
        public
        payable
    {  
        if(_ratetype == "er")
            url = "https://via-oracle.azurewebsites.net/api/via/er";
        else if(_ratetype == "ir")
            url = "https://via-oracle.azurewebsites.net/api/via/ir";

        request("QmdKK319Veha83h6AYgQqhx9YRsJ9MJE7y33oCXyZ4MqHE",
                "POST",
                url,
                '{"json": {"postcodes" : ["'+currency+'"]}}'
                );
    }

}
