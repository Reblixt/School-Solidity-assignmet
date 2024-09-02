// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {EventCreator} from "src/EventCreator.sol";

contract DeployEventCreator is Script {
    EventCreator public eventCreator;

    // string public publicKey = vm.envUint("PUBLIC_KEY");

    function run() public {
        vm.startBroadcast();
        eventCreator = new EventCreator();
        vm.stopBroadcast();
        console2.log("Deployed EventCreator at:", address(eventCreator));
    }
}
