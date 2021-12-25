pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Einheit is ERC1155 {
    uint256 private constant NATURE_ID = 0;     // Metaverse (Einheit) nature. This determines the citizens' statuses and rankings.
    uint256 private constant FAITH_ID= 1;       // Metaverse (Einheit) currency and gov token. This is the acquisition/access power for everything.
    
    uint256 public natureToFaithRatio;      //
    uint256 public minVoteCountPercentage;  // Minimum votes required from citizens before vote is closed and $NATURE is re-distributed
    
    uint256 private tokenId = 100;     // Custom token id iterator. It captures all avatars and creations in the metaverse.

    string private constant URI = "";  // TODO: updates value. URI 

    enum VoteType { BAD, GOOD }; // citizens' vote options
    enum CreationType { BOARD }; // categories of objects that can be created in metaverse

    struct VoteInfo {
        uint256 blockNumber;    // vote block number
        uint256 ugcId;          // reference to ugc being voted for
        VoteType vote;
    }

    struct CreationInfo {
        CreationType creationType;  // creation category
        uint256 tokenId;            // creation uniqueness id
        uint256 createCost;         // how much $FAITH required to create this category
        uint256 voteCost;           // how much $FAITH required to vote for this category
        uint256 updateVoteCost;    // how much $FAITH required to update a vote for this category
    }

    mapping (address => VoteInfo[]) public voteInfo;
    mapping (address => CreationInfo[]) public creationInfo;
    
    constructor() public ERC1155(URI){
        natureToFaithRatio = 1000;  // TODO: change hardcoding to constructor param
        minVoteCountPercentage = 60;// TODO: change hardcoding to constructor param.
                                    // TODO: This should reduce gradually as the size of citizens increase.

        _mint(address(this), NATURE_ID, 10**(18 + natureToFaithRatio), "");
        _mint(address(this), FAITH_ID, 10**18, "");
    }

    /**
     * Mints $FAITH token to user for use
     */
    buyFaith() public payable returns (bool){
        // require has enough sell(dai) token approval

        // require... transfer sell token to address(this)
        // transfer $FAITH to sender
    }

    /**
     * Creates user avatar in metaverse using the $FAITH token
     */
    createAvatar(string uri) public {
        // require does not have avatar already
        // require has enough FAITH token to create avatar

        // concatenate supplied uri with base_uri
        // require tokenId++
        // require update creationInfo
        // mint _mint(address(this), tokenId, 1, data);
        
        // emit event
    }

    /**
     * Create metaverse object using the $FAITH token
     */
    create(CreationType creationType, bytes memory data) public {
        // require has avatar
        // require has enough FAITH to create particular object
        // require data has not been created. may use toLowerCase, and strip symbols.

        // require tokenId++
        // require update creationInfo
        // mint _mint(address(this), tokenId, 1, data);

        // emit event (address, creationType, )
    }

    /**
     * Vote for benefit of creation using the $FAITH token
     * User can update vote using more $FAITH token
     */
    vote(uint256 tokenId, VoteType voteType) public {
        // require sender has avatar
        // requires tokenId exists and is a creation up for vote only
        // require has enough FAITH to vote particular object
        // require has not exisiting vote for this creation

        // add/update vote
        // if votes are resolved, instant updateNature for msg.sender else batch update
    }

    /**
     * @dev Update $NATURE distribution every block based on citizens vote outcomes
     * Based on the votes outcome of majority citizens, $NATURE is distributed and/or deducted
     * Users with max votes receive more $NATURE.
     * Users with min votes reduce their $NATURE.
     */
    _updateNature(bool isSingleCitizen) private {
        // require least vote count ``minVoteCountPercentage`` is reached
        // required that voting status is active

        // resolve votes
        // if isSingleCitizen is true, update single nature...else update for all users with votes

    }
}