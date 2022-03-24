// SPDX-License-Identifier: MIT
// DEPLOYMENT CODE : 22022022_CFX

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Neko is ERC20 {
    constructor() ERC20("Maneki-Neko", "NEKO") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}
