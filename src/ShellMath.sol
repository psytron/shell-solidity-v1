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

import "./Assimilators.sol";

import "./UnsafeMath64x64.sol";

import "./LoihiStorage.sol";

import "abdk-libraries-solidity/ABDKMath64x64.sol";

library ShellMath {

    int128 constant ONE = 0x10000000000000000;
    int128 constant MAX = 0x4000000000000000; // .25 in laments terms
    int128 constant ONE_WEI = 0x12;

    using ABDKMath64x64 for int128;
    using UnsafeMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    function calculateFee (
        int128 _gLiq,
        int128[] memory _bals,
        int128 _beta,
        int128 _delta,
        int128[] memory _weights
    ) internal pure returns (int128 psi_) {

        for (uint i = 0; i < _weights.length; i++) {
            int128 _ideal = _gLiq.us_mul(_weights[i]);
            psi_ += calculateMicroFee(_bals[i], _ideal, _beta, _delta);
        }

    }

    function calculateMicroFee (
        int128 _bal,
        int128 _ideal,
        int128 _beta,
        int128 _delta
    ) private pure returns (int128 fee_) {

        if (_bal < _ideal) {

            int128 _threshold = _ideal.us_mul(ONE - _beta);

            if (_bal < _threshold) {

                int128 _feeSection = _threshold - _bal;

                fee_ = _feeSection.us_div(_ideal);
                fee_ = fee_.us_mul(_delta);

                if (fee_ > MAX) fee_ = MAX;

                fee_ = fee_.us_mul(_feeSection);

            } else fee_ = 0;

        } else {

            int128 _threshold = _ideal.us_mul(ONE + _beta);

            if (_bal > _threshold) {

                int128 _feeSection = _bal - _threshold;

                fee_ = _feeSection.us_div(_ideal);
                fee_ = fee_.us_mul(_delta);

                if (fee_ > MAX) fee_ = MAX;

                fee_ = fee_.us_mul(_feeSection);

            } else fee_ = 0;

        }

    }

    function calculateTrade (
        LoihiStorage.Shell storage shell,
        int128 _oGLiq,
        int128 _nGLiq,
        int128[] memory _oBals,
        int128[] memory _nBals,
        int128 _inputAmt,
        uint _outputIndex
    ) internal view returns (int128 outputAmt_) {

        outputAmt_ = - _inputAmt;

        int128 _lambda = shell.lambda;
        int128 _beta = shell.beta;
        int128 _delta = shell.delta;
        int128[] memory _weights = shell.weights;

        int128 _omega = calculateFee(_oGLiq, _oBals, _beta, _delta, _weights);
        int128 _psi;


        for (uint i = 0; i < 32; i++) {

            psi_ = calculateFee(_nGLiq, _nBals, _beta, _delta, _weights);

            if (( outputAmt_ = _omega < psi_
                    ? - ( _inputAmt + _omega - psi_ )
                    : - ( _inputAmt + _lambda.us_mul(_omega - psi_))
                ) / 1e13 == outputAmt_ / 1e13 ) {

                _nGLiq = _oGLiq + _inputAmt + outputAmt_;

                _nBals[_outputIndex] = _oBals[_outputIndex] + outputAmt_;

                enforceHalts(shell, _oGLiq, _nGLiq, _oBals, _nBals, _weights);
                
                enforceSwapInvariant(_oGLiq, _omega, _nGLiq, _psi);

                require(ABDKMath64x64.sub(_oGLiq, _omega) <= ABDKMath64x64.sub(_nGLiq, psi_), "Shell/swap-invariant-violation");

                return outputAmt_;

            } else {

                _nGLiq = _oGLiq + _inputAmt + outputAmt_;

                _nBals[_outputIndex] = _oBals[_outputIndex].add(outputAmt_);

            }

        }

        revert("Shell/swap-convergence-failed");

    }
    
    function enforceSwapInvariant (
        int128 _oGLiq,
        int128 _omega,
        int128 _nGLiq,
        int128 _psi
    ) private pure {
        
        require(_oGLiq.sub(_omega) / 1e10 <= _nGLiq.sub(_psi) / 1e10, "Shell/swap-invariant-violation");
        
    }

    function calculateLiquidityMembrane (
        LoihiStorage.Shell storage shell,
        int128 _oGLiq,
        int128 _nGLiq,
        int128[] memory _oBals,
        int128[] memory _nBals
    ) internal view returns (int128 shells_, int128 psi_) {

        enforceHalts(shell, _oGLiq, _nGLiq, _oBals, _nBals, shell.weights);

        psi_ = calculateFee(_nGLiq, _nBals, shell.beta, shell.delta, shell.weights);

        int128 _omega = shell.omega;
        int128 _feeDiff = psi_.sub(_omega);
        int128 _liqDiff = _nGLiq.sub(_oGLiq);
        int128 _oUtil = _oGLiq.sub(_omega);
        uint _totalShells = shell.totalSupply.divu(1e18);

        if (_totalShells == 0) {

            shells_ = _nGLiq.sub(psi_);

        } else if (_feeDiff >= 0) {

            shells_ = _liqDiff.sub(_feeDiff).div(_oUtil);

        } else {
            
            shells_ = _liqDiff.sub(shell.lambda.mul(_feeDiff));
            
            shells_ = shells_.div(_oUtil);

        }

        if (_totalShells != 0) {

            shells_ = shells_.mul(_totalShells);
            
            enforceLiquidityInvariant(totalShells, shells_, _oGLiq, _nGLiq, _omega, _psi);

        }

    }
    
    function enforceLiquidityInvariant (
        int128 _totalShells,
        int128 _newShells,
        int128 _oGLiq,
        int128 _nGLiq,
        int128 _omega,
        int128 _psi
    ) internal view {
        
        if (_totalShells == 0) return;
        
        int128 _prevUtilPerShell = _oGLiq
            .sub(_omega)
            .div(_totalShells);
            
        int128 _nextUtilPerShell = _nGLiq
            .sub(_psi)
            .div(_totalShells.add(_newShells));
            
        require(_prevUtilPerShell / 1e10 <= _nextUtilPerShell / 1e10, "Shell/liquidity-invariant-violation");
        
    }

    function enforceHalts (
        LoihiStorage.Shell storage shell,
        int128 _oGLiq,
        int128 _nGLiq,
        int128[] memory _oBals,
        int128[] memory _nBals,
        int128[] memory _weights
    ) private view {

        uint256 _length = _nBals.length;
        int128 _alpha = shell.alpha;

        for (uint i = 0; i < _length; i++) {

            int128 _nIdeal = _nGLiq.us_mul(_weights[i]);

            if (_nBals[i] > _nIdeal) {

                int128 _upperAlpha = ONE + _alpha;

                int128 _nHalt = _nIdeal.us_mul(_upperAlpha);

                if (_nBals[i] > _nHalt){

                    int128 _oHalt = _oGLiq.us_mul(_weights[i]).us_mul(_upperAlpha);

                    if (_oBals[i] < _oHalt) revert("Shell/upper-halt");
                    if (_nBals[i] - _nHalt > _oBals[i] - _oHalt) revert("Shell/upper-halt");

                }

            } else {

                int128 _lowerAlpha = ONE - _alpha;

                int128 _nHalt = _nIdeal.us_mul(_lowerAlpha);

                if (_nBals[i] < _nHalt){

                    int128 _oHalt = _oGLiq.us_mul(_weights[i]).us_mul(_lowerAlpha);

                    if (_oBals[i] > _oHalt) revert("Shell/lower-halt");
                    if (_nHalt - _nBals[i] > _oHalt - _oBals[i]) revert("Shel/lower-halt");

                }
            }
        }

    }

}