// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Office {
    address public manager;

    struct Employee {
        address employeeAddress;
        uint256 employeeID;
        string name;
        string role;
    }

    Employee public managerInfo;
    Employee[] public employees;
    mapping(string => uint256) public salariesByRole;
    mapping(string => uint256) public totalSalaryByRole; // Mapping to store total salary by role

    event EmployeeHired(address indexed employeeAddress, uint256 ID, string name, string role);
    event EmployeePromoted(uint employeeID, string name, string role);
    event EmployeeResigned(uint employeeID, string name, string role);
    event EmployeeFired(uint employeeID, string name, string role);
    event SalaryDistributed(string name, string manager, uint256 totalAmount);

    constructor(string memory managername) {
        manager = msg.sender;

        managerInfo.employeeAddress = manager;
        managerInfo.employeeID = 0;
        managerInfo.name = managername;
        managerInfo.role = "manager";

        salariesByRole["Regional Manager"] = 5000;
        salariesByRole["Salesman"] = 3000;
        salariesByRole["Receptionist"] = 2500;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only the manager can perform this action");
        _;
    }

    modifier onlyEmployee() {
        require(isEmployee(msg.sender), "Only employees can perform this action");
        _;
    }

    function isEmployee(address employeeAddress) internal view returns (bool) {
        for (uint256 i = 0; i < employees.length; i++) {
            if (employees[i].employeeAddress == employeeAddress) {
                return true;
            }
        }
        return false;
    }

    function hireEmployee(address employeeAddress, string memory name, string memory role) external onlyManager {
        require(!isEmployee(employeeAddress), "Employee already exists");
        Employee memory newEmployee = Employee(employeeAddress, employees.length + 1, name, role);
        employees.push(newEmployee);
        emit EmployeeHired(employeeAddress, employees.length + 1, name, role);
    }

    function promoteEmployee(address employeeAddress, string memory newRole) external onlyManager {
        require(isEmployee(employeeAddress), "Employee does not exist");
        string memory getName;
        uint256 getID;
        for (uint256 i = 0; i < employees.length; i++) {
            if (employees[i].employeeAddress == employeeAddress) {
                 getName = employees[i].name;
                 getID = employees[i].employeeID;
                employees[i].role = newRole;
                break;
            }
        }
        emit EmployeePromoted(getID, getName, newRole);
    }

    function resign() external onlyEmployee {
        address employeeAddress = msg.sender;
        string memory getName;
        string memory getRole;
        uint256 getID;
        for (uint256 i = 0; i < employees.length; i++) {
            if (employees[i].employeeAddress == employeeAddress) {
                getName = employees[i].name;
                getRole = employees[i].role;
                getID = employees[i].employeeID;
                delete employees[i];
                emit EmployeeResigned(getID, getName, getRole);
                break;
            }
        }
    }

    function fireEmployee(address employeeAddress) external onlyManager {
        require(isEmployee(employeeAddress), "Employee does not exist");
        string memory getName;
        string memory getRole;
        uint256 getID;
        for (uint256 i = 0; i < employees.length; i++) {
            if (employees[i].employeeAddress == employeeAddress) {
                getName = employees[i].name;
                getRole = employees[i].role;
                getID = employees[i].employeeID;
                delete employees[i];
                emit EmployeeFired(getID, getName, getRole);
                break;
            }
        }
    }

    function setSalary(string memory role, uint256 amount) external onlyManager {
        salariesByRole[role] = amount;
    }

    function distributeSalary() external onlyManager {
        uint256 totalAmount = address(this).balance;
        payable(manager).transfer(getTotalSalaries() - totalAmount);
        require(totalAmount >= getTotalSalaries(), "Insufficient funds in contract");

        // Reset total salary for each role
        for (uint256 i = 0; i < employees.length; i++) {
            string memory role = employees[i].role;
            totalSalaryByRole[role] = 0;
        }

        // Calculate total salary for each role
        for (uint256 i = 0; i < employees.length; i++) {
            string memory role = employees[i].role;
            uint256 salary = salariesByRole[role];
            totalSalaryByRole[role] += salary;
        }

        // Distribute salaries based on roles
        for (uint256 i = 0; i < employees.length; i++) {
            string memory role = employees[i].role;
            uint256 salary = salariesByRole[role];
            salariesByRole[role] = 0; // Reset individual salary after distribution
            payable(employees[i].employeeAddress).transfer(totalAmount * salary / totalSalaryByRole[role]);
        }

        emit SalaryDistributed(managerInfo.name ,managerInfo.role, totalAmount);
    }

    function getTotalSalaries() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < employees.length; i++) {
            total += salariesByRole[employees[i].role];
        }
        return total;
    }
}



