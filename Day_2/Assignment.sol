// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract ERC20{
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;
    uint private _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    // allowances[owner1][spender1] = 20
    // allowances[owner1][spender2] = 30

    event Transfer(address indexed _from, address indexed _to, uint indexed _value);
    event Approval(address indexed _owner, address indexed _spender, uint indexed _value);

    constructor(string memory name_, string memory symbol_, uint8 decimals_){
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name()public view returns(string memory){
        return _name;
    }
    function symbol()public view returns(string memory){
        return _symbol;
    }
    function decimals()public view returns(uint8){
        return _decimals;
    }
    function totalSupply() public view returns(uint){
        return _totalSupply;
    }
    function balanceOf(address _address)public view returns(uint){
       return balances[_address];
    }

    function transfer(address _to, uint _value)public returns(bool success){
        require(_to != address(0) && _to != msg.sender, 'Invalid Address' );
        require(_value > 0, 'Invalid Amount');
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return success;
    }
    function transferFrom(address _owner, address _to, uint _value)public returns(bool success){
        require(_to != address(0) && _to != _owner, 'Invalid Address');
        require(_value <= allowances[_owner][msg.sender], 'Insufficient allowance');
        allowances[_owner][msg.sender] -= _value;
        balances[_owner] -= _value;
        balances[_to] += _value;
        emit Transfer(_owner, _to, _value);
        return success;
    }

    function approve(address _spender, uint _value) public  returns(bool success){
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return success;
    }

    function allowance(address _owner, address _spender)public view returns(uint){
        return allowances[_owner][_spender];
    }
    
    function mint(address _to, uint _value) public{
        require(_to != address(0), 'addresszero detected');
        _totalSupply += _value;
        balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }
}