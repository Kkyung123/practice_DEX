// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/forge-std/src/console.sol";

contract Dex is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 _tokenX;
    IERC20 _tokenY;

    uint k;
    constructor(address tokenX, address tokenY) ERC20("DreamAcademy DEX LP token", "DA-DEX-LP") {
        require(tokenX != tokenY, "DA-DEX: Tokens should be different");

        _tokenX = IERC20(tokenX);
        _tokenY = IERC20(tokenY);
    }

    function swap(uint256 tokenXAmount, uint256 tokenYAmount, uint256 tokenMinimumOutputAmount)
        external
        returns (uint256 outputAmount)
    {   
        if(tokenXAmount > tokenYAmount) {
            require(tokenXAmount != 0 && tokenYAmount == 0);
            uint ireserve = _tokenX.balanceOf(address(this));
            uint oreserve = _tokenY.balanceOf(address(this));
       
            outputAmount = (oreserve - ( _tokenX.balanceOf(address(this)) * _tokenY.balanceOf(address(this)) / (ireserve + tokenXAmount) )) * 999 / 1000;
            require(outputAmount >= tokenMinimumOutputAmount, "exceed minimum amount");
            
            _tokenX.transferFrom(msg.sender, address(this), tokenXAmount);
            _tokenY.transfer(msg.sender, outputAmount);
        } else {
            require(tokenXAmount == 0 && tokenYAmount !=0);
            uint ireserve = _tokenY.balanceOf(address(this));
            uint oreserve = _tokenX.balanceOf(address(this));

            outputAmount = (oreserve - ( _tokenX.balanceOf(address(this)) * _tokenY.balanceOf(address(this)) / (ireserve + tokenYAmount) )) * 999 / 1000;
            require(outputAmount >= tokenMinimumOutputAmount, "exceed minimum amount");
            
            _tokenY.transferFrom(msg.sender, address(this), tokenYAmount);
            _tokenX.transfer(msg.sender, outputAmount);
        }

        k = _tokenX.balanceOf(address(this)) * _tokenY.balanceOf(address(this));

    }

    // function _swap(address input, address output, uint charge, uint amountMin) internal returns(uint outputAmount) {
    //     uint ireserve = IERC20(input).balanceOf(address(this));
    //     uint oreserve = IERC20(output).balanceOf(address(this));

    //     uint _input = charge - (charge / 1000);
    //     outputAmount = oreserve - ( k / (ireserve + _input) );
    //     require(outputAmount >= amountMin, "exceed minimum amount");

    //     IERC20(input).transferFrom(msg.sender, address(this), _input);
    //     IERC20(output).transfer(msg.sender, outputAmount);
    // }

    function addLiquidity(uint256 tokenXAmount, uint256 tokenYAmount, uint256 minimumLPTokenAmount)
        external
        returns (uint256 LPTokenAmount)
    {
        //require(_tokenX.balanceOf(msg.sender) >= tokenXAmount, "invalid balance");
        //require(_tokenY.balanceOf(msg.sender) >= tokenYAmount, "invalid balance");
        uint reserveX = _tokenX.balanceOf(address(this));
        uint reserveY = _tokenY.balanceOf(address(this));

        _tokenX.transferFrom(msg.sender, address(this), tokenXAmount);
        _tokenY.transferFrom(msg.sender, address(this), tokenYAmount);
        k = _tokenX.balanceOf(address(this)) * _tokenY.balanceOf(address(this));

        if (totalSupply() == 0) {
            LPTokenAmount = sqrt(tokenXAmount * tokenYAmount);
        } else {
            LPTokenAmount = ((tokenXAmount * totalSupply() / reserveX) < (tokenYAmount * totalSupply() / reserveY)) ? (tokenXAmount * totalSupply() / reserveX) : (tokenYAmount * totalSupply() / reserveY);
        }

        require(LPTokenAmount > 0, "zero amount");
        require(LPTokenAmount >= minimumLPTokenAmount, "exceed minimum amount");

        _mint(msg.sender, LPTokenAmount);
    }

    function removeLiquidity(uint256 LPTokenAmount, uint256 minimumTokenXAmount, uint256 minimumTokenYAmount)
        external returns (uint256 transferX, uint256 transferY)
    {
        require(LPTokenAmount < totalSupply(), "invalid LPTokenAmount");
        uint reserveX = IERC20(_tokenX).balanceOf(address(this));
        uint reserveY = IERC20(_tokenY).balanceOf(address(this));   

        transferX = (LPTokenAmount * reserveX) / totalSupply();
        transferY = (LPTokenAmount * reserveY) / totalSupply();

        //require(transferX > 0 && transferY > 0, "zero amount");
        require(transferX >= minimumTokenXAmount && transferY >= minimumTokenYAmount, "exceed minimum amount");
        
        _burn(msg.sender, LPTokenAmount);

        _tokenX.transfer(msg.sender, transferX);
        _tokenY.transfer(msg.sender, transferY);

        k = _tokenX.balanceOf(address(this)) * _tokenY.balanceOf(address(this));
    }

    // From UniSwap core
    function sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
