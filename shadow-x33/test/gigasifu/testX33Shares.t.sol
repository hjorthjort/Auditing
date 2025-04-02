// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";

import {IXShadow} from "contracts/interfaces/IXShadow.sol";
import {x33} from "contracts/xShadow/x33.sol";
import {IX33} from "contracts/interfaces/IX33.sol";
import {XShadow} from "contracts/xShadow/XShadow.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// add a custom mock for xSHADOW that includes the SHADOW() function
contract MockXShadow is MockERC20 {
    address public SHADOW;

    function initialize(string memory _name, string memory _symbol, uint8 _decimals, address _shadow) public {
        super.initialize(_name, _symbol, _decimals);
        SHADOW = _shadow;
    }
    
    /// @notice Mimics xShadow's "convertEmissionsToken" by transferring in SHADOW and minting xSHADOW.  
    /// @param _amount Amount of SHADOW tokens to stake/convert.
    function convertEmissionsToken(uint256 _amount) external {
        require(_amount > 0, "Zero amount");
        IERC20(SHADOW).transferFrom(msg.sender, address(this), _amount);

        // minted xShadow
        _mint(msg.sender, _amount);
    }
}

contract MockVoteModule {
    uint256 public unlockTime;
    // The xShadow token we want to deposit
    IERC20 public xShadowToken; // set owner in constructor / init

    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    function setUnlockTime(uint256 _unlockTime) external {
        unlockTime = _unlockTime;
    }

    function setXShadowToken(address _xShadowToken) external {
        xShadowToken = IERC20(_xShadowToken);
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function deposit(uint256 amount) external {
        _balances[msg.sender] += amount;
        _totalSupply += amount;
        // transfer xShadow from x33 to this contract
        xShadowToken.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        // transfer xShadow back to sender
        xShadowToken.transfer(msg.sender, amount);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // required view functions
    function periodFinish() external pure returns (uint256) {
        return 0;
    }

    function earned(address) external pure returns (uint256) {
        return 0;
    }

    function getReward() external {}

    function depositAll() external {
         // 1. check how much xSHADOW x33 has.
        uint256 bal = xShadowToken.balanceOf(msg.sender);
        // 2. pull it from x33 into the voteModule.
        if (bal > 0) {
            xShadowToken.transferFrom(msg.sender, address(this), bal);
            // 3. update the internal _balances so that balanceOf(x33) reflects reality.
            _balances[msg.sender] += bal;
            _totalSupply += bal;
        }
    }
}

import {Shadow} from "contracts/Shadow.sol";

contract TestShareTechnology is Test {
    address dawg = makeAddr("dawg");
    address sifu = makeAddr("sifu");

    x33 x33contract;
    MockERC20 public shadowToken; //  underlying SHADOW token
    MockXShadow public xShadowToken; //  xSHADOW token with SHADOW() function
    address voteModule = address(0x2);
    address voter = address(0x3);
    address accessHub = address(0x4);

    uint256 initialRatio;
    uint256 testMint = 1e18;
    uint256 testWithdraw = 1e18;

    MockVoteModule public mockVoteModule;

    function setUp() public {
        // deploy SHADOW token first
        shadowToken = new MockERC20();
        shadowToken.initialize("Shadow", "SHADOW", 18);
        // deploy xSHADOW token with reference to SHADOW
        xShadowToken = new MockXShadow();
        xShadowToken.initialize("xShadow", "xSHADOW", 18, address(shadowToken));
        // deploy mock vote module
        mockVoteModule = new MockVoteModule();
        // set the xShadow token in the mock
        mockVoteModule.setXShadowToken(address(xShadowToken));
        // set unlock time to 0 to allow immediate unlocking
        mockVoteModule.setUnlockTime(0);
        // initialize x33 with mock vote module
        x33contract = new x33(dawg, accessHub, address(xShadowToken), voter, address(mockVoteModule));
        // deal some tokens
        deal(address(shadowToken), dawg, 1_000_000 * 1e18);
        deal(address(xShadowToken), dawg, 1_000_000 * 1e18);
        deal(address(shadowToken), sifu, 1_000_000 * 1e18);
        deal(address(xShadowToken), sifu, 1_000_000 * 1e18);
        // approvals
        vm.startPrank(dawg);
        shadowToken.approve(voteModule, type(uint256).max);
        shadowToken.approve(address(x33contract), type(uint256).max);
        xShadowToken.approve(voteModule, type(uint256).max);
        xShadowToken.approve(address(x33contract), type(uint256).max);
        x33contract.unlock();
        vm.stopPrank();

        vm.startPrank(sifu);
        shadowToken.approve(voteModule, type(uint256).max);
        shadowToken.approve(address(x33contract), type(uint256).max);
        xShadowToken.approve(voteModule, type(uint256).max);
        xShadowToken.approve(address(x33contract), type(uint256).max);
        // unlock (its locked by default)

        vm.stopPrank();

        // aprovals
    }

    function testInitialDeposit() public {
        vm.startPrank(dawg);

        console.log("--- Initial State dawg ---");
        console.log("current shares supply", x33contract.totalSupply());
        console.log("total assets underlying", x33contract.totalAssets());

        uint256 depositAmount = 420 * 1e18;
        console.log("\n--- Depositing %s wei as dawg---", depositAmount);
        // x33contract.enterVault(depositAmount);

        console.log("new shares supply", x33contract.totalSupply());
        console.log("new underlying supply", x33contract.totalAssets());
        console.log("dawg x33 (shares) balance", x33contract.balanceOf(dawg));
        console.log("voteModule balance", mockVoteModule.balanceOf(address(x33contract)));
        console.log("ratio", x33contract.ratio());

        uint256 testamount = 69 * 1e17;
        console.log("\n--- transfer %s wei as xShadow to compound---", testamount);
        shadowToken.transfer(address(x33contract), testamount);
        x33contract.compound();
        console.log("new shares supply", x33contract.totalSupply());
        console.log("new underlying supply", x33contract.totalAssets());
        console.log("ratio", x33contract.ratio());
        vm.stopPrank();

        vm.startPrank(sifu);
        console.log("--- Initial State sifu ---");
        console.log("current supply", x33contract.totalSupply());
        console.log("underlying current", x33contract.totalAssets());

        uint256 depo = 1e18;
        console.log("\n--- Depositing %s wei as sifu ---", depo);
        //x33contract.enterVault(depo);

        console.log("totalSupply", x33contract.totalSupply());
        console.log("underlying", x33contract.totalAssets());
        console.log("sifu x33 balance", x33contract.balanceOf(sifu));
        console.log("ratio", x33contract.ratio());

        vm.stopPrank();

        vm.startPrank(dawg);
        uint256 depos = 100 * 1e18;
        console.log("\n--- Depositing %s wei as dog---", depos);
        // x33contract.enterVault(depos);
        uint256 with = x33contract.balanceOf(dawg);

        uint256 xshadb4 = xShadowToken.balanceOf(dawg);

        console.log("\n--- withdrawing %s wei as dog---", with);
        // x33contract.exitVault(with);

        console.log("totalSupply", x33contract.totalSupply());
        console.log("underlying", x33contract.totalAssets());
        console.log("sifu x33 balance", x33contract.balanceOf(sifu));
        console.log("dawg x33 balance", x33contract.balanceOf(dawg));
        console.log("dawg xshadow bal dif", xShadowToken.balanceOf(dawg) - xshadb4);
        console.log("voteModule balance", mockVoteModule.balanceOf(address(x33contract)));
        console.log("ratio", x33contract.ratio());
    }
}
