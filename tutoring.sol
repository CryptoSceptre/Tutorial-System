// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TuitionSystem {
    address public owner;
    uint256 public constant MAX_STUDENTS = 1000;
    uint256 public constant MAX_CLASSES_PER_WEEK = 20;
    uint256 public constant MIN_CLASSES_PER_WEEK = 5;
    uint256 public constant MIN_CLASSES_ATTENDED = 3;
    uint256 public constant MAX_SUBJECTS = 5;
    uint256 public constant TUITION_FEE = 600;
    uint256 public constant TUTOR_PAYMENT = 500;
    uint256 public constant BATCH_DURATION = 12 weeks;

    enum Subject { Mathematics, Physics, ComputerScience, Economics, Management }

    struct Student {
        address payable studentAddress;
        uint256[] subjects;
        uint256 classesAttended;
    }

    struct Tutor {
        address payable tutorAddress;
        uint256[] subjects;
        uint256 classesTaught;
    }

    mapping(address => Student) public students;
    mapping(address => Tutor) public tutors;
    mapping(uint256 => address[]) public studentBatch;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function enrollStudent(uint256[] memory _subjects) external payable {
        require(studentBatch[getCurrentBatch()].length < MAX_STUDENTS, "Batch is full");
        require(_subjects.length <= MAX_SUBJECTS, "Too many subjects");
        require(_subjects.length > 0, "Please select at least one subject");
        require(msg.value >= TUITION_FEE * MIN_CLASSES_ATTENDED, "Insufficient payment");

        Student storage student = students[msg.sender];
        student.studentAddress = payable(msg.sender);
        student.subjects = _subjects;
        student.classesAttended = 0;
        studentBatch[getCurrentBatch()].push(msg.sender);
    }

    function becomeTutor(uint256[] memory _subjects) external {
        require(_subjects.length <= MAX_SUBJECTS, "Too many subjects");
        require(_subjects.length > 0, "Please select at least one subject");

        Tutor storage tutor = tutors[msg.sender];
        tutor.tutorAddress = payable(msg.sender);
        tutor.subjects = _subjects;
        tutor.classesTaught = 0;
    }

    function startClass(address _student, uint256 _subject) external onlyOwner {
        require(students[_student].studentAddress != address(0), "Student not found");
        require(studentBatch[getCurrentBatch()].length > 0, "No students in the batch");
        require(_subject < MAX_SUBJECTS, "Invalid subject index");

        students[_student].classesAttended++;
    }

    function endClass(address _tutor, uint256 _subject) external onlyOwner {
        require(tutors[_tutor].tutorAddress != address(0), "Tutor not found");
        require(_subject < MAX_SUBJECTS, "Invalid subject index");

        tutors[_tutor].classesTaught++;
    }

    function payTutor(address _tutor) external onlyOwner {
        require(tutors[_tutor].tutorAddress != address(0), "Tutor not found");
        require(tutors[_tutor].classesTaught > 0, "No classes taught");
        
        payable(_tutor).transfer(TUTOR_PAYMENT * tutors[_tutor].classesTaught);
        tutors[_tutor].classesTaught = 0;
    }

    function getCurrentBatch() public view returns (uint256) {
        return block.timestamp / BATCH_DURATION;
    }

    receive() external payable {}
}
