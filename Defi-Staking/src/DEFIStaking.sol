// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.24;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title DEFI Staking Contract
 * @notice Allows users to stake DEFI tokens and earn DEFI as rewards
 */
contract DEFIStaking {
    using SafeERC20 for IERC20;

    // Events
    /** @notice Emitted when any user stake thier DEFI */
    event Staked(address indexed user, uint256 amount);

    /** @notice Emitted when any withraw their stake and rewards */
    event Withdrawn(address indexed user, uint256 amount);

    // Errors
    /** @notice Thrown when given zero value */
    error ZeroValueNotAllowed();

    // Constants
    uint256 public constant REWARD_PER_DAY_PER_1000_DEFI = 1e18; // 1 DEFI token per day per 1000 DEFI tokens staked
    uint256 public constant BLOCKS_PER_DAY = 24 * 60 * 60 / 6; // Assuming 6 seconds per block
    uint256 public constant SCALE_FACTOR = 1e18; // used for scaling the rewards
    address public DEFI; // Address of the DEFI token

    // Struct for storing deposit details
    struct DepositDetails {
        uint256 stakedAmount;
        uint256 lastStakedBlockNumber;
        uint256 accReward;
    }

    // Mapping to store user stake details
    mapping(address => DepositDetails) public userDeposits;

    /**
     * @dev Contract constructor
     * @param _DEFI Address of the DEFI token
     */
    constructor(address _DEFI) {
        DEFI = _DEFI;
    }

    /**
     * @notice Stake DEFI tokens
     * @param _amount The amount of DEFI tokens to stake
     */
    function stake(uint256 _amount) external {
        ensureNonzeroValueForStakedAmount(_amount);

        IERC20(DEFI).safeTransferFrom(msg.sender, address(this), _amount);
        
        _updateUserDetails(_amount);
        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Withdraw staked DEFI tokens and rewards
     */
    function withdraw() external {
        _updateUserDetails(0);
        DepositDetails memory userDeposit = userDeposits[msg.sender];
        ensureNonzeroValueForStakedAmount(userDeposit.stakedAmount);
        uint256 rewardPlusStakedAmount = userDeposit.stakedAmount + userDeposit.accReward / SCALE_FACTOR;

        delete userDeposits[msg.sender];
        IERC20(DEFI).safeTransfer(msg.sender, rewardPlusStakedAmount);
        emit Withdrawn(msg.sender, rewardPlusStakedAmount);
    }

    /**
     * @notice View rewards for a user
     * @param _user The address of the user
     * @return rewards The accumulated rewards for the user
     */
    function viewRewards(address _user) external view returns (uint256 rewards) {
        DepositDetails memory userDeposit = userDeposits[_user];
        uint256 blockDiff;
        if(userDeposit.lastStakedBlockNumber != 0) {
            blockDiff = block.number - userDeposit.lastStakedBlockNumber; 
        }
        rewards = (userDeposit.accReward + _calculateRewards(userDeposit.stakedAmount, blockDiff));
        rewards = rewards / SCALE_FACTOR;
    }

    /**
     * @dev Update user details
     * @param _stakeAmount The amount of DEFI tokens staked
     */
    function _updateUserDetails(uint256 _stakeAmount) internal {
        DepositDetails storage userDeposit = userDeposits[msg.sender];

        uint256 blockDiff;
        if(userDeposit.lastStakedBlockNumber != 0) {
            blockDiff = block.number - userDeposit.lastStakedBlockNumber; 
        }
         
        userDeposit.accReward += _calculateRewards(userDeposit.stakedAmount, blockDiff);
        userDeposit.stakedAmount += _stakeAmount;
        userDeposit.lastStakedBlockNumber = block.number;
    }

    /**
     * @dev Calculate rewards for a user
     * @param _amount The amount of DEFI tokens staked
     * @param blockDiff The number of blocks since the last update
     * @return The calculated rewards
     */
    function _calculateRewards(uint256 _amount, uint256 blockDiff) internal pure returns (uint256) {
        return (_amount * blockDiff * REWARD_PER_DAY_PER_1000_DEFI * SCALE_FACTOR) / (BLOCKS_PER_DAY * 1000 * 1e18);
    }

    // ---------------------Private functions---------------------------- //

    /**
     * @dev Checks if the provided value is nonzero, reverts otherwise.
     * @param value_ The value to check.
     * @custom:error ZeroValueNotAllowed is thrown if the provided value is zero.
     */
    function ensureNonzeroValueForStakedAmount(uint256 value_) private pure {
        if (value_ == 0) {
            revert ZeroValueNotAllowed();
        }
    }
}
