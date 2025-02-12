// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TimeLockedWallet is Ownable, ReentrancyGuard {
    event Deposited(address indexed sender, uint256 amount, uint256 lockDuration);
    event Withdrawn(address indexed receiver, uint256 amount);

    struct Deposit {
        uint256 amount;
        uint256 unlockTime;
    }

    struct DepositInfo {
        uint256 amount;
        uint256 unlockTime;
        uint256 remainingTime;
        bool isWithdrawable;
    }

    error NotDepositOwner();

    modifier onlyDepositOwner() {
        if (deposits[msg.sender].length == 0) revert NotDepositOwner();
        _;
    }

    mapping(address => Deposit[]) public deposits;
    uint256 public totalBalance;

    constructor() Ownable(msg.sender) {}

    receive() external payable {
        depositWithLock(30 days);
    }

    fallback() external payable {
        depositWithLock(30 days);
    }

    function depositWithLock(uint256 _lockDuration) public payable {
        require(msg.value > 0, "Must send ETH");
        require(_lockDuration > 0, "Lock duration must be greater than 0");

        deposits[msg.sender].push(Deposit({amount: msg.value, unlockTime: block.timestamp + _lockDuration}));

        totalBalance += msg.value;
        emit Deposited(msg.sender, msg.value, _lockDuration);
    }

    function withdraw(uint256 _depositIndex) external nonReentrant {
        Deposit[] storage userDeposits = deposits[msg.sender];
        require(_depositIndex < userDeposits.length, "Invalid deposit index");

        Deposit storage depositToWithdraw = userDeposits[_depositIndex];
        require(depositToWithdraw.amount > 0, "Deposit already withdrawn");
        require(block.timestamp >= depositToWithdraw.unlockTime, "Funds are still locked");

        uint256 amount = depositToWithdraw.amount;
        depositToWithdraw.amount = 0; // Prevent re-entrancy
        totalBalance -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        totalBalance += msg.value;
        emit Deposited(msg.sender, msg.value, 30 days);
    }

    function getMyDeposits() external view onlyDepositOwner returns (DepositInfo[] memory) {
        Deposit[] storage userDeposits = deposits[msg.sender];
        DepositInfo[] memory depositInfos = new DepositInfo[](userDeposits.length);

        for (uint256 i = 0; i < userDeposits.length; i++) {
            Deposit storage _deposit = userDeposits[i];
            uint256 remainingTime = 0;
            bool isWithdrawable = false;

            if (_deposit.amount > 0) {
                if (block.timestamp < _deposit.unlockTime) {
                    remainingTime = _deposit.unlockTime - block.timestamp;
                } else {
                    isWithdrawable = true;
                }
            }

            depositInfos[i] = DepositInfo({
                amount: _deposit.amount,
                unlockTime: _deposit.unlockTime,
                remainingTime: remainingTime,
                isWithdrawable: isWithdrawable
            });
        }

        return depositInfos;
    }

    function getMyWithdrawableDeposits() external view onlyDepositOwner returns (uint256[] memory) {
        Deposit[] storage userDeposits = deposits[msg.sender];
        uint256[] memory withdrawableIndexes = new uint256[](userDeposits.length);
        uint256 count = 0;

        for (uint256 i = 0; i < userDeposits.length; i++) {
            if (userDeposits[i].amount > 0 && block.timestamp >= userDeposits[i].unlockTime) {
                withdrawableIndexes[count] = i;
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = withdrawableIndexes[i];
        }

        return result;
    }

    function getMyDepositCount() external view returns (uint256) {
        if (deposits[msg.sender].length == 0) {
            return 0;
        }
        return deposits[msg.sender].length;
    }
}
