// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/Diamond.sol";
import "../contracts/facets/ERC20Facet.sol";
import "./helpers/DiamondUtils.sol";

contract DiamondDeployer is DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    ERC20Facet erc20Facet;

    string name = "MarsEnergy";
    string symbol = "Mars";
    uint8 public immutable decimals = 18;

    address user1 = vm.addr(0x1);
    address user2 = vm.addr(0x2);

    address user3;
    address user4;

    uint256 privateKey3;
    uint256 privateKey4;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet), name, symbol);
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        erc20Facet = new ERC20Facet(decimals);

        (user3, privateKey3) = mkaddr("USER3");
        (user4, privateKey4) = mkaddr("user4");

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        // ERC20Facet
        cut[2] = (
            FacetCut({
                facetAddress: address(erc20Facet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ERC20Facet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function testERC20Facet_Name() public {
        // binding the contract type and the diamond address...This is like binding the ABI to an address, becuase the Diamond itself does not contain the function, name(). its only the ERC20Facet that contains the function name(),but you are not calling name on the facet, you are calling it on the Diamond Hint: ERC20Facet contains the ABI, while Diamond contains the storage.

        assertEq(ERC20Facet(address(diamond)).name(), name);

        // Hint: Since you have moved the storage from the ERC20Facet the DiamondStorage() struct, and there is no visibility in struct you will have to write the getter function for each of the stroage variable
    }

    function testERC20Facet_Symbol() public {
        assertEq(ERC20Facet(address(diamond)).symbol(), symbol);
    }

    function testERC20Facet_Transfer() public {
        vm.startPrank(user1);

        uint256 mintAmout = 10000e18;
        uint256 transferAmount = 50e18;
        uint256 balanceAfterTransfer = mintAmout - transferAmount;

        ERC20Facet(address(diamond)).mint(user1, mintAmout);

        ERC20Facet(address(diamond)).transfer(user2, transferAmount);

        assertEq(
            ERC20Facet(address(diamond)).balanceOf(user1),
            balanceAfterTransfer
        );
        assertEq(ERC20Facet(address(diamond)).balanceOf(user2), transferAmount);
    }

    function testERC20Facet_TotalSupply() public {
        vm.prank(user1);

        uint256 mintAmount = 2000e18;
        ERC20Facet(address(diamond)).mint(user1, mintAmount);

        assertEq(ERC20Facet(address(diamond)).totalSupply(), mintAmount);
    }

    function testERC20Facet_Mint() public {
        uint256 mintAmount = 5000e18;
        ERC20Facet(address(diamond)).mint(user1, mintAmount);
        assertEq(
            ERC20Facet(address(diamond)).totalSupply(),
            ERC20Facet(address(diamond)).balanceOf(user1)
        );
    }

    function testERC20Facet_Burn() public {
        uint256 mintAmount = 5000e18;
        uint256 burnAmount = 200e18;
        uint256 currentBalance = mintAmount - burnAmount;

        testERC20Facet_Mint();
        assertEq(ERC20Facet(address(diamond)).totalSupply(), mintAmount);

        ERC20Facet(address(diamond)).burn(user1, burnAmount);

        assertEq(ERC20Facet(address(diamond)).balanceOf(user1), currentBalance);
    }

    function testERC20Facet_Allowance() public {
        vm.prank(user1);

        uint256 approvalAmount = 5000;
        ERC20Facet(address(diamond)).approve(user2, approvalAmount);

        assertEq(
            ERC20Facet(address(diamond)).allowance(user1, user2),
            approvalAmount
        );
    }

    function testERC20Facet_Approve() public {
        vm.prank(user1);

        uint256 approvedAmount = 50000;

        assertTrue(ERC20Facet(address(diamond)).approve(user2, approvedAmount));

        assertEq(
            ERC20Facet(address(diamond)).allowance(user1, user2),
            approvedAmount
        );
    }

    function testERC20Facet_TransferFrom() public {
        testERC20Facet_Mint();
        vm.prank(user1);
        uint256 mintAmount = 5000e18;
        uint256 approvalAmount = 500e18;
        uint256 transferAmount = 5e18;
        uint256 balanceAferTransfer = mintAmount - transferAmount;
        uint256 currentApproval = approvalAmount - transferAmount;

        ERC20Facet(address(diamond)).approve(address(this), approvalAmount);
        assertTrue(
            ERC20Facet(address(diamond)).transferFrom(
                user1,
                user2,
                transferAmount
            )
        );
        assertEq(
            ERC20Facet(address(diamond)).allowance(user1, address(this)),
            currentApproval
        );

        assertEq(
            ERC20Facet(address(diamond)).balanceOf(user1),
            balanceAferTransfer
        );

        assertEq(ERC20Facet(address(diamond)).balanceOf(user2), transferAmount);
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
