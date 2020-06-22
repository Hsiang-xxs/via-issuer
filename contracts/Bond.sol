// (c) Kallol Borah, 2020
// Implementation of the Via zero coupon bond.

pragma solidity >=0.4.16 <0.7.0;

import "./erc/ERC20.sol";
import "./oraclize/ViaRate.sol";
import "./utilities/DayCountConventions.sol";
import "./utilities/SafeMath.sol";
import "./utilities/StringUtils.sol";
import '@openzeppelin/upgrades/contracts/Initializable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol';

contract Bond is ERC20, Initializable, Ownable {

    //issuer's address
    address owner;

    //name of Via token (eg, Via-USD%)
    string public name;
    string public symbol;

    uint256 viaBondPrice;
    uint256 faceValue;
    uint256 eth;
    int256 balanceTenure;

    //ether balances held by issuer
    mapping(address => uint256) public ethbalances;

    //a Via bond has some value, corresponds to a fiat currency
    //has a borrower and lender that have agreed to a zero coupon rate which is the start price of the bond
    //and a tenure in unix timestamps of seconds counted from 1970-01-01. Via bonds are of one year tenure.
    //constructor for creating Via bond
    struct loan{
        address borrower;
        bytes32 currency;
        uint256 faceValue;
        uint256 price;
        uint256 collateralAmount;
        bytes32 collateralCurrency;
        uint256 timeOfIssue;
        uint tenure; 
    }

    mapping(address => loan) public loans;

    //initiliaze proxies
    function initialize(string memory _name, address _owner) public {
        Ownable.initialize(_owner);
        owner = _owner;
        name = _name;
        symbol = _name;
    }

    //events to capture and report to Via oracle
    event lent(bytes32 currency, uint value, uint price, uint tenure);
    event redeemed(bytes32 currency, uint value, uint price, uint tenure);

    //requesting issue of Via bonds to borrower for amount of ether as collateral
    function issue(uint256 amount, address borrower) payable public {
        //ensure that request is sent by the issuer
        require(msg.sender == owner);
        //ensure that brought amount is not zero
        require(amount != 0);
        //issues against eth
        require(msg.value!=0);
        //adds paid in ether to this contract's ether balance
        ethbalances[owner] += msg.value;
        //find face value of bond in via denomination
        faceValue = convertToVia(amount, name);
        //find price of via bonds to transfer after applying exchange rate
        viaBondPrice = getBondValueToIssue(faceValue, name, 1);
        //add via bonds to this contract's balance first
        balances[address(this)].add(viaBondPrice); 
        //transfer amount from issuer/sender to borrower 
        transferFrom(address(this), borrower, viaBondPrice);
        //adjust total supply
        totalSupply_ += viaBondPrice;
        //keep track of issues
        storeIssuedBond(borrower, name, faceValue, viaBondPrice, amount, "ether", now, 1);
        //generate event
        emit lent(name, amount, viaBondPrice, 1);
    }

    //requesting redemption of Via bonds and transfer of ether collateral to borrower 
    //to do : redemption of Via bonds for fiat currency
    function redeem(uint256 amount, address borrower) public {
        //ensure request to redeem is authorized by issuer
        require(msg.sender == owner);
        //ensure that sold amount is not zero
        require(amount != 0);
        //find amount of ether to transfer 
        var(eth, balanceTenure) = getBondValueToRedeem(amount, name, borrower);
        //only if this contract's ether balance is more than ether redeemed
        if(ethbalances[owner] > eth){
            //transfer amount from issuer/sender to borrower 
            transferFrom(owner, borrower, eth);
            //adjust total supply
            totalSupply_ +- amount;
            //generate event
            emit redeemed(name, amount, eth, balanceTenure);
        }
    }

    //uses Oraclize to find Via face value of amount passed in currency
    function convertToVia(uint256 amount, bytes32 currency) public returns(uint256){
        //only issuer can call oracle
        require(msg.sender == owner);
        //to first convert amount of ether passed to this function to USD
        uint256 amountInUSD = (amount/1000000000000000000)*uint256(stringToUint(new EthToUSD()));
        //to then convert USD to Via-currency if currency is not USD itself 
        if(currency!="Via-USD"){
            uint256 inVia = amountInUSD * uint256(stringToUint(new ViaRate(+"Via_USD_to_Via_"+substring(currency,4,6), "er")));
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

    //uses Oraclize to calculate price of 1 year zero coupon bond in currency and for amount to issue to borrower
    //to do : we need to support bonds with tenure different than the default 1 year. 
    //we can do this if we can take tenure as parameter from wallet which we are not doing now.
    function getBondValueToIssue(uint256 amount, bytes32 currency, uint tenure) public returns(uint256){
        //only issuer can call oracle
        require(msg.sender == owner);
        //to first convert amount of ether passed to this function to USD
        uint256 amountInUSD = (amount/1000000000000000000)*uint256(stringToUint(new EthToUSD()));
        //to then get Via interest rates from oracle and calculate zero coupon bond price
        if(currency!="Via-USD"){
            return amountInUSD / (1 + uint256(stringToUint(new ViaRate(+"Via_USD_to_Via_"+substring(currency,4,6), "ir")))) ^ tenure;
        }
        else{
            return amountInUSD / (1 + uint256(stringToUint(new ViaRate(+"USD", "ir")))) ^ tenure;
        }
    }

    //calculate price of redeeming zero coupon bond in currency and for amount to borrower who may redeem before end of year
    function getBondValueToRedeem(uint256 _amount, bytes32 _currency, address _borrower) public returns(uint256, uint){
        require(msg.sender == owner);
        //find out if bond is present in list of issued bonds
        uint256 toRedeem;
        for(uint p=0; p < loans[msg.sender][p].length; p++){
            //if bond is found to be issued
            if(loans[msg.sender][p].borrower == _borrower && 
                loans[msg.sender][p].currency == _currency &&
                loans[msg.sender][p].price >= amount){
                    uint256 timeOfIssue = loans[msg.sender][p].timeOfIssue;
                    //if entire amount is to be redeemed, remove issued bond from store
                    if(loans[msg.sender][p].price - amount ==0){
                        toRedeem = amount;
                        delete(loans[msg.sender][p]);
                    }else{
                        //else, reduce outstanding value of bond
                        loans[msg.sender][p].price = loans[msg.sender][p].price - amount;
                    }
                    return(convertFromVia(toRedeem, _currency), DayCountConventions.diffTime(now, timeOfIssue));
            }
        }
        return(0,0);
    }

    function storeIssuedBond(
        address _borrower, 
        bytes32 _currency, 
        uint256 _facevalue, 
        uint256 _viabond, 
        uint256 _amount, 
        bytes32 _collateralCurrency, 
        uint _timeofissue, 
        uint _tenure) 
        internal{
        require(msg.sender == owner);
        // to do : we need to support fiat, Via currencies and different tenures
        loans[msg.sender][loans.length] = loan(_borrower, _currency, _facevalue, _viabond, _amount, _collateralCurrency, _timeofissue, _tenure);
    }

}
