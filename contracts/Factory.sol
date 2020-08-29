// (c) Kallol Borah, 2020
// Implementation of the Via cash and bond factory.

pragma solidity >=0.5.0 <0.7.0;

import "./Cash.sol";
import "./Bond.sol";
import "@openzeppelin/upgrades/contracts/upgradeability/ProxyFactory.sol";

contract Factory is ProxyFactory {

    //data structure for token proxies
    struct via{
        bytes32 tokenType;
        bytes32 name;
    }

    //address of Via contracts
    address ViaBond;
    address ViaCash;

    //addresses of all Via proxies
    mapping(address => via) public token;

    address[] public tokens;

    event TokenCreated(address indexed _address, bytes32 tokenName, bytes32 tokenType);

    function getTokenCount() public view returns(uint tokenCount) {
        return tokens.length;
    }

    function getName(address viaAddress) public view returns(bytes32) {
        return token[viaAddress].name;
    }

    function getType(address viaAddress) public view returns(bytes32) {
        return token[viaAddress].tokenType;
    }

    //token factory 
    function createToken(address _target, bytes32 tokenName, bytes32 tokenType, address _oracle) external{
        address _owner = msg.sender;

        bytes memory _payload = abi.encodeWithSignature("initialize(bytes32,address,address)", tokenName, _owner, _oracle);

        // Deploy proxy
        address _via = deployMinimal(_target, _payload);
        emit TokenCreated(_via, tokenName, tokenType);

        if(tokenType == "Cash"){
                token[_via] = via("ViaCash", tokenName);
                tokens.push(_via);
        }
        else if(tokenType == "Bond"){
                token[_via] = via("ViaBond", tokenName);
                tokens.push(_via);
        }
    }
    
}






