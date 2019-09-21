

pragma solidity ^0.5.6;

import "ds-test/test.sol";

import "../../Prototype.sol";
import "../../ERC20Token.sol";
import "../../ShellFactory.sol";
import "../../Shell.sol";
import "../../testSetup/setupShells.sol";

contract DappTest is DSTest, ShellSetup {
    address shell;

    function setUp () public {
        setupPool();
        setupTokens();
    }

    function testCreateShellWith11Tokens () public {

        shell = setup11TokenShell();
        address[] memory tokens = Shell(shell).getTokens();

        assertEq(address(TEST1), tokens[0]);
        assertEq(address(TEST2), tokens[1]);
        assertEq(address(TEST3), tokens[2]);
        assertEq(address(TEST4), tokens[3]);
        assertEq(address(TEST5), tokens[4]);
        assertEq(address(TEST6), tokens[5]);
        assertEq(address(TEST7), tokens[6]);
        assertEq(address(TEST8), tokens[7]);
        assertEq(address(TEST9), tokens[8]);
        assertEq(address(TEST10), tokens[9]);
        assertEq(address(TEST11), tokens[10]);

    }
}