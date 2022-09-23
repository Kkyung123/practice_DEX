// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/dex.sol";
import "../src/ERC20Mintable.sol";
import "forge-std/src/console2.sol";
import "forge-std/src/Test.sol";

contract DexTest is Test{
    DEXs public Dex1;
    ERC20Mintable public token1;
    ERC20Mintable public token2;
    DEXs public token;
    
    address internal one = address(1);
    address internal two = address(2);
    address internal three = address(3);
    address internal four = address(4);


    function setUp() public{
        token1 = new ERC20Mintable("kkyongi", "KYU1");
        token2 = new ERC20Mintable("kkyongii", "KYU2");

        Dex1 = new DEXs(address(token1), address(token2));

        token1.mint(one, 200);
        token2.mint(one, 200);

        token1.mint(two, 300);
        token2.mint(two, 50);

        token1.mint(three, 200);
        token2.mint(three, 0);

        token1.mint(four, 0);
        token2.mint(four, 200);
      
    }

     function testFirstAddLiquidity() public {
         vm.startPrank(one);
         token1.approve(address(Dex1), 200);
         token2.approve(address(Dex1), 200);
        
         Dex1.addLiquidity(100, 100, 0);

         assertEq(Dex1.balanceOf(one), 100); 
         assertEq(token1.balanceOf(one), 100); 
         assertEq(token2.balanceOf(one), 100); 

         assertEq(token1.balanceOf(address(Dex1)), 100); 
         assertEq(token2.balanceOf(address(Dex1)), 100); 
     }

     function testFailFirstAddLiauidity() public {
         vm.startPrank(one);
         token1.approve(address(Dex1), 100);
         token2.approve(address(Dex1), 100);

         Dex1.addLiquidity(100, 50, 0);
         vm.expectRevert("The proportion is broken");
     }

     function testRemoveLiquidity() public {
         testFirstAddLiquidity();

         Dex1.removeLiquidity(50, 0, 0);
        
         assertEq(token1.balanceOf(address(one)), 150); 
         assertEq(token2.balanceOf(address(one)), 150);
     }
    
     function testSwap() public{
         testFirstAddLiquidity();

         Dex1.swap(50, 0, 0);
         assertEq(token1.balanceOf(address(one)), 50);
         assertEq(token2.balanceOf(address(one)), 134);
     }
     
    receive() external payable {}
}