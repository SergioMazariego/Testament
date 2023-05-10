// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/Testament.sol";

contract TestamentTest is Test {
    Testament public testament;

    /* 
        1. Owner deploy the contract passing as constructor argument the number of days after the inheritance can be claimed by beneficiaries.
        2. Owner call the createBeneficiary() function to create a new beneficiary 1, setting their name, wallet and percenateg (two decimals)to 25% of the total contract balance to inherit.
        3. Owner call the createBeneficiary() function to create a new beneficiary 2, setting their name, wallet and percenateg (two decimals)to 25% of the total contract balance to inherit.
        4. Beneficiary 1 renounce inheritance callin the renounceInheritance() function, inheritance percentage is added to the percentage of the Beneficiary 2 (expected new percentage = 100%).
    */

    /*
    function setUp() public {
        
    }
    */
}
