// (c) Kallol Borah, 2020
// Implementation of the Via cash token.

pragma solidity >=0.5.0 <0.7.0;

import "./erc/ERC20.sol";
import "./oraclize/ViaOracle.sol";
import "./Factory.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";

contract Cash is ERC20, Initializable, Ownable {

    using ABDKMathQuad for uint256;
    using ABDKMathQuad for int256;
    using ABDKMathQuad for bytes16;

    //via factory address
    Factory private factory;

    //via oracle
    ViaOracle private oracle;

    //name of Via cash token (eg, Via-USD)
    bytes32 public name;
    bytes32 public symbol;

    //mapping of buyers (address) to currency (bytes32) to deposit (bytes16) amounts they make against which via cash tokens are issued
    mapping(address => mapping(bytes32 => bytes16)) public deposits;

    //callback identifiers (request_ids) for Oraclize
    bytes32 EthXid;
    bytes32 ViaXid;
    
    //data structure holding details of currency conversion requests pending on oraclize
    struct conversion{
        address party;
        bytes32 operation;
        bytes32 paid_in_currency;
        bytes32 payout_currency;
        bytes32 EthXid;
        bytes16 amount;
        bytes16 EthXvalue;
        bytes16 ViaXvalue;
    }

    //queue of pending conversion requests with each pending request mapped to a request_id returned by oraclize
    mapping(bytes32 => conversion) private conversionQ;

    //events to capture and report to Via oracle
    event ViaCashIssued(bytes32 currency, bytes16 value);
    event ViaCashRedeemed(bytes32 currency, bytes16 value);

    //initiliaze proxies
    function initialize(bytes32 _name, bytes32 _type, address _owner, address _oracle, address _token) public {
        Ownable.initialize(_owner);
        factory = Factory(_owner);
        oracle = ViaOracle(_oracle);
        name = _name;
        symbol = _type;
    }

    //handling pay in of ether for issue of via cash tokens
    function() external payable{
        //ether paid in
        require(msg.value !=0);
        //issue via cash tokens
        issue(ABDKMathQuad.fromUInt(msg.value), msg.sender, "ether");
    }

    //overriding this function of ERC20 standard for transfer of via cash tokens to other users or to this contract for redemption
    function transferFrom(address sender, address receiver, uint256 tokens) public returns (bool){
        //ensure sender has enough tokens in balance before transferring or redeeming them
        require(ABDKMathQuad.cmp(balances[sender],ABDKMathQuad.fromUInt(tokens))==1 ||
                ABDKMathQuad.cmp(balances[sender],ABDKMathQuad.fromUInt(tokens))==0);
        //check if tokens are being transferred to this cash contract
        if(receiver == address(this)){
            //if token name is the same, this transfer has to be redeemed
            if(redeem(ABDKMathQuad.fromUInt(tokens), sender, name))
                return true;
            else
                return false;
        }
        //else request issue of cash tokens requested from receiver
        else if(factory.getType(receiver)=="ViaCash"){
            //only issue if cash tokens are paid in, since bond tokens can't be paid to issue bond token
            if(Cash(address(uint160(receiver))).issue(ABDKMathQuad.fromUInt(tokens), sender, name)){
                //transfer sent tokens and its collateral to this contract's balance because that is required for redemption
                if(transferToken(sender, address(this), tokens)){
                    //adjust total supply
                    totalSupply_ = ABDKMathQuad.sub(totalSupply_, ABDKMathQuad.fromUInt(tokens));
                    //transfer collateral from sender to contract for cash tokens transferred 
                    return true;
                }
                else
                    return false;
            }
            else
                return false;
        }
        else{
            //else, tokens are being sent to another user's account
            //sending contract should be allowed by token owner to make this transfer
            //allowed[sender][msg.sender] = ABDKMathQuad.sub(allowed[sender][msg.sender], ABDKMathQuad.fromUInt(tokens));
            if(transferToken(sender, receiver, tokens))
                return true;
            else
                return false;
        }
    }

    //transfer tokens between one user to another user account, or
    //transfer tokens between one user account to this contract for future redemption
    function transferToken(address sender, address receiver, uint256 tokens) public returns (bool){
        balances[sender] = ABDKMathQuad.sub(balances[sender], ABDKMathQuad.fromUInt(tokens));
        balances[receiver] = ABDKMathQuad.add(balances[receiver], ABDKMathQuad.fromUInt(tokens));
        //transfer paid in deposit from sender as well
        for(uint256 q=0; q<factory.getTokenCount(); q++){
            address viaAddress = factory.tokens(q);
            if(factory.getType(viaAddress) == "ViaCash" && factory.getName(viaAddress) == name){
                deposits[receiver][name] = ABDKMathQuad.add(deposits[receiver][name], ABDKMathQuad.fromUInt(tokens));
                deposits[sender][name] = ABDKMathQuad.sub(deposits[sender][name], ABDKMathQuad.fromUInt(tokens));
                emit Transfer(sender, receiver, tokens);
                return true;
            }
        }
        return false;
    }
    
    //add to token balance of this contract from token balance of sender
    function addToBalance(bytes16 tokens, address sender) public returns (bool){
        //sender should have more tokens than being transferred
        if(ABDKMathQuad.cmp(tokens, balances[sender])==-1 || ABDKMathQuad.cmp(tokens, balances[sender])==0){
            balances[sender] = ABDKMathQuad.sub(balances[sender], tokens);
            balances[address(this)] = ABDKMathQuad.add(balances[address(this)], tokens);
            return true;
        }
        else
            return false;
    }

    //deduct token balance from this contract and add token balance to receiver
    function deductFromBalance(bytes16 tokens, address receiver) public returns (bytes16){
        //this cash token issuer should have more tokens than being deducted
        if(ABDKMathQuad.cmp(tokens, balances[address(this)])==-1 || ABDKMathQuad.cmp(tokens, balances[address(this)])==0){
            balances[address(this)] = ABDKMathQuad.sub(balances[address(this)], tokens);
            balances[receiver] = ABDKMathQuad.add(balances[receiver], tokens);
            return ABDKMathQuad.fromUInt(0);
        }
        else{
            bytes16 balance = ABDKMathQuad.sub(tokens, balances[address(this)]);
            balances[receiver] = ABDKMathQuad.add(balances[receiver], balances[address(this)]);
            balances[address(this)] = 0;            
            return balance;
        }
    }

    //requesting issue of Via to buyer for amount of ether or some other via cash token paid in and stored in cashContract
    function issue(bytes16 amount, address buyer, bytes32 currency) public returns(bool){
        //ensure that brought amount is not zero
        require(amount != 0);
        //find amount of via cash tokens to transfer after applying exchange rate
        if(currency=="ether"){
            //if ether is paid in for issue of non-USD cash token, we need the exchange rate of ether to the USD (ethusd)
            //and the exchange rate of Via-USD to the requested non-USD cash token (eg, Via-EUR)
            if(name!="Via-USD"){
                ViaXid = oracle.request(abi.encodePacked("Via_USD_to_", name),"ver","Cash", address(this)); 
                EthXid = oracle.request("eth","ethusd","EthCash", address(this)); 
                conversionQ[ViaXid] = conversion(buyer, "issue", currency, name, EthXid, amount, ABDKMathQuad.fromUInt(0), ABDKMathQuad.fromUInt(0));
            }
            //if ether is paid in for issue of Via-USD cash token, then all we need is the exchange rate of ether to USD (ethusd)
            //since the exchange rate of USD to Via-USD is always 1
            else{
                EthXid = oracle.request("eth","ethusd","EthCash", address(this)); 
                conversionQ[EthXid] = conversion(buyer, "issue", currency, name, EthXid, amount, ABDKMathQuad.fromUInt(0), ABDKMathQuad.fromUInt(1));
            }
        }
        //if ether is not paid in and instead, some other Via cash token is paid in
        //we need to find the exchange rate between the paid in Via cash token and the cash token this cash contract represents
        else{
            ViaXid = oracle.request(abi.encodePacked(currency, "_to_", name),"er","Cash", address(this)); 
            conversionQ[ViaXid] = conversion(buyer, "issue", currency, name, ABDKMathQuad.fromUInt(0), amount, ABDKMathQuad.fromUInt(0), ABDKMathQuad.fromUInt(0));
        }
        return true;
    }

    //requesting redemption of Via cash token and transfer of currency it was issued against
    function redeem(bytes16 amount, address seller, bytes32 token) private returns(bool){
        //if amount is not zero, there is some left to redeem
        if(amount != 0){
            bytes32 currency_in_deposit;
            //find currency that seller had deposited earlier
            for(uint256 q=0; q<factory.getTokenCount(); q++){
                address viaAddress = factory.tokens(q);
                if(factory.getType(viaAddress) == "ViaCash" && deposits[seller][factory.getName(viaAddress)]>0){
                    currency_in_deposit = factory.getName(viaAddress);
                }
            }
            //if no more currencies to redeem and amount to redeem is not zero, then redemption fails
            if(currency_in_deposit=="" && deposits[seller]["ether"]>0)
                currency_in_deposit = "ether";
            else{
                //if seller has no deposits against paid in tokens, the tokens could have been transferred to this user from a redemption of tokens
                //which were transferred to this user from another user
                for(uint256 q=0; q<factory.getTokenCount(); q++){
                    address viaAddress = factory.tokens(q);
                    if(factory.getType(viaAddress) == "ViaCash" && deposits[address(this)][factory.getName(viaAddress)]>0){
                        currency_in_deposit = factory.getName(viaAddress);
                    }
                }
                if(currency_in_deposit=="" && deposits[address(this)]["ether"]>0)
                    currency_in_deposit = "ether";
                else
                    return false;
            }
            //if currency that this cash token can be redeemed in is ether
            if(currency_in_deposit=="ether"){
                //and if cash token to redeem is not Via USD, we need to get the exchange rate of ether to the Via-USD, 
                //and then the exchange rate of this Via cash token to redeeem and the Via-USD
                if(token!="Via_USD"){
                    EthXid = oracle.request("eth","ethusd","EthCash", address(this)); 
                    ViaXid = oracle.request(abi.encodePacked(token, "_to_Via_USD"),"ver","Cash", address(this)); 
                    conversionQ[ViaXid] = conversion(seller, "redeem", token, currency_in_deposit, EthXid, amount, ABDKMathQuad.fromUInt(0), ABDKMathQuad.fromUInt(0));
                }
                //otherwise if the cash token to redeem is a Via USD, all we need is the exchange rate of ether to the USD
                else{
                    EthXid = oracle.request("eth","ethusd","Cash", address(this)); 
                    conversionQ[EthXid] = conversion(seller, "redeem", token, currency_in_deposit, EthXid, amount, ABDKMathQuad.fromUInt(0), ABDKMathQuad.fromUInt(1));
                }
            }
            //else if the currency this cash token can be redeemed is another Via cash token,
            //we just need the exchange rate of this Via cash token to redeem and the currency that is in deposit
            else{
                ViaXid = oracle.request(abi.encodePacked(token, "_to_", currency_in_deposit),"er","Cash", address(this)); //"1234"; //only for testing
                conversionQ[ViaXid] = conversion(seller, "redeem", token, currency_in_deposit, ABDKMathQuad.fromUInt(0), amount, ABDKMathQuad.fromUInt(0), ABDKMathQuad.fromUInt(0));
            }
        }
        else
            //redemption is complete when amount to redeem becomes zero
            return true;
    }    

    //function called back from Via oracle
    function convert(bytes32 txId, bytes16 result, bytes32 rtype) public {
        //check type of result returned
        if(rtype =="ethusd"){
            conversionQ[txId].EthXvalue = result;
        }
        if(rtype == "er"){
            conversionQ[txId].ViaXvalue = result;
        }
        if(rtype == "ver"){
            conversionQ[txId].ViaXvalue = result;
        }
        //check if cash needs to be issued or redeemed
        if(conversionQ[txId].operation=="issue"){
            if(rtype == "ethusd" || rtype == "ver"){
                //for issuing to happen when ether is paid in,
                //value of ethX (ie ether exchange rate to USD) has to be non-zero 
                //and viaX (ie via exchange) should be non-zero if cash token to be issued is not Via-USD. We store 1 for ViaXvalue if Via-USD has to be issued
                if(ABDKMathQuad.cmp(conversionQ[txId].EthXvalue, ABDKMathQuad.fromUInt(0))!=0 && ABDKMathQuad.cmp(conversionQ[txId].ViaXvalue, ABDKMathQuad.fromUInt(0))!=0){
                    bytes16 via = convertToVia(conversionQ[txId].amount, conversionQ[txId].paid_in_currency,conversionQ[txId].EthXvalue,conversionQ[txId].ViaXvalue);
                    finallyIssue(via, conversionQ[txId].party, conversionQ[txId].paid_in_currency, conversionQ[txId].amount);
                }
            }
            else if(rtype == "er"){
                //for issuing to happen if some other Via cash token is paid in, 
                //only the value of ViaX (ie exchange rate of paid in Via cash token to Via cash token to issue) has to be non-zero
                if(ABDKMathQuad.cmp(conversionQ[txId].ViaXvalue, ABDKMathQuad.fromUInt(0))!=0){
                    bytes16 via = convertToVia(conversionQ[txId].amount, conversionQ[txId].paid_in_currency,conversionQ[txId].EthXvalue,conversionQ[txId].ViaXvalue);
                    finallyIssue(via, conversionQ[txId].party, conversionQ[txId].paid_in_currency, conversionQ[txId].amount);
                }
            }
        }
        else if(conversionQ[txId].operation=="redeem"){
            if(rtype == "ethusd" || rtype == "ver"){
                //for redemption to happen in ether,
                //value of ethX (ie ether exchange rate to USD) has to be non-zero 
                //and viaX (ie via exchange) should be non-zero if cash token to be redeemed is not Via-USD. We store 1 for ViaXvalue if Via-USD has to be redeemed
                if(ABDKMathQuad.cmp(conversionQ[txId].EthXvalue, ABDKMathQuad.fromUInt(0))!=0 && ABDKMathQuad.cmp(conversionQ[txId].ViaXvalue, ABDKMathQuad.fromUInt(0))!=0){
                    bytes16 value = convertFromVia(conversionQ[txId].amount, conversionQ[txId].payout_currency,conversionQ[txId].EthXvalue,conversionQ[txId].ViaXvalue);
                    finallyRedeem(value, conversionQ[txId].payout_currency, conversionQ[txId].party, conversionQ[txId].amount);
                }
            }
            else if(rtype == "er"){
                //for redemption to happen in some other Via cash token
                //the viaX (ie via exchange rate) between the cash token to redeem and the cash token in deposit should be non-zero
                if(ABDKMathQuad.cmp(conversionQ[txId].ViaXvalue, ABDKMathQuad.fromUInt(0))!=0){
                    bytes16 value = convertFromVia(conversionQ[txId].amount, conversionQ[txId].payout_currency,conversionQ[txId].EthXvalue,conversionQ[txId].ViaXvalue);
                    finallyRedeem(value, conversionQ[txId].payout_currency, conversionQ[txId].party, conversionQ[txId].amount);
                }
            }
        }
    }

    //via is the number of this via cash token that is being issued, party is the user account address to which issued tokens are credited
    function finallyIssue(bytes16 via, address party, bytes32 currency, bytes16 amount) private {
        //add paid in currency to depositor
        if(deposits[party][currency]==0){
            deposits[party][currency] = amount;
        }
        else{
            deposits[party][currency] = ABDKMathQuad.add(deposits[party][currency], amount);
        }
        if(currency=="ether"){
            //add via to this contract's balance first (ie issue them first)
            balances[address(this)] = ABDKMathQuad.add(balances[address(this)], via);
            //transfer amount to buyer 
            transfer(party, ABDKMathQuad.toUInt(via));
            //adjust total supply
            totalSupply_ = ABDKMathQuad.add(totalSupply_, via);
        }
        else{
            balances[party] = ABDKMathQuad.add(balances[party], via);
            //adjust total supply
            totalSupply_ = ABDKMathQuad.add(totalSupply_, via);
        }
        //generate event
        emit ViaCashIssued(name, via);
    }

    //value is the redeemable amount in the currency to pay out
    //currency is the pay out currency or currency to pay out
    //party is the user account address to which redemption has to be credited
    //amount is the number of this via cash token that needs to be redeemed
    function finallyRedeem(bytes16 value, bytes32 currency, address party, bytes16 amount) private {
        //check if currency in which redemption is to be done has sufficient balance
        if(currency=="ether"){
            if(ABDKMathQuad.cmp(deposits[party]["ether"], value)==1 || ABDKMathQuad.cmp(deposits[party]["ether"], value)==0){
                deposits[party]["ether"] = ABDKMathQuad.sub(deposits[party]["ether"], value);
                //send redeemed ether to party
                address(uint160(party)).transfer(ABDKMathQuad.toUInt(value));
                //reduces balances
                balances[party] = ABDKMathQuad.sub(balances[party], amount);
                //adjust total supply
                totalSupply_ = ABDKMathQuad.sub(totalSupply_, amount);
                //generate event
                emit ViaCashRedeemed(currency, value);
            }
            //amount to redeem is more than what is in deposit, so we need to remove deposit after redemption,
            //and call the redeem function again for the balance amount that is not yet redeemed
            else{
                bytes16 proportionRedeemed = ABDKMathQuad.div(deposits[party]["ether"], value);
                bytes16 balanceToRedeem = ABDKMathQuad.mul(amount,ABDKMathQuad.sub(ABDKMathQuad.fromUInt(1), proportionRedeemed));
                //send redeemed ether to party which is all of the ether in deposit with this user (party)
                address(uint160(party)).transfer(ABDKMathQuad.toUInt(deposits[party]["ether"]));
                //reduces balances
                balances[party] = ABDKMathQuad.sub(balances[party], ABDKMathQuad.mul(amount, proportionRedeemed));
                //adjust total supply
                totalSupply_ = ABDKMathQuad.sub(totalSupply_, ABDKMathQuad.mul(amount, proportionRedeemed));
                //generate event
                emit ViaCashRedeemed(currency, deposits[party]["ether"]);
                //deposit of ether with the user (party) becomes zero
                deposits[party]["ether"] = 0;
                redeem(balanceToRedeem, party, name);
            }
        }
        //else currency to redeem is not ether
        else{
            for(uint256 q=0; q<factory.getTokenCount(); q++){
                address viaAddress = factory.tokens(q);
                if(factory.getName(viaAddress) == currency && factory.getType(viaAddress) == "ViaCash"){
                    if(ABDKMathQuad.cmp(Cash(address(uint160(viaAddress))).deductFromBalance(value, party),0)==1){
                        deposits[party][currency] = ABDKMathQuad.sub(deposits[party][currency], value);
                        //reduces balances
                        balances[party] = ABDKMathQuad.sub(balances[party], amount);
                        //adjust total supply
                        totalSupply_ = ABDKMathQuad.sub(totalSupply_, amount);
                        //generate event
                        emit ViaCashRedeemed(currency, value);
                    }
                    //amount to redeem is more than what is in deposit, so we need to remove deposit after redemption,
                    //and call the redeem function again for the balance amount that is not yet redeemed
                    else{
                        bytes16 proportionRedeemed = ABDKMathQuad.div(deposits[party][currency], value);
                        bytes16 balanceToRedeem = ABDKMathQuad.mul(amount, ABDKMathQuad.sub(ABDKMathQuad.fromUInt(1), proportionRedeemed));
                        //reduces balances
                        balances[party] = ABDKMathQuad.sub(balances[party], ABDKMathQuad.mul(amount, proportionRedeemed));
                        //adjust total supply
                        totalSupply_ = ABDKMathQuad.sub(totalSupply_, ABDKMathQuad.mul(amount, proportionRedeemed));
                        //generate event
                        emit ViaCashRedeemed(currency, deposits[party][currency]);
                        //deposit of the currency with the user (party) becomes zero
                        deposits[party][currency] = 0;
                        redeem(balanceToRedeem, party, name);
                    }
                }
            }
        }
    }
    
    //get Via exchange rates from oracle and convert given currency and amount to via cash token
    function convertToVia(bytes16 amount, bytes32 paid_in_currency, bytes16 ethusd, bytes16 viarate) private returns(bytes16){
        if(paid_in_currency=="ether"){
            //to first convert amount of ether passed to this function to USD
            bytes16 amountInUSD = ABDKMathQuad.div(ABDKMathQuad.mul(amount, ethusd), ABDKMathQuad.fromUInt(1000000000000000000));
            //to then convert USD to Via-currency if currency of this contract is not USD itself
            if(name!="Via-USD"){
                bytes16 inVia = ABDKMathQuad.mul(amountInUSD, viarate);
                return inVia;
            }
            else{
                return amountInUSD;
            }
        }
        //if currency paid in another via currency
        else{
            bytes16 inVia = ABDKMathQuad.mul(amount, viarate);
            return inVia;
        }
    }

    //convert Via-currency (eg, Via-EUR, Via-INR, Via-USD) to Ether or another Via currency
    //viarate is 1 if pay out currency is ether and this via cash token to redeem is Via-USD, otherwise viarate is exchange rate between this cash token to Via-USD
    //if pay out currency is not ether, then viarate is exchange rate between this cash token and cash token to pay out 
    function convertFromVia(bytes16 amount, bytes32 payout_currency, bytes16 ethusd, bytes16 viarate) private returns(bytes16){
        //if currency to convert to is ether
        if(payout_currency=="ether"){
            bytes16 amountInViaUSD = ABDKMathQuad.mul(amount, viarate);
            bytes16 inEth = ABDKMathQuad.div(amountInViaUSD, ethusd);
            return inEth;
        }
        //else convert to another via currency
        else{
            return ABDKMathQuad.mul(viarate, amount);
        }
    }
    
}
