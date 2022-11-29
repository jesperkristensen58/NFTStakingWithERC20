// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./MyToken.sol";

/**
 * @notice An ERC20 Token Factory Contract.
 * @notice Create new ERC20 Token contracts. Built to compare gas costs between naive creation vs the clones pattern.
 * @author Jesper Kristensen (@cryptojesperk)
 */
contract MyTokenFactory {
    address public immutable erc20Implementation;

    /**
     * @notice Create the ERC20 Factory.
     * @param _erc20Implementation the implementation contract of the ERC20.
     * @dev spins out new ERC20 contracts with various caps.
     */
    constructor(address _erc20Implementation) {
        erc20Implementation = _erc20Implementation;
    }

    /**
     * @notice Create a new ERC20 token contract with a specific cap.
     * @notice Uses the Clone structure.
     * @param _cap the cap of the ERC20.
     */
    function createNewERC20WithClone(uint256 _cap) external returns (MyToken) {
        // use the clones pattern against the internally stored ERC20 contract address
        MyToken theClone = MyToken(ClonesUpgradeable.clone(erc20Implementation));
        theClone.initialize(_cap);

        return theClone;
    }

    /**
     * @notice Create a new ERC20 token contract with a specific cap.
     * @notice Does not use the Clone structure.
     * @param _cap the cap of the ERC20.
     */
    function createNewERC20(uint256 _cap) external returns (MyToken) {
        MyToken theClone = new MyToken();
        theClone.initialize(_cap);

        return theClone;
    }
}