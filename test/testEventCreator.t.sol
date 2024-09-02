// SPDX-License-Identifier: MIT

// This test suite i have devided into 3 parts:
// 1. Test for successful execution
// 2. Test for revert
// 3. Test for states
//
// And at the butten there is pair of helper functions that are used in the test functions

pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {EventCreator} from "src/EventCreator.sol";

contract TestEventCreator is Test {
    EventCreator eventCreator;

    // Fake addresses
    address public alice = vm.addr(0x1);
    address public bob = vm.addr(0x2);
    address public charlie = vm.addr(0x3);
    address public david = vm.addr(0x4);
    address public eve = vm.addr(0x5);
    address public poorFrank = vm.addr(0x6);
    address public eventOwner = vm.addr(0x10);

    // Constants
    uint256 public constant INITIAL_BALANCE = 100 ether;
    uint16 public constant MIMUM_TICKETS = 2;
    uint256 public constant TICKET_PRICE = 100;

    // This function is called before each test function like beforeEach in mocha
    function setUp() public {
        vm.deal(alice, INITIAL_BALANCE);
        vm.deal(bob, INITIAL_BALANCE);
        vm.deal(eventOwner, INITIAL_BALANCE);
        vm.deal(charlie, INITIAL_BALANCE);
        vm.deal(david, INITIAL_BALANCE);
        vm.deal(eve, INITIAL_BALANCE);

        eventCreator = new EventCreator();
        createEventStruct(
            "Rock Concert",
            "Rock concert with the best rock bands",
            "Rock Arena",
            TICKET_PRICE,
            20,
            eventOwner
        );
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

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(2);
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
        createMultiplePurchase(1, 2);

        vm.warp(6 weeks);
        vm.prank(eventOwner);
        eventCreator.withdraw(1);

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        assertEq(eventCreator.getEventBalance(1), 0);

        assert(newEvent.status == EventCreator.EventStatus.ENDED);
    }

    function test_HalfTimeWithdraw() public {
        createMultiplePurchase(1, 2);

        vm.warp(3 weeks);
        vm.prank(eventOwner);
        eventCreator.halfTimeWithdraw(1);

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        assertEq(eventCreator.getEventBalance(1), 0);
        assertEq(newEvent.owner.balance, 800 + INITIAL_BALANCE);
        assert(newEvent.status == EventCreator.EventStatus.OPEN);
    }

    function test_RefundUserWhenEventCanceled() public {
        createMultiplePurchase(1, 2);

        vm.prank(eventOwner);
        eventCreator.cancelEvent(1);

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        EventCreator.Attendee[] memory attendees = newEvent.attendees;

        // assertEq(attendees.length, 0);
        assertEq(eventCreator.getEventBalance(1), 0);
        // bob, alice, charlie
        assertEq(attendees[0].attendeeAddress.balance, INITIAL_BALANCE);
        assertEq(attendees[1].attendeeAddress.balance, INITIAL_BALANCE);
        assertEq(attendees[2].attendeeAddress.balance, INITIAL_BALANCE);
        assert(newEvent.status == EventCreator.EventStatus.ENDED);
    }

    function test_RefundExeciveValueInput() public {
        vm.prank(alice);
        eventCreator.buyTicket{value: 600}(1, 2);
        assertEq(eventCreator.getEventBalance(1), 200);
        assertEq(alice.balance, INITIAL_BALANCE - 200);
    }

    /////// Test for revert ///////
    function test_RevertWhenNoMoreTicketIsAvailable() public {
        createEventStruct(
            "New Rock Concert",
            "Rock concert with the best rock bands",
            "Rock Arena",
            TICKET_PRICE,
            2,
            eventOwner
        );

        vm.prank(alice);
        eventCreator.buyTicket{value: 200}(2, 2);

        vm.expectRevert(
            EventCreator.EventCreator__NotEnoughTicketsAvailable.selector
        );
        vm.prank(bob);
        eventCreator.buyTicket{value: 200}(2, 2);
    }

    function test_RevertWhenTheValueIsNotEnough() public {
        vm.expectRevert(EventCreator.EventCreator__NotEnoughEthValue.selector);
        vm.prank(alice);
        eventCreator.buyTicket{value: 50}(1, 2);
    }

    function test_RevertWhenZeroTicketsArePurchased() public {
        vm.expectRevert(
            EventCreator.EventCreator__MustBuyAtLeastOneTicket.selector
        );
        vm.prank(alice);
        eventCreator.buyTicket{value: 100}(1, 0);
    }

    function test_RevertWhenTheBuyerHaveNotEnoughBalance() public {
        vm.expectRevert();
        vm.prank(poorFrank);
        eventCreator.buyTicket{value: 200}(1, 2);
    }

    function test_RevertWhenDeadlineHasPassed() public {
        vm.warp(5 weeks);
        vm.expectRevert(
            EventCreator.EventCreator__EventHasAlreadyEnded.selector
        );
        vm.prank(alice);
        eventCreator.buyTicket{value: 200}(1, 2);
    }

    function test_RevertWhenDeadlineHasNotPassedInWitdraw() public {
        createMultiplePurchase(1, 2);

        vm.warp(3 weeks);
        vm.expectRevert(
            EventCreator.EventCreator__BeforeEventDeadline.selector
        );
        vm.prank(eventOwner);
        eventCreator.withdraw(1);
    }

    function test_ReventWhenEventIsPaused() public {
        vm.prank(eventOwner);
        eventCreator.pauseEvent(1);

        vm.expectRevert(EventCreator.EventCreator__EventIsNotOpen.selector);
        vm.prank(alice);
        eventCreator.buyTicket{value: 200}(1, 2);
    }

    function test_ReventWhenNotEventOwner() public {
        vm.expectRevert(EventCreator.EventCreator__NotEventOwner.selector);
        vm.prank(alice);
        eventCreator.pauseEvent(1);
    }

    function test_RevertgetAttendeeOfAnEventTicketCountWhenWrongName() public {
        createMultiplePurchase(1, 2);

        vm.expectRevert();
        eventCreator.getAttendeeOfAnEventTicketCount("Rock", bob);
    }

    function test_RevertFallBack() public {
        vm.expectRevert(
            EventCreator.EventCreator__ChoosedAInvalidOption.selector
        );
        vm.prank(alice);
        (bool failed, ) = address(eventCreator).call{value: 1 ether}("");
        assertEq(address(eventCreator).balance, 0);
        assertFalse(failed);
    }

    function test_RevertWhenCreateEventMoreThanMaxTickets() public {
        vm.expectRevert();
        createEventStruct(
            "Rock Concert",
            "Rock concert with the best rock bands",
            "Rock Arena",
            TICKET_PRICE,
            65400,
            eventOwner
        );
    }

    function test_RevertWhenDeadlineIsinThePast() public {
        vm.expectRevert();
        EventCreator.EventDescription memory eventDescription = EventCreator
            .EventDescription({
                eventName: "Revert Event",
                eventDescription: "Revert Event",
                eventLocation: "Revert Event",
                ticketPrice: 100,
                totalTickets: 100
            });
        vm.prank(alice);
        vm.warp(5 weeks);
        eventCreator.createEvent(eventDescription, 2, MIMUM_TICKETS);
    }

    function test_RevertWhenNotEnoughTicketsSoldOnWithdrawHalftime() public {
        vm.prank(alice);
        eventCreator.buyTicket{value: 200}(1, 1);
        vm.warp(3 weeks);
        vm.expectRevert(
            EventCreator.EventCreator__NotEnoughTicketsSold.selector
        );
        vm.prank(eventOwner);
        eventCreator.halfTimeWithdraw(1);
    }

    function test_RevertHalftimeWithdrawWhenHalfDeadlineHasNotPassed() public {
        vm.expectRevert(
            EventCreator.EventCreator__BeforeEventDeadline.selector
        );
        vm.prank(eventOwner);
        eventCreator.halfTimeWithdraw(1);
    }

    /////// Test for States ///////
    function test_StateIsOpen() public view {
        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        assert(newEvent.status == EventCreator.EventStatus.OPEN);
    }

    function test_StateIsPaused() public {
        vm.prank(eventOwner);
        eventCreator.pauseEvent(1);

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        assert(newEvent.status == EventCreator.EventStatus.PAUSED);
    }

    function test_StateIsEnded() public {
        createMultiplePurchase(1, 2);

        vm.warp(6 weeks);
        vm.prank(eventOwner);
        eventCreator.withdraw(1);

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        assert(newEvent.status == EventCreator.EventStatus.ENDED);
    }

    function test_StateIsEndedWhenCancelEventIsCalled() public {
        vm.prank(eventOwner);
        eventCreator.cancelEvent(1);

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        assert(newEvent.status == EventCreator.EventStatus.ENDED);
    }

    function test_StateIsOpenAfterResume() public {
        vm.prank(eventOwner);
        eventCreator.pauseEvent(1);

        EventCreator.EventInfo memory newEvent = eventCreator.getEvent(1);
        assert(newEvent.status == EventCreator.EventStatus.PAUSED);

        vm.prank(eventOwner);
        eventCreator.resumeEvent(1);

        newEvent = eventCreator.getEvent(1);
        assert(newEvent.status == EventCreator.EventStatus.OPEN);
    }

    function test_getAttendeeOfAnEventTicketCount() public {
        createMultiplePurchase(1, 2);

        uint16 ticketCount = eventCreator.getAttendeeOfAnEventTicketCount(
            "Rock Concert",
            bob
        );
        assertEq(ticketCount, 2);
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
