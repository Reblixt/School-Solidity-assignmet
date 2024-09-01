// SPDX-License-Identifier: MIT

//     Pragma statements/
//     Import statements
//     Interfaces
//     Libraries
//     Contracts
//
// Inside each contract, library or interface, use the following order:
//     Type declarations
//     State variables
//     Events
//     Errors
//     Modifiers
//     Constructor
//     External Functions
//     Public Functions
//     getter functions
//     Internal Functions
//     Receive and fallback function
pragma solidity ^0.8.26;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract EventCreator is ReentrancyGuard {
    // This is contract for an event with max 65 000 tickets
    //////////// Type declarations //////////////
    struct EventDescription {
        string eventName;
        string eventDescription;
        string eventLocation;
        uint256 ticketPrice;
        uint16 totalTickets;
    }

    struct Attendee {
        address attendeeAddress;
        uint16 ticketCount;
    }

    struct EventInfo {
        EventDescription eventDescription;
        address owner;
        uint16 ticketsSold;
        uint16 minimumTickets;
        uint16 attendeeCount;
        uint256 deadline;
        EventStatus status;
        Attendee[] attendees;
    }

    enum EventStatus {
        OPEN,
        PAUSED,
        ENDED
    }

    //////////// State variables //////////////
    uint256 public eventId;
    uint256 public eventBalance;

    mapping(uint256 => uint256) private eventBalances;
    mapping(uint256 => EventInfo) private events;
    mapping(string => mapping(address => Attendee)) private eventAttendees;

    //////////// Events //////////////
    event EventCreated(
        string eventName,
        string eventDescription,
        string eventLocation,
        uint256 ticketPrice,
        uint16 totalTickets,
        address eventOwner
    );
    event eventStatus(uint256 eventId, EventStatus status);
    event AttendeeRegistered(
        string eventName,
        address attendeeAddress,
        uint16 ticketCount
    );
    event AttendeeRefunded(
        string eventName,
        address attendeeAddress,
        uint16 ticketCount
    );
    event EventOwnerWithdraw(uint256 eventId, uint256 balance);

    //////////// Errors //////////////
    error EventCreator__choosedAInvalidOption();
    error EventCreator__EventHasAlreadyEnded();
    error EventCreator__EventDoesNotExist();
    error EventCreator__NotEventOwner();
    error EventCreator__BeforeEventDeadline();
    error EventCreator__MustBuyAtLeastOneTicket();
    error EventCreator__NotEnoughTicketsAvailable();
    error EventCreator__HaveInsufficientFunds();
    error EventCreator__NotEnoughEthValue();
    error EventCreator__EventIsNotOpen();
    error EventCreator__NotEnoughTicketsSold();

    //////////// Modifiers //////////////
    modifier onlyEventOwner(uint256 id) {
        if (msg.sender != events[id].owner)
            revert EventCreator__NotEventOwner();
        _;
    }

    //TODO: Add chainspecific varibles
    //TODO: Create a modifier that gives each owner the ability to pause, resume and cancel their event

    constructor() {}

    //////////// External functions //////////////
    /*
     *@dev Create an event with the following parameters
     *@param newEvent - EventDescription struct that contains the event details
     *@param deadline - The deadline for the event
     *@param minimumTickets - The minimum number of tickets that must be sold for the event to take place
     * */
    function createEvent(
        EventDescription memory newEvent,
        uint256 deadline,
        uint16 minimumTickets
    ) external {
        require(
            newEvent.totalTickets <= 65000,
            "Total tickets cannot exceed 65,000"
        );
        require(deadline > block.timestamp, "Deadline must be in the future");
        ++eventId;
        EventInfo storage eventInfo = events[eventId];
        eventInfo.eventDescription = newEvent;
        eventInfo.owner = msg.sender;
        eventInfo.ticketsSold = 0;
        eventInfo.deadline = deadline;
        eventInfo.minimumTickets = minimumTickets;
        eventInfo.status = EventStatus.OPEN;
        events[eventId] = eventInfo;
        emit EventCreated(
            newEvent.eventName,
            newEvent.eventDescription,
            newEvent.eventLocation,
            newEvent.ticketPrice,
            newEvent.totalTickets,
            msg.sender
        );
    }

    //TODO: Consider to add Chainlink priceFeed to get the price of the ticket in SEK
    function buyTicket(
        uint256 id,
        uint16 ticketCount
    ) external payable nonReentrant {
        (EventInfo storage eventInfo, uint256 totalCost) = _checkPermissions(
            ticketCount,
            id
        );
        // Register the attendee
        //TODO: Check if this sturct need to be refactored
        Attendee storage attendee = eventAttendees[
            eventInfo.eventDescription.eventName
        ][msg.sender];
        if (attendee.attendeeAddress == address(0)) {
            attendee.attendeeAddress = msg.sender;
            attendee.ticketCount = ticketCount;
            eventInfo.attendees.push(attendee);
        }
        ++eventInfo.attendeeCount;
        eventInfo.ticketsSold += ticketCount;
        eventBalances[id] += totalCost;

        // Refund any excess payment
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

        emit AttendeeRegistered(
            eventInfo.eventDescription.eventName,
            msg.sender,
            ticketCount
        );
    }

    function withdraw(uint256 id) external nonReentrant onlyEventOwner(id) {
        EventInfo storage eventInfo = events[id];

        if (block.timestamp <= eventInfo.deadline)
            revert EventCreator__BeforeEventDeadline();

        uint256 balance = eventBalances[id];
        eventBalances[id] = 0;
        eventInfo.status = EventStatus.ENDED;
        payable(msg.sender).transfer(balance);

        emit EventOwnerWithdraw(id, balance);
    }

    function halfTimeWithdraw(
        uint256 id
    ) external nonReentrant onlyEventOwner(id) {
        EventInfo storage eventInfo = events[id];

        uint256 halfTime = eventInfo.deadline - (eventInfo.deadline / 2);

        if (block.timestamp <= halfTime)
            revert EventCreator__BeforeEventDeadline();
        if (eventInfo.ticketsSold < eventInfo.minimumTickets)
            revert EventCreator__NotEnoughTicketsSold();

        uint256 balance = eventBalances[id];
        eventBalances[id] = 0;
        payable(msg.sender).transfer(balance);

        emit EventOwnerWithdraw(id, balance);
    }

    function pauseEvent(uint256 id) external onlyEventOwner(id) {
        EventInfo storage eventInfo = events[id];
        eventInfo.status = EventStatus.PAUSED;

        emit eventStatus(id, eventInfo.status);
    }

    function resumeEvent(uint256 id) external onlyEventOwner(id) {
        EventInfo storage eventInfo = events[id];
        eventInfo.status = EventStatus.OPEN;

        emit eventStatus(id, eventInfo.status);
    }

    function cancelEvent(uint256 id) external onlyEventOwner(id) {
        EventInfo storage eventInfo = events[id];
        eventInfo.status = EventStatus.ENDED;

        _refundEveryoneOfEvent(id);

        emit eventStatus(id, eventInfo.status);
    }

    /////////// Getter functions /////////////

    function getEvent(uint256 id) external view returns (EventInfo memory) {
        return events[id];
    }

    function getAttendeeOfAnEventTicketCount(
        string memory eventName,
        address addressOfAttendee
    ) external view returns (uint16) {
        return eventAttendees[eventName][addressOfAttendee].ticketCount;
    }

    function getEventBalance(uint256 id) external view returns (uint256) {
        return eventBalances[id];
    }

    /////////////// Internal functions ///////////////

    function _refundEveryoneOfEvent(uint256 id) internal {
        EventInfo storage eventInfo = events[id];
        for (uint256 i = 0; i < eventInfo.attendees.length; ++i) {
            Attendee storage attendee = eventInfo.attendees[i];
            payable(attendee.attendeeAddress).transfer(
                attendee.ticketCount * eventInfo.eventDescription.ticketPrice
            );

            emit AttendeeRefunded(
                eventInfo.eventDescription.eventName,
                attendee.attendeeAddress,
                attendee.ticketCount
            );
        }
    }

    function _checkPermissions(
        uint256 ticketCount,
        uint256 id
    ) internal view returns (EventInfo storage, uint256) {
        EventInfo storage eventInfo = events[id];
        if (eventInfo.status != EventStatus.OPEN)
            revert EventCreator__EventIsNotOpen();

        if (block.timestamp > eventInfo.deadline)
            revert EventCreator__EventHasAlreadyEnded();

        if (ticketCount <= 0) revert EventCreator__MustBuyAtLeastOneTicket();

        if (
            eventInfo.ticketsSold + ticketCount >
            eventInfo.eventDescription.totalTickets
        ) revert EventCreator__NotEnoughTicketsAvailable();
        uint256 totalCost = eventInfo.eventDescription.ticketPrice *
            ticketCount;

        if (msg.sender.balance < totalCost)
            revert EventCreator__HaveInsufficientFunds();

        if (msg.value < totalCost) revert EventCreator__NotEnoughEthValue();
        return (eventInfo, totalCost);
    }

    //////////// Receive and fallback function //////////////

    fallback() external {
        revert EventCreator__choosedAInvalidOption();
    }
}
