// (c) Kallol Borah, 2020
// Base ERC20 implementation.

pragma solidity >=0.4.16 <0.7.0;

import "../utilities/SafeMath.sol";

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
