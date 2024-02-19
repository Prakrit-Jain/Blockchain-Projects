// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

contract ContractManager is AccessControlEnumerable {
    /**
     * @notice Thrown if the input address is a zero address where it is not allowed.
     */
    error ZeroAddressNotAllowed();

    /**
     * @notice Thrown if the input arrays length mismatch
     */
    error InputArrayLengthMisMatch();

    /**
     * @notice Thrown an error on maxLoopsLimit exceeds for any loop
     */
    error MaxLoopsLimitExceeded();

    /**
     * @notice Thrown if the input address is a non-contract address.
     */
    error NonContractAddress();

    /**
     * @notice Thrown if the contract address already exists in storage.
     */
    error ContractAlreadyExists();

    /**
     * @notice Thrown if the contract address does not exist in storage.
     */
    error ContractDoesNotExist();

    /**
     * @notice Emitted when max loops limit is set
     */
    event MaxLoopsLimitUpdated(
        uint256 oldMaxLoopsLimit,
        uint256 newmaxLoopsLimit
    );

    /**
     * @notice Event emitted when a contract address is added in storage.
     */
    event ContractAdded(
        address indexed contractAddress,
        string description,
        bool exists
    );

    /**
     * @notice Event emitted when the description of a contract address is updated.
     */
    event ContractDescriptionUpdated(
        address indexed contractAddress,
        string oldDescription,
        string updatedDescription
    );

    /**
     * @notice Event emitted when a contract address is removed from storage.
     */
    event ContractRemoved(address indexed contractAddress, bool exists);

    /**
     * @notice Role identifier for a contract manager.
     */
    bytes32 internal constant CONTRACT_MANAGER = keccak256("CONTRACT_MANAGER");

    /**
     * @notice Limit for the loops to avoid the DOS.
     */
    uint256 public maxLoopsLimit;

    /**
     * @notice Stores information for a contract.
     */
    struct ContractInfo {
        // Description of the contract
        string description;
        // Boolean indicating whether the contract exists
        bool exists;
    }

    /**
     * @notice Maps contract addresses to their respective ContractInfo.
     */
    mapping(address => ContractInfo) public contractDetails;

    /**
     * @dev Constructor function to initialize the contract.
     * @param contractAddresses Array of contract addresses.
     * @param descriptions Array of contract descriptions.
     * @param loopsLimit Limit for the loops in the contract to avoid DOS.
     */
    constructor(
        address[] memory contractAddresses,
        string[] memory descriptions,
        uint256 loopsLimit
    ) {
        // Grants the default admin role and contract manager role to the deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CONTRACT_MANAGER, msg.sender);

        maxLoopsLimit = loopsLimit;

        addContractsInBatch(contractAddresses, descriptions);
    }

    /**
     * @notice Adds  new contract address with its description for multiple contracts in batch.
     * @dev Used to add new contracts in batch, only callable by authorized accounts.
     * @param contractAddresses Array of contract addresses.
     * @param descriptions Array of contract descriptions.
     * @custom:error InputArrayLengthMisMatch is thrown if input arrays length mismatch.
     * @custom:error MaxLoopsLimitExceededs thrown if array length exceeds the maxLoopsLimit.
     * @custom:event ContractAdded emits for each contract added on success.
     */
    function addContractsInBatch(
        address[] memory contractAddresses,
        string[] memory descriptions
    ) public {
        _checkRole(CONTRACT_MANAGER, msg.sender);

        uint256 contractAddressesLength = contractAddresses.length;
        uint256 descriptionsLength = descriptions.length;

        if (contractAddressesLength != descriptionsLength) {
            revert InputArrayLengthMisMatch();
        }

        if (contractAddressesLength > maxLoopsLimit) {
            revert MaxLoopsLimitExceeded();
        }

        for (uint i; i < contractAddressesLength; ++i) {
            _addContract(contractAddresses[i], descriptions[i]);
        }
    }

    /**
     * @notice Adds a new contract address with its description.
     * @dev Used to add new contract, only callable by authorized accounts.
     * @param contractAddress The address of the contract to add.
     * @param description The description associated with the contract address.
     * @custom:event ContractAdded emits on success.
     */
    function addContract(
        address contractAddress,
        string calldata description
    ) external {
        _checkRole(CONTRACT_MANAGER, msg.sender);

        _addContract(contractAddress, description);
    }

    /**
     * @notice Updates the description of an existing contract addresses in batch.
     * @dev Used to update the description of an existing contracts in batch, only callable by authorized accounts.
     * @param contractAddresses The address of the contract whose description is to be updated.
     * @param updatedDescriptions The updated description associated with the contract address.
     * @custom:error InputArrayLengthMisMatch is thrown if input arrays length mismatch.
     * @custom:error MaxLoopsLimitExceededs thrown if array length exceeds the maxLoopsLimit.
     * @custom:event ContractDescriptionUpdated emits on success.
     */
    function updateContractsDescriptionsInBatch(
        address[] calldata contractAddresses,
        string[] calldata updatedDescriptions
    ) external {
        _checkRole(CONTRACT_MANAGER, msg.sender);

        uint256 contractAddressesLength = contractAddresses.length;
        uint256 descriptionsLength = updatedDescriptions.length;

        if (contractAddressesLength != descriptionsLength) {
            revert InputArrayLengthMisMatch();
        }

        if (contractAddressesLength > maxLoopsLimit) {
            revert MaxLoopsLimitExceeded();
        }

        for (uint i; i < contractAddressesLength; ++i) {
            _updateContractDescription(
                contractAddresses[i],
                updatedDescriptions[i]
            );
        }
    }

    /**
     * @notice Updates the description of an existing contract address.
     * @dev Used to update the description of an existing contract, only callable by authorized accounts.
     * @param contractAddress The address of the contract whose description is to be updated.
     * @param updatedDescription The updated description associated with the contract address.
     * @custom:event ContractDescriptionUpdated emits on success for each contract description updation.
     */
    function updateContractDescription(
        address contractAddress,
        string calldata updatedDescription
    ) external {
        _checkRole(CONTRACT_MANAGER, msg.sender);

        _updateContractDescription(contractAddress, updatedDescription);
    }

    /**
     * @notice Removes an existing contract addresses and their descriptions in batch.
     * @dev Used to remove an existing contracts from storage, only callable by authorized accounts.
     * @param contractAddresses Array of address of the contracts to remove.
     * @custom:event ContractRemoved emits on success for each contract removed.
     */
    function removeContractsInBatch(
        address[] calldata contractAddresses
    ) external {
        _checkRole(CONTRACT_MANAGER, msg.sender);

        uint256 contractAddressesLength = contractAddresses.length;

        if (contractAddressesLength > maxLoopsLimit) {
            revert MaxLoopsLimitExceeded();
        }

        for (uint i; i < contractAddressesLength; ) {
            _removeContract(contractAddresses[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Removes an existing contract address and its description.
     * @dev Used to remove an existing contract from storage, only callable by authorized accounts.
     * @param contractAddress The address of the contract to remove.
     * @custom:event ContractRemoved emits on success.
     */
    function removeContract(address contractAddress) external {
        _checkRole(CONTRACT_MANAGER, msg.sender);

        _removeContract(contractAddress);
    }

    /**
     * @notice Gives access to other accounts.
     * @dev Provides an contract manager role to specified account, only callable by default admin.
     * @param contractManager The account address to be added for a contract manager role.
     */
    function addContractManagerRole(address contractManager) external {
        _checkRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CONTRACT_MANAGER, contractManager);
    }

    /**
     * @notice Set the limit for the loops can iterate to avoid the DOS.
     * @dev USed to set the maxLoopsLimit, only callable by default admin role.
     * @param limit Limit for the max loops can execute at a time.
     * @custom:event MaxLoopsLimitUpdated emits on success.
     */
    function setMaxLoopsLimit(uint256 limit) external {
        _checkRole(DEFAULT_ADMIN_ROLE, msg.sender);

        emit MaxLoopsLimitUpdated(maxLoopsLimit, limit);
        maxLoopsLimit = limit;
    }

    // ---------------------Internal functions---------------------------- //

    /*
     * @dev Used to add new contract.
     * @param contractAddress The address of the contract to add.
     * @param description The description associated with the contract address.
     * @custom:error ZeroAddressNotAllowed is thrown if the contractAddress is zero address.
     * @custom:error NonContractAddress is thrown if the input address is non contract address.
     * @custom:error ContractAlreadyExists is thrown if the contractAddress already exists.
     */
    function _addContract(
        address contractAddress_,
        string memory description_
    ) internal {
        ensureNonzeroAddress(contractAddress_);
        enforceHasContractCode(contractAddress_);

        if (contractDetails[contractAddress_].exists) {
            revert ContractAlreadyExists();
        }

        contractDetails[contractAddress_] = ContractInfo(description_, true);
        emit ContractAdded(contractAddress_, description_, true);
    }

    /**
     * @dev Used to update the description of an existing contract.
     * @param contractAddress_ The address of the contract whose description is to be updated.
     * @param updatedDescription_ The updated description associated with the contract address.
     * @custom:error ContractDoesNotExist is thrown if the contractAddress does not exist.
     * @custom:event ContractDescriptionUpdated emits on success.
     */
    function _updateContractDescription(
        address contractAddress_,
        string calldata updatedDescription_
    ) internal {
        if (!contractDetails[contractAddress_].exists) {
            revert ContractDoesNotExist();
        }

        string memory oldDescription = contractDetails[contractAddress_]
            .description;
        contractDetails[contractAddress_].description = updatedDescription_;

        emit ContractDescriptionUpdated(
            contractAddress_,
            oldDescription,
            updatedDescription_
        );
    }

    /**
     * @dev Used to remove an existing contract from storage.
     * @param contractAddress_ The address of the contract to remove.
     * @custom:error ContractDoesNotExist is thrown if the contract address does not exist.
     * @custom:event ContractRemoved emits on success.
     */
    function _removeContract(address contractAddress_) internal {
        if (!contractDetails[contractAddress_].exists) {
            revert ContractDoesNotExist();
        }

        delete contractDetails[contractAddress_];
        emit ContractRemoved(contractAddress_, false);
    }

    // ---------------------Private functions---------------------------- //

    /**
     * @dev Checks if the provided address is nonzero, reverts otherwise.
     * @param address_ The address to check.
     * @custom:error ZeroAddressNotAllowed is thrown if the provided address is a zero address.
     */
    function ensureNonzeroAddress(address address_) private pure {
        if (address_ == address(0)) {
            revert ZeroAddressNotAllowed();
        }
    }

    /**
     * @dev Ensure that the given address has contract code deployed.
     * @param contract_ The address to check for contract code.
     * @custom:error NonContractAddress is thrown if input address is non contract address.
     */
    function enforceHasContractCode(address contract_) private view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(contract_)
        }
        if (contractSize == 0) {
            revert NonContractAddress();
        }
    }
}
