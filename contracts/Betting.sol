// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Betting {
    address internal admin;

    enum STATUS {
        WAIT_TO_START,
        WAIT_TO_ACCEPT,
        WAIT_TO_REVEAL,
        WAIT_TO_REVEAL_HALF,
        WAIT_TO_WITHDRAW
    }

    struct propose {
        address proposeMaker;
        bytes32 proposeHashMaker;
        uint256 proposeNumMaker;
        address proposeTaker;
        bytes32 proposeHashTaker;
        uint256 proposeNumTaker;
        uint256 betValue;
        address winner;
        STATUS status;
    }

    mapping(string => propose) public proposeList; //proposeName => propose

    event NEW_PROPOSE(string, address); //proposeName, maker
    event TAKE_PROPOSE(string, address); //proposeName, taker
    event REVEAL(string, string); //proposeName, maker/taker
    event GET_WINNER(string, address); //proposeName, winner
    event WINNER_WITHDRAW(string, address); //proposeName, winner

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
        proposeInstance.status = STATUS.WAIT_TO_ACCEPT;

        emit NEW_PROPOSE(_proposeName, msg.sender);
    }

    /**
     * 接受一个bet
     */
    function takePropose(string calldata _proposeName, bytes32 _proposeHash)
        external
        payable
    {
        propose storage proposeInstance = proposeList[_proposeName];
        require(proposeInstance.betValue > 0, "propose not found");
        require(
            proposeInstance.status == STATUS.WAIT_TO_ACCEPT,
            "propose is already accept"
        );
        require(msg.value >= proposeInstance.betValue, "not enough bet value");

        proposeInstance.proposeTaker = msg.sender;
        proposeInstance.proposeHashTaker = _proposeHash;
        proposeInstance.betValue += msg.value;
        proposeInstance.status = STATUS.WAIT_TO_REVEAL;

        emit TAKE_PROPOSE(_proposeName, msg.sender);
    }

    /**
     * maker 揭晓赌局
     */
    function makerReveal(string calldata _proposeName, uint256 _proposeNum)
        external
    {
        propose storage proposeInstance = proposeList[_proposeName];
        require(proposeInstance.proposeMaker == msg.sender, "not proposeMaker");
        require(
            proposeInstance.status == STATUS.WAIT_TO_REVEAL ||
                proposeInstance.status == STATUS.WAIT_TO_REVEAL_HALF,
            "propose not accepted"
        );

        //验证
        require(
            proposeInstance.proposeHashMaker ==
                keccak256(abi.encodePacked(_proposeNum)),
            "proposeNum and hash not match"
        );

        proposeInstance.proposeNumMaker = _proposeNum;

        if (proposeInstance.status == STATUS.WAIT_TO_REVEAL_HALF) {
            getWinner(_proposeName);
        }
        if (proposeInstance.status == STATUS.WAIT_TO_REVEAL) {
            proposeInstance.status = STATUS.WAIT_TO_REVEAL_HALF;
        }

        emit REVEAL(_proposeName, "MAKER");
    }

    /**
     * taker 揭晓赌局
     */
    function takerReveal(string calldata _proposeName, uint256 _proposeNum)
        external
    {
        propose storage proposeInstance = proposeList[_proposeName];
        require(proposeInstance.proposeTaker == msg.sender, "not proposeTaker");
        require(
            proposeInstance.status == STATUS.WAIT_TO_REVEAL ||
                proposeInstance.status == STATUS.WAIT_TO_REVEAL_HALF,
            "propose not accepted"
        );

        //验证
        require(
            proposeInstance.proposeHashTaker ==
                keccak256(abi.encodePacked(_proposeNum)),
            "proposeNum and hash not match"
        );

        proposeInstance.proposeNumTaker = _proposeNum;

        if (proposeInstance.status == STATUS.WAIT_TO_REVEAL_HALF) {
            getWinner(_proposeName);
        }
        if (proposeInstance.status == STATUS.WAIT_TO_REVEAL) {
            proposeInstance.status = STATUS.WAIT_TO_REVEAL_HALF;
        }

        emit REVEAL(_proposeName, "TAKER");
    }

    /**
     * 决出winner
     */
    function getWinner(string calldata _proposeName) private {
        propose storage proposeInstance = proposeList[_proposeName];
        require(
            proposeInstance.status == STATUS.WAIT_TO_REVEAL_HALF,
            "not enough reveal"
        );

        uint256 sub;
        if (
            proposeInstance.proposeNumMaker >= proposeInstance.proposeNumTaker
        ) {
            sub =
                proposeInstance.proposeNumMaker -
                proposeInstance.proposeNumTaker;
        } else {
            sub =
                proposeInstance.proposeNumTaker -
                proposeInstance.proposeNumMaker;
        }

        if (sub % 2 == 0) {
            proposeInstance.winner = proposeInstance.proposeMaker;
            emit GET_WINNER(_proposeName, proposeInstance.proposeMaker);
        } else {
            proposeInstance.winner = proposeInstance.proposeTaker;
            emit GET_WINNER(_proposeName, proposeInstance.proposeTaker);
        }
    }

    /**
     * Winner提现
     */
    function withDraw(string calldata _proposeName) external {
        propose storage proposeInstance = proposeList[_proposeName];
        require(msg.sender == proposeInstance.winner, "not winner");

        payable(msg.sender).transfer(proposeInstance.betValue);

        delete proposeList[_proposeName];

        emit WINNER_WITHDRAW(_proposeName, msg.sender);
    }

    /**
     * 计算num hash
     */
    function getNumHash(uint256 _num) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_num));
    }
}
