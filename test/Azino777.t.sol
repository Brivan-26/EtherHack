// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Azino777.sol";

contract Azino777Test is Test {
    Azino777 public azino;
    AzzinoHack public hack;

    function setUp() public {
        azino = new Azino777();
        hack = new AzzinoHack(payable(address(azino)));
    }

    function testHack() public {
        // send some ether to azino
        deal(address(azino), 100 ether);
        // send initial eth to pass require condition on calling spin()
        deal(address(hack), 0.02 ether);
        console.log("Attack contract balance before the attack: ", address(hack).balance / 1e18);
        hack.attack();
        assertGt(address(hack).balance, 100 ether);
        console.log("Attack contract balance after the attack: ", address(hack).balance / 1e18);
    }
}
