// (c) Kallol Borah, 2020

pragma solidity >=0.4.16 <0.7.0;

contract Issuer{

    using SafeMath for uint256;

    //this issuer's address
    address owner;

    //instance variables for Via tokens
    Token ViaUSD;
    Token ViaEUR;
    Token ViaINR;

    //structure to keep track of deposits
    struct Deposit{
        uint256 value;
        bytes32 currency;
    }

    //each depositor may have multiple currencies, hence an array
    mapping(address => Deposit[]) public depositors;
    
    //constructor that assigns the issuer
    constructor() public { 
        owner = msg.sender;
        //create Via token contracts
        ViaUSD = new Token("Via-USD");
        ViaEUR = new Token("Via-EUR");
        ViaINR = new Token("Via-INR");
    }
   
    //receive ether and store it against sender address
    receive() external payable{
        //issuer can not deposit 
        require(msg.sender != owner);
        //there should be some deposit
        require(msg.value != 0);
        //store received ether
        //check if ether as a currency is already available in the deposits array
        bool found=false; 
        uint p=0;
        for(p=0; p<depositors[msg.sender].length; p++){
            if(depositors[msg.sender][p].currency="ether"){
                depositors[msg.sender][p].value += msg.value;
                found = true;
            }
        }
        //if not found, add ether as currency and add what is sent by the depositor
        if(!found){
            depositors[msg.sender][p].currency = "ether";
            depositors[msg.sender][p].value = msg.value;
        }
    }

    //issue Via tokens for currency against deposit
    function issue(bytes32 currency) public returns(bool){
        //issuer can not issue to itself
        require(msg.sender != owner);
        //amount of ether to issue via against can not be zero
        require(msg.value != 0);
        //the requestor should have some deposits
        require(depositors[msg.sender].length !=0);
        //call Oracle to check exchange rate of ether/other currency deposit with the fiat currency in request param
        //for the time being assuming it is 1:1
        bool issued = false;
        uint p=0;
        for(p=0; p<depositors[msg.sender].length; p++){
            //call oracle to find exchange rate of depositors[msg.sender][p].currency against currency passed in param
            //msg.value should be replaced with amount after applying exchange rate
            if(depositors[msg.sender][p].value >= msg.value){ 
                if(currency == "Via-USD"){
                    ViaUSD.issue(msg.value, msg.sender);
                    issued = true;
                }
                if(currency == "Via-EUR"){
                    ViaEUR.issue(msg.value, msg.sender);
                    issued = true;
                }
                if(currency == "Via-INR"){
                    ViaINR.issue(msg.value, msg.sender);
                    issued = true;
                }
            }
        }
    }

    //redeem issued Via tokens
    function redeem() public payable{
        require(msg.sender != owner);
        require(msg.value != 0);
        //to do : integrate to bank's credit initiation API
    }

    //keep Via tokens in custody
    function deposit() public payable{
        require(msg.sender != owner);
        require(msg.value != 0);
        //to do : integrate to institutional custody
    }

}

contract ERC20{

    //variables
    uint256 totalSupply_;

    //Via balances held by this address
    mapping(address => uint256) public balances;
    //Delegates allowed to access this address
    mapping(address => mapping (address => uint256)) allowed;

    //erc20 standard events
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    //erc20 standard functions
    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint){
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint tokens) public returns (bool){
        require(tokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[receiver] = balances[receiver].add(tokens);
        emit Transfer(msg.sender, receiver, tokens);
        return true;
    }

    function approve(address spender, uint tokens)  public returns (bool){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint){
        return allowed[tokenOwner][spender];
    }

    function transferFrom(address owner, address buyer, uint tokens) public returns (bool){
        require(tokens <= balances[owner]);
        require(tokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(tokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(tokens);
        balances[buyer] = balances[buyer].add(tokens);
        Transfer(owner, buyer, tokens);
        return true;
    }

}


contract Token is ERC20{

    //address of the issuer of the Via, set once, never reset again
    address immutable issuer;

    //name of Via token (eg, Via-USD)
    string public immutable name;
    string public immutable symbol;
    

    //a Via has balance value equal to a fiat currency
    //for example, 1 Via-USD corresponds to 1 Via corresponding to the USD fiat
    struct Via{
        uint256 value;
        bytes32 currency;
    }

    mapping(address => Via[]) public holdings;

    //events to capture and report to Via oracle
    event sold(bytes32 currency, uint value);

    //constructor for creating Via token
    constructor(bytes32 tokenName) public returns (address){
        //setting issuer address and via token name
        issuer = msg.sender;   
        name = tokenName;
        symbol = tokenName;     
    }

    //requesting issue of Via for value and for fiat currency
    function issue(uint256 amount, address buyer) public {
        //ensure that request is sent by the issuer
        require(msg.sender == issuer);
        //ensure that brought amount is not zero
        require(amount != 0);
        //add amount in issuer/sender's balances
        super.balances[msg.sender] += amount;
        //transfer amount from issuer/sender to buyer 
        super.transfer(buyer, amount);
        //adjust total supply
        super.totalSupply_ += amount;
        //generate event
        emit sold(name, amount);
    }

    //requesting redemption of Via for value and for fiat currency
    function sell(bytes32 currency) payable public {
        //ensure that the issuer is not selling and that issuer setup is done
        require(msg.sender != issuer);
        //ensure that sold amount is not zero
        require(msg.value != 0);
        //remove via corresponding to currency (eg, ether or fiat or some other via-fiat) in beneficiary holdings
        bytes32 name;
        holdings[holdings.length].currency = name;
        //find Via exchange rate for currency from via oracle if currency is not ether, else first find value of ether in fiat
        uint exchanged;
        //subtract via exchanged for amount of currency to beneficiary holdings 
        holdings[holdings.length].value = exchanged;
        //adjust total supply
        totalSupply_ -= exchanged;
        //generate event
        emit sold(name, exchanged);
    }

}


contract Loan is ERC20{

    //a Via loan has some value, corresponds to a fiat currency
    //has a borrower and lender that have agreed to a zero coupon rate called price
    //and a tenure in unix timestamps of seconds counted from 1970-01-01
    //the boolean offer indicates if the Via loan is an offer to lend or not
    struct ViaLoans{
        uint256 value;
        bytes32 currency;
        address payable borrower;
        address payable lender;
        uint tenure;
        uint price;
        bool offer;
    }

    mapping(address => ViaLoans[]) public loans;

    //data structure to hold offers to lend Via in a specific fiat currency
    //over a floor price and floor rate and over a minimum tenure
    struct ViaOffers{
        uint256 value;
        bytes32 currency;
        uint tenure;
        uint price;
    }

    mapping(address => ViaOffers[]) public offers;

    //events to capture and report to Via oracle
    event lent(bytes32 currency, uint value, uint tenure, uint price);
  
    //offering a loan in a currency that is of most benefit
    function offer(bytes32 fiat, uint value) payable public {

    }

    //bid to borrow on an offer
    function bid(bytes32 currency, uint price, uint tenure, uint amount) payable public {
        //ensure that the issuer is not borrowing and that issuer setup is done
        require(msg.sender != issuer);
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

library SafeMath { // Only relevant functions
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256)   {
    uint256 c = a + b;
    assert(c >= a);
    return c;
    }
}

library ViaOracle{


}