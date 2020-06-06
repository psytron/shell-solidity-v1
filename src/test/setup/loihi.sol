pragma solidity ^0.5.0;

import "../../Loihi.sol";

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20NoBool.sol";

import "./storage.sol";

contract ApproveFrom {
    function safeApprove(address _token, address _spender, uint256 _value) public;
}

contract LoihiSetup is StorageSetup {

    function setLoihiParamsSetOne (Loihi _loihi) public {

        uint256 _alpha = 5e17;
        uint256 _beta = 25e16;
        uint256 _max = .05e18;
        uint256 _epsilon = 2.5e14;
        uint256 _lambda = .2e18;

        _loihi.setParams(_alpha, _beta, _max, _epsilon, _lambda, 0);

    }

    function setLoihiParamsSetTwo (Loihi _loihi) public {

       uint256 _alpha = .5e18;
       uint256 _beta = .25e18;
       uint256 _max = .05e18;
       uint256 _epsilon = 5e14;
       uint256 _lambda = .2e18;

       _loihi.setParams(_alpha, _beta, _max, _epsilon, _lambda, 0);

    }

    function setLoihiParamsSetThree (Loihi _loihi) public {

        uint256 _alpha = .5e18;
        uint256 _beta = .25e18;
        uint256 _max = .05e18;
        uint256 _epsilon = 0;
        uint256 _lambda = 1e18;

        _loihi.setParams(_alpha, _beta, _max, _epsilon, _lambda, 0);

    }

    function includeAssimilators (Loihi _loihi) public {

        _loihi.includeAssimilator(address(dai), address(daiAssimilator), address(cdaiAssimilator));
        _loihi.includeAssimilator(address(chai), address(chaiAssimilator), address(cdaiAssimilator));
        _loihi.includeAssimilator(address(cdai), address(cdaiAssimilator), address(cdaiAssimilator));

        _loihi.includeAssimilator(address(usdc), address(usdcAssimilator), address(cusdcAssimilator));
        _loihi.includeAssimilator(address(cusdc), address(cusdcAssimilator), address(cusdcAssimilator));

        _loihi.includeAssimilator(address(usdt), address(usdtAssimilator), address(ausdtAssimilator));
        _loihi.includeAssimilator(address(ausdt), address(ausdtAssimilator), address(ausdtAssimilator));

        _loihi.includeAssimilator(address(asusd), address(asusdAssimilator), address(asusdAssimilator));
        _loihi.includeAssimilator(address(susd), address(susdAssimilator), address(asusdAssimilator));

    }

    function setNumeraireAssetsSetOne_30_30_30_10 (Loihi _loihi) public {

        _loihi.includeNumeraireAsset(address(dai), address(cdai), .3e18);
        _loihi.includeNumeraireAsset(address(usdc), address(cusdc), .3e18);
        _loihi.includeNumeraireAsset(address(usdt), address(ausdt), .3e18);
        _loihi.includeNumeraireAsset(address(susd), address(asusd), .1e18);

    }

    function setNumeraireAssetsSetTwo_30_30_30_10 (Loihi _loihi) public {

        _loihi.includeNumeraireAsset(address(dai), address(cdai), .3e18);
        _loihi.includeNumeraireAsset(address(usdc), address(cusdc), .3e18);
        _loihi.includeNumeraireAsset(address(usdt), address(ausdt), .3e18);
        _loihi.includeNumeraireAsset(address(susd), address(asusd), .1e18);

    }

    function setNumeraireAssetsSetOne_33_33_33 (Loihi _loihi) public {

        _loihi.includeNumeraireAsset(address(dai), address(cdai), 333333333333333333);
        _loihi.includeNumeraireAsset(address(usdc), address(cusdc), 333333333333333333);
        _loihi.includeNumeraireAsset(address(usdt), address(ausdt), 333333333333333333);

    }

    function setNumeraireAssetsSetTwo_33_33_33 (Loihi _loihi) public {

        _loihi.includeNumeraireAsset(address(dai), address(cdai), 333333333333333333);
        _loihi.includeNumeraireAsset(address(usdc), address(cusdc), 333333333333333333);
        _loihi.includeNumeraireAsset(address(usdt), address(ausdt), 333333333333333333);

    }

    function approveStablecoins (address _approveTo) public {

        approve(address(dai), _approveTo);
        approve(address(chai), _approveTo);
        approve(address(cdai), _approveTo);

        approve(address(usdc), _approveTo);
        approve(address(cusdc), _approveTo);

        approveBad(address(usdt), _approveTo);
        approve(address(ausdt), _approveTo);

        approve(address(susd), _approveTo);
        approve(address(asusd), _approveTo);

    }

    function interApproveStablecoinsLocal (address _approveFrom) public {

        address[] memory targets = new address[](5);
        address[] memory spenders = new address[](5);
        targets[0] = address(dai); spenders[0] = address(chai);
        targets[1] = address(dai); spenders[1] = address(cdai);
        targets[2] = address(susd); spenders[2] = address(asusd);
        targets[3] = address(usdc); spenders[3] = address(cusdc);
        targets[4] = address(usdt); spenders[4] = address(ausdt);

        for (uint i = 0; i < targets.length; i++) {
            ApproveFrom(_approveFrom).safeApprove(targets[i], spenders[i], uint256(0));
            ApproveFrom(_approveFrom).safeApprove(targets[i], spenders[i], uint256(-1));
        }

    }

    function interApproveStablecoinsRPC (address _approveFrom) public {

        address[] memory targets = new address[](5);
        address[] memory spenders = new address[](5);
        targets[0] = address(dai); spenders[0] = address(chai);
        targets[1] = address(dai); spenders[1] = address(cdai);
        targets[2] = address(susd); spenders[2] = aaveLpCore;
        targets[3] = address(usdc); spenders[3] = address(cusdc);
        targets[4] = address(usdt); spenders[4] = aaveLpCore;

        for (uint i = 0; i < targets.length; i++) {
            ApproveFrom(_approveFrom).safeApprove(targets[i], spenders[i], uint256(0));
            ApproveFrom(_approveFrom).safeApprove(targets[i], spenders[i], uint256(-1));
        }

    }

    function approve (address token, address l) public {
        uint256 approved = IERC20(token).allowance(address(this), l);
        if (approved > 0) IERC20(token).approve(l, 0);
        IERC20(token).approve(l, uint256(-1));
    }

    function approveBad (address token, address l) public {
        uint256 approved = IERC20NoBool(token).allowance(address(this), l);
        if (approved > 0) IERC20NoBool(token).approve(l, 0);
        IERC20NoBool(token).approve(l, uint256(-1));
    }


}