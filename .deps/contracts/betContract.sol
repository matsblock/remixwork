//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./dai.sol";
import "./treasuryContractTest.sol";
import "./enetScoreConsumer.sol";

contract betContract is EnetscoresConsumer{
    address public owner;
    address public treasuryAddress;
    address public tokenAddress;
    uint public homeOdd;
    uint public awayOdd;
    uint public tiedOdd;
    uint public totalBets;
    bool public betOpen;

    bool public matchFinished; // false: pending, true: finished
    GameResolve public matchStatus;

    betOption public matchWinner;

    enum betOption {
        home,
        away,
        tied
    }

    struct betStruct {
        betOption option;
        uint256 amount;
        uint odd;
    }
        
    mapping(address => betStruct) public bets;

    constructor(address _treasuryAddress, address _tokenAddress,uint _homeOdd, uint _awayOdd, uint _tiedOdd) {
        owner = msg.sender;
        treasuryAddress = _treasuryAddress;
        tokenAddress = _tokenAddress;
        homeOdd = _homeOdd;
        awayOdd = _awayOdd;
        tiedOdd = _tiedOdd;
        betOpen = true;
    }

    function setBet(betOption _choice, uint _amount) public {
        bets[msg.sender].option = _choice;
        bets[msg.sender].amount += _amount;

        if(_choice == betOption.home){
        bets[msg.sender].odd = homeOdd;
        }
        if(_choice == betOption.away){
        bets[msg.sender].odd = awayOdd;
        }
        if(_choice == betOption.tied){
        bets[msg.sender].odd = tiedOdd;
        }

        totalBets += _amount;
        depositDAI(_amount);

    }

    function setMockMatch(string memory _status, uint8 _homeScore, uint8 _awayScore) public onlyOwner {
        matchStatus.status = _status;
        matchStatus.homeScore = _homeScore;
        matchStatus.awayScore = _awayScore;
    }

    function resolveWinner(bytes32 _requestId, uint256 _idx) public onlyOwner{

        matchStatus = getGameResolve(_requestId, _idx);
        
        require (keccak256(abi.encodePacked('finished')) == keccak256(abi.encodePacked(matchStatus.status)));
       
       if(matchStatus.homeScore>matchStatus.awayScore) {
            matchWinner = betOption.home;
        } 
        if(matchStatus.homeScore<matchStatus.awayScore) {
            matchWinner = betOption.away;
        }
        if(matchStatus.homeScore == matchStatus.awayScore) {
            matchWinner = betOption.tied;
        }
    }

    function depositDAI(uint amount) public {
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    function payDAItoTreasury() public onlyOwner{
        uint amount = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(treasuryAddress, amount);
    }

    function approvePayment() public {
        require (keccak256(abi.encodePacked('finished')) == keccak256(abi.encodePacked(matchStatus.status)));
        require (matchWinner == bets[msg.sender].option);
        uint _amount = bets[msg.sender].amount * bets[msg.sender].odd / 10 ** 18;
        ItreasuryContract(treasuryAddress).approveSatelliteContract(address(this), _amount);
    }

    function claimUserReward() public {
        require (keccak256(abi.encodePacked('finished')) == keccak256(abi.encodePacked(matchStatus.status)));
        require (matchWinner == bets[msg.sender].option);
        uint _amount = bets[msg.sender].amount * bets[msg.sender].odd / 10 ** 18;
        IERC20(tokenAddress).transferFrom(treasuryAddress,msg.sender, _amount);
    }
    
    function setHomeOdd(uint _odd) public onlyOwner{
         homeOdd = _odd;
    }
    function setAwayOdd(uint _odd) public onlyOwner{
         awayOdd = _odd;
    }
    function setTiedOdd(uint _odd) public onlyOwner{
         tiedOdd = _odd;
    }

    function openBet() public onlyOwner{
        betOpen = true;
    }

    function closeBet() public onlyOwner{
        betOpen = false;        
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'only owner');
        _;
    }


}