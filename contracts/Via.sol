// (c) Kallol Borah, 2020
// Implementation of the Via tokens with ERC20 compliance so that integration to wallets and exchanges is seamless.

pragma solidity >=0.4.16 <0.7.0;

import "./provableAPI.sol";

contract Issuer{

    //this issuer's address
    address owner;

    //instance variables for Via tokens
    Cash VUSD;
    Cash VEUR;
    Cash VINR;
    Bond VBUSD;
    Bond VBEUR;
    Bond VBINR;

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
        VUSD = new ViaUSD();
        VEUR = new ViaEUR();
        VINR = new ViaINR();
        VBUSD = new ViaBondUSD();
        VBEUR = new ViaBondEUR();
        VBINR = new ViaBondINR();

    }
    
    //receive ether, store it against sender address, and issue Via-USD against it
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
            if(depositors[msg.sender][p].currency=="ether"){
                depositors[msg.sender][p].value += msg.value;
                found = true;
            }
        }
        //if not found, add ether as currency and add what is sent by the depositor
        if(!found){
            depositors[msg.sender][p].currency = "ether";
            depositors[msg.sender][p].value = msg.value;
        }
        //issue Via-USD by default
        VUSD.issue(msg.value, msg.sender);
        depositors[msg.sender][p].value =- msg.value;
    }

    //issue Via tokens for different currencies against ether deposit
    //issue Via bonds for different currencies against ether deposit
    //todo : can we accept other via cash tokens in addition to ether ?
    function buy(bytes32 token, uint256 amount) public payable returns(bool){
        //issuer can not issue to itself
        require(msg.sender != owner);
        //amount of ether to consume to issue via tokens or via bonds can not be zero
        require(amount != 0);
        //the requestor should have some deposits
        require(depositors[msg.sender].length !=0);
        //store received ether
        bool found=false; 
        uint p=0;
        for(p=0; p<depositors[msg.sender].length; p++){
            if(depositors[msg.sender][p].currency=="ether"){
                depositors[msg.sender][p].value += msg.value;
                found = true;
            }
        }
        //if not found, add ether as currency and add what is sent by the depositor
        if(!found){
            depositors[msg.sender][p].currency = "ether";
            depositors[msg.sender][p].value = msg.value;
        }
        //request issue Via tokens or bonds against paid in ether
        bool issued = false;
        p=0;
        for(p=0; p<depositors[msg.sender].length; p++){
            //issue only if stored ether is more than amount to consume to issue via tokens
            if(depositors[msg.sender][p].value >= amount){ 
                //issue tokens
                if(token == "Via-USD"){
                    VUSD.issue(amount, msg.sender);
                    depositors[msg.sender][p].value =- amount;
                    issued = true;
                }
                if(token == "Via-EUR"){
                    VEUR.issue(amount, msg.sender);
                    depositors[msg.sender][p].value =- amount;
                    issued = true;
                }
                if(token == "Via-INR"){
                    VINR.issue(amount, msg.sender);
                    depositors[msg.sender][p].value =- amount;
                    issued = true;
                }
                //issue bonds
                if(token == "ViaBond-USD"){
                    VBUSD.issue(amount, msg.sender);
                    depositors[msg.sender][p].value =- amount;
                    issued = true;
                }
                if(token == "ViaBond-EUR"){
                    VBEUR.issue(amount, msg.sender);
                    depositors[msg.sender][p].value =- amount;
                    issued = true;
                }
                if(token == "ViaBond-INR"){
                    VBINR.issue(amount, msg.sender);
                    depositors[msg.sender][p].value =- amount;
                    issued = true;
                }
            }
        }
        return issued;
    }

    //redeem issued Via tokens
    function sell(bytes32 token, uint256 amount) public {
        require(msg.sender != owner);
        require(amount !=0);
        //redeem tokens
        if(token == "Via-USD"){
            VUSD.redeem(amount, msg.sender);
        }
        if(token == "Via-EUR"){
            VEUR.redeem(amount, msg.sender);
        }
        if(token == "Via-INR"){
            VINR.redeem(amount, msg.sender);
        }
        //redeem bonds
        if(token == "ViaBond-USD"){
            VBUSD.redeem(amount, msg.sender);
        }
        if(token == "ViaBond-EUR"){
            VBEUR.redeem(amount, msg.sender);
        }
        if(token == "ViaBond-INR"){
            VBINR.redeem(amount, msg.sender);
        }
        //to do : integrate to bank's credit initiation API if it is redemption in fiat

    }

    //keep Via tokens in custody
    function deposit() public payable{
        require(msg.sender != owner);
        require(msg.value != 0);
        //to do : integrate to institutional custody
    }

}

contract ERC20{

    using SafeMath for uint256;

    //address of the issuer of the Via, set once, never reset again
    address public issuer;

    //allowing 2-floating points for Via tokens
    uint8 public constant decimals = 2;

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

contract Cash is ERC20 {

    //events to capture and report to Via oracle
    event sold(string currency, uint value);

    //constructor for creating Via token
    constructor() public {
        //setting issuer address
        issuer = msg.sender;   
    }

    //requesting issue of Via to buyer for amount of ether
    function issue(uint256 amount, address buyer) public virtual{
        //ensure that request is sent by the issuer
        require(msg.sender == issuer);
        //ensure that brought amount is not zero
        require(amount != 0);
    }

    //requesting redemption of Via and transfer of ether to seller 
    //to do : redemption for fiat currency
    function redeem(uint256 amount, address seller) public virtual{
        //ensure request to redeem is authorized by issuer
        require(msg.sender == issuer);
        //ensure that sold amount is not zero
        require(amount != 0);
    }
    
    //uses Oraclize 
    function convertToVia(uint256 amount, bytes32 currency) public returns(uint256){
        //only issuer can call oracle
        require(msg.sender == issuer);
        //to first convert amount of ether passed to this function to USD
        uint256 amountInUSD = (amount/1000000000000000000)*uint256(stringToUint(new EthToUSD()));
        //to then convert USD to Via-currency if currency is not USD itself 
        if(currency!="USD"){
            uint256 inVia = amountInUSD * uint256(stringToUint(new ViaRate(+"Via_USD_to_Via_"+currency,"er")));
            return inVia;
        }
        else{
            return amountInUSD;
        }
    }

    //convert Via-currency (eg, Via-EUR, Via-INR, Via-USD) to Ether
    function convertFromVia(uint256 amount, bytes32 currency) public returns(uint256){
        //only issuer can call oracle
        require(msg.sender == issuer);
        if(currency!="USD"){
            uint256 amountInViaUSD = amount * uint256(stringToUint(new ViaRate(+"Via_"+currency+"_to_Via_USD","er")));
            uint256 inEth = amountInViaUSD * (1/uint256(stringToUint(new EthToUSD())));
            return inEth;
        }
        else{
            uint256 inEth = amount * (1/uint256(stringToUint(new EthToUSD())));
            return inEth;
        }
    }

}

contract ViaUSD is Cash{

    //name of Via token (eg, Via-USD)
    string public constant name = "Via-USD";
    string public constant symbol = "Via-USD";

    uint256 via;
    uint256 eth;

    //requesting issue of Via for amount of ether
    function issue(uint256 amount, address buyer) public override{
        //calling super
        super.issue(amount, buyer);
        //find amount of via tokens to transfer after applying exchange rate
        via = super.convertToVia(amount, "USD");
        //transfer amount from issuer/sender to buyer 
        transfer(buyer, via);
        //adjust total supply
        totalSupply_ += via;
        //generate event
        emit sold(name, amount);
    }

    //requesting redemption of Via-USD
    function redeem(uint256 amount, address seller) public override {
        //calling super
        super.redeem(amount, seller);
        //find amount of ether to transfer after applying via exchange rate
        eth = super.convertFromVia(amount, "USD");
        //only if this contract's ether balance is more than ether redeemed
        if(address(this).balance > eth){
            //transfer amount from issuer/sender to seller 
            transfer(seller, eth);
            //adjust total supply
            totalSupply_ +- amount;
            //generate event
            emit sold(name, amount);
        }
    }

}

contract ViaEUR is Cash{

    //name of Via token (eg, Via-USD)
    string public constant name = "Via-EUR";
    string public constant symbol = "Via-EUR";

    uint256 via;
    uint256 eth;

    //requesting issue of Via for amount of ether
    function issue(uint256 amount, address buyer) public override{
        //calling super
        super.issue(amount, buyer);
        //find amount of via tokens to transfer after applying exchange rate
        via = super.convertToVia(amount, "EUR");
        //transfer amount from issuer/sender to buyer 
        transfer(buyer, via);
        //adjust total supply
        totalSupply_ += via;
        //generate event
        emit sold(name, amount);
    }

    //requesting redemption of Via-EUR
    function redeem(uint256 amount, address seller) public override {
        //calling super
        super.redeem(amount, seller);
        //find amount of ether to transfer after applying via exchange rate
        eth = super.convertFromVia(amount, "EUR");
        //only if this contract's ether balance is more than ether redeemed
        if(address(this).balance > eth){
            //transfer amount from issuer/sender to seller 
            transfer(seller, eth);
            //adjust total supply
            totalSupply_ +- amount;
            //generate event
            emit sold(name, amount);
        }
    }

}

contract ViaINR is Cash{

    //name of Via token (eg, Via-USD)
    string public constant name = "Via-INR";
    string public constant symbol = "Via-INR";

    uint256 via;
    uint256 eth;

    //requesting issue of Via for amount of ether
    function issue(uint256 amount, address buyer) public override{
        //calling super
        super.issue(amount, buyer);
        //find amount of via tokens to transfer after applying exchange rate
        via = super.convertToVia(amount, "INR");
        //transfer amount from issuer/sender to buyer 
        transfer(buyer, via);
        //adjust total supply
        totalSupply_ += via;
        //generate event
        emit sold(name, amount);
    }

    //requesting redemption of Via-INR
    function redeem(uint256 amount, address seller) public override {
        //calling super
        super.redeem(amount, seller);
        //find amount of ether to transfer after applying via exchange rate
        eth = super.convertFromVia(amount, "INR");
        //only if this contract's ether balance is more than ether redeemed
        if(address(this).balance > eth){
            //transfer amount from issuer/sender to seller 
            transfer(seller, eth);
            //adjust total supply
            totalSupply_ +- amount;
            //generate event
            emit sold(name, amount);
        }
    }

}

contract Bond is ERC20{

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
        uint timeOfIssue;
        uint tenure; 
    }

    mapping(address => loan) public loans;

    constructor() public {
        //setting issuer address
        issuer = msg.sender;   
    }

    //events to capture and report to Via oracle
    event lent(bytes32 currency, uint value, uint price, uint tenure);
    event redeemed(bytes32 currency, uint value, uint price, uint tenure);

    //requesting issue of Via bonds to borrower for amount of ether as collateral
    function issue(uint256 amount, address borrower) public virtual{
        //ensure that request is sent by the issuer
        require(msg.sender == issuer);
        //ensure that brought amount is not zero
        require(amount != 0);
    }

    //requesting redemption of Via bonds and transfer of ether collateral to borrower 
    //to do : redemption of Via bonds for fiat currency
    function redeem(uint256 amount, address borrower) public virtual{
        //ensure request to redeem is authorized by issuer
        require(msg.sender == issuer);
        //ensure that sold amount is not zero
        require(amount != 0);
    }

    //uses Oraclize to find Via face value of amount passed in currency
    function convertToVia(uint256 amount, bytes32 currency) public returns(uint256){
        //only issuer can call oracle
        require(msg.sender == issuer);
        //to first convert amount of ether passed to this function to USD
        uint256 amountInUSD = (amount/1000000000000000000)*uint256(stringToUint(new EthToUSD()));
        //to then convert USD to Via-currency if currency is not USD itself 
        if(currency!="USD"){
            uint256 inVia = amountInUSD * uint256(stringToUint(new ViaRate(+"Via_USD_to_Via_"+currency, "er")));
            return inVia;
        }
        else{
            return amountInUSD;
        }
    }

    //convert Via-currency (eg, Via-EUR, Via-INR, Via-USD) to Ether
    function convertFromVia(uint256 amount, bytes32 currency) public returns(uint256){
        //only issuer can call oracle
        require(msg.sender == issuer);
        if(currency!="USD"){
            uint256 amountInViaUSD = amount * uint256(stringToUint(new ViaRate(+"Via_"+currency+"_to_Via_USD","er")));
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
        require(msg.sender == issuer);
        //to first convert amount of ether passed to this function to USD
        uint256 amountInUSD = (amount/1000000000000000000)*uint256(stringToUint(new EthToUSD()));
        //to then get Via interest rates from oracle and calculate zero coupon bond price
        if(currency!="USD"){
            return amountInUSD / (1 + uint256(stringToUint(new ViaRate(+"Via_USD_to_Via_"+currency, "ir")))) ^ tenure;
        }
        else{
            return amountInUSD / (1 + uint256(stringToUint(new ViaRate(+"USD", "ir")))) ^ tenure;
        }
    }

    //calculate price of redeeming zero coupon bond in currency and for amount to borrower who may redeem before end of year
    function getBondValueToRedeem(uint256 _amount, bytes32 _currency, address _borrower) public returns(uint256, uint){
        require(msg.sender == issuer);
        //find out if bond is present in list of issued bonds
        uint256 toRedeem;
        for(uint p=0; p < loans[msg.sender][p].length; p++){
            //if bond is found to be issued
            if(loans[msg.sender][p].borrower == _borrower && 
                loans[msg.sender][p].currency == _currency &&
                loans[msg.sender][p].price >= amount){
                    uint timeOfIssue = loans[msg.sender][p].timeOfIssue;
                    //if entire amount is to be redeemed, remove issued bond from store
                    if(loans[msg.sender][p].price - amount ==0){
                        toRedeem = amount;
                        delete(loans[msg.sender][p]);
                    }else{
                        //else, reduce outstanding value of bond
                        loans[msg.sender][p].price = loans[msg.sender][p].price - amount;
                    }
                    return(convertFromVia(toRedeem, _currency), now - timeOfIssue);
            }
        }
        return(0,0);
    }

    function storeIssuedBond(address _borrower, bytes32 _currency, uint256 _facevalue, uint256 _viabond, uint256 _amount, bytes32 _collateralCurrency, uint _timeofissue, uint _tenure){
        require(msg.sender == issuer);
        loans[msg.sender][loans.length].borrower = _borrower;
        loans[msg.sender][loans.length].currency = _currency;
        loans[msg.sender][loans.length].faceValue = _facevalue;
        loans[msg.sender][loans.length].price = _viabond;
        loans[msg.sender][loans.length].collateralAmount = _amount;
        loans[msg.sender][loans.length].collateralCurrency = _collateralCurrency; //to do : we need to support fiat and Via currencies too
        loans[msg.sender][loans.length].timeOfIssue = _timeofissue;
        loans[msg.sender][loans.length].tenure = _tenure; //to do : we need to support different tenures also
    }

}

contract ViaBondUSD is Bond{

    //name of Via bond (eg, ViaBond-USD)
    string public constant name = "Via-USD%";
    string public constant symbol = "Via-USD%";

    uint256 viabond;
    uint256 facevalue;
    uint256 eth;
    uint balanceTenure;

    //requesting issue of Via bond for amount of ether
    function issue(uint256 amount, address borrower) public override{
        //calling super
        super.issue(amount, borrower);
        //find face value of bond in via denomination
        facevalue = super.convertToVia(amount, "USD");
        //find price of via bonds to transfer after applying exchange rate
        viabond = super.getBondValueToIssue(amount, "USD", 1); 
        //transfer amount from issuer/sender to borrower 
        transfer(borrower, viabond);
        //adjust total supply
        totalSupply_ += viabond;
        //keep track of issues
        storeIssuedBond(borrower, "Via-USD", facevalue, viabond, amount, "ether", now, 1);
        //generate event
        emit lent(name, amount, viabond, 1);
    }

    //requesting redemption of Via bonds
    function redeem(uint256 amount, address borrower) public override {
        //calling super
        super.redeem(amount, borrower);
        //find amount of ether to transfer 
        var(eth, balanceTenure) = super.getBondValueToRedeem(amount, "USD", borrower);
        //only if this contract's ether balance is more than ether redeemed
        if(address(this).balance > eth){
            //transfer amount from issuer/sender to borrower 
            transfer(borrower, eth);
            //adjust total supply
            totalSupply_ +- amount;
            //generate event
            emit redeemed(name, amount, eth, balanceTenure);
        }
    }
}

contract ViaBondEUR is Bond{

    //name of Via bond (eg, ViaBond-USD)
    string public constant name = "Via-EUR%";
    string public constant symbol = "Via-EUR%";

    uint256 viabond;
    uint256 facevalue;
    uint256 eth;
    uint balanceTenure;

    //requesting issue of Via bond for amount of ether
    function issue(uint256 amount, address borrower) public override{
        //calling super
        super.issue(amount, borrower);
        //find face value of bond in via denomination
        facevalue = super.convertToVia(amount, "EUR");
        //find price of via bonds to transfer after applying exchange rate
        viabond = super.getBondValueToIssue(amount, "EUR", 1); 
        //transfer amount from issuer/sender to borrower 
        transfer(borrower, viabond);
        //adjust total supply
        totalSupply_ += viabond;
        //keep track of issues
        storeIssuedBond(borrower, "Via-EUR", facevalue, viabond, amount, "ether", now, 1);
        //generate event
        emit lent(name, amount, viabond, 1);
    }

    //requesting redemption of Via bonds
    function redeem(uint256 amount, address borrower) public override {
        //calling super
        super.redeem(amount, borrower);
        //find amount of ether to transfer 
        var(eth, balanceTenure) = super.getBondValueToRedeem(amount, "EUR", borrower);
        //only if this contract's ether balance is more than ether redeemed
        if(address(this).balance > eth){
            //transfer amount from issuer/sender to borrower 
            transfer(borrower, eth);
            //adjust total supply
            totalSupply_ +- amount;
            //generate event
            emit redeemed(name, amount, eth, balanceTenure);
        }
    }
}

contract ViaBondINR is Bond{

    //name of Via bond (eg, ViaBond-USD)
    string public constant name = "Via-INR%";
    string public constant symbol = "Via-INR%";

    uint256 viabond;
    uint256 facevalue;
    uint256 eth;
    uint balanceTenure;

    //requesting issue of Via bond for amount of ether
    function issue(uint256 amount, address borrower) public override{
        //calling super
        super.issue(amount, borrower);
        //find face value of bond in via denomination
        facevalue = super.convertToVia(amount, "INR");
        //find price of via bonds to transfer after applying exchange rate
        viabond = super.getBondValueToIssue(amount, "INR", 1); 
        //transfer amount from issuer/sender to borrower 
        transfer(borrower, viabond);
        //adjust total supply
        totalSupply_ += viabond;
        //keep track of issues
        storeIssuedBond(borrower, "Via-INR", facevalue, viabond, amount, "ether", now, 1);
        //generate event
        emit lent(name, amount, viabond, 1);
    }

    //requesting redemption of Via bonds
    function redeem(uint256 amount, address borrower) public override {
        //calling super
        super.redeem(amount, borrower);
        //find amount of ether to transfer 
        var(eth, balanceTenure) = super.getBondValueToRedeem(amount, "INR", borrower);
        //only if this contract's ether balance is more than ether redeemed
        if(address(this).balance > eth){
            //transfer amount from issuer/sender to borrower 
            transfer(borrower, eth);
            //adjust total supply
            totalSupply_ +- amount;
            //generate event
            emit redeemed(name, amount, eth, balanceTenure);
        }
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

    //added from https://ethereum.stackexchange.com/questions/62371/convert-a-string-to-a-uint256-with-error-handling
    function stringToUint(string s) view returns (uint, bool) {
        bool hasError = false;
        bytes memory b = bytes(s);
        uint result = 0;
        uint oldResult = 0;
        for (uint i = 0; i < b.length; i++) { // c = b[i] was not needed
            if (b[i] >= 48 && b[i] <= 57) {
                // store old value so we can check for overflows
                oldResult = result;
                result = result * 10 + (uint(b[i]) - 48); // bytes and int are not compatible with the operator -.
                // prevent overflows
                if(oldResult > result ) {
                    // we can only get here if the result overflowed and is smaller than last stored value
                    hasError = true;
                }
            } else {
                hasError = true;
            }
        }
        return (result, hasError); 
    }
}

//taken from Oraclize's examples, with minor modifications
contract ViaRate is usingProvable {

    event LogNewProvableQuery(string description);
    event LogResult(string result);

    bytes32 currency;
    bytes32 url;

    constructor(bytes32 _currency, bytes32 _ratetype)
        public
    {
        provable_setProof(proofType_Android | proofStorage_IPFS);
        currency = _currency;
    }

    function __callback(
        bytes32 _myid,
        string memory _result,
        bytes memory _proof
    )
        public returns(string)
    {
        require(msg.sender == provable_cbAddress());
        emit LogResult(_result);
        return _result;
    }

    function request(
        string memory _query,
        string memory _method,
        string memory _url,
        string memory _kwargs
    )
        public
        payable
    {
        if (provable_getPrice("computation") > address(this).balance) {
            emit LogNewProvableQuery("Provable query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
            provable_query("computation",
                [_query,
                _method,
                _url,
                _kwargs]
            );
        }
    }
    
    //uses the processing engine for via exchange rates
    function requestPost()
        public
        payable
    {  
        if(_ratetype == "er")
            url = "https://via-oracle.azurewebsites.net/api/via/er";
        else if(_ratetype == "ir")
            url = "https://via-oracle.azurewebsites.net/api/via/ir";

        request("QmdKK319Veha83h6AYgQqhx9YRsJ9MJE7y33oCXyZ4MqHE",
                "POST",
                url,
                '{"json": {"postcodes" : ["'+currency+'"]}}'
                );
    }

}

//taken from Oraclize's examples, with minor modifications
contract EthToUSD is usingProvable {

    event LogNewProvableQuery(string description);
    event LogNewKrakenPriceTicker(string price);

    constructor()
        public
    {
        provable_setProof(proofType_Android | proofStorage_IPFS);
        update(); // Update price on contract creation...
    }

    function __callback(
        bytes32 _myid,
        string memory _result,
        bytes memory _proof
    )
        public returns (string)
    {
        require(msg.sender == provable_cbAddress());
        emit LogNewKrakenPriceTicker(_result);
        return _result;
    }

    function update()
        public
        payable
    {
        if (provable_getPrice("URL") > address(this).balance) {
            emit LogNewProvableQuery("Provable query was NOT sent, please add some ETH to cover for the query fee!");
        } else {
            emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
            provable_query(60, "URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHXUSD.c.0");
        }
    }
}
