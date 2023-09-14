pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AirNFTToken is ERC20 {

    // 1 Billion total supply
    uint tokenTotalSupply = 1000000000;

    constructor() public ERC20("AirNFT Token", "AIRT") {
        _mint(msg.sender, tokenTotalSupply * (10 ** uint256(decimals())));
    }
}
