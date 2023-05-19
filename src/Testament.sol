// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// Import required OpenZeppelin contracts.
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Testament
 * @dev A smart contract for managing inheritance payouts.
 */
contract Testament is AccessControl {

    // Use SafeMath library to prevent math errors such as overflows in complex arithmetic.
    using SafeMath for uint256;
    
    // Current inheritance percentage available
    uint256 availablePercentage;

    // Variable that holds the unix time at when this contract was deployed.
    uint256 deploymentTime;
    // Stores the time after which the inheritance can be claimed in days
    uint256 inheritanceClaimingAllowedAfter;

    // Declaration of the beneficiary role
    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY");

    // Declare the Beneficiary struct.
    struct Beneficiary {
        // Name of the beneficiary
        string name;
        // Wallet of the beneficiary
        address payable wallet;
        // Define the percentage of the corresponding payment in the smallest units because Solidity doesn't take decimals (two decimals values has been stablished).
        uint256 percentage;
    }

    /**
     * @dev Event to show a beneficiary's information.
     * @param name The name of the beneficiary.
     * @param wallet The wallet address of the beneficiary.
     * @param percentage The percentage of the inheritance that the beneficiary is entitled to.
     */
    event ShowBenenficiary(string name, address wallet, uint percentage);
    event BeneficiaryDeleted(string name, address wallet, uint percentage);
    /**
     * @dev Event to show the amount of inheritance claimed by a beneficiary.
     * @param amount The amount of inheritance claimed by the beneficiary.
    */
    event inheritanceClaimed(uint amount);

    // Declare an array to hold all Beneficiaries.
    Beneficiary [] public beneficiaries;

    /**
     * @dev Grants the admin role to the contract deployer and sets the deployment time and the time after which the inheritance can be claimed.
     * @param _inheritanceClaimingAllowedAfter The number of days after which the inheritance can be claimed.
     */
    constructor(uint256 _inheritanceClaimingAllowedAfter) {
        // Grant the ADMIN_ROLE to the contract deployer.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Set the deployment time to the current block timestamp.
        deploymentTime = block.timestamp;
        // Set the time after which the inheritance can be claimed.
        inheritanceClaimingAllowedAfter = _inheritanceClaimingAllowedAfter;
        // Set the percentage of inheritance as 100% when deployed
        availablePercentage = 10000;
    }

    /**
     * @dev Creates a new Beneficiary and adds them to the beneficiaries array.
     * @param _name The name of the new Beneficiary.
     * @param _wallet The wallet address of the new Beneficiary.
     * @param _percentage The percentage of the inheritance that the new Beneficiary will receive.
     */
    function createBeneficiary(string memory _name, address payable _wallet, uint _percentage) public {
        // Check if the caller has the ADMIN_ROLE.
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You are not the admin of this contract");
        // Check if beneficiary already registered
        require(!hasRole(BENEFICIARY_ROLE, _wallet), "Beneficiary already registerd");
        //Inheritance is between 1 and 100 percent, with two decimal places.
        require(_percentage >= 100 && _percentage <= availablePercentage, "Percentage must be between 1 and 100 and be available");
        // Declare a new Beneficiary instance.
        Beneficiary memory beneficiary;
        beneficiary.name = _name;
        beneficiary.wallet = _wallet;
        beneficiary.percentage = _percentage;
        // Update new available percentage 
        availablePercentage = availablePercentage - _percentage;
        // Add the new Beneficiary to the beneficiaries array.
        beneficiaries.push(beneficiary);
        // Grant the BENEFICIARY_ROLE to the new Beneficiary.
        _grantRole(BENEFICIARY_ROLE, beneficiary.wallet);
    }

    /**
     * @dev Deletes a Beneficiary from the beneficiaries array.
     * @param _wallet The wallet address of the Beneficiary to be deleted.
     */
    function deleteBeneficiary(address _wallet) public {
        // Check if the caller has the ADMIN_ROLE.
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You are not the admin of this contract");
        // Loop through all Beneficiaries in the array.
        for (uint i = 0; i < beneficiaries.length; i++) {
            if (beneficiaries[i].wallet == _wallet) { 
                // Add to the available percentage the percentage of the deleted beneficiary
                availablePercentage += beneficiaries[i].percentage;
                    // Debug statement to check if the code is being executed
                    emit BeneficiaryDeleted(beneficiaries[i].name, beneficiaries[i].wallet, beneficiaries[i].percentage);
                    // Shift all elements in the array after the deleted element one position to the left
                    for (uint j = i; j < beneficiaries.length - 1; j++) {
                        beneficiaries[j] = beneficiaries[j + 1];
                    }
                    // Delete the last element of the array (which is now a duplicate of the deleted element)
                    beneficiaries.pop();
            }
        }
    }

    /**
     * @dev Declare the function to list all beneficiaries.
     * @notice This function can only be called by the admin of this contract.
     */
    function listBeneficiaries() public {
        // Check if the caller has the ADMIN_ROLE.
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You are not the admin of this contract");
        // Loop through all Beneficiaries in the array and emit an event for each one.
        for (uint i = 0; i < beneficiaries.length; i++) {
            emit ShowBenenficiary(beneficiaries[i].name, beneficiaries[i].wallet, beneficiaries[i].percentage);
        }
    }

    /**
     * @dev Declare the function to claim inheritance if the caller is a beneficiary.
     * @notice This function can only be called by a beneficiary of this contract.
     * @notice Inheritance can only be claimed after a specified number of days after contract deployment.
     * @notice The caller's wallet will receive a percentage of the total balance, based on their percentage of the total inheritance.
     * @notice If the transfer of funds fails, the function will revert.
     */
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
        // Remove the percentage available for the beneficiary who already claimed inheritance
        b.percentage = 0;
        // Emit an event to show the amount claimed by the beneficiary.
        emit inheritanceClaimed(amountBeneficiary);
    }

    /**
     * @dev Declare the function to renounce inheritance.
     * @notice This function can only be called by a beneficiary of this contract.
     * @notice If there are no beneficiaries left, the function will revert.
     * @notice The caller's beneficiary role will be revoked, and they will be removed from the list of beneficiaries.
     */
    function renounceInheritance() public {
        require(hasRole(BENEFICIARY_ROLE, msg.sender), "Caller is not a beneficiary of inheritance");
        availablePercentage += getBeneficiaryPercentage();
        // Percentage of inheritance is re-distributed across left beneficiaries
        _redistributeInheritance();
        // To do: add require if no beneficiary is left
        // Beneficiary renounce inheritance, beneficiary role is revoked
        renounceRole(BENEFICIARY_ROLE, msg.sender);
        // Beneficiary is deleted from the list of beneficiaries
        delete beneficiaries[getBeneficiaryId()];                   
    }


/**
 * @dev Returns information about a beneficiary.
 * @return A tuple containing the name, wallet address, percentage, and ID of the beneficiary.
 * @notice This function can only be called by the beneficiary whose information is being requested.
 * @notice If the beneficiary is not found, the function will revert.
 */
function getBeneficiaryInfo() public view returns (string memory, address payable, uint256, uint256) {
    uint id;
    for (uint i = 0; i < beneficiaries.length; i++) {
        // Check if the wallet address of the current Beneficiary matches the input address.
        if (beneficiaries[i].wallet == msg.sender) { 
            id = i;
            return (beneficiaries[i].name, beneficiaries[i].wallet, beneficiaries[i].percentage, id);         
        }
    }
    // Revert if the beneficiary is not found
    revert();
}

    /**
     * @dev Retrieves the name of the beneficiary associated with the current account.
     * @return The name (string) of the beneficiary.
     */
    function getBeneficiaryName() public view returns (string memory) {
        // Call the getBeneficiaryInfo() function to retrieve the tuple, and assign the first element to the name variable.
        (string memory name, , , ) = getBeneficiaryInfo();
        return name;
    }

    /**
     * @dev Retrieves the wallet address of the beneficiary associated with the current account.
     * @return The wallet address (address payable) of the beneficiary.
     */
    function getBeneficiaryWallet() public view returns (address payable) {
        // Call the getBeneficiaryInfo() function to retrieve the tuple, and assign the second element to the wallet variable.
        ( , address payable wallet, , ) = getBeneficiaryInfo();
        return wallet;
    }

    /**
     * @dev Retrieves the percentage of the inheritance that the beneficiary associated with the current account is entitled to.
     * @return The percentage (uint256) of the inheritance that the beneficiary is entitled to.
     */
    function getBeneficiaryPercentage() public view returns (uint256) {
        // Call the getBeneficiaryInfo() function to retrieve the tuple, and assign the third element to the percentage variable.
        ( , , uint256 percentage, ) = getBeneficiaryInfo();
        return percentage;
    }

    /**
     * @dev Retrieves the ID of the beneficiary associated with the current account.
     * @return The ID (uint256) of the beneficiary
     */
    function getBeneficiaryId() public view returns (uint256) {
        // Call the getBeneficiaryInfo() function to retrieve the tuple, and assign the fourth element to the id variable.
        ( , , , uint256 id) = getBeneficiaryInfo();
        return id;
    }

    /**
     * @dev Distributes inheritance among the beneficiaries according to their assigned percentage 
    */
    function _redistributeInheritance() internal {
        uint percetageToDistribute = getBeneficiaryPercentage();
        uint beneficiariesQuantity = (beneficiaries.length - 1);
        // (e.g 15.00% / 4 = )
        uint percetageForEachBeneficiary = percetageToDistribute / beneficiariesQuantity;
        // Loop through all beneficiaries and add the percetageForEachBeneficiary
        for(uint i = 0; i < beneficiaries.length; i++) {
            beneficiaries[i].percentage = beneficiaries[i].percentage + percetageForEachBeneficiary;
            // Update new available percentage
            availablePercentage -= beneficiaries[i].percentage;
        } 
    }

    // Declare the function to deposit ether to this contract
    function depositEth(uint256 amount) payable public {}

    // Function to consult available percentage

    function getAvaiablePercentage() public view returns (uint256){
        return availablePercentage;
    }

    receive() external payable {}
}