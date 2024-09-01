// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {EventCreator} from "src/EventCreator.sol";

contract TestEventCreator is Test {
    EventCreator eventCreator;

    address public alice = vm.addr(0x1);
    address public bob = vm.addr(0x2);
    address public charlie = vm.addr(0x3);
    address public david = vm.addr(0x4);
    address public eve = vm.addr(0x5);
    address public eventOwner = vm.addr(0x10);

    uint256 public constant INITIAL_BALANCE = 100 ether;
    uint16 public constant MIMUM_TICKETS = 2;
    uint256 public constant TICKET_PRICE = 100;

    function setUp() public {
        vm.deal(alice, INITIAL_BALANCE);
        vm.deal(bob, INITIAL_BALANCE);
        vm.deal(eventOwner, INITIAL_BALANCE);
        vm.deal(charlie, INITIAL_BALANCE);
        vm.deal(david, INITIAL_BALANCE);
        vm.deal(eve, INITIAL_BALANCE);

        eventCreator = new EventCreator();
    }

    //////// Test for successful execution ////////
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
            TICKET_PRICE,
            300,
            eventOwner
        );

        vm.prank(alice);
        eventCreator.buyTicket{value: 200}(1, 2);

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        EventCreator.Attendee[] memory attendees = newEvent.attendees;

        assertEq(newEvent.owner, eventOwner);
        assertEq(newEvent.ticketsSold, 2);
        assertEq(attendees.length, 1);
        assertEq(attendees.length, newEvent.attendeeCount);
        assertEq(attendees[0].attendeeAddress, alice);
        assertEq(attendees[0].ticketCount, 2);
        assertEq(eventCreator.getEventBalance(1), 200);
    }

    function test_MultipleAtendees() public {
        createEventStruct(
            "Rock Concert",
            "Rock concert with the best rock bands",
            "Rock Arena",
            TICKET_PRICE,
            20,
            eventOwner
        );
        // 4 attendees buy 2 tickets each
        createMultiplePurchase(1, 2);

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        EventCreator.Attendee[] memory attendees = newEvent.attendees;
        assertEq(attendees.length, 4);
        assertEq(attendees[0].attendeeAddress, bob);
        assertEq(attendees[1].attendeeAddress, alice);
        assertEq(attendees[2].attendeeAddress, charlie);
        assertEq(attendees[3].attendeeAddress, david);
    }

    function test_Withdraw() public {
        createEventStruct(
            "Rock Concert",
            "Rock concert with the best rock bands",
            "Rock Arena",
            TICKET_PRICE,
            20,
            eventOwner
        );
        createMultiplePurchase(1, 2);

        vm.warp(6 weeks);
        vm.prank(eventOwner);
        eventCreator.withdraw(1);

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        assertEq(eventCreator.getEventBalance(1), 0);

        assert(newEvent.status == EventCreator.EventStatus.ENDED);
    }

    function test_HalfTimeWithdraw() public {
        createEventStruct(
            "Rock Concert",
            "Rock concert with the best rock bands",
            "Rock Arena",
            TICKET_PRICE,
            20,
            eventOwner
        );
        createMultiplePurchase(1, 2);

        vm.warp(3 weeks);
        vm.prank(eventOwner);
        eventCreator.halfTimeWithdraw(1);

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        assertEq(eventCreator.getEventBalance(1), 0);
        assertEq(newEvent.owner.balance, 800 + INITIAL_BALANCE);
        assert(newEvent.status == EventCreator.EventStatus.OPEN);
    }

    /////// Test for revert ///////
    function test_RevertWhenNoMoreTicketIsAvailable() public {
        createEventStruct(
            "Rock Concert",
            "Rock concert with the best rock bands",
            "Rock Arena",
            TICKET_PRICE,
            2,
            eventOwner
        );
        vm.prank(alice);
        eventCreator.buyTicket{value: 200}(1, 2);

        vm.expectRevert(
            EventCreator.EventCreator__NotEnoughTicketsAvailable.selector
        );
        vm.prank(bob);
        eventCreator.buyTicket{value: 200}(1, 2);
    }

    /////// Test for States ///////
    function test_StateIsOpen() public {
        createEventStruct(
            "Rock Concert",
            "Rock concert with the best rock bands",
            "Rock Arena",
            TICKET_PRICE,
            20,
            eventOwner
        );

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        assert(newEvent.status == EventCreator.EventStatus.OPEN);
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

    function createMultiplePurchase(
        uint256 eventId,
        uint16 ticketCount
    ) public {
        vm.prank(bob);
        eventCreator.buyTicket{value: ticketCount * 100}(eventId, ticketCount);
        vm.prank(alice);
        eventCreator.buyTicket{value: ticketCount * 100}(eventId, ticketCount);
        vm.prank(charlie);
        eventCreator.buyTicket{value: ticketCount * 100}(eventId, ticketCount);
        vm.prank(david);
        eventCreator.buyTicket{value: ticketCount * 100}(eventId, ticketCount);
    }
}
