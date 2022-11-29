// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "hardhat/console.sol";

/**
 * @notice An NFT Contract with God Mode: ability to transfer NFTs between accounts forcefully. A main contract/controller (not seen here) can receive ERC20 Tokens (not shown here) to mint these NFTs in here.
 * @notice Anyone can mint these NFTs. Then, they can send them to the Controller.sol contract to earn MyToken rewards.
 * @author Jesper Kristensen (@cryptojesperk)
 */
contract MyNFTGodMode is Initializable, OwnableUpgradeable, ERC721Upgradeable {
    string public constant NAME = "MyNFT";
    string public constant SYMBOL = "MNT";
    uint256 public tokenSupply; // will also act as the NFT id
    address public _owner; // needs to be after previous storage variables above (to upgrade)

    // emit a mint event
    event Mint(address indexed receiver, uint256 tokenId);

    /**
     * @notice Initialize our NFT contract.
     * @dev the NFT contract is controlled by the controller contract which is the only one that can mint.
     */
    function initialize() public initializer {
        __ERC721_init(NAME, SYMBOL);
        __Ownable_init();
    }

    /**
     * @notice Force transfer an NFT between accounts ("God mode"). Only the NFT contract owner can do this.
     * @notice NOTE that this will break the controller contract and the internal accounting (who owns which staked NFT)
     * @param from the account to transfer from
     * @param to the account to transfer to
     * @param tokenId the NFT id to transfer
     */
    function forceTransfer(address from, address to, uint256 tokenId) external onlyOwner {
        // we are god: overrule owner or any approved address
        _transfer(from, to, tokenId);
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
