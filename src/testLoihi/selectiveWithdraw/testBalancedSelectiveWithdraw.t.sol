pragma solidity ^0.5.6;

import "ds-test/test.sol";
import "ds-math/math.sol";
import "../../Loihi.sol";
import "../../ERC20I.sol";
import "../flavorsSetup.sol";
import "../adaptersSetup.sol";
import "../../ChaiI.sol";

contract PotMock {
    constructor () public { }
    function rho () public returns (uint256) { return now - 500; }
    function drip () public returns (uint256) { return (10 ** 18) * 2; }
    function chi () public returns (uint256) { return (10 ** 18) * 2; }
}

contract BalancedSelectiveWithdrawTest is AdaptersSetup, DSMath, DSTest {
    Loihi l;

    function setUp() public {
        setupFlavors();
        setupAdapters();

        address pot = address(new PotMock());
        l = new Loihi(
            chai, cdai, dai, pot,
            cusdc, usdc,
            usdt
        );

        ERC20I(chai).approve(address(l), 100000 * (10 ** 18));
        ERC20I(cdai).approve(address(l), 100000 * (10 ** 18));
        ERC20I(dai).approve(address(l), 100000 * (10 ** 18));
        ERC20I(cusdc).approve(address(l), 100000 * (10 ** 18));
        ERC20I(usdc).approve(address(l), 100000 * (10 ** 18));
        ERC20I(usdt).approve(address(l), 100000 * (10 ** 18));

        uint256 weight = WAD / 3;

        l.includeNumeraireAndReserve(dai, chaiAdapter);
        l.includeNumeraireAndReserve(usdc, cusdcAdapter);
        l.includeNumeraireAndReserve(usdt, usdtAdapter);

        l.includeAdapter(chai, chaiAdapter, chaiAdapter, weight);
        l.includeAdapter(dai, daiAdapter, chaiAdapter, weight);
        l.includeAdapter(cdai, cdaiAdapter, chaiAdapter, weight);
        l.includeAdapter(cusdc, cusdcAdapter, cusdcAdapter, weight);
        l.includeAdapter(usdc, usdcAdapter, cusdcAdapter, weight);
        l.includeAdapter(usdt, usdtAdapter, usdtAdapter, weight);

        l.setAlpha((5 * WAD) / 10);
        l.setBeta((25 * WAD) / 100);
        l.setFeeDerivative(WAD / 10);
        l.setFeeBase(500000000000000);

        uint256 shells = l.proportionalDeposit(300 * (10 ** 18));

        // emit log_named_address("chai", chai);
        // emit log_named_address("chaiAdapter", chaiAdapter);
        // emit log_named_address("dai", dai);
        // emit log_named_address("daiAdapter", daiAdapter);
        // emit log_named_address("usdc", usdc);
        // emit log_named_address("usdcAdapter", usdcAdapter);
        // emit log_named_address("usdt", usdt);

    }

    function testSelectiveWithdraw10x0y0z () public {
        uint256[] memory amounts = new uint256[](3);
        address[] memory tokens = new address[](3);

        tokens[0] = dai; amounts[0] = WAD * 10;
        tokens[1] = usdc; amounts[1] = 0;
        tokens[2] = usdt; amounts[2] = 0;

        uint256 newShells = l.selectiveWithdraw(tokens, amounts);
        assertEq(newShells, 10005000000000000000);
    }

    function testSelectiveWithdraw10x15y0z () public {
        uint256[] memory amounts = new uint256[](3);
        address[] memory tokens = new address[](3);

        tokens[0] = dai; amounts[0] = WAD * 10;
        tokens[1] = usdc; amounts[1] = WAD * 15;
        tokens[2] = usdt; amounts[2] = 0;

        uint256 newShells = l.selectiveWithdraw(tokens, amounts);
        assertEq(newShells, 25012500000000000000);
    }

    function testSelectiveWithdraw10x15y20z () public {
        uint256[] memory amounts = new uint256[](3);
        address[] memory tokens = new address[](3);

        tokens[0] = dai; amounts[0] = WAD * 10;
        tokens[1] = usdc; amounts[1] = WAD * 15;
        tokens[2] = usdt; amounts[2] = WAD * 20;

        uint256 newShells = l.selectiveWithdraw(tokens, amounts);
        assertEq(newShells, 45022500000000000000);
    }

    function testSelectiveWithdraw33333333333333x0y0z () public {
        uint256[] memory amounts = new uint256[](3);
        address[] memory tokens = new address[](3);

        tokens[0] = dai; amounts[0] = 33333333333333333333;
        tokens[1] = usdc; amounts[1] = 0;
        tokens[2] = usdt; amounts[2] = 0;

        uint256 newShells = l.selectiveWithdraw(tokens, amounts);
        assertEq(newShells, 33350000000000000000);
    }

    function testSelectiveWithdraw45x0y0z () public {
        uint256[] memory amounts = new uint256[](3);
        address[] memory tokens = new address[](3);

        tokens[0] = dai; amounts[0] = 45 * WAD;
        tokens[1] = usdc; amounts[1] = 0;
        tokens[2] = usdt; amounts[2] = 0;

        uint256 newShells = l.selectiveWithdraw(tokens, amounts);
        assertEq(newShells, 45112618566176470592);

    }

    function testSelectiveWithdraw60x0y0z () public {
        uint256[] memory amounts = new uint256[](3);
        address[] memory tokens = new address[](3);

        tokens[0] = dai; amounts[0] = 59999000000000000000;
        tokens[1] = usdc; amounts[1] = 0;
        tokens[2] = usdt; amounts[2] = 0;

        uint256 newShells = l.selectiveWithdraw(tokens, amounts);
        assertEq(newShells, 60529209897743485963);

    }

    function testFailSelectiveWithdraw150x0y0z () public {
        uint256[] memory amounts = new uint256[](3);
        address[] memory tokens = new address[](3);

        tokens[0] = dai; amounts[0] = 150 * WAD;
        tokens[1] = usdc; amounts[1] = 0;
        tokens[2] = usdt; amounts[2] = 0;

        uint256 newShells = l.selectiveWithdraw(tokens, amounts);

    }

    function testSelectiveWithdraw10x0y50z () public {
        uint256[] memory amounts = new uint256[](3);
        address[] memory tokens = new address[](3);

        tokens[0] = dai; amounts[0] = 10 * WAD;
        tokens[1] = usdc; amounts[1] = 0;
        tokens[2] = usdt; amounts[2] = 50 * WAD;

        uint256 newShells = l.selectiveWithdraw(tokens, amounts);
        assertEq(newShells, 60155062500000000000);
    }

    function testSelectiveWithdraw75x75y5z () public {
        uint256[] memory amounts = new uint256[](3);
        address[] memory tokens = new address[](3);

        tokens[0] = dai; amounts[0] = 75 * WAD;
        tokens[1] = usdc; amounts[1] = 75 * WAD;
        tokens[2] = usdt; amounts[2] = 5 * WAD;

        uint256 newShells = l.selectiveWithdraw(tokens, amounts);
        assertEq(newShells, 155601468749999999994);
    }

    function testFailSelectiveWithdraw10x10y90z () public {
        uint256[] memory amounts = new uint256[](3);
        address[] memory tokens = new address[](3);

        tokens[0] = dai; amounts[0] = 10 * WAD;
        tokens[1] = usdc; amounts[1] = 10 * WAD;
        tokens[2] = usdt; amounts[2] = 90 * WAD;

        uint256 newShells = l.selectiveWithdraw(tokens, amounts);
        assertEq(newShells, 354996024173027989465);

    }

}