// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./VemateToken.sol";
import "https://github.com/sadiq1971/sol-contracts/blob/main/lib/Ownable.sol";

contract Staking is Ownable{
    Vemate private vemate;

    struct Position {
        uint256 positionId;
        address walletAddress;
        uint256 createdDate;
        uint256 unlockDate;
        uint256 percentInterest;
        uint256 tokenStaked;
        uint256 tokenInterest;
        bool open;
    }

    Position position;

    uint16[] public lockPeriods;

    mapping(uint => Position) public positions;
    mapping(address => uint[]) public positionIdsByAddress;
    mapping(uint => uint) public tiers;

    uint256 private constant DAY = 24 * 60 * 60;
    uint256 public totalAmountOfStaked;
    uint256 public currentPositionId;

    constructor(address payable vemateToken) 
    payable {
        require(vemateToken != address(0x0));
        require(owner() != address(0), "Owner must be set");

        currentPositionId = 0;

        tiers[90] = 700;
        tiers[180] = 1000;
        tiers[360] = 1200;

        lockPeriods.push(90);
        lockPeriods.push(180);
        lockPeriods.push(360);
    }

    function stakeToken(uint numDays, uint256 tokenAmount) 
    external 
    payable {
        require(tiers[numDays] > 0, "Mapping not found");
        require(getAmountLeftForPool()>= tokenAmount, "Not enough amount left for pool");

        uint256 interest = calculateInterest(tiers[numDays], tokenAmount);
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

    function calculateInterest(uint basisPoints, uint256 tokenAmount) 
    private 
    pure 
    returns(uint) {
        uint256 totalInterestAmount = (basisPoints/1000) * tokenAmount; 
        return totalInterestAmount;
    }

    function modifyLockPeriods(uint16 numDays, uint16 basisPoints) 
    external onlyOwner{
        tiers[numDays] = basisPoints;
        lockPeriods.push(numDays);
    }

    function getLockPeriods() 
    external 
    view 
    returns(uint16[] memory){
        return lockPeriods;
    }

    function getPositionById(uint positionId) 
    external 
    view 
    returns(Position memory){
        return positions[positionId];
    }

    function getPositionIdsForAddress(address walletAddress) 
    external 
    view 
    returns(uint[] memory) {
        return positionIdsByAddress[walletAddress];
    }

    function changeLockDate(uint positionId, uint newUnlockDate) 
    external onlyOwner{
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
    function getAmountLeftForPool() 
    public 
    view 
    returns(uint256){
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
        uint256 stakedTime = positions[positionId].createdDate;
        uint256 timeDifference = time - stakedTime;
        require(time < positions[positionId].unlockDate, "already fullfilled the period");

        uint amount = positions[positionId].tokenStaked;

        uint256 penalty = checkPenalty(timeDifference, amount);

        uint256 amountAfterPenalty = amount - penalty;
        vemate.transfer(_msgSender(), amountAfterPenalty);

        totalAmountOfStaked -= amount;
        positions[positionId].open = false;
    }

    function checkPenalty(uint256 _time, uint256 _stakedAmount) private pure returns(uint) {
        uint256 stakedTime_ = _time;
        uint256 penalty;
        uint numberOfDays = stakedTime_ / DAY;
        uint256 stakedToken = _stakedAmount;

        if(numberOfDays<10){
            penalty = (stakedToken*2)/10;
            return penalty;
        } else if(numberOfDays < 20) {
            penalty = (stakedToken*2)/10;
            return penalty;
        } else if(numberOfDays < 30) {
            penalty = (stakedToken*2)/10;
            return penalty;
        } else if(numberOfDays < 60) {
            penalty = (stakedToken*2)/10;
            return penalty;
        } else {
            return 0;
        }
    }
}