pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "./IContract.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./IterableMapping.sol";

contract CloverDarkSeedStake is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using IterableMapping for IterableMapping.Map;

    uint256 public CloverFieldCarbonRewardRate = 15e17;
    uint256 public CloverFieldPearlRewardRate = 3e18;
    uint256 public CloverFieldRubyRewardRate = 2e19;
    uint256 private CloverFieldDiamondRewardRate = 4e19;

    uint256 public CloverYardCarbonRewardRate = 1e17;
    uint256 public CloverYardPearlRewardRate = 2e17;
    uint256 public CloverYardRubyRewardRate = 12e17;
    uint256 private CloverYardDiamondRewardRate = 24e17;

    uint256 public CloverPotCarbonRewardRate = 8e15;
    uint256 public CloverPotPearlRewardRate = 12e15;
    uint256 public CloverPotRubyRewardRate = 6e16;
    uint256 private CloverPotDiamondRewardRate = 12e16;

    uint256 public rewardInterval = 1 days;
    uint256 public marketingFee = 1000;
    uint256 public totalClaimedRewards;
    uint256 public marketingFeeTotal;
    uint256 public waterInterval = 2 days;

    address public DarkSeedToken;
    address public DarkSeedNFT;
    address public DarkSeedController;
    address public DarkSeedPicker;

    address public marketingWallet;

    
    bool public isStakingEnabled = false;
    bool public isMarketingFeeActivated = false;
    bool public canClaimReward = false;

    EnumerableSet.AddressSet private CloverDiamondFieldAddresses;
    EnumerableSet.AddressSet private CloverDiamondYardAddresses;
    EnumerableSet.AddressSet private CloverDiamondPotAddresses;
    EnumerableSet.AddressSet private holders;

    mapping (address => uint256) public depositedCloverFieldCarbon;
    mapping (address => uint256) public depositedCloverFieldPearl;
    mapping (address => uint256) public depositedCloverFieldRuby;
    mapping (address => uint256) public depositedCloverFieldDiamond;

    mapping (address => uint256) public depositedCloverYardCarbon;
    mapping (address => uint256) public depositedCloverYardPearl;
    mapping (address => uint256) public depositedCloverYardRuby;
    mapping (address => uint256) public depositedCloverYardDiamond;

    mapping (address => uint256) public depositedCloverPotCarbon;
    mapping (address => uint256) public depositedCloverPotPearl;
    mapping (address => uint256) public depositedCloverPotRuby;
    mapping (address => uint256) public depositedCloverPotDiamond;

    mapping (address => uint256) public claimableRewards;

    mapping (address => uint256) public stakingTime;
    mapping (address => uint256) public totalDepositedTokens;
    mapping (address => uint256) public totalEarnedTokens;
    mapping (address => uint256) public lastClaimedTime;
    mapping (address => uint256) public lastWatered;
    mapping (address => bool) public noMarketingList;

    IterableMapping.Map private _owners;
    // mapping(uint256 => address) private _owners;

    event RewardsTransferred(address holder, uint256 amount);

    constructor(address _marketingWallet, address _DarkSeedToken, address _DarkSeedNFT, address _DarkSeedController, address _DarkSeedPicker) {
        DarkSeedPicker = _DarkSeedPicker;
        DarkSeedToken = _DarkSeedToken;
        DarkSeedNFT = _DarkSeedNFT;
        DarkSeedController = _DarkSeedController;
        marketingWallet = _marketingWallet;

        CloverDiamondFieldAddresses.add(address(0));
        CloverDiamondYardAddresses.add(address(0));
        CloverDiamondPotAddresses.add(address(0));

        noMarketingList[owner()] = true;
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners.get(tokenId);
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function randomNumberForCloverField() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

    function getLuckyWalletForCloverField() public view returns (address) {
        require (msg.sender == DarkSeedController, "Only controller can call this function");
        uint256 luckyWallet = randomNumberForCloverField() % CloverDiamondFieldAddresses.length();
        return CloverDiamondFieldAddresses.at(luckyWallet);
    }

    function randomNumberForCloverYard() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

    function getLuckyWalletForCloverYard() public view returns (address) {
        require (msg.sender == DarkSeedController, "Only controller can call this function");
        uint256 luckyWallet = randomNumberForCloverYard() % CloverDiamondYardAddresses.length();
        return CloverDiamondYardAddresses.at(luckyWallet);
    }

    function randomNumberForCloverPot() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

    function getLuckyWalletForCloverPot() public view returns (address) {
        require (msg.sender == DarkSeedController, "Only controller can call this function");
        uint256 luckyWallet = randomNumberForCloverPot() % CloverDiamondPotAddresses.length();
        return CloverDiamondPotAddresses.at(luckyWallet);
    }

    function updateAccount(address account) private {
        uint256 pendingDivs = getPendingDivs(account);
        lastClaimedTime[account] = block.timestamp;
        claimableRewards[account] += pendingDivs;
    }

    function estimateRewards(address account) public view returns(uint256) {
        uint256 pendingDivs = getPendingDivs(account);
        return claimableRewards[account] + pendingDivs;
    }
    
    function getPendingDivs(address _holder) public view returns (uint256) {
        
        uint256 pendingDivs = getPendingDivsField(_holder)
        .add(getPendingDivsYard(_holder))
        .add(getPendingDivsPot(_holder));
            
        return pendingDivs;
    }
    
    function getNumberOfHolders() public view returns (uint256) {
        return holders.length();
    }
    
    function claimDivs() public {
        require(canClaimReward, "Please waite to enable this function..");
        address account = msg.sender;
        updateAccount(account);
        if (claimableRewards[account] > 0){
            uint256 rewards = claimableRewards[account];
            uint256 _marketingFee = rewards * marketingFee / 10000;
            uint256 afterFee = rewards - _marketingFee;
            if (!isMarketingFeeActivated || noMarketingList[account]) {
                require(IContract(DarkSeedToken).sendToken2Account(account, rewards), "Can't transfer tokens!");
                totalEarnedTokens[account] = totalEarnedTokens[account].add(rewards);
                totalClaimedRewards = totalClaimedRewards.add(rewards);
                emit RewardsTransferred(account, rewards);
            } else {
                require(IContract(DarkSeedToken).sendToken2Account(account, afterFee), "Can't transfer tokens!");
                require(IContract(DarkSeedToken).sendToken2Account(marketingWallet, _marketingFee), "Can't transfer tokens.");
                totalEarnedTokens[account] = totalEarnedTokens[account].add(afterFee);
                totalClaimedRewards = totalClaimedRewards.add(rewards);
                emit RewardsTransferred(account, afterFee);
            }
        }
        claimableRewards[account] = 0;
    }

    function updateRewardInterval(uint256 _sec) public onlyOwner {
        rewardInterval = _sec;
    }

    function updateCloverField_Carbon_Pearl_Ruby_Diamond_RewardRate(uint256 _carbon, uint256 _pearl, uint256 _ruby, uint256 _diamond) public onlyOwner {
        CloverFieldCarbonRewardRate = _carbon;
        CloverFieldPearlRewardRate = _pearl;
        CloverFieldRubyRewardRate = _ruby;
        CloverFieldDiamondRewardRate = _diamond;
    }

    function updateCloverYard_Carbon_Pearl_Ruby_Diamond_RewardRate(uint256 _carbon, uint256 _pearl, uint256 _ruby, uint256 _diamond) public onlyOwner {
        CloverYardCarbonRewardRate = _carbon;
        CloverYardPearlRewardRate = _pearl;
        CloverYardRubyRewardRate = _ruby;
        CloverYardDiamondRewardRate = _diamond;
    }

    function updateCloverPot_Carbon_Pearl_Ruby_Diamond_RewardRate(uint256 _carbon, uint256 _pearl, uint256 _ruby, uint256 _diamond) public onlyOwner {
        CloverPotCarbonRewardRate = _carbon;
        CloverPotPearlRewardRate = _pearl;
        CloverPotRubyRewardRate = _ruby;
        CloverPotDiamondRewardRate = _diamond;
    }

    function getTimeDiff(address _holder) public view returns (uint256) {
        require(holders.contains(_holder), "You are not a holder!");
        require(totalDepositedTokens[_holder] > 0, "You have no tokens!");
        uint256 wastedTime = 0;
        if (block.timestamp - lastWatered[_holder] > waterInterval) {
            wastedTime = block.timestamp - lastWatered[_holder] - waterInterval;
        } 
        uint256 timeDiff = block.timestamp - lastClaimedTime[_holder];
        if (timeDiff > wastedTime) {
            timeDiff -= wastedTime;
        } else {
            timeDiff = 0;
        }
        return timeDiff;
    }

    function getCloverFieldCarbonReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 cloverFieldCarbon = depositedCloverFieldCarbon[_holder];
        uint256 CloverFieldCarbonReward = cloverFieldCarbon.mul(CloverFieldCarbonRewardRate).div(rewardInterval).mul(getTimeDiff(_holder));

        return CloverFieldCarbonReward;
    }

    function getCloverFieldPearlReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 cloverFieldPearl = depositedCloverFieldPearl[_holder];
        uint256 CloverFieldPearlReward = cloverFieldPearl.mul(CloverFieldPearlRewardRate).div(rewardInterval).mul(getTimeDiff(_holder));

        return CloverFieldPearlReward;
    }

    function getCloverFieldRubyReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 cloverFieldRuby = depositedCloverFieldRuby[_holder];
        uint256 CloverFieldRubyReward = cloverFieldRuby.mul(CloverFieldRubyRewardRate).div(rewardInterval).mul(getTimeDiff(_holder));

        return CloverFieldRubyReward;
    }

    function getCloverFieldDiamondReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 cloverFieldDiamond = depositedCloverFieldDiamond[_holder];
        uint256 CloverFieldDiamondReward = cloverFieldDiamond.mul(CloverFieldDiamondRewardRate).div(rewardInterval).mul(getTimeDiff(_holder));

        return CloverFieldDiamondReward;
    }

    function getCloverYardCarbonReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 cloverYardCarbon = depositedCloverYardCarbon[_holder];
        uint256 CloverYardCarbonReward = cloverYardCarbon.mul(CloverYardCarbonRewardRate).div(rewardInterval).mul(getTimeDiff(_holder));

        return CloverYardCarbonReward;
    }

    function getCloverYardPearlReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 cloverYardPearl = depositedCloverYardPearl[_holder];
        uint256 CloverYardPearlReward = cloverYardPearl.mul(CloverYardPearlRewardRate).div(rewardInterval).mul(getTimeDiff(_holder));

        return CloverYardPearlReward;
    }

    function getCloverYardRubyReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 cloverYardRuby = depositedCloverYardRuby[_holder];
        uint256 CloverYardRubyReward = cloverYardRuby.mul(CloverYardRubyRewardRate).div(rewardInterval).mul(getTimeDiff(_holder));

        return CloverYardRubyReward;
    }

    function getCloverYardDiamondReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 cloverYardDiamond = depositedCloverYardDiamond[_holder];
        uint256 CloverYardDiamondReward = cloverYardDiamond.mul(CloverYardDiamondRewardRate).div(rewardInterval).mul(getTimeDiff(_holder));

        return CloverYardDiamondReward;
    }

    function getCloverPotCarbonReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 cloverPotCarbon = depositedCloverPotCarbon[_holder];
        uint256 CloverPotCarbonReward = cloverPotCarbon.mul(CloverPotCarbonRewardRate).div(rewardInterval).mul(getTimeDiff(_holder));

        return CloverPotCarbonReward;
    }

    function getCloverPotPearlReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 cloverPotPearl = depositedCloverPotPearl[_holder];
        uint256 CloverPotPearlReward = cloverPotPearl.mul(CloverPotPearlRewardRate).div(rewardInterval).mul(getTimeDiff(_holder));

        return CloverPotPearlReward;
    }

    function getCloverPotRubyReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 cloverPotRuby = depositedCloverPotRuby[_holder];
        uint256 CloverPotRubyReward = cloverPotRuby.mul(CloverPotRubyRewardRate).div(rewardInterval).mul(getTimeDiff(_holder));

        return CloverPotRubyReward;
    }

    function getCloverPotDiamondReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 cloverPotDiamond = depositedCloverPotDiamond[_holder];
        uint256 CloverPotDiamondReward = cloverPotDiamond.mul(CloverPotDiamondRewardRate).div(rewardInterval).mul(getTimeDiff(_holder));

        return CloverPotDiamondReward;
    }
    
    function getPendingDivsField(address _holder) private view returns (uint256) {
        
        uint256 pendingDivs = getCloverFieldCarbonReward(_holder)
        .add(getCloverFieldPearlReward(_holder))
        .add(getCloverFieldRubyReward(_holder))
        .add(getCloverFieldDiamondReward(_holder));
            
        return pendingDivs;
    }
    
    function getPendingDivsYard(address _holder) private view returns (uint256) {
        
        uint256 pendingDivs = getCloverYardCarbonReward(_holder)
        .add(getCloverYardPearlReward(_holder))
        .add(getCloverYardRubyReward(_holder))
        .add(getCloverYardDiamondReward(_holder));
            
        return pendingDivs;
    }
    
    function getPendingDivsPot(address _holder) private view returns (uint256) {
        
        uint256 pendingDivs = getCloverPotCarbonReward(_holder)
        .add(getCloverPotPearlReward(_holder))
        .add(getCloverPotRubyReward(_holder))
        .add(getCloverPotDiamondReward(_holder));
            
        return pendingDivs;
    }

    function stake(uint256[] memory tokenId) public {
        require(isStakingEnabled, "Staking is not activeted yet..");

        updateAccount(msg.sender);
        
        for (uint256 i = 0; i < tokenId.length; i++) {

            IContract(DarkSeedNFT).setApprovalForAll_(address(this));
            IContract(DarkSeedNFT).safeTransferFrom(msg.sender, address(this), tokenId[i]);

            if (tokenId[i] <= 1e3) {
                if (IContract(DarkSeedController).isCloverFieldCarbon_(tokenId[i])) {
                    depositedCloverFieldCarbon[msg.sender]++;
                } else if (IContract(DarkSeedController).isCloverFieldPearl_(tokenId[i])) {
                    depositedCloverFieldPearl[msg.sender]++;
                } else if (IContract(DarkSeedController).isCloverFieldRuby_(tokenId[i])) {
                    depositedCloverFieldRuby[msg.sender]++;
                } else if (IContract(DarkSeedController).isCloverFieldDiamond_(tokenId[i])) {
                    depositedCloverFieldDiamond[msg.sender]++;
                    if (!CloverDiamondFieldAddresses.contains(msg.sender)) {
                        CloverDiamondFieldAddresses.add(msg.sender);
                    }
                }
            }

            if (tokenId[i] > 1e3 && tokenId[i] <= 11e3) {
                if (IContract(DarkSeedController).isCloverYardCarbon_(tokenId[i])) {
                    depositedCloverYardCarbon[msg.sender]++;
                } else if (IContract(DarkSeedController).isCloverYardPearl_(tokenId[i])) {
                    depositedCloverYardPearl[msg.sender]++;
                } else if (IContract(DarkSeedController).isCloverYardRuby_(tokenId[i])) {
                    depositedCloverYardRuby[msg.sender]++;
                } else if (IContract(DarkSeedController).isCloverYardDiamond_(tokenId[i])) {
                    depositedCloverYardDiamond[msg.sender]++;
                    if (!CloverDiamondYardAddresses.contains(msg.sender)) {
                        CloverDiamondYardAddresses.add(msg.sender);
                    }
                }
            }

            if (tokenId[i] > 11e3 && tokenId[i] <= 111e3) {
                if (IContract(DarkSeedController).isCloverPotCarbon_(tokenId[i])) {
                    depositedCloverPotCarbon[msg.sender]++;
                } else if (IContract(DarkSeedController).isCloverPotPearl_(tokenId[i])) {
                    depositedCloverPotPearl[msg.sender]++;
                } else if (IContract(DarkSeedController).isCloverPotRuby_(tokenId[i])) {
                    depositedCloverPotRuby[msg.sender]++;
                } else if (IContract(DarkSeedController).isCloverPotDiamond_(tokenId[i])) {
                    depositedCloverPotDiamond[msg.sender]++;
                    if (!CloverDiamondPotAddresses.contains(msg.sender)) {
                        CloverDiamondPotAddresses.add(msg.sender);
                    }
                }
            }

            if (tokenId[i] > 0) {
                _owners.set(tokenId[i], msg.sender);
            }

            totalDepositedTokens[msg.sender]++;
        }

        if (!holders.contains(msg.sender) && totalDepositedTokens[msg.sender] > 0) {
            holders.add(msg.sender);
            stakingTime[msg.sender] = block.timestamp;
            lastWatered[msg.sender] = block.timestamp;
        }
    }
    
    function unstake(uint256[] memory tokenId) public {
        require(totalDepositedTokens[msg.sender] > 0, "Stake: You don't have staked token..");
        updateAccount(msg.sender);

        for (uint256 i = 0; i < tokenId.length; i++) {
            require(_owners.get(tokenId[i]) == msg.sender, "Stake: Please enter correct tokenId..");
            
            if (tokenId[i] > 0) {
                IContract(DarkSeedNFT).safeTransferFrom(address(this), msg.sender, tokenId[i]);
            }
            totalDepositedTokens[msg.sender] --;

            if (tokenId[i] <= 1e3) {
                if (IContract(DarkSeedController).isCloverFieldCarbon_(tokenId[i])) {
                    depositedCloverFieldCarbon[msg.sender] --;
                } else if(IContract(DarkSeedController).isCloverFieldPearl_(tokenId[i])) {
                    depositedCloverFieldPearl[msg.sender] --;
                } else if(IContract(DarkSeedController).isCloverFieldRuby_(tokenId[i])) {
                    depositedCloverFieldRuby[msg.sender] --;
                } else if(IContract(DarkSeedController).isCloverFieldDiamond_(tokenId[i])) {
                    depositedCloverFieldDiamond[msg.sender] --;
                    if (depositedCloverFieldDiamond[msg.sender] == 0) {
                        CloverDiamondFieldAddresses.remove(msg.sender);
                    }
                }
            }

            if (tokenId[i] > 1e3 && tokenId[i] <= 11e3) {
                if (IContract(DarkSeedController).isCloverYardCarbon_(tokenId[i])) {
                    depositedCloverYardCarbon[msg.sender] --;
                } else if(IContract(DarkSeedController).isCloverYardPearl_(tokenId[i])) {
                    depositedCloverYardPearl[msg.sender] --;
                } else if(IContract(DarkSeedController).isCloverYardRuby_(tokenId[i])) {
                    depositedCloverYardRuby[msg.sender] --;
                } else if(IContract(DarkSeedController).isCloverYardDiamond_(tokenId[i])) {
                    depositedCloverYardDiamond[msg.sender] --;
                    if (depositedCloverYardDiamond[msg.sender] == 0) {
                        CloverDiamondYardAddresses.remove(msg.sender);
                    }
                }
            }

            if (tokenId[i] > 11e3 && tokenId[i] <= 111e3) {
                if (IContract(DarkSeedController).isCloverPotCarbon_(tokenId[i])) {
                    depositedCloverPotCarbon[msg.sender] --;
                } else if(IContract(DarkSeedController).isCloverPotPearl_(tokenId[i])) {
                    depositedCloverPotPearl[msg.sender] --;
                } else if(IContract(DarkSeedController).isCloverPotRuby_(tokenId[i])) {
                    depositedCloverPotRuby[msg.sender] --;
                } else if(IContract(DarkSeedController).isCloverPotDiamond_(tokenId[i])) {
                    depositedCloverPotDiamond[msg.sender] --;
                    if (depositedCloverPotDiamond[msg.sender] == 0) {
                        CloverDiamondPotAddresses.remove(msg.sender);
                    }
                }
            }

            if (tokenId[i] > 0) {
                _owners.remove(tokenId[i]);
            }
        }
        
        if (holders.contains(msg.sender) && totalDepositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }

    function water() public {
        updateAccount(msg.sender);
        lastWatered[msg.sender] = block.timestamp;
    }

    function updateWaterInterval(uint256 sec) public onlyOwner {
        waterInterval = sec;
    }
    
    function enableStaking() public onlyOwner {
        isStakingEnabled = true;
    }

    function disableStaking() public onlyOwner {
        isStakingEnabled = false;
    }

    function enableClaimFunction() public onlyOwner {
        canClaimReward = true;
    }

    function disableClaimFunction() public onlyOwner {
        canClaimReward = false;
    }

    function enableMarketingFee() public onlyOwner {
        isMarketingFeeActivated = true;
    }

    function disableMarketingFee() public onlyOwner {
        isMarketingFeeActivated = false;
    }

    function setDarkSeedPicker(address _DarkSeedPicker) public onlyOwner {
        DarkSeedPicker = _DarkSeedPicker;
    }

    function set_Seed_Controller(address _wallet) public onlyOwner {
        DarkSeedController = _wallet;
    }

    function set_DarkSeedToken(address SeedsToken) public onlyOwner {
        DarkSeedToken = SeedsToken;
    }

    function set_DarkSeedNFT(address nftToken) public onlyOwner {
        DarkSeedNFT = nftToken;
    }

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        marketingWallet = _marketingWallet;
    }

    // function to allow admin to transfer *any* BEP20 tokens from this contract..
    function transferAnyBEP20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "SEED$ Stake: amount must be greater than 0");
        require(recipient != address(0), "SEED$ Stake: recipient is the zero address");
        IContract(tokenAddress).transfer(recipient, amount);
    }

    function stakedTokensByOwner(address account) public view returns (uint[] memory) {
        uint[] memory tokenIds = new uint[](totalDepositedTokens[account]);
        uint counter = 0;
        for (uint i = 0; i < _owners.size(); i++) {
            uint tokenId = _owners.getKeyAtIndex(i);
            if (_owners.get(tokenId) == account) {
                tokenIds[counter] = tokenId;
                counter++;
            }
        }
        return tokenIds;
    }

    function totalStakedCloverFieldsByOwner(address account) public view returns (uint) {
        return depositedCloverFieldCarbon[account] 
        + depositedCloverFieldDiamond[account]
        + depositedCloverFieldPearl[account]
        + depositedCloverFieldRuby[account]; 
    }

    function totalStakedCloverYardsByOwner(address account) public view returns (uint) {
        return depositedCloverYardCarbon[account] 
        + depositedCloverYardDiamond[account]
        + depositedCloverYardPearl[account]
        + depositedCloverYardRuby[account]; 
    }

    function totalStakedCloverPotsByOwner(address account) public view returns (uint) {
        return depositedCloverPotCarbon[account] 
        + depositedCloverPotDiamond[account]
        + depositedCloverPotPearl[account]
        + depositedCloverPotRuby[account]; 
    }

    function totalStakedCloverFields() public view returns (uint) {
        uint counter = 0;
        for (uint i = 0; i < holders.length(); i++) {
            counter += totalStakedCloverFieldsByOwner(holders.at(i));
        }
        return  counter;
    }

    function totalStakedCloverYards() public view returns (uint) {
        uint counter = 0;
        for (uint i = 0; i < holders.length(); i++) {
            counter += totalStakedCloverYardsByOwner(holders.at(i));
        }
        return  counter;
    }

    function totalStakedCloverPots() public view returns (uint) {
        uint counter = 0;
        for (uint i = 0; i < holders.length(); i++) {
            counter += totalStakedCloverPotsByOwner(holders.at(i));
        }
        return  counter;
    }

    function passedTime(address account) public view returns (uint) {
        if (totalDepositedTokens[account] == 0) {
          return 0;  
        } else {
            return block.timestamp - lastWatered[account];
        }
    }

    function readRewardRates() public view returns(
        uint fieldCarbon, uint fieldPearl, uint fieldRuby, uint fieldDiamond,
        uint yardCarbon, uint yardPearl, uint yardRuby, uint yardDiamond,
        uint potCarbon, uint potPearl, uint potRuby, uint potDiamond
    ){
        fieldCarbon = CloverFieldCarbonRewardRate;
        fieldPearl = CloverFieldPearlRewardRate;
        fieldRuby = CloverFieldRubyRewardRate;
        fieldDiamond = CloverFieldDiamondRewardRate;

        yardCarbon = CloverYardCarbonRewardRate;
        yardPearl = CloverYardPearlRewardRate;
        yardRuby = CloverYardRubyRewardRate;
        yardDiamond = CloverYardDiamondRewardRate;

        potCarbon = CloverPotCarbonRewardRate;
        potPearl = CloverPotPearlRewardRate;
        potRuby = CloverPotRubyRewardRate;
        potDiamond = CloverPotDiamondRewardRate;
    }

    function setNoMarketingAddress(address acc) public onlyOwner {
        noMarketingList[acc] = true;
    }
}