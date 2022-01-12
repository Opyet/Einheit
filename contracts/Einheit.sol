pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Einheit is ERC1155, Ownable {
    using SafeMath for uint256;
    // user => avatar
    mapping (address => uint256) public avatarsInfo;
    // user => creation => votes
    mapping (address => mapping(uint256 => VoteType)) public votesInfo;
    // mapping (uint256 => VoteType => address[]) public votesInfo;
    mapping (uint256 => CreationInfo) public creationsInfo;
    mapping (CreationType => CategoryInfo) public categoriesInfo;
    // creation => votesCount
    mapping (uint256 => uint256) public votesCountInfo;

    event Create(address indexed by, CreationType indexed creationType, uint256 tokenId, uint256 timestamp);
    event Vote(address indexed by, VoteType indexed voteType, uint256 tokenId, uint256 timestamp);
    event Buy(address indexed by, uint256 amount, uint256 timestamp);

    uint256 private constant NATURE_ID = 0;     // Metaverse (Einheit) nature. This determines the citizens' statuses and rankings.
    uint256 private constant FAITH = 1;         // Metaverse (Einheit) currency and gov token. This is the acquisition/access power for everything.
    
    uint256 public natureToFaithRatio;          //
    
    uint256 public _avatarsCount = 0;
    uint256 private _tokenId = 100;     // Custom token ids iterator starts from 100. It captures all avatars and creations in the metaverse.
    uint256 private _minVoteCountPercentage;  // Minimum votes required from citizens before vote is closed and $NATURE is re-distributed
    uint256 private _faithReserveTokenCost;
    string private constant BASE_URI = "";   // TODO: update value of BASE_URI ... IPFS / filecoin / etc. 
    IERC20 private _reserveAsset;        // reserve token contract

    enum VoteType { NONE, BAD, GOOD } // citizens' vote options
    enum CreationType { AVATAR, BOARD } // categories of objects that can be created in metaverse

    struct CategoryInfo {
        uint256 createCost;         // how much $FAITH required to create this category
        bool isVotable;             // is available for voting? avatars cannot be voted for
    }

    struct CreationInfo {
        uint256 voteCost;           // how much $FAITH required to vote for this category
        uint256 updateVoteCost;     // how much $FAITH required to update a vote for this category
        uint256 upVotes;            // BAD votes count
        uint256 downVotes;          // GOOD votes count
        CreationType creationType;  // creation category
        bool isResolved;
        bool exists;
    }
    
    constructor(
        address reserveAsset
    ) ERC1155(BASE_URI){
        natureToFaithRatio = 1000;  // TODO: change hardcoding to constructor param
        _faithReserveTokenCost = 10; // 1 DAI = 10 $FAITH
        _minVoteCountPercentage = 60000;// TODO: change hardcoding to constructor param. * 1,000
                                    // TODO: This should reduce gradually as the size of citizens increase.

        _reserveAsset = IERC20(reserveAsset);
        _mint(address(this), NATURE_ID, 10**21, "");
        _mint(address(this), FAITH, 10**18, "");

        //TODO: move creation info to init() function
        CategoryInfo memory _avatarCategory = categoriesInfo[CreationType.AVATAR];
        _avatarCategory.isVotable = false;
        _avatarCategory.createCost = 25;    // $FAITH required to create

        CategoryInfo memory _boardCategory = categoriesInfo[CreationType.BOARD];
        _boardCategory.isVotable = false;
        _boardCategory.createCost = 10;    // $FAITH required to create
    }

    /**
     * Mints $FAITH token amount to user
     */
    function buy(uint256 amount) public {
        uint256 cost = amount * _faithReserveTokenCost;
        require(
            _reserveAsset.transferFrom(
                _msgSender(),
                address(this),
                cost
            ),
            "Einheit:buy:Reserve asset transfer for buy failed"
        );

        // transfer $FAITH to sender
        safeTransferFrom(address(this), _msgSender(), FAITH, amount, "");

        emit Buy(_msgSender(), amount, block.timestamp);
    }

    /**
     * Creates user avatar in metaverse using the $FAITH token
     */
    function createAvatar(string memory uri) public {
        // require does not have avatar already
        require(avatarsInfo[_msgSender()] == 0, "Einheit:createAvatar: an avatar already exists");
        // require has enough FAITH token to create avatar
        uint256 cost = categoriesInfo[CreationType.AVATAR].createCost;
        require(balanceOf(_msgSender(), FAITH) >= cost, "Einheit:createAvatar: insufficient FAITH token");
        safeTransferFrom(
            _msgSender(),
            address(this),
            FAITH,
            cost,
            ""
        ); // "Einheit:createAvatar:FAITH transfer for createAvatar failed"
        
        // require _tokenId++
        _tokenId++;
        
        // require mint 
        _mint(_msgSender(), _tokenId, 1, abi.encodePacked(BASE_URI, uri)); //"Einheit:createAvatar: mint failed");

        // update avatarsInfo
        avatarsInfo[_msgSender()] = _tokenId;
        _avatarsCount++;

        emit Create(_msgSender(), CreationType.AVATAR, _tokenId, block.timestamp);
    }

    /**
     * Create metaverse object using the $FAITH token
     */
    function create(CreationType creationType, bytes memory data) public {
        // require has avatar
        require(avatarsInfo[_msgSender()] > 0, "Einheit:create: user avatar does not exists");
        // require has enough FAITH to create particular object
        uint256 cost = categoriesInfo[creationType].createCost;
        require(balanceOf(_msgSender(), FAITH) >= cost, "Einheit:create: insufficient FAITH token");

        // TODO: require data has not been created. may use toLowerCase, and strip symbols.

        // require _tokenId++
        _tokenId++;

        safeTransferFrom(
            _msgSender(),
            address(this),
            FAITH,
            cost,
            ""
        );
        // "Einheit:create:FAITH transfer for create failed"
        
        // mint 
        _mint(_msgSender(), _tokenId, 1, abi.encodePacked(BASE_URI, data)); //"Einheit:create: mint failed"

        // update avatarsInfo
        CreationInfo memory _creation;
        _creation.voteCost = 10;
        _creation.updateVoteCost = 15;
        _creation.upVotes = 0;
        _creation.downVotes = 0;
        _creation.creationType = creationType;
        _creation.isResolved = false;
        _creation.exists = true;

        creationsInfo[_tokenId] = _creation;

        emit Create(_msgSender(), CreationType.AVATAR, _tokenId, block.timestamp);
    }

    /**
     * Vote for benefit of creation using the $FAITH token
     * User can update vote using more $FAITH token
     */
    function vote(uint256 tokenId, VoteType voteType) public {
        // require valif vote type
        require(voteType != VoteType.NONE, "Einheit:vote: user avatar does not exists");
        // require sender has avatar
        require(avatarsInfo[_msgSender()] > 0, "Einheit:vote: user avatar does not exists");
        // requires creation exists
        require(creationsInfo[tokenId].exists, "Einheit:vote: creation does not exists");
        // require has enough FAITH to vote particular object
        uint256 cost = 0;
        bool hasVoted = false;
        if(votesInfo[_msgSender()][tokenId] != VoteType.NONE) {
            hasVoted = true;
        }
        if(!hasVoted) {
            cost = creationsInfo[_tokenId].voteCost;
        }else{
            cost = creationsInfo[_tokenId].updateVoteCost;
        }
        require(balanceOf(_msgSender(), FAITH) >= cost, "Einheit:vote: insufficient FAITH token");

        safeTransferFrom(
            _msgSender(),
            address(this),
            FAITH,
            cost,
            ""
        );
        // "Einheit:vote:FAITH transfer for vote failed"

        // add new or update vote
        votesInfo[_msgSender()][tokenId] = voteType;
        if(voteType == VoteType.GOOD){
            creationsInfo[tokenId].upVotes++;
        }
        if(voteType == VoteType.BAD){
            creationsInfo[tokenId].downVotes++;
        }

        // update votes count when user doesn't already have a vote
        if(!hasVoted){
            votesCountInfo[tokenId]++;
        }

        // if votes are resolved, instant updateNature for msg.sender else batch update
        CreationInfo memory creation = creationsInfo[tokenId];
        if(creation.isResolved){
            // required that voting status is active
            // if(voting is active){
                // require least vote count ``_minVoteCountPercentage`` is reached
                if(_quorumReached(tokenId) == true){
                    _updateNature(true);
                }
            // }
        }else{                
            if(_quorumReached(tokenId) == true){
                // TODO: resolve votes. this is a single time event


                // TODO: what happens about locking resolved votes

                _updateNature(false);
            }
        }
    }

    function _quorumReached(uint256 tokenId) private view returns(bool) {
        if(votesCountInfo[tokenId].mul(1000).div(_avatarsCount) < _minVoteCountPercentage){
            return false;
        }else{
            return true;
        }
    }

    /**
     * @dev Update $NATURE distribution every block based on citizens vote outcomes
     * Based on the votes outcome of majority citizens, $NATURE is distributed and/or deducted
     * Users with max votes receive more $NATURE.
     * Users with min votes reduce their $NATURE.
     */
    function _updateNature(bool isSingleCitizen) internal {
        
        // if isSingleCitizen is true, update single nature...else update for all users with votes

    }
}