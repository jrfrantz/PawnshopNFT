//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


// todo: pragmas and pull in sendwethoreth
contract PawnVault is ERC721Holder {

    address public owner;
    address public lender;
    
    address public token;
    uint256 public id;

    uint256 public askPrice; // TODO make this loanOutstanding and allow partial paybacks
    uint256 public pawnDuration;
    uint256 public annualInterestRateBips; // 50 --> 0.5% interest per year

    uint256 public starttime;

    enum State { inactive, cancelled, pawned, liquidated, withdrawn}
    
    State public state;
    

    function initialize(
        address _owner, 
        address _token, uint256 _tokenId,
        uint256 _askPrice,
        uint256 _pawnDuration, uint256 _annualInterestRateBips) external initializer {
        
        __ERC721Holder_init();

        owner = _owner;
        token = _token;
        id = _id;
        askPrice = _askPrice;
        pawnDuration = _pawnDuration;
        annualInterestRateBips = _annualInterestRateBips;
        
        starttime = block.timestamp;
        
        state = inactive;
    }

    /**
     * change your mind if you haven't gotten any bites
     */ 
    function cancel() external {
        require(msg.sender == owner, "cancel: not owner");
        require(state == inactive, "cancel: too late");

        IERC721(token).transferFrom(address(this), msg.sender, id);

        state = cancelled;
    }
    /**
    * 
    */
    function redeem() external payable {
        require (state == pawned, "redeem: nothing to redeem");
        require (msg.sender == owner, "redeem: not depositor");


        // calculate the interest paid in a year
        uint256 annualFee = askPrice * annualInterestRateBips / 10000;
        // turn that into seconds 
        uint256 feePerSecond = annualFee / 31536000;
        // get time duration that interest is owed
        uint256 timeBorrowed = block.timestamp - starttime;


        uint256 interestOwed = feePerSecond * timeBorrowed;
        require(msg.value > askPrice + interestOwed);

        // TODO: sendEthorWeth from partybid in the amount of either address(this) or just the amt calculated

        state = withdrawn;
    }


    /**
    * lender methods
    */
    function stake() external payable {
        require(msg.value == askPrice, "stake: pay list price");

        lender = msg.sender;
        starttime = block.timestamp;
        
        state = pawned;
    }


    function liquidate() external {
        require(state == pawned, "liquidate: item not pawned");
        require(msg.sender == lender, "only lender can liquidate");
        require(block.timestamp >= starttime + pawnDuration);

        // TODO allow partial payback logic
        state = liquidated;
    }

}

/**
 * HELPER FUNCTIONS
*/
function withdrawPrice() pure returns (uint256 owed) {

}