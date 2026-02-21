// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
interface IERC20 {
    function transferFrom(address _owner, address _to, uint _value) external returns(bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _address) external view returns (uint256);               
}
contract Register {
    enum PaymentStatus {
        paid,
        pending
    }    
    enum Status {
        active,
        inactive
    }
    
    struct Student {
        string name;
        uint256 id;
        address studentAddress;
        uint16 level;
        string course;
        Status status;
        PaymentStatus paymentStatus;
    }

    struct Staff {
        string teacherName;
        uint256 id;
        address staffAddress;
        uint256 salary;
        uint256 lastPaidAt;
        Status status;
    }

    Status public status;

    uint16 level_100 = 100;
    uint16 level_200 = 200;
    uint16 level_300 = 300;
    uint16 level_400 = 400;

    Student[] public students;
    Staff[] public staffs;

    address[] public studentsAddresses;
    address[] public staffAddresses;

    uint256 staffId;
    uint256 public studentId;
    uint256 public fee;

    event RegistrationSuccessful (address indexed _student, uint256 _amount);
    event PaymetSuccessful (address indexed _teacher, uint256 _amount);

    mapping(address => uint256) public ERCbalance;
    mapping(uint16 => uint256) public schoolFee;
    mapping(uint16 => uint256) public staffSalary;

    address tokenAddress;
    IERC20 public immutable token;

    constructor(address _address) {
        tokenAddress = _address;
        token = IERC20(tokenAddress);
        
        schoolFee[level_100] = 1000;
        schoolFee[level_200] = 2000;
        schoolFee[level_300] = 3000;
        schoolFee[level_400] = 4000;

        staffSalary[level_100] = 500;
        staffSalary[level_200] = 1000;
        staffSalary[level_300] = 1500;
        staffSalary[level_400] = 2000;

    }


    function RegisterStudent(string memory _name, uint16 _level, string memory _course) public returns(bool) {
        fee = schoolFee[_level];

        require (fee > 0, "can't pay Zero fee");
        require(_level == 100 || _level == 200 || _level == 300 || _level == 400, "Invalid level");
        require(token.balanceOf(msg.sender) >= fee, "Not enough funds to register");
        
        token.transferFrom(msg.sender, address(this), fee);

        studentId = studentId + 1;
        Student memory student = Student({
            name: _name,
            id: studentId,
            studentAddress: msg.sender, 
            level:_level, 
            course: _course, 
            status: Status.active,
            paymentStatus: PaymentStatus.paid
        });
        students.push(student);
        studentsAddresses.push(msg.sender);

        emit RegistrationSuccessful (msg.sender, fee);
        return true;
    }

    function ExpelStudent(address _address) internal {
        for (uint i = 0; i < students.length; i++) {
            if (students[i].studentAddress == _address) {
                students[i] = students[students.length - 1];
                students.pop();
                break;
            }
        }
    }

    function EmployStaff(string memory _name, uint16 _level, address _address) public returns(bool){
        require(_level == 100 || _level == 200 || _level == 300 || _level == 400, "Invalid level");
        
        staffId ++;
        staffs.push();
        Staff storage staff = staffs[staffs.length - 1];
        staff.teacherName = _name;
        staff.id = staffId;
        staff.staffAddress = _address;
        staff.salary = staffSalary[_level];
        staff.status = Status.active;

        staffAddresses.push(_address);

        return true;
    }

    function SackStaff(address _address) internal {
        for (uint i = 0; i < staffs.length; i++) {
            if (staffs[i].staffAddress == _address) {
                staffs[i] = staffs[students.length - 1];
                staffs.pop();
                break;
            }
        }
    }

    function PayStaffSalary(address _address) public returns(bool){
        require(_address != address(0));
        
        Staff storage staff = staffs[staffs.length - 1];

        token.transfer(_address, staff.salary);

        staff.lastPaidAt = block.timestamp;
        emit PaymetSuccessful (_address, staff.salary);

        return true;
    }
    function listStudents() public view returns(string[] memory){
        string[] memory names = new string[](students.length);

        for(uint i = 0; i < students.length; i++) {
            names[i] = students[i].name;
        }
        return names;
    }

    function listStaffs() public view returns(string[] memory){
        string[] memory names = new string[](staffs.length);

        for(uint i = 0; i < staffs.length; i++) {
            names[i] = staffs[i].teacherName;
        }
        return names;
    }

}