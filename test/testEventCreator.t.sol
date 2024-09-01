// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {EventCreator} from "src/EventCreator.sol";

contract TestEventCreator is Test {
    EventCreator eventCreator;

    address public alice = vm.addr(0x1);
    address public bob = vm.addr(0x2);
    address public eventOwner = vm.addr(0x3);

    uint16 public constant MIMUM_TICKETS = 2;

    function setUp() public {
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(eventOwner, 100 ether);

        eventCreator = new EventCreator();
    }

    function test_createEvent() public {
        createEventStruct(
            "Rock Concert",
            "Rock concert with the best rock bands",
            "Rock Arena",
            100,
            100,
            eventOwner
        );

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        EventCreator.EventDescription memory descr = newEvent.eventDescription;
        EventCreator.Attendee[] memory attendees = newEvent.attendees;

        assertEq(descr.eventName, "Rock Concert");
        assertEq(
            descr.eventDescription,
            "Rock concert with the best rock bands"
        );
        assertEq(descr.eventLocation, "Rock Arena");
        assertEq(descr.ticketPrice, 100);
        assertEq(descr.totalTickets, 100);
        assertEq(newEvent.owner, eventOwner);
        assertEq(newEvent.ticketsSold, 0);
        assertEq(attendees.length, 0);
    }

    function test_buyTicket() public {
        createEventStruct(
            "Rock Concert",
            "Rock concert with the best rock bands",
            "Rock Arena",
            100,
            100,
            eventOwner
        );

        vm.prank(alice);
        eventCreator.buyTicket{value: 200}(1, 2);

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        EventCreator.Attendee[] memory attendees = newEvent.attendees;

        assertEq(newEvent.owner, eventOwner);
        assertEq(newEvent.ticketsSold, 2);
        assertEq(attendees.length, 1);
        assertEq(attendees[0].attendeeAddress, alice);
        assertEq(attendees[0].ticketCount, 2);
    }

    /////////////// Helper functions ///////////////

    function createEventStruct(
        string memory name,
        string memory desc,
        string memory location,
        uint256 price,
        uint16 totalTickets,
        address prankster
    ) public {
        EventCreator.EventDescription memory eventDescription = EventCreator
            .EventDescription({
                eventName: name,
                eventDescription: desc,
                eventLocation: location,
                ticketPrice: price,
                totalTickets: totalTickets
            });
        vm.prank(prankster);
        eventCreator.createEvent(eventDescription, 4 weeks, MIMUM_TICKETS);
    }
}
