// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Betting {
    address internal admin;

    struct propose {
        address proposeMaker;
        bytes32 proposeHashMaker;
        address proposeTaker;
        uint256 proposeNumTaker;
        uint256 betValue;
        bool isAccept;
    }

    mapping(string => propose) public proposeList; //proposeName => propose

    event NEW_PROPOSE(string, address); //proposeName, maker
    event TAKE_PROPOSE(string, address); //proposeName, taker
    event REVEAL(string, address); //proposeName, winner

    constructor() {
        admin = msg.sender;
    }

    /**
     * 发出一个bet请求
     */
    function makePropose(string calldata _proposeName, bytes32 _proposeHash)
        external
        payable
    {
        propose storage proposeInstance = proposeList[_proposeName];
        require(proposeInstance.betValue == 0, "proposeName already exists");
        require(msg.value > 0, "bet must > 0");

        proposeInstance.proposeMaker = msg.sender;
        proposeInstance.proposeHashMaker = _proposeHash;
        proposeInstance.betValue = msg.value;

        emit NEW_PROPOSE(_proposeName, msg.sender);
    }

    /**
     * 接受一个bet
     */
    function takePropose(string calldata _proposeName, uint256 _proposeNum)
        external
        payable
    {
        propose storage proposeInstance = proposeList[_proposeName];
        require(proposeInstance.betValue > 0, "propose not found");
        require(!proposeInstance.isAccept, "propose is already accept");
        require(msg.value >= proposeInstance.betValue, "not enough bet value");

        proposeInstance.proposeNumTaker = _proposeNum;
        proposeInstance.isAccept = true;
        proposeInstance.betValue += msg.value;
        proposeInstance.proposeTaker = msg.sender;

        emit TAKE_PROPOSE(_proposeName, msg.sender);
    }

    /**
     * 揭晓赌局
     */
    function reveal(string calldata _proposeName, uint256 _proposeNumA)
        external
    {
        propose storage proposeInstance = proposeList[_proposeName];
        require(proposeInstance.proposeMaker == msg.sender, "not proposer");
        require(proposeInstance.isAccept, "propose not accepted");

        //验证
        require(
            proposeInstance.proposeHashMaker ==
                keccak256(abi.encodePacked(_proposeNumA)),
            "proposeNum and hash not match"
        );

        uint256 sub;
        if (_proposeNumA >= proposeInstance.proposeNumTaker) {
            sub = _proposeNumA - proposeInstance.proposeNumTaker;
        } else {
            sub = proposeInstance.proposeNumTaker - _proposeNumA;
        }

        if (sub % 2 == 0) {
            payable(proposeInstance.proposeMaker).transfer(
                proposeInstance.betValue
            );
            emit REVEAL(_proposeName, proposeInstance.proposeMaker);
        } else {
            payable(proposeInstance.proposeTaker).transfer(
                proposeInstance.betValue
            );
            emit REVEAL(_proposeName, proposeInstance.proposeTaker);
        }

        delete proposeList[_proposeName];
    }

    /**
     * 计算num hash
     */
    function getNumHash(uint256 _num) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_num));
    }
}
