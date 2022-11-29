// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice An ERC20 Token Contract. This is the Reward token given out by the Controller to stakers.
 * @author Jesper Kristensen (@cryptojesperk)
 */
contract MyToken is Initializable, ERC20Upgradeable, ERC20CappedUpgradeable {
    address private deployer;
    string public constant NAME = "MyToken";
    string public constant SYMBOL = "MYT";
    uint256 private wTokensPerWei;
    mapping(address => bool) private admins;

    event Buy(address indexed buyer, uint256 amount, uint256 price);

    /**
     * @notice Initialize our ERC20 Token contract.
     * @dev Deploying this contract mints initialSupply to the deployer.
     */
    function initialize(uint256 _cap) public initializer {
        wTokensPerWei = 2; // 1 wei buys 2 wTokens; in general, 1 wei buys `wTokens_per_Wei` wTokens.

        __ERC20_init(NAME, SYMBOL);
        __ERC20Capped_init(_cap * 1 ether);

        ERC20Upgradeable._mint(address(this), 100 * 1 ether);
        deployer = msg.sender;
        admins[deployer] = true;
    }

    /**
     * @notice Restrict access to only admins.
     */
    modifier onlyAdmin() {
        require(admins[msg.sender], "unauthorized!");
        _;
    }

    /**
     * @notice Change the price of the Token. This is in units of "wTokens per Wei".
     * @param newPrice the new price to use. If "2" this means you get 2 wToken per 1 wei, or 2 tokens per 1 ether.
     */
    function setPrice(uint256 newPrice) external onlyAdmin {
        wTokensPerWei = newPrice;
    }

    /**
     * @notice Add admin to internal state.
     * @param newAdmin the new admin to add.
     */
    function addAdmin(address newAdmin) external onlyAdmin {
        admins[newAdmin] = true;
    }

    /**
     * @notice Remove admin from internal state.
     * @param adminToRemove the admin to remove.
     * @dev note: Cannot remove deployer (original admin).
     */
    function removeAdmin(address adminToRemove) external onlyAdmin {
        require(adminToRemove != deployer, "invalid admin to remove!");
        admins[adminToRemove] = false;
    }

    /**
     * @notice Admins can mint tokens to anyone.
     */
    function mintToken(address to, uint256 amount) external onlyAdmin {
        _mint(to, amount);

        emit Buy(to, amount, wTokensPerWei);
    }

    /**
     * @notice Buy the Token for ether.
     * @dev if there is an internal supply, send from that, if not: mint new.
     */
    function buyToken() external payable {
        uint256 wTokensToSell = msg.value * wTokensPerWei;

        // do we have internal tokens in our supply?
        if (ERC20Upgradeable.balanceOf(address(this)) >= wTokensToSell) _transfer(address(this), msg.sender, wTokensToSell);
        else _mint(msg.sender, wTokensToSell);

        emit Buy(msg.sender, wTokensToSell, wTokensPerWei);
    }

    /**
     * @dev For an admin to extract tokens out of the contract.
     * @dev meant as an emergency case.
     */
    function withdrawTokensToAdmin() external onlyAdmin {
        _transfer(address(this), msg.sender, ERC20Upgradeable.balanceOf(address(this)));
    }

    /**
     * @dev For an admin to extract ether out of the contract.
     * @dev meant as an emergency case.
     */
    function withdrawFundsToAdmin() external onlyAdmin {
        (bool ok, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(ok, "transfer failed!");
    }

    /**
     * @dev Override super _mint. Adds no new functionality.
     * @param account the account to mint tokens to.
     * @param amount the amount of tokens to mint.
     */
    function _mint(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20CappedUpgradeable)
    {
        super._mint(account, amount);
    }
}
