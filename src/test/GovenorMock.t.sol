// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {console} from "forge-std/console.sol";
import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {Utils} from "./utils/Utils.sol";

import {GovernorMock} from "openzeppelin-contracts/mocks/GovernorMock.sol";
import {ERC20VotesMock} from "openzeppelin-contracts/mocks/ERC20VotesMock.sol";
import {CallReceiverMock} from "openzeppelin-contracts/mocks/CallReceiverMock.sol";
import {IVotes} from "openzeppelin-contracts/governance/utils/IVotes.sol";

contract BaseSetup is Test {
    Utils internal utils;
    address payable[] internal users;

    address internal alice;
    address internal bob;
    address internal carol;

    GovernorMock internal governorMock;
    ERC20VotesMock internal erc20VotesMock;
    CallReceiverMock internal callReceiverMock;

    function setUp() public virtual {
        utils = new Utils();
        users = utils.createUsers(3);

        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");
        carol = users[2];
        vm.label(carol, "Carol");

        erc20VotesMock = new ERC20VotesMock("MockToken", "MTKN");
        erc20VotesMock.mint(alice, 100);
        governorMock = new GovernorMock(
            "OZ-Governor",
            IVotes(address(erc20VotesMock)),
            4,
            16,
            10
        );
        callReceiverMock = new CallReceiverMock();
    }
}

contract WhenTransferringTokens is BaseSetup {
    function setUp() public virtual override {
        BaseSetup.setUp();
        console.log("When transferring tokens");
    }

    function testPropose() public {
        // set block.number after snapshot
        vm.prank(alice);
        erc20VotesMock.delegate(bob);
        vm.prank(alice);
        erc20VotesMock.transfer(bob, 100);

        address[] memory targets = new address[](1);
        targets[0] = address(callReceiverMock);

        uint256[] memory values = new uint256[](1);
        values[0] = 1;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encode("mockFunction()");

        uint256 proposalId = governorMock.propose(
            targets,
            values,
            calldatas,
            "<proposal description>"
        );
        vm.roll(10);
        vm.prank(bob);
        governorMock.castVote(proposalId, 1);
        vm.roll(30);
        erc20VotesMock.getPastVotes(bob, governorMock.proposalSnapshot(proposalId));
        erc20VotesMock.numCheckpoints(bob);
        governorMock.state(proposalId);
        governorMock.proposalVotes(proposalId);
        governorMock.execute(
            targets,
            values,
            calldatas,
            keccak256(bytes("<proposal description>"))
        );
    }
}
