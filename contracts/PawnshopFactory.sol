//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
// todo: make ownable and pausable

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


import "./InitializedProxy.sol";
import "./PawnVault.sol";
contract PawnshopFactory is Ownable, Pausable {
    uint256 public pawnCount;
    
    mapping (uint256 => address) public pawns;

    address public immutable logic;

    event PawnAsk(address indexed token, uint256 id, uint256 askPrice, address pawn, uint256 pawnId);

    constructor() {
        logic = address(new PawnVault());
    }
    // must be approved

    // (1, 2) NFT (addr, tokenId)
    // (3) cash requested
    // (4) time duration
    // (5) bidder's accepted interest rate in bips. 50 = 0.5% annual interest
    function offer(
        address _token, uint256 _tokenId,
        uint256 _askPrice,
        uint256 _pawnDuration, 
        uint256 _annualInterestRateBips
    ) external whenNotPaused returns(uint256) {
    
        bytes memory _initializationCalldata =
        abi.encodeWithSignature(
            "initialize(address,address,uint256,uint256,uint256,uint256)",
            msg.sender,
            _token,
            _id,
            _askPrice,
            _pawnDuration,
            _annualInterestRateBips
        );

        address pawn = address(
            new InitializedProxy(
                logic,
                _initializationCalldata
            )
        );

        emit PawnAsk(_token, _tokenId, _askPrice, pawn, pawnCount);

        IERC721(_token).safeTransferFrom(msg.sender, vault, _id);
        
        pawns[pawnCount] = pawn;
        pawnCount++;

        return pawnCount - 1;
    }


    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}