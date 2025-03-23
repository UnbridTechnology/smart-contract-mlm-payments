// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MLMPayments is ReentrancyGuard, Ownable {
    IERC20 public usdtToken;
    mapping(address => uint256) public allowedWithdrawals;

    event WithdrawalApproved(address indexed recipient, uint256 amount);
    event WithdrawalMade(address indexed recipient, uint256 amount);
    event USDTTokenSet(address indexed newUsdtToken);
    event TransfersCompleted(uint256 totalTransferred);

    constructor(address _initialOwner, address _usdtToken) Ownable(_initialOwner) {
        setUsdtToken(_usdtToken);
    }

    /**
     * @dev Sets a new USDT token contract address.
     * @param newUsdtToken The address of the new USDT token contract.
     */
    function setUsdtToken(address newUsdtToken) public onlyOwner {
        require(newUsdtToken != address(0), "Invalid token address");
        usdtToken = IERC20(newUsdtToken);
        emit USDTTokenSet(newUsdtToken);
    }

    function emergencyWithdraw(uint256 amount) public onlyOwner {
        require(
            usdtToken.transfer(owner(), amount),
            "Emergency withdrawal failed"
        );
    }

    function depositAndTransfer(
        uint256 totalAmount,
        address[] memory recipients,
        uint256[] memory amounts
    ) public onlyOwner nonReentrant {
        require(recipients.length == amounts.length, "Arrays length mismatch");

        require(
            usdtToken.allowance(msg.sender, address(this)) >= totalAmount,
            "Contract not approved to transfer totalAmount"
        );

        require(
            usdtToken.transferFrom(msg.sender, address(this), totalAmount),
            "Token transfer failed"
        );

        uint256 totalTransferred = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                usdtToken.transfer(recipients[i], amounts[i]),
                "Transfer to recipient failed"
            );
            totalTransferred += amounts[i];
        }

        emit TransfersCompleted(totalTransferred);
    }
}
