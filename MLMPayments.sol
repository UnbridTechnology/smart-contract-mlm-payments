// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MLMPayments is ReentrancyGuard, Ownable {
    event WithdrawalApproved(address indexed recipient, uint256 amount);
    event WithdrawalMade(address indexed recipient, uint256 amount);
    event TransfersCompleted(address indexed token, uint256 totalTransferred);
    event NativeTransfersCompleted(uint256 totalTransferred);

    /**
     * @dev Transfer multiple amounts of an ERC20 token to multiple recipients
     * @param erc20Token Address of the ERC20 token to transfer
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts to transfer (in token decimals)
     */
    function transferERC20(
        address erc20Token,
        address[] memory recipients,
        uint256[] memory amounts
    ) public onlyOwner nonReentrant {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(erc20Token != address(0), "Invalid token address");

        IERC20 token = IERC20(erc20Token);
        uint256 totalAmount = 0;

        // Calculate total amount needed
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        // Transfer tokens from sender to contract first
        require(
            token.transferFrom(msg.sender, address(this), totalAmount),
            "Initial token transfer failed"
        );

        uint256 totalTransferred = 0;

        // Distribute tokens to recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                token.transfer(recipients[i], amounts[i]),
                "Transfer to recipient failed"
            );
            totalTransferred += amounts[i];
        }

        emit TransfersCompleted(erc20Token, totalTransferred);
    }

    /**
     * @dev Transfer native currency (MATIC) to multiple recipients
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts to transfer (in wei)
     */
    function transferNative(
        address[] memory recipients,
        uint256[] memory amounts
    ) public payable onlyOwner nonReentrant {
        require(recipients.length == amounts.length, "Arrays length mismatch");

        uint256 totalAmount = 0;

        // Calculate total amount needed
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        require(msg.value >= totalAmount, "Insufficient native currency sent");

        uint256 totalTransferred = 0;

        // Distribute native currency to recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Transfer to recipient failed");
            totalTransferred += amounts[i];
        }

        // Return any excess funds
        if (msg.value > totalTransferred) {
            (bool success, ) = msg.sender.call{value: msg.value - totalTransferred}("");
            require(success, "Excess funds return failed");
        }

        emit NativeTransfersCompleted(totalTransferred);
    }

    /**
     * @dev Emergency withdrawal of any ERC20 token
     * @param erc20Token Address of the ERC20 token to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdrawERC20(address erc20Token, uint256 amount) public onlyOwner {
        require(IERC20(erc20Token).transfer(owner(), amount), "Emergency withdrawal failed");
    }

    /**
     * @dev Emergency withdrawal of native currency
     * @param amount Amount to withdraw in wei
     */
    function emergencyWithdrawNative(uint256 amount) public onlyOwner {
        (bool success, ) = owner().call{value: amount}("");
        require(success, "Emergency withdrawal failed");
    }

    // Fallback function to receive native currency
    receive() external payable {}
}