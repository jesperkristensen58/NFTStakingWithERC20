// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./MyNFT.sol";
import "./MyToken.sol";

/**
 * @notice The Controller contract which receives NFTs as staking and pays an ERC20 Token as reward.
 * @author Jesper Kristensen (@cryptojesperk)
 */
contract Controller is IERC721Receiver {

    address internal immutable deployer;
    MyNFT internal immutable stakedNFT;

    // keep track of which NFTs are staked by which user
    mapping(uint256 => address) private staker;  // keep track of who owns what NFT to handle withdrawals
    mapping(address => mapping(uint256 => uint256)) private listIndexToTokenId; // (staker) -> (list index) -> (token ID)
    mapping(address => mapping(uint256 => uint256)) private tokenIdToListIndex; // (staker) -> (token ID) -> (list index)

    // track rewards per NFT
    MyToken private rewardToken;  // the token you earn as reward
    uint256 public rewardRatePerInterval = 10;  // how many tokens do you receive per staked item per 24 hours
    mapping(address => uint256) private numStaked;
    mapping(uint256 => uint256) private stakedAtBlocktimestamp; // (tokenId) => (staking start timestamp)
    mapping(uint256 => uint256) private numIntervalsAlreadyCollected; // (tokenId) => (num 24 hours collected)
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
    function setRewardRate(uint256 newRate) external onlyOwner {
        rewardRatePerInterval = newRate;
    }

    /**
     * @notice Reset the NFT Tracking State when the user withdraws an NFT from the contract.
     * @param tokenIdDeleted The ID of the token to be deleted and removed from our staking.
     */
    function _resetNFTTrackingStateOnWithdrawal(uint tokenIdDeleted) internal {

        address _staker = staker[tokenIdDeleted];
        delete staker[tokenIdDeleted];

        uint lastIndex = numStaked[_staker] - 1;

        numStaked[_staker] -= 1;
        delete stakedAtBlocktimestamp[tokenIdDeleted];
        delete numIntervalsAlreadyCollected[tokenIdDeleted];

        // now ... the following is a bit tricky:
        // we want to remove in general an element from a list but efficiently
        // so the way we do this is to replace the element removed (indexDeleted) with the last
        // element (at lastIndex) in the list and since we reduced the length of the list above (numStaked)
        // already. So the list will be correct and contain all NFTs staked by the user even after withdrawing this one,
        // so below we are doing this swap (note: we can probably optimize if last index == index deleted):
        uint indexDeleted = tokenIdToListIndex[_staker][tokenIdDeleted];
        uint lastTokenId = listIndexToTokenId[_staker][lastIndex];
        // make the last token now be pointed to by the just-deleted index:
        tokenIdToListIndex[_staker][lastTokenId] = indexDeleted;
        listIndexToTokenId[_staker][indexDeleted] = lastTokenId;

        delete tokenIdToListIndex[_staker][tokenIdDeleted];
    }

    /**
     * @notice Withdraw the NFT staked into the contract.
     * @param tokenId The NFT to withdraw.
     */
    function withdrawNFT(uint256 tokenId) external {
        require(msg.sender == staker[tokenId], "not authorized to withdraw!");
        
        // reset the NFT staking conditions
        // this means we do not tally up more rewards for this specific NFT
        _resetNFTTrackingStateOnWithdrawal(tokenId);

        // now transfer the NFT from us to the user/staker
        stakedNFT.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /**
     * @notice Withdraw the rewards for this user given all their staked tokens.
     */
    function withdrawReward() external {
        require(numStaked[msg.sender] > 0, "not staker in the contract!");
        uint _numStaked = numStaked[msg.sender];

        uint[] memory whichTokenId = new uint[](_numStaked);
        bool[] memory didTokenIdGiveReward = new bool[](_numStaked);
        
        uint totalNetNewIntervalsAllNFTs; // across all staked NFTs of this user
        for (uint i; i < _numStaked; i++) {
            // pick one of the staked NFTs of this user
            uint thisTokenId = listIndexToTokenId[msg.sender][i];

            // let's check how many reward intervals this specific NFT has covered since initial staking
            // first, how many intervals have passed in total for this NFT since it was staked...
            uint256 thisTotalNumIntervals = _computeGlobalNumIntervalsSingleNFT(thisTokenId);

            // take this most up to date number of intervals covered, but subtract our running counter
            // of past intervals we already accounted for
            // in other words: ensure that each interval passed for this NFT is never
            // double-counted (or multi-counted, to be precise):
            uint newIntervals = thisTotalNumIntervals - numIntervalsAlreadyCollected[thisTokenId];

            // tally up the total net new intervals across all staked NFTs
            totalNetNewIntervalsAllNFTs += newIntervals;

            // update the intervals already collected for this NFT, so that we don't double count
            numIntervalsAlreadyCollected[thisTokenId] += newIntervals;

            whichTokenId[i] = thisTokenId;

            if (newIntervals > 0)
                didTokenIdGiveReward[i] = true;
        }

        // now that we have counted all intervals passed by *all* NFTs for this user, we can simply multiply by the reward rate:
        // note that we assume the reward rate is the same for all NFTs:
        uint totalReward = (totalNetNewIntervalsAllNFTs * rewardRatePerInterval) * 1 ether;

        // design decision: do not spend gas on a zero-value transfer
        if (totalReward > 0)
            rewardToken.mintToken(msg.sender, totalReward);  // the user earned tokens

        // let's log all this, even if totalReward is zero
        emit Reward(msg.sender, totalReward, whichTokenId, didTokenIdGiveReward);
    }

    /**
     * @notice Compute the number of `rewardInterval`s passed for a single NFT since staking.
     * @param tokenId the token ID to check.
     * @return the number of `rewardInterval` intervals passed for a single NFT since staking (e.g. 24 hours).
     */
    function _computeGlobalNumIntervalsSingleNFT(uint tokenId) internal view returns (uint256) {
        uint deltaTime = block.timestamp - stakedAtBlocktimestamp[tokenId];
        if (deltaTime == 0) return 0; // safeMath ensures it's not < 0

        return deltaTime / rewardInterval;  // rewardInterval = 24 hours, e.g.;
    }

    /**
     * @dev For the owner to extract ether out of the contract if needed.
     * @dev meant as an emergency case.
     */
    function withdrawFundsToAdmin() external onlyOwner {
        (bool ok,) = payable(msg.sender).call{value: address(this).balance}("");
        require(ok, "transfer failed!");
    }

    /**
     * @notice Implement gas-efficient version of NFT transfer to the contract.
     * @dev when NFT is transferred to this contract, this function is automatically called, so make state changes here.
     * @dev this implies that we don't need a separate "depositNFT" function.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {

        // keep track of who owns which nfts
        staker[tokenId] = from;  // log the owner of the NFT
        listIndexToTokenId[from][numStaked[from]] = tokenId;
        tokenIdToListIndex[from][tokenId] = numStaked[from]; // where is the tokenId in the global index, for this staker
        numStaked[from] += 1;
        
        // for rewards
        stakedAtBlocktimestamp[tokenId] = block.timestamp;
        delete numIntervalsAlreadyCollected[tokenId]; // make sure this is reset

        return IERC721Receiver.onERC721Received.selector;
    }
}