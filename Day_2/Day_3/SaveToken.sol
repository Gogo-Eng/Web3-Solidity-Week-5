// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

Contract SaveToken {
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;
    uint private _totalSupply;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowances;

    event DepositSuccessful(address indexed sender, uint256 indexed amount);
    event WithdrawalSuccessful(address indexed receiver, uint256 indexed amount, bytes data);

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

    function mint(address _to, uint _value) public{
        require(_to != address(0), 'addresszero detected');
        _totalSupply += _value;
        balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }

    function getERCSavings() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    
    
    
    function deposit() external payable {
        require(msg.sender != address(0), "Address zero detected");
        require(msg.value > 0, "Can't deposit zero value");

        balances[msg.sender] = balances[msg.sender] + msg.value;

        emit DepositSuccessful(msg.sender, msg.value);
    }
    
    function getEthSavings() external view returns (uint256) {
        return balances[msg.sender];
    }

    
   function withdrawERC(uint256 _amount) external {
        require(msg.sender != address(0), "Address zero detected");

        uint256 userSavings_ = balances[msg.sender];

        require(userSavings_ > 0, "Insufficient funds");

        balances[msg.sender] = userSavings_ - _amount;
        (bool result, bytes memory data) = payable(msg.sender).call{value: _amount}("");

        require(result, "transfer failed");

        emit WithdrawalSuccessful(msg.sender, _amount, data);
    }


    function withdrawETH(uint256 _amount) external {
        require(msg.sender != address(0), "Address zero detected");

        uint256 userSavings_ = balances[msg.sender];

        require(userSavings_ > 0, "Insufficient funds");

        balances[msg.sender] = userSavings_ - _amount;
        (bool result, bytes memory data) = payable(msg.sender).call{value: _amount}("");

        require(result, "transfer failed");

        emit WithdrawalSuccessful(msg.sender, _amount, data);
    }

    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}