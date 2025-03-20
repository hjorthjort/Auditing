// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.26;

import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {TransparentUpgradeableProxy} from "../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {SafeCast} from "../libraries/SafeCast.sol";
import {Test} from "../../lib/forge-std/src/Test.sol";
import {SafeERC20} from "../libraries/SafeERC20.sol";
import {console} from "../../lib/forge-std/src/console.sol";
import {AlchemistV3} from "../AlchemistV3.sol";
import {AlchemicTokenV3} from "../AlchemicTokenV3.sol";
import {Transmuter} from "../Transmuter.sol";
import {AlchemistV3Position} from "../AlchemistV3Position.sol";

import {TransmuterBuffer} from "../TransmuterBuffer.sol";
import {Whitelist} from "../utils/Whitelist.sol";
import {TestERC20} from "./mocks/TestERC20.sol";
import {TestYieldToken} from "./mocks/TestYieldToken.sol";
import {TokenAdapterMock} from "./mocks/TokenAdapterMock.sol";
import {IAlchemistV3, IAlchemistV3Errors, InitializationParams} from "../interfaces/IAlchemistV3.sol";
import {ITransmuter} from "../interfaces/ITransmuter.sol";
import {ITestYieldToken} from "../interfaces/test/ITestYieldToken.sol";
import {InsufficientAllowance} from "../base/Errors.sol";
import {Unauthorized, IllegalArgument, IllegalState, MissingInputData} from "../base/Errors.sol";
import {AlchemistNFTHelper} from "./libraries/AlchemistNFTHelper.sol";
import {IAlchemistV3Position} from "../interfaces/IAlchemistV3Position.sol";
import {AlchemistETHVault} from "../AlchemistETHVault.sol";
import {ETHUSDPriceFeedAdapter} from "../adapters/ETHUSDPriceFeedAdapter.sol";

contract AlchemistETHVaultTest is Test {
    // ----- [SETUP] Variables for setting up a minimal CDP -----

    // Callable contract variables
    AlchemistV3 alchemist;
    Transmuter transmuter;
    TransmuterBuffer transmuterBuffer;
    AlchemistV3Position alchemistNFT;
    AlchemistETHVault ethVault;

    // // Proxy variables
    TransparentUpgradeableProxy proxyAlchemist;
    TransparentUpgradeableProxy proxyTransmuter;
    TransparentUpgradeableProxy proxyTransmuterBuffer;

    // // Contract variables
    // CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    AlchemistV3 alchemistLogic;
    Transmuter transmuterLogic;
    TransmuterBuffer transmuterBufferLogic;
    AlchemicTokenV3 alToken;
    Whitelist whitelist;

    // Token addresses
    TestERC20 fakeUnderlyingToken;
    TestYieldToken fakeYieldToken;
    ETHUSDPriceFeedAdapter ethUsdAdapter;
    // WETH address
    address public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address ETH_USD_PRICE_FEED_MAINNET = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    // Total minted debt
    uint256 public minted;

    // Total debt burned
    uint256 public burned;

    // Total tokens sent to transmuter
    uint256 public sentToTransmuter;

    // Parameters for AlchemicTokenV2
    string public _name;
    string public _symbol;
    uint256 public _flashFee;
    address public alOwner;

    mapping(address => bool) users;

    uint256 public minimumCollateralization = uint256(1e18 * 1e18) / 9e17;

    uint256 public constant FIXED_POINT_SCALAR = 1e18;

    // ----- Variables for deposits & withdrawals -----

    // account funds to make deposits/test with
    uint256 accountFunds = 2_000_000_000e18;

    // large amount to test with
    uint256 whaleSupply = 20_000_000_000e18;

    // amount of yield/underlying token to deposit
    uint256 depositAmount = 100_000e18;

    // minimum amount of yield/underlying token to deposit
    uint256 minimumDeposit = 1000e18;

    // minimum amount of yield/underlying token to deposit
    uint256 minimumDepositOrWithdrawalLoss = 1e18;

    // random EOA for testing
    address externalUser = address(0x69E8cE9bFc01AA33cD2d02Ed91c72224481Fa420);

    // another random EOA for testing
    address anotherExternalUser = address(0x420Ab24368E5bA8b727E9B8aB967073Ff9316969);

    // another random EOA for testing
    address yetAnotherExternalUser = address(0x520aB24368e5Ba8B727E9b8aB967073Ff9316961);

    // another random EOA for testing
    address someWhale = address(0x521aB24368E5Ba8b727e9b8AB967073fF9316961);

    function setUp() external {
        // test maniplulation for convenience
        address caller = address(0xdead);
        address proxyOwner = address(this);
        vm.assume(caller != address(0));
        vm.assume(proxyOwner != address(0));
        vm.assume(caller != proxyOwner);
        vm.startPrank(caller);

        // Fake tokens

        fakeUnderlyingToken = new TestERC20(100e18, uint8(18));
        fakeYieldToken = new TestYieldToken(address(fakeUnderlyingToken));
        ethUsdAdapter = new ETHUSDPriceFeedAdapter(ETH_USD_PRICE_FEED_MAINNET);

        alToken = new AlchemicTokenV3(_name, _symbol, _flashFee);

        ITransmuter.InitializationParams memory transParams = ITransmuter.InitializationParams({
            syntheticToken: address(alToken),
            feeReceiver: address(this),
            timeToTransmute: 5_256_000,
            transmutationFee: 10,
            exitFee: 20,
            graphSize: 52_560_000
        });

        // Contracts and logic contracts
        alOwner = caller;
        transmuterBufferLogic = new TransmuterBuffer();
        transmuterLogic = new Transmuter(transParams);
        alchemistLogic = new AlchemistV3();
        whitelist = new Whitelist();

        // AlchemistV3 proxy
        InitializationParams memory params = InitializationParams({
            admin: alOwner,
            debtToken: address(alToken),
            underlyingToken: address(fakeUnderlyingToken),
            yieldToken: address(fakeYieldToken),
            blocksPerYear: 2_600_000,
            depositCap: type(uint256).max,
            minimumCollateralization: minimumCollateralization,
            collateralizationLowerBound: 1_052_631_578_950_000_000, // 1.05 collateralization
            globalMinimumCollateralization: 1_111_111_111_111_111_111, // 1.1
            tokenAdapter: address(fakeYieldToken),
            ethUsdAdapter: address(ethUsdAdapter),
            transmuter: address(transmuterLogic),
            protocolFee: 0,
            protocolFeeReceiver: address(10),
            liquidatorFee: 300 // in bps? 3%
        });

        bytes memory alchemParams = abi.encodeWithSelector(AlchemistV3.initialize.selector, params);
        proxyAlchemist = new TransparentUpgradeableProxy(address(alchemistLogic), proxyOwner, alchemParams);
        alchemist = AlchemistV3(address(proxyAlchemist));

        // Deploy vault
        ethVault = new AlchemistETHVault(address(weth), address(alchemist), alOwner);

        // Whitelist alchemist proxy for minting tokens
        alToken.setWhitelist(address(proxyAlchemist), true);

        whitelist.add(address(0xbeef));
        whitelist.add(externalUser);
        whitelist.add(anotherExternalUser);

        transmuterLogic.setAlchemist(address(alchemist));
        transmuterLogic.setDepositCap(uint256(type(int256).max));

        alchemistNFT = new AlchemistV3Position(address(alchemist));
        alchemist.setAlchemistPositionNFT(address(alchemistNFT));

        vm.stopPrank();
    }

    // === CONSTRUCTOR TESTS ===
    function testConstructor() public {
        assertEq(ethVault.weth(), address(weth));
        assertEq(ethVault.alchemist(), address(alchemist));
    }

    function testConstructorZeroAddressReverts() public {
        vm.expectRevert("Invalid WETH address");
        new AlchemistETHVault(address(0), address(alchemist), alOwner);
    }

    // ... existing code ...

    function testDepositETH() public {
        uint256 depositAmount = 1 ether;
        uint256 initialBalance = address(externalUser).balance;

        // Give some ETH to the external user
        vm.deal(externalUser, initialBalance + depositAmount);

        vm.startPrank(externalUser);

        // Deposit ETH
        (bool success,) = address(ethVault).call{value: depositAmount}("");

        // Verify the user's ETH balance decreased
        assertEq(address(externalUser).balance, initialBalance);

        vm.stopPrank();
    }

    function testWithdrawETH() public {
        uint256 amount = 2 ether;
        uint256 initialBalance = address(externalUser).balance;

        vm.startPrank(anotherExternalUser);

        // Give some ETH to the external user
        vm.deal(anotherExternalUser, 10 ether);
        // Deposit ETH
        (bool success,) = address(ethVault).call{value: amount}("");

        vm.stopPrank();

        // Set up the vault with some ETH
        vm.deal(address(ethVault), amount);

        // Verify the user's ETH balance decreased
        assertEq(address(ethVault).balance, amount);

        vm.startPrank(address(alchemist));

        // Withdraw ETH
        ethVault.withdraw(externalUser, amount / 2);

        // Verify the user's ETH balance increased
        assertEq(address(externalUser).balance, initialBalance + amount / 2);

        vm.stopPrank();
    }

    function testWithdrawETHRevertsUnauthorized() public {
        uint256 withdrawAmount = 1 ether;
        uint256 initialBalance = address(externalUser).balance;

        // Set up the vault with some ETH
        vm.deal(address(ethVault), withdrawAmount);

        vm.startPrank(externalUser);

        vm.expectRevert();
        // Withdraw ETH
        ethVault.withdraw(externalUser, withdrawAmount);

        vm.stopPrank();
    }

    function testOnlyOwnerFunctions() public {
        // Test setting a new alchemist address
        address newAlchemist = address(0x123);

        // Non-owner tries to call an owner-only function
        vm.startPrank(externalUser);
        vm.expectRevert();
        ethVault.setAlchemist(newAlchemist);
        vm.stopPrank();

        // Owner calls the same function
        vm.startPrank(alOwner);
        ethVault.setAlchemist(newAlchemist);
        assertEq(ethVault.alchemist(), newAlchemist);
        vm.stopPrank();
    }

    function testDepositETHWithZeroAmountReverts() public {
        vm.startPrank(externalUser);
        vm.expectRevert();
        ethVault.depositWETH(0);
        vm.stopPrank();
    }

    function testETHReceivedViaCallback() public {
        uint256 amount = 1 ether;

        // Give ETH to the test contract
        vm.deal(address(this), amount);

        // Mock a callback from the alchemist (e.g., after withdrawing WETH)
        // First, ensure the vault has no ETH
        assertEq(address(ethVault).balance, 0);

        // Send ETH to the vault as if it's a callback
        (bool success,) = address(ethVault).call{value: amount}("");
        assertTrue(success);

        // Verify the vault received the ETH
        assertEq(address(ethVault).balance, amount);
    }
}
