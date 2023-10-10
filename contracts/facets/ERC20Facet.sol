// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";

// Hint: In the Diamond Standard we are basically separating storage from Logic. The storage is set to the struct of the Diamond Storage while the logic is implemented in the facet.

contract ERC20Facet {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    // Hint: All constant and immutable state variables can't change thus we don't move them to the Diamond Storage...LibDiamond.sol
    uint8 public immutable decimals;
    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    constructor(uint8 _decimals) {
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /**
     * GETTER FUNCTIONS
     *
     *  Hint: Since you have moved the storage from the ERC20Facet the DiamondStorage() struct, and there is no visibility in struct you will have to write the getter function for each of the stroage variable
     */

    function name() public view returns (string memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.name;
    }

    function balanceOf(address owner) public view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.balanceOf[owner];
    }

    function symbol() public view returns (string memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.symbol;
    }

    function totalSupply() public view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.totalSupply;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.allowance[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        /**
         * Hint: DiamondStorage is the  struct DiamondStorage {}
         * diamondStorage() is a pure function that returns the DiamondStorage struct....
         *  function diamondStorage() internal pure returns (DiamondStorage storage ds){}
         */

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            ds.balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        uint256 allowed = ds.allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            ds.allowance[from][msg.sender] = allowed - amount;

        ds.balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            ds.balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(ds.name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal virtual {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            ds.balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            ds.totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}
