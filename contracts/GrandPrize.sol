// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// errors
error GrandPrize__AlreadyAParticipant();
error GrandPrize__TaskLengthTooShort();
error GrandPrize__GameValueOnlyForGameType();
error GrandPrize__PrizePoolTooLow();
error GrandPrize__TimeTooClose();
error GrandPrize__WinnersMustBeGreaterThanOne();
error GrandPrize__IndexOutOfBounds();
error GrandPrize__AlreadyJoinedActivity();
error GrandPrize__InsufficientEntryFee();
error GrandPrize__NotAParticipant();

/// @title Grand Prize
/// @author Favour Aniogor
/// @notice This is responsible for selecting random winners and dissing out airdrop
/// @dev This uses chainlink VRF to generate random numbers and select winners
contract GrandPrize {
    uint256 public s_totalParticipants;
    mapping(address => bool) private s_isParticipant;
    mapping(uint256 => mapping(address => bool)) private s_submittedIndividuals;
    mapping(uint256 => mapping(address => bool)) private s_joinedActivity;
    mapping(uint256 => uint256) private s_activityToEntryFeesBalance;
    Activity[] public s_activities;

    /// events
    /// @notice This event to be emitted when a new activity is created
    /// @param _author the address that created the activity
    /// @param _prizePool total amount to the won
    /// @param _maxWinners the total amount of people that can win
    /// @param _entryFee amount needed to join the activity
    /// @param _closeTime when the activity closes
    event NewActivity(address indexed _author, uint256 _prizePool, uint256 _maxWinners, uint256 _entryFee, uint256 _closeTime);
    /// @notice This event to be emitted when a participant joins an activity
    /// @param _participant the address that joined the activity
    /// @param _entryFee the amount paid to join the activity
    /// @param _activityIndex the index of the activity joined
    event JoinedActivity(address indexed _participant, uint256 _entryFee, uint256 indexed _activityIndex);

    /// @notice This the datatype for activity type
    enum ActivityType {
        Game,
        Content
    }
    
    /// @notice This is the data structure for the activities
    struct Activity {
        string _task;
        uint256 _entryFee;
        uint256 _prizePool;
        uint256 _gameValue;
        ActivityType _activityType;
        uint256 _acceptedEntries;
        uint256 _closeTime;
        address _author;
        uint256 _maxWinners;
    }

    /// @notice This allows user to register as Participant in the GrandPrize system
    /// @dev This uses the s_isParticipant variable to carefully map new participants. 
    function registerAsParticipant() external {
        if(s_isParticipant[msg.sender]){
            revert GrandPrize__AlreadyAParticipant();
        }
        s_isParticipant[msg.sender] = true;
        s_totalParticipants++;
    }

    /// @notice This function allows a user create an activity
    /// @param _task a parameter for the task that is to be executed in the activity
    /// @param _entryFee a parameter for the fee that a user needs to pay to summit the activity 
    /// @param _gameValue a parameter for the game activity type that says the amount the individual as to pay to join the game
    /// @param _prizePool a parameter for the total amount of reward the activity gives in GPT
    /// @param _activityType a parameter for the category the activity falls under.
    /// @param _closeTime a parameter for when the activity closes.
    /// @param _maxWinners a parameter the amount of winners the activity should have.
    function createActivity(string memory _task, uint256 _entryFee, uint256 _gameValue, uint256 _prizePool, ActivityType _activityType, uint256 _closeTime, uint256 _maxWinners) external {
        if(bytes(_task).length < 5){
            revert GrandPrize__TaskLengthTooShort();
        }
        if(_prizePool <= 0){
            revert GrandPrize__PrizePoolTooLow();
        }
        if(_activityType != ActivityType.Game && _gameValue > 0){
            revert GrandPrize__GameValueOnlyForGameType();
        }
        if(_closeTime <= block.timestamp){
            revert GrandPrize__TimeTooClose();
        }
        if(_maxWinners < 1){
            revert GrandPrize__WinnersMustBeGreaterThanOne();
        }
        s_activities.push(Activity(_task, _entryFee, _gameValue, _prizePool, _activityType, 0, _closeTime, msg.sender, _maxWinners));
        emit NewActivity(msg.sender, _prizePool, _maxWinners, _entryFee, _closeTime);
    }

    /// @notice This allows users to join any activity
    /// @param _activityIndex a parameter for the index of the activty you want to join
    function joinActivity(uint256 _activityIndex) external payable {
        if(!s_isParticipant[msg.sender]){
            revert GrandPrize__NotAParticipant();
        }
        if(_activityIndex >= s_activities.length){
            revert GrandPrize__IndexOutOfBounds();
        }
        if(s_joinedActivity[_activityIndex][msg.sender]){
            revert GrandPrize__AlreadyJoinedActivity();
        }
        if(s_activities[_activityIndex]._entryFee > msg.value){
            revert GrandPrize__InsufficientEntryFee();
        }
        s_joinedActivity[_activityIndex][msg.sender] = true;
        s_activityToEntryFeesBalance[_activityIndex] += msg.value;
        emit JoinedActivity(msg.sender, msg.value, _activityIndex);
    }

}