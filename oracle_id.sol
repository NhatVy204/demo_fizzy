// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FlightOracle {
    address public owner;
    mapping(string => uint256) public flightDelays;

    constructor() {
        owner = msg.sender;
    }

    function updateFlightStatus(string memory flightNumber, uint256 delayInMinutes) external {
        require(msg.sender == owner, "Only owner can update");
        flightDelays[flightNumber] = delayInMinutes;
    }

    function getFlightStatus(string memory flightNumber) external view returns (uint256) {
        return flightDelays[flightNumber];
    }
}