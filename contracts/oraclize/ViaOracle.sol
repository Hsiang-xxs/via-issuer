//(c) Kallol Borah, 2020
// Via oracle client

pragma solidity >=0.5.0 <0.7.0;

import "./provableAPI.sol";
import "../utilities/StringUtils.sol";
import "../Cash.sol";
import "../Bond.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";

contract ViaOracle is usingProvable {

    using stringutils for *;

    using ABDKMathQuad for uint256;
    using ABDKMathQuad for int256;
    using ABDKMathQuad for bytes16;

    struct params{
        address payable caller;
        bytes32 tokenType;
        bytes32 rateType;
    }

    mapping (bytes32 => params) public pendingQueries;

    event LogNewProvableQuery(string description);
    event LogResult(bytes32 tokenType, bytes32 rateType, string result);

    constructor()
        public
        payable
    {
        // note : replace OAR if you are testing Oracle with ethereum-bridge (https://github.com/provable-things/ethereum-bridge)
        OAR = OracleAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475); 
        provable_setProof(proofType_TLSNotary | proofStorage_IPFS);
    }

    function __callback(
        bytes32 _myid,
        string memory _result,
        bytes memory _proof
    )
        public 
    {
        //to do : lines below throw error
        //require(msg.sender == provable_cbAddress());
        //require (pendingQueries[_myid].tokenType == "Cash" || pendingQueries[_myid].tokenType == "Bond"
        //    || pendingQueries[_myid].tokenType == "EthCash" || pendingQueries[_myid].tokenType == "EthBond");

        emit LogResult(pendingQueries[_myid].tokenType, pendingQueries[_myid].rateType, _result);
        
        if(pendingQueries[_myid].tokenType == "Cash"){
            Cash cash = Cash(pendingQueries[_myid].caller);
            cash.convert(_myid, ABDKMathQuad.fromUInt(_result.stringToUint()), pendingQueries[_myid].rateType);
        }
        else if(pendingQueries[_myid].tokenType == "Bond"){
            Bond bond = Bond(pendingQueries[_myid].caller);
            bond.convert(_myid, ABDKMathQuad.fromUInt(_result.stringToUint()), pendingQueries[_myid].rateType);
        }
        else if(pendingQueries[_myid].tokenType == "EthCash"){
            Cash cash = Cash(pendingQueries[_myid].caller);
            cash.convert(_myid, ABDKMathQuad.fromUInt(_result.stringToUint()), pendingQueries[_myid].rateType);
        }
        else if(pendingQueries[_myid].tokenType == "EthBond"){
            Bond bond = Bond(pendingQueries[_myid].caller);
            bond.convert(_myid, ABDKMathQuad.fromUInt(_result.stringToUint()), pendingQueries[_myid].rateType);
        }
        //to do : following line also throws error
        //delete pendingQueries[_myid]; 
    }

    //uses the processing engine for via exchange rates
    function requestPost(bytes memory _currency, bytes32 _ratetype, bytes32 _tokenType, address payable _tokenContract)
        public
        payable
        //returns (bytes32)
    {  
        //if (provable_getPrice("URL") > address(this).balance) {
        //    emit LogNewProvableQuery("Provable query was NOT sent, please add some ETH to cover for the query fee!");
        //} else {
            if(_ratetype == "er" || _ratetype == "ver"){
                emit LogNewProvableQuery("Provable query was sent for Via oracle rates, standing by for the answer...");
                bytes32 queryId = "1234"; //provable_query("URL", "oracleurlhere"); 
                params memory p = pendingQueries[queryId];
                p.caller = _tokenContract;
                p.tokenType = _tokenType;
                p.rateType = _ratetype;
                __callback("1234", "10.0", "0x0");
                //return queryId;
            }
            else if(_ratetype == "ir"){
                emit LogNewProvableQuery("Provable query was sent for Via oracle rates, standing by for the answer...");
                bytes32 queryId = "5678"; //provable_query("URL", "oracleurlhere");
                params memory p = pendingQueries[queryId];
                p.caller = _tokenContract;
                p.tokenType = _tokenType;
                p.rateType = _ratetype;
                __callback("5678", "1.0", "0x0");
                //return queryId;
            }
            else if(_ratetype == "ethusd"){
                emit LogNewProvableQuery("Provable query was sent for ETH-USD, standing by for the answer...");
                bytes32 queryId = "9101112"; //provable_query("URL", "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price");
                params memory p = pendingQueries[queryId];
                p.caller = _tokenContract;
                p.tokenType = _tokenType;
                p.rateType = _ratetype;
                __callback("9101112", "300.0", "0x0");
                //return queryId;
            }
        //}        
    }

    function request(bytes memory _currency, bytes32 _ratetype, bytes32 _tokenType, address payable _tokenContract)
        public
        payable
        returns (bytes32)
    {  
        if (provable_getPrice("URL") > address(this).balance) {
            emit LogNewProvableQuery("Provable query was NOT sent, please add some ETH to cover for the query fee!");
        } else {
            if(_ratetype == "er" || _ratetype == "ver"){
                emit LogNewProvableQuery("Provable query was sent for Via oracle rates, standing by for the answer...");
                bytes32 queryId = provable_query("URL", string(abi.encodePacked("json(https://url/rates/er/",_currency,").rate")));  
                params memory p = pendingQueries[queryId];
                p.caller = _tokenContract;
                p.tokenType = _tokenType;
                p.rateType = _ratetype;
                return queryId;
            }
            else if(_ratetype == "ir"){
                emit LogNewProvableQuery("Provable query was sent for Via oracle rates, standing by for the answer...");
                bytes32 queryId = provable_query("URL", string(abi.encodePacked("json(https://url/rates/ir/",_currency,").rate")));
                params memory p = pendingQueries[queryId];
                p.caller = _tokenContract;
                p.tokenType = _tokenType;
                p.rateType = _ratetype;
                return queryId;
            }
            else if(_ratetype == "ethusd"){
                emit LogNewProvableQuery("Provable query was sent for ETH-USD, standing by for the answer...");
                bytes32 queryId = provable_query("URL", "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price");
                params memory p = pendingQueries[queryId];
                p.caller = _tokenContract;
                p.tokenType = _tokenType;
                p.rateType = _ratetype;
                return queryId;
            }
        }        
    }
}