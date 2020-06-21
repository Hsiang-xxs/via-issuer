// (c) Kallol Borah, 2020
// Implementation of the Via cash token.

pragma solidity >=0.4.16 <0.7.0;

import "./erc/ERC20.sol";
import "./oraclize/ViaRate.sol";
import "./oraclize/EthToUSD.sol";
import "./utilities/StringUtils.sol";
import '@openzeppelin/upgrades/contracts/Initializable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol';

contract Cash is ERC20, Initializable, Ownable {

    //issuer's address
    address owner;

    //name of Via token (eg, Via-USD)
    string public name;
    string public symbol;

    uint256 via;
    uint256 eth;

    //ether balances held by issuer
    mapping(address => uint256) public ethbalances;

    //events to capture and report to Via oracle
    event sold(string currency, uint value);
    event redeemed(string currency, uint value);

    //initiliaze proxies
    function initialize(string memory _name, address _owner) public {
        Ownable.initialize(_owner);
        owner = _owner;
        name = _name;
        symbol = _name;
    }
    
    //requesting issue of Via to buyer for amount of ether
    function issue(uint256 amount, address buyer) payable public {
        //only issuer can request issue
        require(owner == msg.sender);
        //ensure that brought amount is not zero
        require(amount != 0);
        //issues against eth
        require(msg.value!=0);
        //adds paid in ether to this contract's ether balance
        ethbalances[owner] += msg.value;
        //find amount of via tokens to transfer after applying exchange rate
        via = convertToVia(amount, name);
        //add via to this contract's balance first
        balances[address(this)].add(via);
        //transfer amount to buyer 
        transferFrom(address(this), buyer, via);
        //adjust total supply
        totalSupply_ += via;
        //generate event
        emit sold(name, amount);
    }

    //requesting redemption of Via and transfer of ether to seller 
    //to do : redemption for fiat currency
    function redeem(uint256 amount, address seller) public {
        //only issuer can request redemption
        require(owner == msg.sender);
        //ensure that sold amount is not zero
        require(amount != 0);
        //find amount of ether to transfer after applying via exchange rate
        eth = convertFromVia(amount, name);
        //only if the issuer's ether balance is more than ether redeemed
        if(ethbalances[owner] > eth){
            //transfer amount from issuer/sender to seller 
            transferFrom(owner, seller, eth);
            //adjust total supply
            totalSupply_ +- amount;
            //generate event
            emit redeemed(name, amount);
        }
    }
    
    //uses Oraclize 
    function convertToVia(uint256 amount, bytes32 currency) public returns(uint256){
        //only issuer can call oracle
        require(msg.sender == owner);
        //to first convert amount of ether passed to this function to USD
        uint256 amountInUSD = (amount/1000000000000000000)*uint256(stringToUint(new EthToUSD()));
        //to then convert USD to Via-currency if currency is not USD itself 
        if(currency!="Via-USD"){
            uint256 inVia = amountInUSD * uint256(stringToUint(new ViaRate(+"Via_USD_to_Via_"+substring(currency,4,6),"er")));
            return inVia;
        }
        else{
            return amountInUSD;
        }
    }

    //convert Via-currency (eg, Via-EUR, Via-INR, Via-USD) to Ether
    function convertFromVia(uint256 amount, bytes32 currency) public returns(uint256){
        //only issuer can call oracle
        require(msg.sender == owner);
        if(currency!="Via-USD"){
            uint256 amountInViaUSD = amount * uint256(stringToUint(new ViaRate(+"Via_"+substring(currency,4,6)+"_to_Via_USD","er")));
            uint256 inEth = amountInViaUSD * (1/uint256(stringToUint(new EthToUSD())));
            return inEth;
        }
        else{
            uint256 inEth = amount * (1/uint256(stringToUint(new EthToUSD())));
            return inEth;
        }
    }

}
