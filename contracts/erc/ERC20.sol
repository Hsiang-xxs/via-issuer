// (c) Kallol Borah, 2020
// Base ERC20 implementation.

pragma solidity >=0.5.0 <0.7.0;

import "abdk-libraries-solidity/ABDKMathQuad.sol";

contract ERC20{

    using ABDKMathQuad for uint256;
    using ABDKMathQuad for int256;
    using ABDKMathQuad for bytes16;

    //address of the issuer of the Via, set once, never reset again
    address public issuer;

    //allowing 2-floating points for Via tokens
    uint8 public constant decimals = 2;

    //variables
    bytes16 totalSupply_;

    //Via balances held by this address
    mapping(address => bytes16) public balances;
    //Delegates allowed to access this address
    mapping(address => mapping (address => bytes16)) allowed;

    //erc20 standard events
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    //erc20 standard functions
    function totalSupply() public view returns (uint){
        return ABDKMathQuad.toUInt(totalSupply_);
    }

    function balanceOf(address tokenOwner) public view returns (uint){
        return ABDKMathQuad.toUInt(balances[tokenOwner]);
    }

    function transfer(address receiver, uint tokens) public returns (bool){
        require(ABDKMathQuad.cmp(ABDKMathQuad.fromUInt(tokens),balances[address(this)])==-1 || 
                ABDKMathQuad.cmp(ABDKMathQuad.fromUInt(tokens),balances[address(this)])==0);
        balances[address(this)] = ABDKMathQuad.sub(balances[address(this)], ABDKMathQuad.fromUInt(tokens));
        balances[receiver] = ABDKMathQuad.add(balances[receiver], ABDKMathQuad.fromUInt(tokens));
        emit Transfer(address(this), receiver, tokens);
        return true;
    }    

    function approve(address spender, uint tokens)  public returns (bool){
        allowed[msg.sender][spender] = ABDKMathQuad.fromUInt(tokens);
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint){
        return ABDKMathQuad.toUInt(allowed[tokenOwner][spender]);
    }

    function transferFrom(address owner, address buyer, uint tokens) public returns (bool){
        require(ABDKMathQuad.cmp(ABDKMathQuad.fromUInt(tokens), balances[owner])==-1 ||
                ABDKMathQuad.cmp(ABDKMathQuad.fromUInt(tokens), balances[owner])==0);
        //require(ABDKMathQuad.cmp(ABDKMathQuad.fromUInt(tokens), balances[owner])==0);
        require(ABDKMathQuad.cmp(ABDKMathQuad.fromUInt(tokens), allowed[owner][msg.sender])==-1 || ABDKMathQuad.cmp(ABDKMathQuad.fromUInt(tokens), allowed[owner][msg.sender])==0);
        balances[owner] = ABDKMathQuad.sub(balances[owner], ABDKMathQuad.fromUInt(tokens));
        allowed[owner][msg.sender] = ABDKMathQuad.sub(allowed[owner][msg.sender], ABDKMathQuad.fromUInt(tokens));
        balances[buyer] = ABDKMathQuad.add(balances[buyer], ABDKMathQuad.fromUInt(tokens));
        emit Transfer(owner, buyer, tokens);
        return true;
    }

}
