// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice An NFT Contract. A main contract (not seen here) can receive ERC20 Tokens (not shown here) to mint these NFTs in here.
 */
contract MyToken is ERC20, ERC20Capped, Ownable {

    string public constant NAME = "MyToken";
    string constant public SYMBOL = "MYT";
    uint256 constant private CAP = 1_000_000;
    uint256 private wTokens_per_Wei = 2;  // 1 wei buys 2 wTokens; in general, 1 wei buys `wTokens_per_Wei` wTokens.

    event Buy(address indexed buyer, uint amount, uint price);

    /**
     * @notice Construct our ERC20 Token contract.
     * @param initialSupply The initial supply of tokens (not wTokens, but Tokens).
     * @dev Deploying this contract mints initialSupply to the deployer.
     */
    constructor(uint256 initialSupply) ERC20(NAME, SYMBOL) ERC20Capped(CAP * 10 ** decimals()) {
        // initially mint to this contract some initial supply
        ERC20._mint(address(this), initialSupply * 10 ** decimals());
    }

    /**
     * @notice Change the price of the Token. This is in units of "wTokens per Wei".
     * @param newPrice the new price to use. If "2" this means you get 2 wToken per 1 wei, or 2 tokens per 1 ether.
     */
    function setPrice(uint newPrice) external onlyOwner {
        wTokens_per_Wei = newPrice;
    }

    /**
     * @notice Buy the Token for ether.
     * @dev if there is an internal supply, send from that, if not: mint new.
     */
    function buyToken() external payable {
        uint256 wTokensToSell = msg.value * wTokens_per_Wei;

        // do we have internal tokens in our supply?
        if (ERC20.balanceOf(address(this)) >= wTokensToSell)
            _transfer(address(this), msg.sender, wTokensToSell);
        else
            _mint(msg.sender, wTokensToSell);
        
        emit Buy(msg.sender, wTokensToSell, wTokens_per_Wei);
    }

    /**
     * @notice Override super _mint. Adds no new functionality.
     * @param account the account to mint tokens to.
     * @param amount the amount of tokens to mint.
     */
    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }
}