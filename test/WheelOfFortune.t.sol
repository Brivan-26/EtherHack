// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/WheelOfFortune.sol";

contract WheelOfFortuneTest is Test {
    WheelOfFortune public target;
    WheelOfFortuneHack public hack;
    function setUp() public {
        target = new WheelOfFortune();
        hack = new WheelOfFortuneHack(payable(address(target)));   
        // send some ether to both contracts
        deal(address(target), 100 ether);
    }
    
    function testHack() public {
        console.log("Attack contract balance before the attack: ", address(hack).balance /1e18);
        hack.attack{value: 0.02 ether}();
        assertGt(address(hack).balance, 100 ether);
        console.log("Attack contract balance after the attack: ", address(hack).balance / 1e18);
    }
}
