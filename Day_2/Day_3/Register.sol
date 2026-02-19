// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract Register {
    struct Student {
        uint256 id;
        string  name;
        address walletAddress;
        uint256 level;          // 100, 200, 300, 400
        uint256 feesRequired;   // based on level
        uint256 feesPaid;
        uint256 paidAt;         // timestamp
        bool    status;
    }

    struct Staff {
        uint256 id;
        string  name;
        address walletAddress;
        uint256 salary;
        uint256 lastPaidAt;     // timestamp
        bool    status;
    }                             // deployer = school admin

    mapping(address => Student) students;          // wallet → Student
    mapping(address => Staff)   staffs;             // wallet → Staff
    mapping(uint256 => uint256) levelFees;         
    
    Student[] public studentList;                           
    Staff[] public staffList;
    address[] public studentAddresses;
    address[] public staffAddresses;

    uint256 studentCount;
    uint256 staffCount;

    address public owner;
    IERC20 schoolToken;

    constructor(address _tokenAddress) {
        schoolToken = IERC20(_tokenAddress);

        owner = msg.sender;
        levelFees[100] = 100 * 1e18;    
        levelFees[200] = 150 * 1e18;    
        levelFees[300] = 200 * 1e18;    
        levelFees[400] = 250 * 1e18;    
    }

    function registerStudent(address _address, string memory _name, uint256 _level) public payable returns(bool _success)  {
        require(_level == 100 || _level == 200 || _level == 300 || _level == 400, "Invalid level");
        uint256 fee = levelFees[_level];
        require(fee > 0, "Fee cannot be zero");
        
        bool success = schoolToken.transferFrom(_address, address(this), fee);
        require(success, "Token transfer failed");
        students[msg.sender] = Student({
            id: studentCount,
            name: _name,
            walletAddress: msg.sender,
            level: _level,
            feesRequired: fee,
            feesPaid: fee,
            paidAt: block.timestamp,
            status: true
        });

        studentCount++;
        studentAddresses.push(msg.sender); 
        return success;
    }

    function registerStaff(address staffAddress, string memory _name, uint _salary) public {
        staffs[staffAddress] = Staff({
        id:            staffCount,
        name:          _name,
        walletAddress: staffAddress,
        salary:        _salary,
        lastPaidAt:    0,        // never been paid yet
        status:        true
    });
        
        staffCount++;
        staffAddresses.push(staffAddress); 
    }

    function payStaff(address staffAddress) external{
        Staff storage staff = staffs[staffAddress];

        schoolToken.transfer(staffAddress, staff.salary);

        staff.lastPaidAt = block.timestamp;
    }
    
    function getAllStaffs() external view returns (Staff[] memory) {
        Staff[] memory result = new Staff[](staffAddresses.length);

        for (uint256 i = 0; i < staffAddresses.length; i++) {
            result[i] = staffs[staffAddresses[i]];
        }

        return result;
    }

    function getAllStudents() external view returns (Student[] memory) {
        Student[] memory result = new Student[](studentAddresses.length);

        for (uint256 i = 0; i < studentAddresses.length; i++) {
            result[i] = students[studentAddresses[i]];
        }

        return result;
    }

}