Compiling 29 files with Solc 0.8.26
Solc 0.8.26 finished in 1.80s
Compiler run successful!
Analysing contracts...
Running tests...

Ran 1 test for test/testDeployment.s.sol:testDeployEventCreator
[PASS] testDeployIsAnAddress() (gas: 2580756)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 5.38ms (1.21ms CPU time)

Ran 27 tests for test/testEventCreator.t.sol:TestEventCreator
[PASS] test_HalfTimeWithdraw() (gas: 355738)
[PASS] test_MultipleAtendees() (gas: 358811)
[PASS] test_RefundExeciveValueInput() (gas: 142571)
[PASS] test_RefundUserWhenEventCanceled() (gas: 413006)
[PASS] test_ReventWhenEventIsPaused() (gas: 54420)
[PASS] test_ReventWhenNotEventOwner() (gas: 13898)
[PASS] test_RevertFallBack() (gas: 19310)
[PASS] test_RevertHalftimeWithdrawWhenHalfDeadlineHasNotPassed() (gas: 21771)
[PASS] test_RevertWhenCreateEventMoreThanMaxTickets() (gas: 17146)
[PASS] test_RevertWhenDeadlineHasNotPassedInWitdraw() (gas: 333257)
[PASS] test_RevertWhenDeadlineHasPassed() (gas: 28936)
[PASS] test_RevertWhenDeadlineIsinThePast() (gas: 17622)
[PASS] test_RevertWhenNoMoreTicketIsAvailable() (gas: 361936)
[PASS] test_RevertWhenNotEnoughTicketsSoldOnWithdrawHalftime() (gas: 148705)
[PASS] test_RevertWhenTheBuyerHaveNotEnoughBalance() (gas: 18068)
[PASS] test_RevertWhenTheValueIsNotEnough() (gas: 35261)
[PASS] test_RevertWhenZeroTicketsArePurchased() (gas: 28316)
[PASS] test_RevertgetAttendeeOfAnEventTicketCountWhenWrongName() (gas: 330742)
[PASS] test_StateIsEnded() (gas: 371722)
[PASS] test_StateIsEndedWhenCancelEventIsCalled() (gas: 72639)
[PASS] test_StateIsOpen() (gas: 41348)
[PASS] test_StateIsOpenAfterResume() (gas: 69222)
[PASS] test_StateIsPaused() (gas: 70107)
[PASS] test_Withdraw() (gas: 374140)
[PASS] test_buyTicket() (gas: 165265)
[PASS] test_createEvent() (gas: 260549)
[PASS] test_getAttendeeOfAnEventTicketCount() (gas: 329312)
Suite result: ok. 27 passed; 0 failed; 0 skipped; finished in 146.89ms (31.52ms CPU time)

Ran 2 test suites in 147.91ms (152.26ms CPU time): 28 tests passed, 0 failed, 0 skipped (28 total tests)
| File                            | % Lines        | % Statements   | % Branches     | % Funcs        |
|---------------------------------|----------------|----------------|----------------|----------------|
| script/DeployEventCreator.s.sol | 100.00% (4/4)  | 100.00% (4/4)  | 100.00% (0/0)  | 100.00% (1/1)  |
| src/EventCreator.sol            | 98.75% (79/80) | 98.88% (88/89) | 94.44% (17/18) | 93.33% (14/15) |
| Total                           | 98.81% (83/84) | 98.92% (92/93) | 94.44% (17/18) | 93.75% (15/16) |
