// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.5.0;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ICToken.sol";
import "../adapterDSMath.sol";

contract MainnetDaiAdapter is AdapterDSMath {

    ICToken constant cdai = ICToken(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    IERC20 constant dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    uint256 constant ZEN_DELTA = 1e12;

    constructor () public { }

    function toZen (uint256 _amount) internal pure returns (int128 _zenAmt) {
        zenAmt_ = (_amount / ZEN_DELTA).fromUInt();
    }

    function fromZen (int128 _zenAmt) internal pure returns (uint256 amount_) {
        amount_ = _zenAmt.toUInt() * ZEN_DELTA;
    }

    // transfers raw amonut of dai in, wraps it in cDai, returns numeraire amount
    function intakeRaw (uint256 _amount) public returns (int128 amount_) {

        dai.transferFrom(msg.sender, address(this), _amount);

        uint256 success = cdai.mint(_amount);

        if (success != 0) revert("CDai/mint-failed");

        amount_ = toZen(_amount);

    }

    // transfers numeraire amount of dai in, wraps it in cDai, returns raw amount
    function intakeNumeraire (int128 _amount) public returns (uint256 amount_) {

        amount_ = fromZen(_amount);

        dai.transferFrom(msg.sender, address(this), amount_);

        uint256 success = cdai.mint(amount_);

        if (success != 0) revert("CDai/mint-failed");

    }

    // takes raw amount of dai, unwraps that from cDai, transfers it out, returns numeraire amount
    function outputRaw (address _dst, uint256 _amount) public returns (int128 amount_) {

        uint256 success = cdai.redeemUnderlying(_amount);

        if (success != 0) revert("CDai/redeemUnderlying-failed");

        dai.transfer(dst, _amount);

        amount_ = toZen(_amount);

    }

    // takes numeraire amount of dai, unwraps corresponding amount of cDai, transfers that out, returns numeraire amount
    function outputNumeraire (address _dst, int128 _amount) public returns (uint256 amount_) {

        amount_ = fromZen(_amount);

        uint256 success = cdai.redeemUnderlying(amount_);

        if (success != 0) revert("CDai/redeemUnderlying-failed");

        dai.transfer(_dst, amount_);

        return amount_;

    }

    // takes numeraire amount and returns raw amount
    function viewRawAmount (int128 _amount) public pure returns (uint256 amount_) {

        amount_ = fromZen(_amount);

    }

    // takes raw amount and returns numeraire amount
    function viewNumeraireAmount (uint256 _amount) public pure returns (int128 amount_) {

        amount_ = toZen(_amount).fromUInt();

    }

    // returns current balance in numeraire
    function viewNumeraireBalance () public view returns (int128 amount_) {

        uint256 _rate = cdai.exchangeRateStored();

        uint256 _balance = cdai.balanceOf(addr);

        if (balance == 0) return ABDKMath64x64.fromUInt(0);

        amount_ = toZen(_balance.wmul(_rate));

    }

}