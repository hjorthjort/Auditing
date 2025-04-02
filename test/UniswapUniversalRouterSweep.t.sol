// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

interface IUniversalRouter {
    /// @notice The UniversalRouter's primary entry point.
    /// @param commands A sequence of 1-byte commands
    /// @param inputs   An array of ABI-encoded inputs for each command
    /// @param deadline A timestamp by which this transaction must be completed
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable;
}

contract Commands {
    // Masks to extract certain bits of commands
    bytes1 internal constant FLAG_ALLOW_REVERT = 0x80;
    bytes1 internal constant COMMAND_TYPE_MASK = 0x3f;

    // Command Types. Maximum supported command at this moment is 0x3f.
    // The commands are executed in nested if blocks to minimise gas consumption

    // Command Types where value<=0x07, executed in the first nested-if block
    uint256 constant V3_SWAP_EXACT_IN = 0x00;
    uint256 constant V3_SWAP_EXACT_OUT = 0x01;
    uint256 constant PERMIT2_TRANSFER_FROM = 0x02;
    uint256 constant PERMIT2_PERMIT_BATCH = 0x03;
    uint256 constant SWEEP = 0x04;
    uint256 constant TRANSFER = 0x05;
    uint256 constant PAY_PORTION = 0x06;
    // COMMAND_PLACEHOLDER = 0x07;

    // Command Types where 0x08<=value<=0x0f, executed in the second nested-if block
    uint256 constant V2_SWAP_EXACT_IN = 0x08;
    uint256 constant V2_SWAP_EXACT_OUT = 0x09;
    uint256 constant PERMIT2_PERMIT = 0x0a;
    uint256 constant WRAP_ETH = 0x0b;
    uint256 constant UNWRAP_WETH = 0x0c;
    uint256 constant PERMIT2_TRANSFER_FROM_BATCH = 0x0d;
    uint256 constant BALANCE_CHECK_ERC20 = 0x0e;
    // COMMAND_PLACEHOLDER = 0x0f;

    // Command Types where 0x10<=value<=0x20, executed in the third nested-if block
    uint256 constant V4_SWAP = 0x10;
    uint256 constant V3_POSITION_MANAGER_PERMIT = 0x11;
    uint256 constant V3_POSITION_MANAGER_CALL = 0x12;
    uint256 constant V4_INITIALIZE_POOL = 0x13;
    uint256 constant V4_POSITION_MANAGER_CALL = 0x14;
    // COMMAND_PLACEHOLDER = 0x15 -> 0x20

    // Command Types where 0x21<=value<=0x3f
    uint256 constant EXECUTE_SUB_PLAN = 0x21;
    // COMMAND_PLACEHOLDER for 0x22 to 0x3f
}

contract UniversalRouterTest is Test, Commands {
    /// Mainnet addresses
    address constant UNIVERSAL_ROUTER = 0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af;
    address constant USDC            = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // Pick any USDC whale address that definitely holds enough USDC:
    address constant USDC_WHALE      = 0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341;
    address alice = makeAddr("alice"); // pseudo-random new address

    function setUp() public {
        // Fork mainnet at a recent block (2025-04-01)
        vm.createSelectFork("mainnet", 22174204); 

        // Impersonate a USDC whale so we can transfer out some tokens
        vm.startPrank(USDC_WHALE);
        // Transfer 100 USDC to the UniversalRouter
        IERC20(USDC).transfer(UNIVERSAL_ROUTER, 100e6);
        vm.stopPrank();

    }

    function testSweep() public {
        // 1) Check that Alice starts with 0 USDC.
        uint256 beforeBal = IERC20(USDC).balanceOf(alice);
        assertEq(beforeBal, 0, "Alice should start with 0 USDC");

        // 2) Construct a single command: SWEEP(USDC -> Alice, minAmount=1)
        bytes memory commands = hex"04"; // SWEEP command
        // UniversalRouter’s Dispatcher decodes SWEEP as:
        //   abi.decode(inputs, (address token, address recipient, uint160 amountMin))
        // so we encode USDC, alice, and 1 as the min amount:
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(USDC, alice, uint160(1));

        // 3) Call `execute`. We can do this from a random sender—no special perms required.
        vm.startPrank(address(0x1234));
        IUniversalRouter(UNIVERSAL_ROUTER).execute(commands, inputs, block.timestamp + 300);
        vm.stopPrank();

        // 4) Verify that Alice’s balance increased by 100 USDC
        uint256 afterBal = IERC20(USDC).balanceOf(alice);
        assertEq(afterBal - beforeBal, 100e6, "Alice did not receive the expected 100 USDC");
    }

    function testTransfer() public {
        // 1) Check that Alice starts with 0 USDC.
        uint256 beforeBal = IERC20(USDC).balanceOf(alice);
        assertEq(beforeBal, 0, "Alice should start with 0 USDC");

        // 2) Construct a single command: SWEEP(USDC -> Alice, minAmount=1)
        bytes memory commands = hex"05"; // TRANSFER command
        // UniversalRouter’s Dispatcher decodes TRANSFER as:
        //   abi.decode(inputs, (address token, address recipient, uint160 amountMin))
        // so we encode USDC, alice, and 1 as the min amount:
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(USDC, alice, uint160(100e6));

        // 3) Call `execute`. We can do this from a random sender—no special perms required.
        vm.startPrank(address(0x1234));
        IUniversalRouter(UNIVERSAL_ROUTER).execute(commands, inputs, block.timestamp + 300);
        vm.stopPrank();

        // 4) Verify that Alice’s balance increased by 100 USDC
        uint256 afterBal = IERC20(USDC).balanceOf(alice);
        assertEq(afterBal - beforeBal, 100e6, "Alice did not receive the expected 100 USDC");
    }
}

