// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/CallMeMaybe.sol";

contract CallMeMaybeTest is Test {
    CallMeMaybe public target;
    CallMeMaybeHack public hack;

    function setUp() public {
        target = new CallMeMaybe();
        // send some ether to both contracts
        deal(address(target), 100 ether);
    }

    function testHack() public {
        console.log("Attack contract balance before the attack: ", address(hack).balance / 1e18);
        hack = new CallMeMaybeHack(payable(address(target)));
        assertEq(address(hack).balance, 100 ether);
        console.log("Attack contract balance after the attack: ", address(hack).balance / 1e18);
    }
}
