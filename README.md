# School assignment in solidity --> Carl Klöfverskjöld
## EventCreator contract
The `EventCreator` contract is a Solidity contract that allows users to create, manage, and participate in events. It's designed to handle events with a maximum of 65,000 tickets.

## Key Features

1. **Event Creation**: Users can create an event by providing details such as the event name, description, location, ticket price, total tickets, deadline, and minimum tickets required for the event to take place.

2. **Ticket Purchase**: Users can buy tickets for an event. The contract ensures that the event is open, has not ended, and has enough tickets available. It also checks that the user has sufficient funds and has sent enough Ether to cover the cost of the tickets.

3. **Event Management**: The owner of an event can pause, resume, or cancel the event. If an event is cancelled, all attendees are refunded.

4. **Withdraw Funds**: The owner of an event can withdraw the funds collected from ticket sales. This can be done either at the end of the event or at the halfway point if the minimum number of tickets has been sold.

5. **Fallback Function**: The contract includes a fallback function that reverts any transactions that don't match the available functions, preventing Ether from being sent to the contract without a function call.

### Requirment for VG:
[x] A constructor
[x] Atleast: 1 custom error, one require, one assert, one revert, event, and modifier
[x] Have a falback function
[x] Identify and implement atleast three gasoptimzing solution with an explaination.
[ ] Distrubute and verify the contract on etherscan. And provide a link 
[ ] Atleast test coverage of 90%
