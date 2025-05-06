//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/interface/IRebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {CCIPLocalSimulatorFork} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";

contract CrossChainTest is Test {
    uint256 sepoliaFork;
    uint256 arbSepoliaFork;

    address constant owner = makeAddr("owner");
    address constant user = makeAddr("user");

    CCIPLocalSimulatorFork ccipLocalSimulatorFork;
    RebaseToken sepoliaToken;
    RebaseToken arbSepoliaToken;
    Vault vault;

    function setUp() public {
        sepoliaFork = vm.createSelectFork("sepolia");
        arbSepoliaFork = vm.createFork("arb-sepolia");

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // 1. Depoly and configure on Sepolia
        vm.startPrank(owner);
        sepoliaToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(sepoliaToken)));
        vm.stopPrank();

        // 2. Deploy and configure on Arbitrum Sepolia
        vm.selectFork(arbSepoliaFork);
        vm.startPrank(owner);
        arbSepoliaToken = new RebaseToken();
        vm.stopPrank();
    }
}
