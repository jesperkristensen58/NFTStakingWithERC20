// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// local contracts
import "./MyNFT.sol";

/**
 * @notice The Controller contract which receives NFTs as staking and pays an ERC20 Token reward.
 */
contract Controller is IERC721Receiver {

    address immutable internal deployer;
    IERC721 private stakedNFT;
    mapping(uint256 => address) public staker;  // keep track of who owns what NFT to handle withdrawals

    // track rewards
    IERC20 private rewardToken;  // the token you earn as reward
    uint256 public rewardRate_per_24hrs = 10;  // how many tokens do you receive per staked item per 24 hours
    mapping(uint256 => uint256) stakedAtBlocktimestamp; // (tokenId) => (staking start timestamp)
    
    event Buy(address indexed buyer, uint256 amountTokens, uint256 indexed nftIDBought);

    /**
     * @notice Construct the controller.
     */
    constructor() {
        deployer = msg.sender;
    }

    /**
     * @notice create our own modifier for the deployer/owner.
     * @dev we don't want Ownable since we don't want renounce, transferOwnership, etc.
     */
    modifier onlyOwner {
        require(msg.sender == deployer, "not owner!");
        _;
    }

    /**
     * @notice Set the token address in the controller.
     * @param _rewardToken the address of the Reward token. This token is rewarded to the NFT staker (the user).
     */
    function setTokenAddress(IERC20 _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
    }

    function withdrawNFT(uint256 tokenId) external {
        require(msg.sender == staker[tokenId], "not authorized to withdraw!");
        stakedNFT.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawReward() external {
        // TODO: COMPUTE REWARD BASED ON STAKING TIME VS CURRENT TIME!
        
    }

    /**
     * @notice Implement gas-efficient version of NFT transfer to the contract.
     * @dev when NFT is transferred to this contract, this function is automatically called, so make state changes here.
     * @dev this implies that we don't need a separate "depositNFT" function.
     */
    function onERC721Received(
        address from,
        address,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        staker[tokenId] = from;  // log the owner of the NFT
        stakedAtBlocktimestamp[tokenId] = block.timestamp;

        return IERC721Receiver.onERC721Received.selector;
    }
}