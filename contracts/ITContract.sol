pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

interface ITContract {
    function ownerOf(uint256) external returns (address);
    function tokenByIndex(uint256) external returns (uint256);
    function tokenURI(uint256) external returns (string memory);
    function freeMint(address, uint256, string memory) external;
}