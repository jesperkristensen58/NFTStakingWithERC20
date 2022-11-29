// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

/**
 * @notice An NFT Contract. A main contract/controller (not seen here) can receive ERC20 Tokens (not shown here) to mint these NFTs in here.
 * @notice Anyone can mint these NFTs. Then, they can send them to the Controller.sol contract to earn MyToken rewards.
 * @author Jesper Kristensen (@cryptojesperk)
 */
contract MyNFT is ERC721Upgradeable {
    string public constant NAME = "MyNFT";
    string public constant SYMBOL = "MNT";
    uint256 public tokenSupply; // will also act as the NFT id

    // emit a mint event
    event Mint(address indexed receiver, uint256 tokenId);

    /**
     * @notice Initialize our NFT contract.
     * @dev the NFT contract is controlled by the controller contract which is the only one that can mint.
     */
    function initialize() public initializer {
        __ERC721_init(NAME, SYMBOL);
    }

    /**
     * @notice Mint a new NFT from this collection to the receiver.
     */
    function mint() external {
        uint256 currentSupply = tokenSupply;
        tokenSupply++;

        emit Mint(msg.sender, currentSupply);

        _safeMint(msg.sender, currentSupply);
    }
}
