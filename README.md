# Testament

Testament is a smart contract written in Solidity that allows a person to create a will and specify beneficiaries who will receive an inheritance.

## Features

- Create a new beneficiary
- Delete an existing beneficiary
- List all beneficiaries
- Claim inheritance

## Usage

To use the contract, you will need to deploy it to the Ethereum network. Once deployed, you can interact with the contract using a web3-enabled wallet such as Metamask.

### Creating a Beneficiary

To create a new beneficiary, you will need to call the `createBeneficiary` function and pass in the beneficiary's name, wallet address, and percentage of the inheritance they will receive. You must have the `ADMIN_ROLE` to create a new beneficiary.

### Deleting a Beneficiary

To delete an existing beneficiary, you will need to call the `deleteBeneficiary` function and pass in the beneficiary's wallet address. You must have the `ADMIN_ROLE` to delete a beneficiary.

### Listing Beneficiaries

To list all beneficiaries, you will need to call the `listBeneficiaries` function. You must have the `ADMIN_ROLE` to list beneficiaries.

### Claiming Inheritance

To claim an inheritance, a beneficiary must call the `claimInheritance` function. The beneficiary must have the `BENEFICIARY_ROLE` and the time since contract deployment must be greater than or equal to the specified number of days for inheritance claiming. The inheritance amount will be sent to the beneficiary's wallet address.

The owner of the contract can specify the point in time when beneficiaries can claim the inheritance by passing in the number of days after contract deployment to the `Testament` constructor.

### Depositing ETH

To deposit ETH to the contract, call the `depositEth` function with the amount you want to deposit.

```solidity
function depositEth(uint256 amount) payable public
```