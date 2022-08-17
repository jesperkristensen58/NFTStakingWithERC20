// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;


import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./MyNFT.sol";
import "./MyToken.sol";

/**
 * @notice The Controller contract which receives NFTs as staking and pays an ERC20 Token reward.
 */
contract Controller is IERC721Receiver {

    address internal immutable deployer;
    MyNFT internal immutable stakedNFT;
    mapping(uint256 => address) private staker;  // keep track of who owns what NFT to handle withdrawals
    mapping(address => mapping(uint256 => uint256)) private globalIndexToTokenId; // (staker) -> (global list index) -> (token ID)
    mapping(address => mapping(uint256 => uint256)) private tokenIdToGlobalIndex; // (staker) -> (token ID) -> (global list index)

    // track rewards
    MyToken private rewardToken;  // the token you earn as reward
    uint256 public rewardRate_per_Interval = 10;  // how many tokens do you receive per staked item per 24 hours
    mapping(address => uint256) private numStaked;
    mapping(uint256 => uint256) stakedAtBlocktimestamp; // (tokenId) => (staking start timestamp)
    mapping(uint256 => uint256) numIntervalsCollected; // (tokenId) => (num 24 hours collected)
    uint256 rewardInterval = 60 seconds;
    
    event Reward(address indexed toStaker, uint256 amount, uint[] nftTokenIds, bool[] didTokenIdGiveReward);

    /**
     * @notice Construct the controller.
     * @param stakedNFTContractAddress The NFT collection address being staked for rewards.
     */
    constructor(MyNFT stakedNFTContractAddress, MyToken _rewardTokenAddress) {
        deployer = msg.sender;
        stakedNFT = MyNFT(stakedNFTContractAddress);
        rewardToken = MyToken(_rewardTokenAddress);
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
        rewardRate_per_Interval = newRate;
    }

    /**
     * @notice Reset the staking conditions of this Token ID.
     * @param tokenIdDeleted The ID of the token to reset.
     */
    function _reset(uint tokenIdDeleted) internal {

        address _staker = staker[tokenIdDeleted];
        staker[tokenIdDeleted] = address(0);

        uint lastIndex = numStaked[_staker] - 1;
        lastIndex = lastIndex <= 0 ? 0 : lastIndex;

        numStaked[_staker] -= 1;
        stakedAtBlocktimestamp[tokenIdDeleted] = 0;
        numIntervalsCollected[tokenIdDeleted] = 0;

        uint indexDeleted = tokenIdToGlobalIndex[_staker][tokenIdDeleted];
        // tokenIdDeleted

        // lastIndex
        uint lastTokenId = globalIndexToTokenId[_staker][lastIndex];

        // make the last token now be pointed to by the just-deleted index:
        tokenIdToGlobalIndex[_staker][lastTokenId] = indexDeleted;
        globalIndexToTokenId[_staker][indexDeleted] = lastTokenId;

        tokenIdToGlobalIndex[_staker][tokenIdDeleted] = 0;
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
        uint _numStaked = numStaked[msg.sender];

        bool[] memory didTokenIdGiveReward = new bool[](_numStaked);
        uint[] memory nftIdsCollectingReward = new uint[](_numStaked);
        
        uint totalNumIntervals; // across all staked NFTs of this user
        for (uint i; i < _numStaked; i++) {
            uint thisTokenId = globalIndexToTokenId[msg.sender][i];

            // yes, so collect rewards, count the number of `rewardInterval` for this NFT
            uint256 thisNumIntervals = _compute_num_intervals_single_nft(thisTokenId);
            assert(thisNumIntervals >= numIntervalsCollected[thisTokenId]); // panic check

            // and update our rewards collected for this token
            // but subtract everything we have counted in the past for this NFT:
            uint newIntervals = thisNumIntervals - numIntervalsCollected[thisTokenId];

            if (newIntervals > 0) {
                totalNumIntervals += newIntervals;

                // update the rewards collected for this token
                numIntervalsCollected[thisTokenId] += newIntervals;

                didTokenIdGiveReward[i] = true;
            }
            nftIdsCollectingReward[i] = thisTokenId;
        }

        uint totalReward = (totalNumIntervals * rewardRate_per_Interval) * (10 ** rewardToken.decimals());

        if (totalReward > 0) {
            rewardToken.mintToken(msg.sender, totalReward);

            emit Reward(msg.sender, totalReward, nftIdsCollectingReward, didTokenIdGiveReward);
        }
    }

    /**
     * @notice Compute the number of 24 hour periods passed for a single NFT since staking.
     * @param tokenId the token ID to check.
     * @return the number of `rewardInterval` intervals passed for a single NFT since staking (e.g. 24 hours).
     */
    function _compute_num_intervals_single_nft(uint tokenId) internal view returns (uint256) {
        uint currTime = block.timestamp;
        uint deltaTime = currTime - stakedAtBlocktimestamp[tokenId];
        if (deltaTime <= 0) return 0;

        uint numIntervals = deltaTime / rewardInterval;  // rewardInterval = 24 hours, e.g.

        return numIntervals;
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

        // keep track of who owns which nfts
        staker[tokenId] = from;  // log the owner of the NFT
        globalIndexToTokenId[from][numStaked[from]] = tokenId;
        tokenIdToGlobalIndex[from][tokenId] = numStaked[from]; // where is the tokenId in the global index, for this staker
        numStaked[from] += 1;
        
        // for rewards
        stakedAtBlocktimestamp[tokenId] = block.timestamp;
        numIntervalsCollected[tokenId] = 0;

        return IERC721Receiver.onERC721Received.selector;
    }
}