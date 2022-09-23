// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "./Math.sol";

contract DEX is IERC20, ERC20 {

    address public tokenX;
    address public tokenY;
    uint112 private reserve0;           
    uint112 private reserve1;
    uint public k; // x*y=k
    uint private unlocked = 1;

    constructor(address _tokenX, address _tokenY) ERC20("kkyung", "KYU"){
        tokenX = _tokenX;
        tokenY = _tokenY;
    }

    function getReserves() public returns (uint112 _reserve0, uint112 _reserve1) {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function swap(uint256 tokenXAmount, uint256 tokenYAmount, uint256 tokenMinimumOutputAmount) external lock returns (uint256 outputAmount) {
        (address input, address output, uint _input, uint _output) =
        (tokenXAmount < tokenYAmount) ? (tokenY, tokenX, tokenYAmount, tokenXAmount) : (tokenX, tokenY, tokenXAmount, tokenYAmount);

        require(_input != 0 && _output == 0, "invalid token Amount");
        return _swap(input, output, _input, tokenMinimumOutputAmount);
    }

    function _swap(address input, address output, uint charge, uint amountMin) internal returns(uint outputAmount) {
        uint ireserve = IERC20(input).balanceOf(address(this));
        uint oreserve = IERC20(output).balanceOf(address(this));

        uint _input = charge - (charge / 1000);
        outputAmount = oreserve - ( k / (ireserve + _input) );
        require(outputAmount >= amountMin, "exceed minimum amount");

        IERC20(input).transferFrom(msg.sender, address(this), _input);
        IERC20(output).transfer(msg.sender, outputAmount);
    }

    function addLiquidity(uint256 tokenXAmount, uint256 tokenYAmount, uint256 minimumLPTokenAmount) external returns (uint256 LPTokenAmount){
        require(IERC20(tokenX).balanceOf(msg.sender) >= tokenXAmount, "invalid balance");
        require(IERC20(tokenY).balanceOf(msg.sender) >= tokenYAmount, "invalid balance");
        uint reserveX = IERC20(tokenX).balanceOf(address(this));
        uint reserveY = IERC20(tokenY).balanceOf(address(this));

        IERC20(tokenX).transferFrom(msg.sender, address(this), tokenXAmount);
        IERC20(tokenY).transferFrom(msg.sender, address(this), tokenYAmount);
        k = (reserveX + tokenXAmount) * (reserveY + tokenYAmount);

        if (totalSupply() == 0) {
            LPTokenAmount = Math.sqrt(tokenXAmount * tokenYAmount);
        } else {
            LPTokenAmount = Math.min(tokenXAmount * totalSupply() / reserveX, tokenYAmount * totalSupply() / reserveY);
        }

        require(LPTokenAmount > 0, "zero amount");
        require(LPTokenAmount >= minimumLPTokenAmount, "exceed minimum amount");

        _mint(msg.sender, LPTokenAmount);
    }   

    function removeLiquidity(uint256 LPTokenAmount, uint256 minimumTokenXAmount, uint256 minimumTokenYAmount) external{
        require(LPTokenAmount < totalSupply(), "invalid LPTokenAmount");
        uint reserveX = IERC20(tokenX).balanceOf(address(this));
        uint reserveY = IERC20(tokenY).balanceOf(address(this));   

        uint amountX = (LPTokenAmount * reserveX) / totalSupply();
        uint amountY = (LPTokenAmount * reserveY) / totalSupply();

        require(amountX > 0 && amountY > 0, "zero amount");
        require(amountX > minimumTokenXAmount && amountY > minimumTokenYAmount, "exceed minimum amount");
        
        _burn(msg.sender, LPTokenAmount);

        IERC20(tokenX).transfer(msg.sender, amountX);
        IERC20(tokenY).transfer(msg.sender, amountY);

        k = (reserveX - amountX) * (reserveY - amountY);
    }

}