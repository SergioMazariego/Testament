// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// Import required OpenZeppelin contracts.
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Declare the contract.
contract Testament is AccessControl {

    // Use SafeMath library to prevent math errors such as overflows.
    using SafeMath for uint256;
    
    // Declare state variables.
    uint256 deploymentTime;
    // Stores the time after which the inheritance can be claimed
    uint256 inheritanceClaimingAllowedAfter;

    // Declare role identifiers.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY");

    // Declare the Beneficiary struct.
    struct Beneficiary {
        string name;
        address payable wallet;
        // Define the percentage in the smallest units because Solidity doesn't take decimals.
        uint256 percentage;
    }

    // Declare events.
    event ShowBenenficiary(string name, address wallet, uint percentage);
    event inheritanceClaimed(uint amount);

    // Declare an array to hold all Beneficiaries.
    Beneficiary [] public beneficiaries;

    // Declare the constructor.
    constructor(uint256 _inheritanceClaimingAllowedAfter) {
        // Grant the ADMIN_ROLE to the contract deployer.
        _grantRole(ADMIN_ROLE, msg.sender);
        // Set the deployment time to the current block timestamp.
        deploymentTime = block.timestamp;
        // Set the time after which the inheritance can be claimed.
        inheritanceClaimingAllowedAfter = _inheritanceClaimingAllowedAfter;
    }

    // Declare the function to create a new Beneficiary.
    function createBeneficiary(string memory _name, address payable _wallet, uint _percentage) public {
        // Check if the caller has the ADMIN_ROLE.
        require(hasRole(ADMIN_ROLE, msg.sender), "You are not the admin of this contract");
        // Declare a new Beneficiary instance.
        Beneficiary memory beneficiary;
        beneficiary.name = _name;
        beneficiary.wallet = _wallet;
        beneficiary.percentage = _percentage;
        // Add the new Beneficiary to the beneficiaries array.
        beneficiaries.push(beneficiary);
        // Grant the BENEFICIARY_ROLE to the new Beneficiary.
        _grantRole(BENEFICIARY_ROLE, beneficiary.wallet);
    }

    // Declare the function to delete a Beneficiary.
    function deleteBeneficiary(address _wallet) public {
        // Check if the caller has the ADMIN_ROLE.
        require(hasRole(ADMIN_ROLE, msg.sender), "You are not the admin of this contract");
        // Loop through all Beneficiaries in the array.
        for (uint i = 0; i < beneficiaries.length; i++) {
            // Check if the wallet address of the current Beneficiary matches the input address.
            if (beneficiaries[i].wallet == _wallet) { 
                // Delete the Beneficiary from the array.
                delete beneficiaries[i];                   
            }
        }
    }

    // Declare the function to list all Beneficiaries.
    function listBeneficiaries() public {
        // Check if the caller has the ADMIN_ROLE.
        require(hasRole(ADMIN_ROLE, msg.sender), "You are not the admin of this contract");
        // Loop through all Beneficiaries in the array and emit an event for each one.
        for (uint i = 0; i < beneficiaries.length; i++) {
            emit ShowBenenficiary(beneficiaries[i].name, beneficiaries[i].wallet, beneficiaries[i].percentage);
        }
    }

    // Declare the function to claim inheritance if the caller is a beneficiary
    function claimInheritance() public {
        // Check if the caller has the BENEFICIARY_ROLE.
        require(hasRole(BENEFICIARY_ROLE, msg.sender), "You are not a beneficiary");
        // Check if the time since contract deployment is greater than or equal to the specified number of days for inheritance claiming.
        require(block.timestamp >= deploymentTime + inheritanceClaimingAllowedAfter, "Inheritance cannot be claimed before 365 days");
        // Get the total balance of the contract.
        uint256 totalBalance = address(this).balance;
        // Declare a Beneficiary instance.
        Beneficiary memory b;
        // Loop through all Beneficiaries in the array to find the one that matches the caller's address.
        for (uint i = 0; i < beneficiaries.length; i++) {
            if (beneficiaries[i].wallet == msg.sender) {
                b = beneficiaries[i];
            }
        }
        // Calculate the inheritance amount for the Beneficiary based on their percentage of the total balance.
        uint256 amountBeneficiary = (totalBalance * b.percentage) / 10000;
        // Send the inheritance amount to the Beneficiary's wallet address.
        (bool sent, ) = b.wallet.call{value: amountBeneficiary}("");
        // Check if the transfer was successful.
        require(sent, "Failed to send Ether");
        // Emit an event to show the amount claimed by the beneficiary.
        emit inheritanceClaimed(amountBeneficiary);
    }

    // Declare the function to deposit ETH to this contract
    function depositEth(uint256 amount) payable public {}

    receive() external payable {}
}