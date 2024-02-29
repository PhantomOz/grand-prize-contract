// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// errors
error GrandPrize__AlreadyAParticipant();

/// @title Grand Prize
/// @author Favour Aniogor
/// @notice This is responsible for selecting random winners and dissing out airdrop
/// @dev This uses chainlink VRF to generate random numbers and select winners
contract GrandPrize {
    uint256 public s_totalParticipants;
    mapping(address => bool) private s_isParticipant;

    /// @notice This the datatype for activity type
    enum ActivityType {
        Game;
        Content;
    }
    
    /// @notice This is the data structure for the activities
    struct Activity {
        string _task;
        uint256 _entryFee;
        uint256 _prizePool;
        uint256 _gameValue;
        ActivityType _activityType;
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

}