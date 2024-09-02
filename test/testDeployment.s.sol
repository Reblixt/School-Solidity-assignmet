// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {DeployEventCreator} from "script/DeployEventCreator.s.sol";

contract testDeployEventCreator is Test {
    DeployEventCreator deployEventCreator;

    function setUp() public {
        deployEventCreator = new DeployEventCreator();
    }

    function testDeployIsAnAddress() public {
        deployEventCreator.run();
        assert(address(deployEventCreator) != address(0));
    }
}
