// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @notice An NFT Contract. A main contract/controller (not seen here) can receive ERC20 Tokens (not shown here) to mint these NFTs in here.
 * @author Jesper Kristensen (@cryptojesperk)
 */
contract MyNFT is ERC721, ERC721Enumerable {

    string public constant NAME = "MyNFT";
    string public constant SYMBOL = "MNT";
    uint256 public tokenSupply; // will also act as the NFT id

    event Mint(address indexed receiver, uint tokenId);

    /**
     * @notice Construct our NFT contract.
     * @dev the NFT contract is controlled by the controller contract which is the only one that can mint.
     */
    constructor() ERC721(NAME, SYMBOL) {}

    /**
     * @notice Mint a new NFT from this collection to the receiver.
     */
    function mint() external {
        uint currentSupply = tokenSupply;
        tokenSupply++;

        _safeMint(msg.sender, currentSupply);

        emit Mint(msg.sender, currentSupply);
    }

    /**
     * @dev Override the _beforeTokenTransfer
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Override the supportsInterface
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}