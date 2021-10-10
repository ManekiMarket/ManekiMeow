// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.1.0/token/ERC20/ERC20.sol";

contract Neko2 is ERC20 {
    constructor() ERC20("Maneki-Neko", "NEKO") {
        _mint(msg.sender, 1000000000000000 * 10 ** decimals());
    }
}
