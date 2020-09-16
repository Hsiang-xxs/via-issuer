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

    //list of issued token products
    mapping(bytes => address) products;

    //list of token product issuers
    mapping(bytes32 => mapping(bytes32 => address)) issuers;

    event IssuerCreated(address indexed _address, bytes32 tokenName, bytes32 tokenType);
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

    //retrieve token product address for given identifier (symbol)
    function getProduct(bytes memory symbol) public returns(address){
        return products[symbol];
    }

    //retrieve token product issuer address for given token name and type
    function getIssuer(bytes32 tokenType, bytes32 tokenName) public returns(address){
        return issuers[tokenType][tokenName];
    }

    //token issuer factory 
    function createIssuer(address _target, bytes32 tokenName, bytes32 tokenType, address _oracle, address _token) external{
        address _owner = msg.sender;

        bytes memory _payload = abi.encodeWithSignature("initialize(bytes32,bytes32,address,address,address)", tokenName, tokenType, address(this), _oracle, _token);

        // Deploy proxy
        address _issuer = deployMinimal(_target, _payload);
        emit IssuerCreated(_issuer, tokenName, tokenType);

        if(tokenType == "Cash"){
                token[_issuer] = via("ViaCash", tokenName);
                tokens.push(_issuer);
                issuers["ViaCash"][tokenName] = _issuer;
        }
        else if(tokenType == "Bond"){
                token[_issuer] = via("ViaBond", tokenName);
                tokens.push(_issuer);
                issuers["ViaBond"][tokenName] = _issuer;
        }
    }
    
    //token factory
    function createToken(address _target, bytes32 tokenName, bytes32 tokenProduct, bytes memory tokenSymbol) public returns(address){
        address _owner = msg.sender;

        bytes memory _payload = abi.encodeWithSignature("initialize(bytes32,address,bytes32,bytes32)", tokenName, _owner, tokenProduct, tokenSymbol);

        // Deploy proxy
        address _token = deployMinimal(_target, _payload);
        products[tokenSymbol] = _token;       
        emit TokenCreated(_token, tokenName, tokenProduct);
        return _token;
    }
}






