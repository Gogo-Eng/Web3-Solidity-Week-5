// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IERC20 {
    function transferFrom(address _owner, address _to, uint _value)external returns(bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _address) external view returns (uint256);
    }
    
    
contract SaveToken {
    
    IERC20 public gogo;

    constructor(address _gogo) {
        gogo = IERC20(_gogo);
    }

    mapping(address => uint256) public EthBalances;
    mapping(address => uint256) public ErcBalances;

    function depositETH() external payable {
        require(msg.sender != address(0), "Address zero detected");
        require(msg.value > 0, "Can't deposit zero value");

        EthBalances[msg.sender] = EthBalances[msg.sender] + msg.value;
    }
    
    function depositERC(uint256 _amount) external {
        require(msg.sender != address(0), "Address zero detected");
        require(_amount > 0, "Amount must be greater than zero");
        gogo.transferFrom(msg.sender, address(this), _amount);
        ErcBalances[msg.sender] = ErcBalances[msg.sender] + _amount;
    }

    function getETHbalance() public view returns (uint256) {
        return EthBalances[msg.sender];
    }

    function getERCbalance() public view returns (uint256) {
        return ErcBalances[msg.sender];
    }
    
    
    function withdrawERC(uint256 _amount) external {
        require(msg.sender != address(0), "Address zero detected");

        uint256 userSavings_ = ErcBalances[msg.sender];

        require(userSavings_ > 0, "Insufficient funds");

        ErcBalances[msg.sender] = userSavings_ - _amount;
        gogo.transfer(msg.sender, _amount);
    }

    function withdrawETH(uint256 _amount) external {
        require(msg.sender != address(0), "Address zero detected");

        uint256 userSavings_ = EthBalances[msg.sender];

        require(userSavings_ > 0, "Insufficient funds");

        EthBalances[msg.sender] = userSavings_ - _amount;
        (bool result, bytes memory data) = payable(msg.sender).call{value: _amount}("");

        require(result, "transfer failed");
    }

    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}