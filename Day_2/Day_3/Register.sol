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
        uint8 level;
        string course;
        PaymentStatus status;
    }

    struct Teacher {
        string teacherName;
        uint256 id;
        address teacherAddress;
        uint256 salary;
        Status status;
    }

    //Status public status;

    uint8 immutable level_100;
    uint8 immutable level_200;
    uint8 immutable level_300;
    uint8 immutable level_400;

    uint8 immutable level_1;
    uint8 immutable level_2;
    uint8 immutable level_3;
    uint8 immutable level_4;

    Student[] public students;
    Teacher[] public teachers;

    address[] public studentsAddresses;
    address[] public teachersAddresses;

    uint8 teacherId;
    uint studentId;

    event RegistrationSuccessful (address indexed _student, uint256 _amount);

    mapping(address => uint256) public ERCbalance;
    mapping(uint8 => uint256) public schoolFee;
    mapping(uint8 => uint256) public teacherSalary;

    address tokenAddress;
    IERC20 public immutable token;

    constructor(address _address) {
        tokenAddress = _address;
        token = IERC20(tokenAddress);
        
        schoolFee[level_100] = 1000;
        schoolFee[level_200] = 2000;
        schoolFee[level_300] = 3000;
        schoolFee[level_400] = 4000;

        teacherSalary[level_1] = 500;
        teacherSalary[level_2] = 1000;
        teacherSalary[level_3] = 1500;
        teacherSalary[level_4] = 2000;

    }


    function RegisterStudent(string memory _name, uint8 _level, string memory _course) public returns(bool) {
        uint256 fee = schoolFee[_level];

        require (fee > 0, "can't pay Zero fee");
        require(_level == 100 || _level == 200 || _level == 300 || _level == 400, "Invalid Level");
        require(IERC20(tokenAddress).balanceOf(msg.sender) >= fee, "Not enough funds to register");
        
        ERCbalance[msg.sender] = ERCbalance[msg.sender] - fee;
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), fee));

        studentId = studentId + 1;
        Student memory student = Student({
            name: _name,
            id: studentId,
            studentAddress: msg.sender, 
            level:_level, course: _course, 
            status: PaymentStatus.paid
        });
        students.push(student);
        studentsAddresses.push(msg.sender);

        emit RegistrationSuccessful (msg.sender, fee);
        return true;
    }

    function RegisterTeacher(string memory _name, uint8 _level, address _address) public returns(bool){
        teacherId ++;
        teachers.push();
        Teacher storage teacher = teachers[teachers.length - 1];
        teacher.teacherName = _name;
        teacher.id = teacherId;
        teacher.teacherAddress = _address;
        teacher.salary = teacherSalary[_level];
        teacher.status = Status.active;

        teachersAddresses.push(_address);

        return true;
    }

    function listStudents() public view returns(string memory){
        string memory all_students = "";
        for(uint i = 0; i < students.length; i++) {
            Student storage student = students[i];
            all_students = student.name;   
        }
        return all_students;
    }

}