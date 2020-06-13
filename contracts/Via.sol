// (c) Kallol Borah, 2020

pragma solidity >=0.4.16 <0.7.0;

contract Via{

    //address of the issuer of the Via
    address public issuer;

    //is issuer set up complete ?
    bool setup;

    //a Via has balance value equal to a fiat currency
    //for example, 1 Via-USD corresponds to 1 Via corresponding to the USD fiat
    struct Via{
        uint value;
        bytes32 currency;
    }

    Via[] public holdings;

    //a Via loan has some value, corresponds to a fiat currency
    //has a borrower and lender that have agreed to a zero coupon rate called price
    //and a tenure in unix timestamps of seconds counted from 1970-01-01
    //the boolean offer indicates if the Via loan is an offer to lend or not
    struct ViaLoans{
        uint value;
        bytes32 currency;
        address payable borrower;
        address payable lender;
        uint tenure;
        uint price;
        bool offer;
    }

    ViaLoans[] public loans;

    //data structure to hold offers to lend Via in a specific fiat currency
    //over a floor price and floor rate and over a minimum tenure
    struct ViaOffers{
        uint value;
        bytes32 currency;
        uint tenure;
        uint price;
    }

    ViaOffers[] public offers;

    //any Via user can have some holdings and some loans
    struct Beneficiary{
        uint holdings;
        uint loans;
        uint offers;
    }
    
    //declares a state variable for each beneficiary
    mapping(address => Beneficiary) public beneficiaries;

    //events to capture and report to Via oracle
    event sold(bytes32 currency, uint value);
    event lent(bytes32 currency, uint value, uint tenure, uint price);

    //constructor that assigns the issuer
    constructor() public {
        issuer = msg.sender;
        setup = true;
    }

    //requesting issue of Via for value and for fiat currency
    function buy(bytes32 currency) payable public {
        //ensure that the issuer is not buying and that issuer setup is done
        require(msg.sender != issuer && setup);
        //ensure that brought amount is not zero
        require(msg.value != 0);
        //add via corresponding to currency (eg, ether or fiat or some other via-fiat) in beneficiary holdings
        bytes32 name;
        holdings[holdings.length].currency = name;
        //find Via exchange rate for currency from via oracle if currency is not ether, else first find value of ether in fiat
        uint exchanged;
        //add via exchanged for amount of currency to beneficiary holdings 
        holdings[holdings.length].value = exchanged;
        //generate event
        emit sold(name, exchanged);
    }

    //requesting redemption of Via for value and for fiat currency
    function sell(bytes32 currency) payable public {
        //ensure that the issuer is not selling and that issuer setup is done
        require(msg.sender != issuer && setup);
        //ensure that sold amount is not zero
        require(msg.value != 0);
        //remove via corresponding to currency (eg, ether or fiat or some other via-fiat) in beneficiary holdings
        bytes32 name;
        holdings[holdings.length].currency = name;
        //find Via exchange rate for currency from via oracle if currency is not ether, else first find value of ether in fiat
        uint exchanged;
        //subtract via exchanged for amount of currency to beneficiary holdings 
        holdings[holdings.length].value = exchanged;
        //generate event
        emit sold(name, exchanged);
    }

    //offering a loan in a currency that is of most benefit
    function offer(bytes32 fiat, uint value) payable public {

    }

    //bid to borrow on an offer
    function bid(bytes32 currency, uint price, uint tenure, uint amount) payable public {
        //ensure that the issuer is not borrowing and that issuer setup is done
        require(msg.sender != issuer && setup);
        //ensure that collateral offered is not zero
        require(msg.value != 0);
        //ensure that there is currency and enough of it to lend
        for(uint p=0; p < offers.length; p++){
            if(offers[p].currency == currency && offers[p].value >= amount){
                //take approval from lender
            }
        }
    }

    //pay back loan
    function payback() payable public {

    }

}