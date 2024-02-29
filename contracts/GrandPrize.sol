// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {ERC20Token} from "./ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

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
error GrandPrize__NotJoinedActivity();
error GrandPrize__GameValueTooLow();
error GrandPrize__ActivityNotClosed();
error GrandPrize__ActivityNoLongerOpen();

/// @title Grand Prize
/// @author Favour Aniogor
/// @notice This is responsible for selecting random winners and dissing out airdrop
/// @dev This uses chainlink VRF to generate random numbers and select winners
contract GrandPrize is VRFConsumerBaseV2, Ownable {
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    ERC20Token private s_token;
    uint256 public s_totalParticipants;
    mapping(address => bool) private s_isParticipant;
    mapping(uint256 => mapping(address => bool)) private s_submittedIndividuals;
    mapping(uint256 => mapping(address => bool)) private s_joinedActivity;
    mapping(uint256 => uint256) private s_activityToEntryFeesBalance;
    mapping(uint256 => address[]) private s_submittedAddresses;
    Activity[] public s_activities;
    mapping(uint256 => uint256) private s_pickingWinnerActivityId;

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
    /// @notice This event to be emitted when a participant submits an entry for an activity
    /// @param _participant the address that submitted the entry for the activity
    /// @param _activityIndex the index of the activity the participant submitted entry for
    /// @param _gameValue the amount the _participant paid for a valid entry
    event EntrySubmitted(address indexed _participant,uint256 indexed _activityIndex, uint256 _gameValue);
    /// @notice This event to be emitted when the pickwinner function is executed successfully
    /// @param _activityIndex the index of the activity that we are trying to pick a winner from
    /// @param _requestId the id returned from our VRF
    event RequestedActivityWinner(uint256 indexed _requestId, uint256 indexed _activityIndex);
    /// @notice This event to be emitted when a winner is selected
    /// @param _activityId the index of the activity that the participants won
    /// @param _winner the address that won
    event WinnerPicked(address indexed _winner, uint256 indexed _activityId);

    /// @notice This the datatype for activity type
    enum ActivityType {
        Game,
        Content
    }

    /// @notice this is the datatype for checking the status of an activity
    enum ActivityStatus{
        OPEN,
        CALCULATING,
        CLOSED
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
        address[] _winners;
        ActivityStatus _status;
    }

    /// @notice Setting contract on deployment
    /// @param _keyHash used by 
    constructor(bytes32 _keyHash, uint64 _subscriptionId, uint32 _callbackGasLimit, address _vrfCoordinator, string memory _name, string memory _symbol, uint8 _decimal, uint256 _totalSupply) VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender){
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_token = new ERC20Token(_name, _symbol, _decimal, _totalSupply);
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
    function createActivity(string memory _task, uint256 _entryFee, uint256 _gameValue, uint256 _prizePool, ActivityType _activityType, uint256 _closeTime, uint256 _maxWinners) external onlyOwner {
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
        s_activities.push(Activity(_task, _entryFee, _prizePool, _gameValue, _activityType, 0, _closeTime, msg.sender, _maxWinners, new address[](0), ActivityStatus.OPEN));
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
        if(s_activities[_activityIndex]._status != ActivityStatus.OPEN){
            revert GrandPrize__ActivityNoLongerOpen();
        }
        if(s_activities[_activityIndex]._entryFee > msg.value){
            revert GrandPrize__InsufficientEntryFee();
        }
        s_joinedActivity[_activityIndex][msg.sender] = true;
        s_activityToEntryFeesBalance[_activityIndex] += msg.value;
        emit JoinedActivity(msg.sender, msg.value, _activityIndex);
    }

    /// @notice This function allows a participant to submit entry for an activity
    /// @param _activityIndex a parameter for the index of the activty you want submit entry for.
    /// @param _taskUri a parameter for the task submission for the entry
    function submitEntry(uint256 _activityIndex, string calldata _taskUri) external payable{
        if(_activityIndex >= s_activities.length){
            revert GrandPrize__IndexOutOfBounds();
        }
        if(!s_joinedActivity[_activityIndex][msg.sender]){
            revert GrandPrize__NotJoinedActivity();
        }
        if(s_activities[_activityIndex]._activityType == ActivityType.Content && bytes(_taskUri).length < 5){
            revert GrandPrize__TaskLengthTooShort();
        } 
        if(s_activities[_activityIndex]._gameValue > msg.value){
            revert GrandPrize__GameValueTooLow();
        }
        if(s_activities[_activityIndex]._status != ActivityStatus.OPEN){
            revert GrandPrize__ActivityNoLongerOpen();
        }
        s_submittedIndividuals[_activityIndex][msg.sender] = true;
        s_submittedAddresses[_activityIndex].push(msg.sender);
        emit EntrySubmitted(msg.sender, _activityIndex, msg.value);
    }

    /// @notice This allows a winner to be picked
    /// @param _activityIndex a parameter for the index of the activity to pick winner from 
    function pickWinner(uint256 _activityIndex) external {
        if(_activityIndex >= s_activities.length){
            revert GrandPrize__IndexOutOfBounds();
        }
        if(s_activities[_activityIndex]._closeTime > block.timestamp){
            revert GrandPrize__ActivityNotClosed();
        }
        uint256 _requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            4,
            i_callbackGasLimit,
            4
        );
        s_pickingWinnerActivityId[_requestId] = _activityIndex;
        s_activities[_activityIndex]._status = ActivityStatus.CALCULATING;
        emit RequestedActivityWinner(_requestId, _activityIndex);
    }

    /// @notice This is called by the VRFCoordinator when it is time to get a random word verifier
    /// @param randomWords the random words genarated from chainlink.
    /// @param requestId the requestId return from the vrfCoordinator 
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        selectWinnerAndDisburseToken(randomWords, requestId);
    }

    /// @notice This selects the winners and disburse the ERC20 Token GPT 
    /// @param _randomWords gotten from our chainlink VRF
    /// @param _requestId the requestId return from the vrfCoordinator 
    function selectWinnerAndDisburseToken(uint256[] memory _randomWords, uint256 _requestId) internal {
        uint256 _maxWinners;
        uint256 _activityId = s_pickingWinnerActivityId[_requestId];

        if(s_activities[_activityId]._maxWinners <= s_submittedAddresses[_activityId].length){
            _maxWinners = s_activities[_activityId]._maxWinners;
        }else{
            _maxWinners = s_submittedAddresses[_activityId].length;
        }
        uint256 _price = (s_activities[_activityId]._prizePool / _maxWinners);

        for(uint256 i = 0; i < _maxWinners; i++){
            uint256 indexOfWinner = _randomWords[0] % (s_submittedAddresses[_activityId].length - i);
            address winner = s_submittedAddresses[_activityId][indexOfWinner];
            s_activities[_activityId]._winners.push(winner);
            s_token.transfer(winner, _price);
            emit WinnerPicked(winner, _activityId);
        }
        s_activities[_activityId]._status = ActivityStatus.CLOSED;
    }

}