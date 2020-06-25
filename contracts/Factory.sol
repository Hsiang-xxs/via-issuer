// (c) Kallol Borah, 2020
// Implementation of the Via cash and bond factory.

pragma solidity >=0.4.16 <0.7.0;

import "./Cash.sol";
import "./Bond.sol";
import '@openzeppelin/upgrades/contracts/upgradeability/ProxyFactory.sol';

contract Factory is ProxyFactory {

    //this issuer's address
    address owner;

    //data structure for token proxies
    struct via{
        bytes32 tokenType;
        bytes32 name;
    }

    //address of Via contracts
    address ViaBond;
    address ViaCash;

    //addresses of all Via proxies
    mapping(address => via) public tokens;

    //constructor that assigns the issuer
    constructor (address _ViaBond, address _ViaCash) public {
        owner = msg.sender;
        ViaBond = _ViaBond;
        ViaCash = _ViaCash;
    }

    //token factory 
    function createToken(bytes memory _data, string contractType) public returns (address){
        //issuer can only be one that starts the factory
        require(owner == msg.sender);
        //creates singleton via cash and bond tokens
        if(contractType == "Cash"){
            address proxy = deployMinimal(ViaCash, _data);
            if(tokens[proxy]==address(0)){
                tokens[proxy] = via("ViaCash", _data);
            }
        }
        else if(contractType == "Bond"){
            address proxy = deployMinimal(ViaBond, _data);
            if(tokens[proxy]==address(0)){
                tokens[proxy] = via("ViaBond", _data);
            }
        }
        return proxy;
    }
    
}






