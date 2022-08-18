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
 * @notice The Controller contract which receives NFTs as staking and pays an ERC20 Token as reward.
 * @author Jesper Kristensen (@cryptojesperk)
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
    uint256 rewardInterval = 24 hours;
    
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
     * @param tokenIdDeleted The ID of the token to be deleted and removed from our staking.
     */
    function _reset(uint tokenIdDeleted) internal {

        address _staker = staker[tokenIdDeleted];
        delete staker[tokenIdDeleted];

        uint lastIndex = numStaked[_staker] - 1;
        lastIndex = lastIndex <= 0 ? 0 : lastIndex;

        numStaked[_staker] -= 1;
        delete stakedAtBlocktimestamp[tokenIdDeleted];
        delete numIntervalsCollected[tokenIdDeleted];

        // now ... the following is a bit tricky:
        // we want to remove in general an element from a list but efficiently
        // so the way we do this is to replace the element removed (indexDeleted) with the last
        // element (at lastIndex) in the list and since we reduced the length of the list above (numStaked)
        // already. So the list will be correct and contain all NFTs staked by the user even after withdrawing this one,
        // so below we are doing this swap (note: we can probably optimize if last index == index deleted):
        uint indexDeleted = tokenIdToGlobalIndex[_staker][tokenIdDeleted];
        uint lastTokenId = globalIndexToTokenId[_staker][lastIndex];
        // make the last token now be pointed to by the just-deleted index:
        tokenIdToGlobalIndex[_staker][lastTokenId] = indexDeleted;
        globalIndexToTokenId[_staker][indexDeleted] = lastTokenId;

        delete tokenIdToGlobalIndex[_staker][tokenIdDeleted];
    }

    /**
     * @notice Withdraw the NFT staked into the contract.
     * @param tokenId The NFT to withdraw.
     */
    function withdrawNFT(uint256 tokenId) external {
        require(msg.sender == staker[tokenId], "not authorized to withdraw!");
        
        // reset the NFT staking conditions
        // this means we do not tally up more rewards for this specific NFT
        _reset(tokenId);

        // now transfer the NFT from us to the user/staker
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
            // pick one of the staked NFTs of this user
            uint thisTokenId = globalIndexToTokenId[msg.sender][i];

            // let's check how many reward intervals this specific NFT has covered since initial staking
            uint256 thisNumIntervals = _compute_num_intervals_single_nft(thisTokenId);
            assert(thisNumIntervals >= numIntervalsCollected[thisTokenId]); // panic check

            // take this most up to date number of intervals covered, but subtract our running counter
            // of past intervals we already accounted for in the past
            // in other words: ensure that each interval passed for this NFT is never double-counted (or multi-counted, to be precise):
            uint newIntervals = thisNumIntervals - numIntervalsCollected[thisTokenId];

            if (newIntervals > 0) {
                // hey, we actually do have some rewards to collect for this specific NFT
                totalNumIntervals += newIntervals;

                // update the rewards collected for this NFT, so that we don't double count
                numIntervalsCollected[thisTokenId] += newIntervals;

                didTokenIdGiveReward[i] = true;  // let's store this for the event to be emitted later
            }
            nftIdsCollectingReward[i] = thisTokenId;
        }

        // now that we have counted all intervals passed by *all* NFTs for this user, we can simply multiply by the reward rate:
        // note that we assume the reward rate is the same for all NFTs:
        uint totalReward = (totalNumIntervals * rewardRate_per_Interval) * (10 ** rewardToken.decimals());

        if (totalReward > 0) {
            // the user earned something!
            rewardToken.mintToken(msg.sender, totalReward);

            // let's log this as well
            emit Reward(msg.sender, totalReward, nftIdsCollectingReward, didTokenIdGiveReward);
        }
    }

    /**
     * @notice Compute the number of `rewardInterval`s passed for a single NFT since staking.
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