// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./VemateToken.sol";
import "https://github.com/sadiq1971/sol-contracts/blob/main/lib/Ownable.sol";

contract Staking is Ownable{
    Vemate immutable private vemate;

    struct Position {
        uint positionId;
        address walletAddress;
        uint createdDate;
        uint unlockDate;
        uint percentInterest;
        uint tokenStaked;
        uint tokenInterest;
        bool open;
    }

    Position position;

    uint256 public totalAmountOfStaked;
    uint public currentPositionId;
    mapping(uint => Position) public positions;
    mapping(address => uint[]) public positionIdsByAddress;
    mapping(uint => uint) public tiers;
    uint[] public lockPeriods;

    constructor(address payable vemateToken) payable {
        require(vemateToken != address(0x0));
        require(owner() != address(0), "Owner must be set");

        currentPositionId = 0;

        tiers[30] = 700;
        tiers[90] = 1000;
        tiers[180] = 1200;

        lockPeriods.push(30);
        lockPeriods.push(90);
        lockPeriods.push(180);
    }

    function stakeToken(uint numDays, uint256 tokenAmount) external payable {
        require(tiers[numDays] > 0, "Mapping not found");
        require(getAmountLeftForPool()>= tokenAmount, "Not enough amount left for pool");

        uint256 interest = calculateInterest(tiers[numDays], numDays, tokenAmount);
        uint256 total = tokenAmount + interest;

        require(getAmountLeftForPool()>= total, "Not enough amount left for pool");

        uint256 time = getCurrentTime();

        positions[currentPositionId] = Position (
            currentPositionId,
            msg.sender,
            time,
            time + (numDays * 1 days),
            tiers[numDays],
            tokenAmount,
            interest,
            true
        );

        vemate.transferFrom(msg.sender, address(this), tokenAmount);

        positionIdsByAddress[msg.sender].push(currentPositionId);
        currentPositionId += 1;
        totalAmountOfStaked += tokenAmount;

    }

    function calculateInterest(uint basisPoints, uint numDays, uint tokenAmount) private pure returns(uint) {
        return basisPoints * tokenAmount;
    }

    function modifyLockPeriods(uint numDays, uint basisPoints) external onlyOwner{
        // require(owner == msg.sender, "Only owner may modify staking periods");

        tiers[numDays] = basisPoints;
        lockPeriods.push(numDays);
    }

    function getLockPeriods() external view returns(uint[] memory){
        return lockPeriods;
    }

    function getInterestRate(uint numDays) external view returns(uint) {
        tiers[numDays];
    }

    function getPositionById(uint positionId) external view returns(Position memory){
        return positions[positionId];
    }

    function getPositionIdsForAddress(address walletAddress) external view returns(uint[] memory) {
        return positionIdsByAddress[walletAddress];
    }

    function changeLockDate(uint positionId, uint newUnlockDate) external onlyOwner{
        positions[positionId].unlockDate = newUnlockDate;
    }

    function getCurrentTime()
    internal
    virtual
    view
    returns(uint256){
        return block.timestamp;
    }

    /**
    * @dev Returns the amount of tokens that can be withdrawn by the owner.
    * @return the amount of tokens
    */
    function getAmountLeftForPool() public view returns(uint256){
        return vemate.balanceOf(address(this)) - totalAmountOfStaked;
    }

    function withdrawWithInterest(uint positionId) external {
        require(positions[positionId].walletAddress == msg.sender, "Only position creator may modify position");
        require(positions[positionId].open == true, "Already unstaked");

        uint256 time = getCurrentTime();
        require(time > positions[positionId].unlockDate, "Not fullfill the period");

        uint tokenAmount = positions[positionId].tokenStaked;
        uint amountWithInterest = tokenAmount + positions[positionId].tokenInterest;
        vemate.transfer(_msgSender(), amountWithInterest);

        totalAmountOfStaked -= tokenAmount;
        positions[positionId].open = false;
    }

    function emergencyWithdraw(uint positionId) external {
        require(positions[positionId].walletAddress == msg.sender, "Only position creator may modify position");
        require(positions[positionId].open == true, "Already unstaked");
        
        uint256 time = getCurrentTime();
        require(time < positions[positionId].unlockDate, "already fullfilled the period");

        uint amount = positions[positionId].tokenStaked;
        vemate.transfer(_msgSender(), amount);

        totalAmountOfStaked -= amount;
        positions[positionId].open = false;
    }
}