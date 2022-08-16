// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// TODO: RENAME THE "24 hours" AND GENERALIZE IT TO "CHUNKS OF INTERVALS PASSED".
// TODO: TEST THE IMPLEMENTATION...

/**
 * @notice The Controller contract which receives NFTs as staking and pays an ERC20 Token reward.
 */
contract Controller is IERC721Receiver {

    address immutable internal deployer;
    IERC721Enumerable private stakedNFT;
    mapping(uint256 => address) public staker;  // keep track of who owns what NFT to handle withdrawals

    // track rewards
    IERC20Metadata private rewardToken;  // the token you earn as reward
    uint256 public rewardRate_per_24hrs = 10;  // how many tokens do you receive per staked item per 24 hours
    mapping(address => uint256) public numStaked;
    mapping(uint256 => uint256) stakedAtBlocktimestamp; // (tokenId) => (staking start timestamp)
    mapping(uint256 => uint256) num24hoursCollected; // (tokenId) => (num 24 hours collected)
    uint256 rewardInterval = 24 hours;
    
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
     * @notice Set a new reward rate per `rewardInterval`.
     * @param newRate The new reward rate. Example: newRate = 2. The user earns 2 Tokens per rewardInterval=24 hours, per staked NFT.
     */
    function setRewardRate(uint256 newRate) external {
        rewardRate_per_24hrs = newRate;
    }

    /**
     * @notice Set the token address in the controller.
     * @param _rewardToken the address of the Reward token. This token is rewarded to the NFT staker (the user).
     */
    function setTokenAddress(IERC20Metadata _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
    }

    /**
     * @notice Reset the staking conditions of this Token ID.
     * @param tokenId The ID of the token to reset.
     */
    function _reset(uint tokenId) internal {
        address staker = staker[tokenId];
        delete staker[tokenId];
        numStaked[staker] -= 1;
        delete stakedAtBlocktimestamp[tokenId];
        delete num24hoursCollected[tokenId];
    }

    /**
     * @notice Withdraw the NFT staked into the contract.
     * @param tokenId The NFT to withdraw.
     */
    function withdrawNFT(uint256 tokenId) external {
        require(msg.sender == staker[tokenId], "not authorized to withdraw!");
        
        // reset the NFT staking conditions
        _reset(tokenId);

        stakedNFT.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /**
     * @notice Withdraw the rewards for this user given all their staked tokens.
     */
    function withdrawReward() external {
        require(numStaked[msg.sender] > 0, "not staker in the contract!");
        
        // how many NFTs are owned by the caller in the collection
        uint bal = stakedNFT.balanceOf(msg.sender);
        assert(bal > 0);
        
        uint numFound;
        uint totalNum24Hours; // across all staked NFTs of this user
        for (uint i; i < bal; i++) {
            // get this specific NFT owned by the caller:
            uint thisTokenID = stakedNFT.tokenOfOwnerByIndex(msg.sender, i);

            // is the owner/caller staking this NFT in our contract rn?
            if (staker[thisTokenID] == address(0))
                continue; // ..no
            
            numFound += 1;

            // yes, so collect rewards, count the number of `rewardInterval` for this NFT
            uint256 thisNum24Hours = _compute_num_24hours_single_nft(thisTokenID);

            assert(thisNum24Hours >= num24hoursCollected[thisTokenID]); // panic check

            // and update our rewards collected for this token
            // but subtract everything we have counted in the past for this NFT:
            totalNum24Hours += thisNum24Hours - num24hoursCollected[thisTokenID];
            
            // update the rewards collected for this token
            num24hoursCollected[thisTokenID] += thisNum24Hours;

            if (numFound == numStaked[msg.sender])
                break;
        }

        uint totalReward = totalNum24Hours * rewardRate_per_24hrs;

        rewardToken.transferFrom(address(this), msg.sender, totalReward * (10 ** rewardToken.decimals()));
    }

    /**
     * @notice Compute the number of 24 hour periods passed for a single NFT since staking.
     * @param tokenId the token ID to check.
     * @return the number of 24 hour periods passed for a single NFT since staking.
     */
    function _compute_num_24hours_single_nft(uint tokenId) internal view returns (uint256) {
        uint currTime = block.timestamp;
        uint deltaTime = currTime - stakedAtBlocktimestamp[tokenId];
        if (deltaTime <= 0) return 0;

        uint num24hours = deltaTime % rewardInterval;  // rewardInterval = 24 hours, e.g.

        return num24hours;
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
        numStaked[from] += 1;
        num24hoursCollected[tokenId] = 0;

        return IERC721Receiver.onERC721Received.selector;
    }
}