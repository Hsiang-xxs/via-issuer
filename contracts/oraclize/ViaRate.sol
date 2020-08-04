//taken from Oraclize's examples, with minor modifications
//(c) Kallol Borah, 2020

pragma solidity >=0.5.0 <0.7.0;

import "./provableAPI.sol";
import "../utilities/StringUtils.sol";
import "../Cash.sol";
import "../Bond.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";

contract ViaRate is usingProvable {

    using stringutils for *;

    struct params{
        address payable caller;
        bytes32 tokenType;
        bytes32 rateType;
    }

    mapping (bytes32 => params) public pendingQueries;

    event LogNewProvableQuery(string description);
    event LogResult(string result);

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
        emit LogResult(_result);
        if(pendingQueries[_myid].tokenType == "Cash"){
            Cash cash = Cash(pendingQueries[_myid].caller);
            cash.convert(_myid, ABDKMathQuad.fromUInt(_result.stringToUint()), pendingQueries[_myid].rateType);
        }
        else {
            Bond bond = Bond(pendingQueries[_myid].caller);
            bond.convert(_myid, ABDKMathQuad.fromUInt(_result.stringToUint()), pendingQueries[_myid].rateType);
        }
        delete pendingQueries[_myid]; 
    }

    //uses the processing engine for via exchange rates
    function requestPost(bytes memory _currency, bytes32 _ratetype, bytes32 _tokenType, address payable _tokenContract)
        public
        payable
        returns (bytes32)
    {  
        if (provable_getPrice("URL") > address(this).balance) {
            emit LogNewProvableQuery("Provable query was NOT sent, please add some ETH to cover for the query fee!");
        } else {
            emit LogNewProvableQuery("Provable query was sent for Via rates, standing by for the answer...");
            if(_ratetype == "er"){
                bytes32 queryId = "1234"; //provable_query("URL", "oracleurlhere"); 
                pendingQueries[queryId] = params(_tokenContract, _tokenType, _ratetype);
                __callback("1234", "10.0", "0x0");
                //return queryId;
            }
            else if(_ratetype == "ver"){
                bytes32 queryId = "3456"; //provable_query("URL", "oracleurlhere"); 
                pendingQueries[queryId] = params(_tokenContract, _tokenType, _ratetype);
                __callback("3456", "10.0", "0x0");
                //return queryId;
            }
            else if(_ratetype == "ir"){
                bytes32 queryId = "5678"; //provable_query("URL", "oracleurlhere");
                pendingQueries[queryId] = params(_tokenContract, _tokenType, _ratetype);
                __callback("5678", "1.0", "0x0");
                //return queryId;
            }
        }
        
    }

}
