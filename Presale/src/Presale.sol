// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title Presale Contract for ChainForgeToken (CFT)
/// @author Prakrit-Jain
/// @notice This contract handles the presale of CFT tokens in exchange for USDT, with a referral reward system and refund mechanisms.
contract Presale is Ownable, ReentrancyGuard {
    using Math for uint256;

    IERC20 public CFT;  // ChainForgeToken instance
    IERC20 public USDT; // USDT instance
    uint256 public presalePrice = 0.001 * 1e18; // 1 CFT = 0.001 USDT
    uint256 public constant CFTForSale = 500000 * 1e18; // 500,000 CFT allocated for presale
    uint256 public totalUSDTCollected;  // Total USDT collected during presale
    uint256 public totalCFTSold;  // Total CFT sold during presale
    bool public presaleActive = true;  // Boolean indicating if the presale is active
    bool public presaleSuccess;  // Boolean indicating if the presale was successful
    uint256 public minContribution = 10 * 1e18;  // Minimum contribution (10 USDT)
    uint256 public maxContribution = 5000 * 1e18;  // Maximum contribution (5000 USDT per address)

    mapping(address => uint256) public contributions;  // Maps user addresses to their contributions
    mapping(address => address) public referrer;  // Tracks referrers for each participant

    uint256[] public referralRewardPercentages = [10, 7, 5, 3, 1];  // Reward percentages for referrers across levels

    /// @notice Emitted when a user purchases CFT tokens
    /// @param buyer The address of the user purchasing tokens
    /// @param amount The amount of CFT tokens bought
    /// @param referrer The address of the user's referrer, if any
    event Purchase(address indexed buyer, uint256 amount, address indexed referrer);

    /// @notice Emitted when a user claims their tokens after a successful presale
    /// @param user The address of the user claiming tokens
    /// @param amount The amount of tokens claimed
    event TokensClaimed(address indexed user, uint256 amount);

    /// @notice Emitted when a user receives a refund after a failed presale
    /// @param user The address of the user receiving the refund
    /// @param amount The amount of USDT refunded
    event Refund(address indexed user, uint256 amount);

    /// @notice Emitted when the owner withdraws USDT from the contract
    /// @param owner The address of the contract owner
    /// @param amount The amount of USDT withdrawn
    event USDTWithdrawn(address indexed owner, uint256 amount);

    /// @notice Emitted when the presale is finalized, indicating its success or failure
    /// @param success A boolean indicating whether the presale was successful
    event PresaleFinalized(bool success);

    /// @notice Initializes the presale contract
    /// @param _CFT The address of the CFT token
    /// @param _USDT The address of the USDT token
    constructor(IERC20 _CFT, IERC20 _USDT) Ownable(msg.sender) {
        CFT = _CFT;
        USDT = _USDT;
    }

    /// @notice Allows users to buy CFT tokens during the presale
    /// @param usdtAmount The amount of USDT to contribute
    /// @param referrerAddress The address of the referrer, if any
    /// @dev Users can only contribute between `minContribution` and `maxContribution` and must not exceed the total amount of CFT available.
    function buyCFT(uint256 usdtAmount, address referrerAddress) external nonReentrant {

        require(presaleActive, "Presale is not active");
        require(usdtAmount >= presalePrice, "Insufficient USDT for the minimum CFT"); // Handle this first
        require(usdtAmount >= minContribution, "Below minimum contribution");
        require(usdtAmount <= maxContribution, "Above maximum contribution");

        uint256 cftAmount = usdtAmount.mulDiv(1e18, presalePrice);
        require(totalCFTSold + cftAmount <= CFTForSale, "Not enough CFT left for sale");

        // Track contributions and referrer
        if (referrerAddress != address(0) && referrer[msg.sender] == address(0)) {
            referrer[msg.sender] = referrerAddress;
        }

        // Transfer USDT from buyer to contract
        USDT.transferFrom(msg.sender, address(this), usdtAmount);
        contributions[msg.sender] += cftAmount;
        totalUSDTCollected += usdtAmount;
        totalCFTSold += cftAmount;

        // Distribute referral rewards
        _distributeReferralRewards(msg.sender, usdtAmount);

        emit Purchase(msg.sender, cftAmount, referrerAddress);
    }

    /// @notice Distributes referral rewards for a buyer
    /// @param buyer The address of the buyer
    /// @param amount The amount of USDT contributed
    /// @dev Rewards are distributed based on the `referralRewardPercentages` array across referral levels.
    function _distributeReferralRewards(address buyer, uint256 amount) internal {
        address currentReferrer = referrer[buyer];
        for (uint256 i; i < referralRewardPercentages.length;) {
            if (currentReferrer == address(0)) break;
            uint256 reward = amount.mulDiv(referralRewardPercentages[i], 100);
            USDT.transfer(currentReferrer, reward);
            currentReferrer = referrer[currentReferrer];

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Allows users to claim their tokens after the presale is successful
    /// @dev Tokens can only be claimed after the presale has been marked successful by the owner.
    function claimTokens() external nonReentrant {
        require(presaleSuccess, "Presale not successful");
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "No tokens to claim");

        contributions[msg.sender] = 0;
        CFT.transfer(msg.sender, amount);

        emit TokensClaimed(msg.sender, amount);
    }

    /// @notice Allows users to receive a refund if the presale fails
    /// @dev Only callable if the presale has been marked as failed. Refunds are based on the user's contributions.
    function refund() external nonReentrant {
        require(!presaleSuccess, "Presale succeeded, refund not possible");
        uint256 contribution = contributions[msg.sender];
        require(contribution > 0, "No contributions to refund");

        contributions[msg.sender] = 0;
        uint256 refundAmount = contribution.mulDiv(presalePrice, 1e18);
        USDT.transfer(msg.sender, refundAmount);

        emit Refund(msg.sender, refundAmount);
    }

    /// @notice Allows the owner to withdraw the collected USDT after a successful presale
    /// @dev Only callable after the presale has been marked as successful.
    function withdrawUSDT() external onlyOwner nonReentrant {
        require(presaleSuccess, "Presale not successful");
        uint256 balance = USDT.balanceOf(address(this));
        require(balance > 0, "No funds to withdraw");

        USDT.transfer(owner(), balance);

        emit USDTWithdrawn(owner(), balance);
    }

    /// @notice Finalizes the presale, indicating success or failure
    /// @param success A boolean indicating whether the presale was successful
    /// @dev This function can only be called once to finalize the presale.
    function finalizePresale(bool success) external onlyOwner {
        require(presaleActive, "Presale already finalized");
        presaleActive = false;
        presaleSuccess = success;

        emit PresaleFinalized(success);
    }
}
