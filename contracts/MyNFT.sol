// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice An NFT Contract. A main contract (not seen here) can receive ERC20 Tokens (not shown here) to mint these NFTs in here.
 */
contract MyNFT is ERC721, ERC721Enumerable {

    string public constant NAME = "MyNFT";
    string public constant SYMBOL = "MNT";
    uint256 public tokenSupply;
    mapping(address => bool) isAdmin;
    address immutable internal deployer;

    event Mint(address indexed receiver, uint tokenId);

    /**
     * @notice Construct our NFT contract.
     * @dev the NFT contract is controlled by the controller contract which is the only one that can mint.
     */
    constructor() ERC721(NAME, SYMBOL) {
        deployer = msg.sender;
        isAdmin[deployer] = true;
    }

    /**
     * @notice Restrict functionality to admins.
     */
    modifier onlyAdmin {
        require(isAdmin[msg.sender],
        "MyNFT: not an admin!");
        _;
    }

    /**
     * @notice Add an admin to the internal admin list.
     * @param newAdmin the new admin to add.
     */
    function addAdmin(address newAdmin) external onlyAdmin {
        isAdmin[newAdmin] = true;
    }

    /**
     * @notice Remove an admin from the internal admin list.
     * @param admin the admin to remove.
     */
    function removeAdmin(address admin) external onlyAdmin {
        require(admin != deployer, "cannot remove owner from admin list!");
        isAdmin[admin] = false;
    }

    /**
     * @notice Mint a new NFT from this collection to the receiver.
     * @dev Only an admin can create a new NFT.
     * @param receiver The receiver of the new NFT.
     * @return the ID of the NFT just minted.
     */
    function mint(address receiver) external onlyAdmin returns (uint256) {
        uint currentSupply = tokenSupply;
        _safeMint(receiver, currentSupply);

        tokenSupply++;

        emit Mint(receiver, currentSupply);

        return currentSupply;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}