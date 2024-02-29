// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// errors
error GrandPrize__AlreadyAParticipant();

/// @title Grand Prize
/// @author Favour Aniogor
/// @notice This is responsible for selecting random winners and dissing out airdrop
/// @dev This uses chainlink VRF to generate random numbers and select winners
contract GrandPrize {
    mapping(address => bool) private s_isParticipant;

    /// @notice This allows user to register as Participant in the GrandPrize system
    /// @dev This uses the s_isParticipant variable to carefully map new participants. 
    function registerAsParticipant() external {
        if(s_isParticipant[msg.sender]){
            revert GrandPrize__AlreadyAParticipant();
        }
        s_isParticipant[msg.sender] = true;
    }

}