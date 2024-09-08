// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Presale.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./mocks/MockERC20.sol";

contract PresaleTest is Test {
    Presale presale;
    IERC20 CFT;
    IERC20 USDT;
    address owner = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);
    address referrer1 = address(0x4);
    address referrer2 = address(0x5);

    uint256 presalePrice = 0.001 * 1e18;
    uint256 minContribution = 10 * 1e18; // 10 USDT
    uint256 maxContribution = 5000 * 1e18; // 5000 USDT
    uint256 totalCFTForSale = 500000 * 1e18; // 500,000 CFT

    function setUp() public {
        CFT = IERC20(address(new MockERC20("ChainForgeToken", "CFT", totalCFTForSale)));
        USDT = IERC20(address(new MockERC20("Tether", "USDT", 1000000 * 1e18)));

        presale = new Presale(CFT, USDT);
        presale.transferOwnership(owner);
        
        // Fund user1, user2, referrer1, and referrer2 with USDT
        deal(address(USDT), user1, 6000 * 1e18);
        deal(address(USDT), user2, 6000 * 1e18);
        deal(address(USDT), referrer1, 1000 * 1e18);
        deal(address(USDT), referrer2, 1000 * 1e18);
        
        // Approve presale contract to spend USDT from users
        vm.prank(user1);
        USDT.approve(address(presale), 6000 * 1e18);
        vm.prank(user2);
        USDT.approve(address(presale), 6000 * 1e18);
    }

    function testBuyCFTWithoutReferral() public {
        vm.prank(user1);
        presale.buyCFT(100 * 1e18, address(0));

        uint256 expectedCFT = (100 * 1e18) * (1e18) / presalePrice;

        assertEq(presale.contributions(user1), expectedCFT);
        assertEq(presale.totalUSDTCollected(), 100 * 1e18);
        assertEq(presale.totalCFTSold(), expectedCFT);
    }

    function testBuyCFTWithReferral() public {
        // Step 1: Capture the referrer's initial balance
        uint256 referrerInitialBalance = USDT.balanceOf(referrer1);

        // Step 2: User1 buys CFT with 100 USDT and provides referrer1 as a referral
        vm.prank(user1);
        presale.buyCFT(100 * 1e18, referrer1);

        // Step 3: Calculate expected CFT tokens and referrer reward
        uint256 expectedCFT = (100 * 1e18)  * 1e18 / presalePrice;
        uint256 referrerReward = (100 * 1e18) * 10 / 100; // Assuming 10% referral reward

        // Step 4: Assert that user1's contribution was correctly recorded
        assertEq(presale.contributions(user1), expectedCFT);

        // Step 5: Assert that referrer1 received the correct reward
        uint256 referrerFinalBalance = USDT.balanceOf(referrer1);
        assertEq(referrerFinalBalance, referrerInitialBalance + referrerReward);
    }

    function testCannotContributeBelowMin() public {
        vm.prank(user1);
        vm.expectRevert("Below minimum contribution");
        presale.buyCFT(5 * 1e18, address(0)); // Below minimum contribution
    }

    function testCannotContributeAboveMax() public {
        vm.prank(user1);
        vm.expectRevert("Above maximum contribution");
        presale.buyCFT(6000 * 1e18, address(0)); // Above maximum contribution
    }

    function testCannotBuyInsufficientUSDT() public {
        vm.prank(user1);
        vm.expectRevert("Insufficient USDT for the minimum CFT");
        presale.buyCFT(0.0005 * 1e18, address(0));
    }

    function testCannotExceedCFTForSale() public {
        uint256 contribution = (totalCFTForSale * presalePrice) / 1e18 + 1; // One more than total supply

        vm.prank(user1);
        vm.expectRevert("Not enough CFT left for sale");
        presale.buyCFT(contribution, address(0));
    }

    function testClaimTokens() public {
        // Step 1: Buy CFT tokens before the presale is finalized
        vm.prank(user1);
        presale.buyCFT(100 * 1e18, address(0)); // User1 buys with 100 USDT
        
        // Step 2: Finalize the presale as successful
        vm.prank(owner);
        presale.finalizePresale(true); // Finalizing the presale as successful
        
        // Step 3: Claim tokens after the presale is finalized
        uint256 expectedTokens = (100 * 1e18) * 1e18 / presalePrice;
        
        // Fund the presale contract
        deal(address(CFT), address(presale), 1e23);

        vm.prank(user1);
        presale.claimTokens(); // User1 claims tokens
        
        // Verify that the user received the correct amount of CFT tokens
        assertEq(CFT.balanceOf(user1), expectedTokens);
        
        // Ensure the user's contribution is set to 0 after claiming
        assertEq(presale.contributions(user1), 0);
    }

    function testCannotClaimBeforeFinalize() public {
        vm.prank(user1);
        presale.buyCFT(100 * 1e18, address(0));

        vm.prank(user1);
        vm.expectRevert("Presale not successful");
        presale.claimTokens();
    }

    function testRefund() public {
    // Prank the user to simulate the purchase of CFT tokens
    vm.prank(user1);
    presale.buyCFT(100 * 1e18, address(0)); // Buying 100 USDT worth of CFT

    // Finalize the presale as unsuccessful
    vm.prank(owner);
    presale.finalizePresale(false); // Marking presale as failed

    // Check the initial balance of the user before refund
    uint256 initialBalance = USDT.balanceOf(user1);

    // Prank the user and call the refund function
    vm.prank(user1);
    presale.refund(); // User requests a refund

    // Calculate expected balance after refund
    uint256 expectedBalance = initialBalance + (100 * 1e18); // Refund of 100 USDT

    // Check if the user's balance increased by the refund amount
    assertEq(USDT.balanceOf(user1), expectedBalance); // Ensure correct refund is issued

    // Ensure that the contributions of the user are set back to 0
    assertEq(presale.contributions(user1), 0);
}

    function testWithdrawUSDT() public {
        vm.prank(user1);
        presale.buyCFT(100 * 1e18, address(0));

        vm.prank(owner);
        presale.finalizePresale(true);

        uint256 contractBalance = USDT.balanceOf(address(presale));

        vm.prank(owner);
        presale.withdrawUSDT();

        assertEq(USDT.balanceOf(owner), contractBalance);
    }

    function testFinalizePresaleOnce() public {
        vm.prank(owner);
        presale.finalizePresale(true);

        vm.expectRevert("Presale already finalized");
        vm.prank(owner);
        presale.finalizePresale(true);
    }

    function testCannotRefundAfterSuccess() public {
        vm.prank(user1);
        presale.buyCFT(100 * 1e18, address(0));

        vm.prank(owner);
        presale.finalizePresale(true);

        vm.expectRevert("Presale succeeded, refund not possible");
        vm.prank(user1);
        presale.refund();
    }
}
