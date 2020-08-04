//taken from Oraclize's examples, with minor modifications
//(c) Kallol Borah, 2020

pragma solidity >=0.5.0 <0.7.0;

import "./provableAPI.sol";
import "../utilities/StringUtils.sol";
import "../Cash.sol";
import "../Bond.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";

//taken from Oraclize's examples, with minor modifications
contract EthToUSD is usingProvable {

    using stringutils for *;

    struct params{
        address payable caller;
        bytes32 tokenType;
    }

    mapping (bytes32 => params) public pendingQueries;

    event LogNewProvableQuery(string description);
    event LogNewETHPriceTicker(string price);

    constructor()
        public
    {
        // provable_setProof(proofType_TLSNotary | proofStorage_IPFS);
    }

    function __callback(
        bytes32 _myid,
        string memory _result,
        bytes memory _proof
    )
        public
    {
        require(msg.sender == provable_cbAddress());
        require (pendingQueries[_myid].tokenType == "Cash" || pendingQueries[_myid].tokenType == "Bond");
        emit LogNewETHPriceTicker(_result);
        if(pendingQueries[_myid].tokenType == "Cash"){
            Cash cash = Cash(pendingQueries[_myid].caller);
            cash.convert(_myid, ABDKMathQuad.fromUInt(_result.stringToUint()), "ethusd");
        }
        else {
            Bond bond = Bond(pendingQueries[_myid].caller);
            bond.convert(_myid, ABDKMathQuad.fromUInt(_result.stringToUint()), "ethusd");
        }
        delete pendingQueries[_myid];
    }

    function update(bytes32 _tokenType, address payable _tokenContract)
        public
        payable
        returns (bytes32)
    {
        if (provable_getPrice("URL") > address(this).balance) {
            emit LogNewProvableQuery("Provable query was NOT sent, please add some ETH to cover for the query fee!");
        } else {
            emit LogNewProvableQuery("Provable query was sent for ETH-USD, standing by for the answer...");
            bytes32 queryId = "9101112"; //provable_query("URL", "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price");
            pendingQueries[queryId] = params(_tokenContract, _tokenType);
            __callback("9101112", "300.0", "0x0");
            //return queryId;
        }
    }
}