// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DEFIStaking.sol";
import "./Mocks/MockToken.sol";

contract DEFIStakingTest is Test {
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    error ZeroValueNotAllowed();

    DEFIStaking public defiStaking;
    MockToken DEFIToken;

    struct DepositDetails {
        uint256 stakedAmount;
        uint256 lastStakedBlockNumber;
        uint256 accReward;
    }

    function setUp() public {
        DEFIToken = new MockToken("DEFIToken", "DEFI", 18);
        defiStaking = new DEFIStaking(address(DEFIToken));
    }

    function test_UserStakeDEFIZeroAmount() public {

        vm.expectRevert(ZeroValueNotAllowed.selector);
        defiStaking.stake(0);
    }

    function test_UserStakeDEFI(uint256 amount) public {
        vm.assume(amount > 0);
        DEFIToken.faucet(amount);
        DEFIToken.approve(address(defiStaking), amount);
        
        vm.expectEmit(address(defiStaking));
        emit Staked(address(this), amount);
        defiStaking.stake(amount);
        (uint256 stakedAmount, uint256 lastStakedBlockNumber, uint256 accReward) = defiStaking.userDeposits(address(this));

        assertEq(stakedAmount, amount);
        assertEq(lastStakedBlockNumber, block.number);
        assertEq(accReward, 0);
    }

    function test_UserViewRewards() public  {
        uint256 amount = 1631;
        DEFIToken.faucet(amount);
        DEFIToken.approve(address(defiStaking), amount);
        
        vm.expectEmit(address(defiStaking));
        emit Staked(address(this), amount);
        defiStaking.stake(amount);

        vm.roll(1000);
        uint256 reward = amount * (1000 - 1) * 1e18 / (14400 * 1e18 * 1000);
        assertEq(defiStaking.viewRewards(address(this)), reward);
 
    }

    function test_UserWithdraw() public {
        uint256 amount = 1000e18;
        DEFIToken.faucet(amount);
        DEFIToken.approve(address(defiStaking), amount);
        
        vm.expectEmit(address(defiStaking));
        emit Staked(address(this), amount);
        defiStaking.stake(amount);

        // airdrop some DEFI to staking contract
        vm.prank(address(defiStaking));
        DEFIToken.faucet(10e18);

        vm.roll(1000);
        defiStaking.withdraw();
        uint256 reward = amount * (1000 - 1) * 1e18 / (14400 * 1e18 * 1000);
        assertEq(DEFIToken.balanceOf(address(this)), amount + reward);
        
    }

    function test_UserStakeMultipleTimes() public {
        uint256 stake1 = 1000e18;
        DEFIToken.faucet(stake1);
        DEFIToken.approve(address(defiStaking), stake1);
        
        vm.expectEmit(address(defiStaking));
        emit Staked(address(this), stake1);
        defiStaking.stake(stake1);
        (uint256 stakedAmount, uint256 lastStakedBlockNumber, uint256 accReward) = defiStaking.userDeposits(address(this));

        assertEq(stakedAmount, stake1);
        assertEq(lastStakedBlockNumber, block.number);
        assertEq(accReward, 0);

        // forward 14400 blocks
        vm.roll(14401);
        uint256 stake2 = 2000e18;
        DEFIToken.faucet(stake2);
        DEFIToken.approve(address(defiStaking), stake2);
        
        vm.expectEmit(address(defiStaking));
        emit Staked(address(this), stake2);
        defiStaking.stake(stake2);
        (uint256 stakedAmount2, uint256 lastStakedBlockNumber2, uint256 accReward2) = defiStaking.userDeposits(address(this));

        uint256 reward = stake1 * (14401 - 1) * 1e18 / (14400 * 1e18 * 1000); // =1 defi as reward
        assertEq(stakedAmount2, stake1 + stake2);
        assertEq(lastStakedBlockNumber2, 14401);
        assertEq(accReward2, reward * 1e18);
    }

}
