contract;

use standards::src5::State;

abi OwnedProxy {
    #[storage(write)]
    fn set_proxy_owner(new_proxy_owner: State);
}

abi Game {
    #[storage(read, write)]
    fn set_freemint_maxnodenum(_true_false: bool, _max_node_num: u64);

    #[storage(read, write)]
    fn set_first_node(_identity: Identity, _community_name: str);

    #[storage(read, write)]
    fn set_node_level_membernum(_level: u64, _num: u64);

    #[storage(read, write)]
    fn set_random_token_contract(_random_contract_id: b256, _token_contract_id: b256, _asset_id: b256);

    #[storage(read, write)]
    fn set_third_pointowner_contract(_contract_id: b256, _identity: Identity);

    #[storage(read, write)]
    fn set_fruit_price(_apple_price: u64, _banana_price: u64, _ananas_price: u64);

    #[storage(read, write)]
    fn set_days(_one_day: u64, _two_days: u64, _five_days: u64, _epoch_diff: u64);

    #[storage(read, write)]
    fn set_accelerator_hour(_add_eight_hour: u64, _add_sixteen_hour: u64, _add_oneday_hour: u64);    

    #[storage(read, write)]
    fn set_lucky_combine_battle_list_price(_lucky_price: u64, _combine_price: u64, _battle_price: u64, _list_price: u64);

    #[storage(read, write)]
    fn set_constellation_token_price(_constellation_price: u64, _token_price: u64);

    #[storage(read, write)]
    fn set_monster_node_rebirth_gene_price(_monster_price: u64, _node_price: u64, _rebirth_price: u64, _gene_price: u64);

    #[storage(read, write)]
    fn add_airdrop_phase();

    #[payable, storage(read, write)]
    fn become_node(_community_name: str);

    #[payable, storage(read, write)]
    fn mint_monster(_inviter: Identity);

    #[storage(read, write)]
    fn free_mint_monster(_inviter: Identity);

    #[storage(read)]
    fn get_my_info(_identity: Identity)->(Option<Monster>, Option<Fruit>, Option<Constellation>, Option<Accelerator>, EpochRef, BattleBonus, InviteBonus, CommunityBonus);

    #[storage(read)]
    fn get_total_point(_airdrop_phase: u64)->Option<u64>;

    #[storage(read)]
    fn get_share_bonus_list(_identity: Identity) -> Vec<BonusList>;

    #[storage(read)]
    fn get_invite_bonus_list(_identity: Identity) -> Vec<BonusList>;

    #[storage(read)]
    fn get_community_bonus_list(_identity: Identity) -> Vec<BonusList>;

    #[storage(read)]
    fn get_lucky_banana_universal(_epoch: u64)->(Option<u64>, Option<u64>);

    #[storage(read)]
    fn get_dev_airdrop_balance()->(u64, u64);

    #[payable, storage(read, write)]
    fn buy_fruit(_styles: u8, _amount: u16);

    #[storage(read, write)]
    fn feed_fruit(_styles: u8);

    #[storage(read, write)]
    fn using_accelerator_card(_styles: u8);

    #[storage(read, write)]
    fn claim_constellation()->u8;

    #[payable, storage(read, write)]
    fn combine_constellation();

    #[storage(read, write)]
    fn swap_constellation_to_coin(_use_styles: u8, _amount: u16);

    #[storage(read, write)]
    fn claim_battle_bonus(_epoch: u64);

    #[storage(read, write)]
    fn claim_invite_bonus(_epoch: u64);

    #[storage(read, write)]
    fn claim_node_bonus(_epoch: u64);

    #[payable, storage(read, write)]
    fn regenerate_gene();

    #[payable, storage(read, write)]
    fn rebirth();

    #[payable, storage(read, write)]
    fn list_constellation(_styles: u8) -> b256;

    #[storage(read, write)]
    fn delist_constellation(_listid: b256);

    #[payable, storage(read, write)]
    fn battle(_use_styles: u8, _listid: b256) -> bool;

    #[storage(read, write)]
    fn launch_community_battle(_node_side: Identity);

    #[storage(read, write)]
    fn add_accelerator();

    #[payable, storage(read, write)]
    fn lucky_turntable() -> u8;

    #[storage(read, write)]
    fn use_universal_card(_styles: u8);

    #[payable, storage(read, write)]
    fn buy_coin(amount: u64);

    #[storage(read, write)]
    fn claim_point(_identity: Identity, _airdrop_phase: u64, amount: u64);

    #[storage(read, write)]
    fn claim_battle_pool(_amount: u64);

    #[storage(read, write)]
    fn claim(_amount: u64, _styles: u8);

    #[storage(read, write)]
    fn dev_claim(_amount: u64);

    #[storage(read, write)]
    fn airdrop_claim(_amount: u64);

    #[storage(read, write)]
    fn add_constellation_for_test(_identity: Identity);//delete when deploy on mainnet

}

abi Random {
    #[storage(read, write)]
    fn getRandom() -> u64;
}

abi Token {
    #[storage(read, write)]
    fn mint(recipient: Identity, sub_id: SubId, amount: u64);
}

abi ThirdContract {
    #[storage(read)]
    fn get_eligible(identity: Identity) -> bool;
}

use ::sway_libs::{
    ownership::errors::InitializationError,
    upgradability::{
        _proxy_owner,
        _proxy_target,
        _set_proxy_owner,
        _set_proxy_target,
        only_proxy_owner,
    },
};
use standards::{src14::{SRC14, SRC14Extension}};
use std::execution::run_external;
use std::{
    auth::msg_sender,
    block::timestamp,
    call_frames::msg_asset_id,
    constants::ZERO_B256,
    constants::DEFAULT_SUB_ID,
    context::msg_amount,
    hash::*,
    storage::{
        storage_bytes::*,
        storage_string::*,
        storage_vec::*,
    },
    asset::*,
    string::String,
};
use std::primitive_conversions::u64::*;
use std::bytes::Bytes;
use std::logging::log;

enum MintError {
    AlreadyMinted: (),
    FreeMintNotOpen: (),
}

enum AmountError {
    NeedAboveZero: (),
    AmountNotAllow: (),
}

enum AvailableError {
    NotAvailable: (),
}

enum EligibleError {
    NodeNotAvailable: (),
    InviterNotAvailable: (),
    NodeLevelNotSame: (),
}

enum TimeError {
    NotEnoughTime: (),
    Expiry: (),
}

enum AuthorizationError {
    SenderNotOwner: (),
}

enum AssetError {
    InsufficientPayment: (),
    IncorrectAssetSent: (),
}

struct Monster {
    gene: u64,
    starttime: u64,
    genetime: u64,
    cardtime: u64,
    turntabletime: u64,
    expiry: u64,
    bonus: u64,
}

struct Fruit{
    apple: u16,
    banana: u16,
    ananas: u16,
}

struct Accelerator{
    eight_add: u16,
    sixteen_add: u16,
    twentyfour_add: u16,
}

struct Constellation{
    aries: u16,
    taurus: u16,
    gemini: u16,
    cancer: u16,
    leo: u16,
    virgo: u16,
    libra: u16,
    scorpio: u16,
    sagittarius: u16,
    capricornus: u16,
    aquarius: u16,
    pisces: u16,
    zodiac: u16,
    universal: u16,
}

struct Market{
    owner: Identity,
    ownergene: u64,
    bonus: u64,
    constella: u16,
    epoch: u64,
}

struct EpochRef{
    airdrop_phase: u64,
    epoch: u64,
    epoch_time: u64,
    mypoint: Option<u64>,
    my_node_member_num: Option<u64>,
    my_node_level: Option<u64>,
    node_name: Option<String>,
    my_communitybattle_epoch_pair: Option<Identity>,
    my_invite_total_num: Option<u64>,
    my_invite_eligible: Option<bool>,
    my_battle_pool: Option<u64>,
    my_buy_coin: Option<u64>,
}

struct BattleBonus{
    battle_epoch_should_bonus: u64,
    battle_epoch_total_weight: Option<u64>,
    my_battle_epoch_weight: Option<u64>,
    left_bonus: u64,
}

struct InviteBonus{
    invite_epoch_should_bonus: u64,
    invite_epoch_total_num: Option<u64>,
    my_invite_epoch_num: Option<u64>,
    left_bonus: u64,
}

struct CommunityBonus{
    community_epoch_should_bonus: u64,
    community_epoch_total_cpoints: Option<u64>,
    my_cpoints: Option<u64>,
    left_bonus: u64,
}

struct BonusList{
    epoch_should_bonus: Option<u64>,
    epoch_total_weight: Option<u64>,
    my_epoch_weight: Option<u64>,
    has_claimed: Option<bool>,
    epoch: u64,
}

struct ListEvent{
    owner: Identity,
    ownergene: u64,
    bonus: u64,
    constella: u16,
    epoch: u64,
    id: b256,
    time: u64,
}

struct DeListEvent{
    owner: Identity,
    constella: u16,
    epoch: u64,
    id: b256,
    time: u64,
}

struct BattleEvent{
    winer: Identity,
    loser: Identity,
    winer_back: u16, //constellation type
    winer_win: u16,  //constellation type
    loser_get: u64, //token
    epoch: u64,
    id: b256, //delist id
    time: u64,
}

struct EnterPoolEvent{
    owner: Identity,
    weight: u64,
    epoch: u64,
    time: u64,
}

struct UpdateWeightPoolEvent{
    owner: Identity,
    weight: u64,
    epoch: u64,
    time: u64,
}
struct GetCPointsEvent{
    node: Identity,
    from: Identity,
    total_cpoints: u64,
    add_cpoints: u64,
    epoch: u64,
    time: u64,
}

struct UpdateCPointsEvent{
    node: Identity,
    from: Identity,
    total_cpoints: u64,
    add_cpoints: u64,
    epoch: u64,
    time: u64,
}

struct InviteEvent{
    inviter: Identity,
    invitee: Identity,
    node: Identity,
    epoch: u64,
    time: u64,
}

struct BeNodeEvent{
    node: Identity,
    name: str,
    level: u64,
    time: u64,
}

struct NodeLevelUpdateEvent{
    node: Identity,
    level: u64,
    time: u64,
}

struct CommunityBattleEvent{
    challenger: Identity,
    challenged: Identity,
    epoch: u64,
    time: u64,
}

configurable {
    AIRDROP: Identity = Identity::Address(Address::from(0x3b8726d7b9c9c659c3d51f29b636c40a70a039c9b0b2b2a376e93da0d334a93a)),
}

storage {
    one_day: u64 = 60*60*24,
    two_days: u64 = 60*60*24*2,
    five_days: u64 = 60*60*24*5,
    add_eight_hour: u64 = 60*60*8,
    add_sixteen_hour: u64 = 60*60*16,
    add_oneday_hour: u64 = 60*60*24,
    epoch_diff: u64 = 60*60*24*12,//change to 12 days, encourage battle and invite
    free_mint: bool = false,
    epoch: u64 = 0,
    epoch_time: u64 = 0,
    airdrop_phase: u64 = 1,
    node_price: u64 = 1000000, //0.001ETH
    max_node_num: u64 = 10,
    available_node_num: u64 = 0,
    monster_price: u64 = 500000,
    rebirth_price: u64 = 300000,
    gene_price: u64 = 300000,
    apple_price: u64 = 100000,
    banana_price: u64 = 200000,
    ananas_price: u64 = 400000,
    lucky_price: u64 = 50*1000000000,
    combine_price: u64 = 500*1000000000,
    battle_price: u64 = 100*1000000000,
    list_price: u64 = 90*1000000000,
    token_price: u64 = 1000000, //1000000 token/eth
    max_banana: u64 = 100,
    max_universal: u64 = 100,
    max_buy_coin_foreach: u64 = 1000000000000000, //decimal is 9
    constellation_price: u64 = 50000000000,//decimal is 9, encourage battle
    dev_balance: u64 = 0,
    airdrop_balance: u64 = 0,
    lucky_banana: StorageMap<u64, u64> = StorageMap {},
    lucky_universal: StorageMap<u64, u64> = StorageMap {},
    total_point: StorageMap<u64, u64> = StorageMap {},
    mymonster: StorageMap<Identity, Monster> = StorageMap {},
    myfruit: StorageMap<Identity, Fruit> = StorageMap {},
    myconstellation: StorageMap<(Identity, u64), Constellation> = StorageMap {},
    my_name_accelerator: StorageMap<(Identity, u64), bool> = StorageMap {},
    battle_total_bonus: u64 = 0,
    my_battle_epoch_weight: StorageMap<(Identity, u64), u64> = StorageMap {}, //my share weight
    my_battle_claimed: StorageMap<(Identity, u64), bool> = StorageMap {},
    battle_epoch_total_weight: StorageMap<u64, u64> = StorageMap {}, // battle_epoch_should_bonus/battle_epoch_total_weight for one share bonus
    battle_epoch_should_bonus: StorageMap<u64, u64> = StorageMap {},
    battle_epoch_total_bonus: StorageMap<u64, u64> = StorageMap {},
    community_total_bonus: u64 = 0,
    my_cpoints: StorageMap<(Identity, u64), u64> = StorageMap {},//u64->epoch, node member battle and combine same num for cpoints adding to noder
    my_community_claimed: StorageMap<(Identity, u64), bool> = StorageMap {},
    community_epoch_total_cpoints: StorageMap<u64, u64> = StorageMap {}, // community_epoch_should_bonus/community_epoch_total_cpoints for one share bonus
    community_epoch_should_bonus: StorageMap<u64, u64> = StorageMap {},
    community_epoch_total_bonus: StorageMap<u64, u64> = StorageMap {},
    my_communitybattle_epoch_pair: StorageMap<(Identity, u64), Identity> = StorageMap {}, //who is my battle side
    invite_total_bonus: u64 = 0,
    my_invite_total_num: StorageMap<Identity, u64> = StorageMap {}, //my inviter num
    my_invite_epoch_num: StorageMap<(Identity, u64), u64> = StorageMap {}, //my epoch inviter num
    my_invite_claimed: StorageMap<(Identity, u64), bool> = StorageMap {},
    invite_epoch_total_num: StorageMap<u64, u64> = StorageMap {}, // invite_epoch_should_bonus/invite_epoch_total_num for one share bonus
    invite_epoch_should_bonus: StorageMap<u64, u64> = StorageMap {},
    invite_epoch_total_bonus: StorageMap<u64, u64> = StorageMap {},
    myaccelerator: StorageMap<Identity, Accelerator> = StorageMap {},
    mypoints: StorageMap<(Identity, u64), u64> = StorageMap {},//u64->airdrop_phase
    my_battle_pool: StorageMap<Identity, u64> = StorageMap {},
    my_buy_coin_amount: StorageMap<Identity, u64> = StorageMap {},
    markets: StorageMap<b256, Market> = StorageMap {},
    my_inviter: StorageMap<Identity, Identity> = StorageMap {}, //who is my inviter
    inviter_eligible: StorageMap<Identity, bool> = StorageMap {},
    node_eligible: StorageMap<Identity, bool> = StorageMap {},
    my_node: StorageMap<Identity, Identity> = StorageMap {}, //who is my node
    my_node_level: StorageMap<Identity, u64> = StorageMap {}, //same level can battle each other
    my_node_member_num: StorageMap<Identity, u64> = StorageMap {}, 
    node_name: StorageMap<Identity, StorageString> = StorageMap {},
    node_level_map_membernum: StorageMap<u64, u64> = StorageMap {},
    random_contract_id: b256 = 0xb9d62dec6e8b87e495772cd81862db31394bfc3b4d1cb6e04c530f21e3ac1f80,
    token_contract_id: b256 = 0xb9d62dec6e8b87e495772cd81862db31394bfc3b4d1cb6e04c530f21e3ac1f80,
    third_contract_id: b256 = 0xb9d62dec6e8b87e495772cd81862db31394bfc3b4d1cb6e04c530f21e3ac1f80,
    asset_id: b256 = 0xb9d62dec6e8b87e495772cd81862db31394bfc3b4d1cb6e04c530f21e3ac1f80,
    point_owner: Identity = Identity::ContractId(ContractId::from(0xb9d62dec6e8b87e495772cd81862db31394bfc3b4d1cb6e04c530f21e3ac1f80)),
}

impl SRC14 for Contract {

    #[storage(read, write)]
    fn set_proxy_target(new_target: ContractId) {
        only_proxy_owner();
        _set_proxy_target(new_target);
    }

    #[storage(read)]
    fn proxy_target() -> Option<ContractId> {
        _proxy_target()
    }
}

impl SRC14Extension for Contract {
    
    #[storage(read)]
    fn proxy_owner() -> State {
        _proxy_owner()
    }
}

impl OwnedProxy for Contract {

    #[storage(write)]
    fn set_proxy_owner(new_proxy_owner: State) {
        only_proxy_owner();
        _set_proxy_owner(new_proxy_owner);
    }
}

impl Game for Contract {
    #[storage(read, write)]
    fn set_freemint_maxnodenum(_true_false: bool, _max_node_num: u64){
        only_proxy_owner();
        storage.free_mint.write(_true_false);
        storage.max_node_num.write(_max_node_num);
    }

    #[storage(read, write)]
    fn set_first_node(_identity: Identity, _community_name: str){
        only_proxy_owner();

        //if benode after invited, then should add 1 in me, sub 1 from before node
        let before_node = storage.my_node.get(_identity).try_read();
        if before_node.is_some() {
            let before_node_member_num = storage.my_node_member_num.get(before_node.unwrap()).try_read();
            if before_node_member_num.is_some() {
                let mut _before_node_member_num = before_node_member_num.unwrap();
                if _before_node_member_num > 0 {
                    _before_node_member_num = _before_node_member_num - 1;
                    storage.my_node_member_num.insert(before_node.unwrap(), _before_node_member_num);
                }
            }
        }

        storage.my_node.insert(_identity, _identity);
        storage.node_eligible.insert(_identity, true);
        //deal node member num 
        let record = storage.mymonster.get(_identity).try_read();
        if record.is_some() {//has monster, should add 1 member for self
           storage.my_node_member_num.insert(_identity, 1);
        }else{//dont has monster, member is 0
           storage.my_node_member_num.insert(_identity, 0);
        }

        storage.my_node_level.insert(_identity, 1);
        storage.inviter_eligible.insert(_identity, true);
        //insert node name
        storage.node_name.insert(_identity, StorageString{});
        storage.node_name.get(_identity).write_slice(String::from_ascii_str(_community_name));
        log(BeNodeEvent{
            node: _identity,
            name: _community_name,
            level: 1,
            time: timestamp(),
        });
    }

    #[storage(read, write)]
    fn set_node_level_membernum(_level: u64, _num: u64){//1, 10; 2, 50; 3, 100; 4, 200; 5, 500; 6, 1000; 
        only_proxy_owner();
        storage.node_level_map_membernum.insert(_level, _num);
    }

    #[storage(read, write)]
    fn set_random_token_contract(_random_contract_id: b256, _token_contract_id: b256, _asset_id: b256){
        only_proxy_owner();
        storage.random_contract_id.write(_random_contract_id);
        storage.token_contract_id.write(_token_contract_id);
        storage.asset_id.write(_asset_id);
    }

    #[storage(read, write)]
    fn set_third_pointowner_contract(_contract_id: b256, _identity: Identity){
        only_proxy_owner();
        storage.third_contract_id.write(_contract_id);
        storage.point_owner.write(_identity);
    }

    #[storage(read, write)]
    fn set_fruit_price(_apple_price: u64, _banana_price: u64, _ananas_price: u64){
        only_proxy_owner();
        require(
            _apple_price > 0 && _banana_price > 0 && _ananas_price > 0, 
            AmountError::NeedAboveZero,
        );
        storage.apple_price.write(_apple_price);
        storage.banana_price.write(_banana_price);
        storage.ananas_price.write(_ananas_price);
    }

    #[storage(read, write)]
    fn set_days(_one_day: u64, _two_days: u64, _five_days: u64, _epoch_diff: u64){
        only_proxy_owner();
        require(
            _one_day > 0 && _two_days > 0 && _five_days > 0 && _epoch_diff > 0, 
            AmountError::NeedAboveZero,
        );
        storage.one_day.write(_one_day);
        storage.two_days.write(_two_days);
        storage.five_days.write(_five_days);
        storage.epoch_diff.write(_epoch_diff);
    }

    #[storage(read, write)]
    fn set_accelerator_hour(_add_eight_hour: u64, _add_sixteen_hour: u64, _add_oneday_hour: u64){
        only_proxy_owner();
        require(
            _add_eight_hour > 0 && _add_sixteen_hour > 0 && _add_oneday_hour > 0, 
            AmountError::NeedAboveZero,
        );
        storage.add_eight_hour.write(_add_eight_hour);
        storage.add_sixteen_hour.write(_add_sixteen_hour);
        storage.add_oneday_hour.write(_add_oneday_hour);
    }

    #[storage(read, write)]
    fn set_lucky_combine_battle_list_price(_lucky_price: u64, _combine_price: u64, _battle_price: u64, _list_price: u64){
        only_proxy_owner();
        storage.lucky_price.write(_lucky_price);
        storage.combine_price.write(_combine_price);
        storage.battle_price.write(_battle_price);
        storage.list_price.write(_list_price);
    }

    #[storage(read, write)]
    fn set_constellation_token_price(_constellation_price: u64, _token_price: u64){
        only_proxy_owner();
        storage.constellation_price.write(_constellation_price);
        storage.token_price.write(_token_price);
    }

    #[storage(read, write)]
    fn set_monster_node_rebirth_gene_price(_monster_price: u64, _node_price: u64, _rebirth_price: u64, _gene_price: u64){
        only_proxy_owner();
        storage.monster_price.write(_monster_price);
        storage.node_price.write(_node_price);
        storage.rebirth_price.write(_rebirth_price);
        storage.gene_price.write(_gene_price);
    }

    #[storage(read, write)]
    fn add_airdrop_phase(){
        only_proxy_owner();
        storage.airdrop_phase.write(storage.airdrop_phase.read() + 1);
    }

    #[payable]
    #[storage(read, write)]
    fn become_node(_community_name: str){
        let identity = msg_sender().unwrap();
        require(
            storage.available_node_num.read() < storage.max_node_num.read(),
            AvailableError::NotAvailable,
        );

        //check and deal epoch
        check_deal_epoch();

        let _epoch = storage.epoch.read();
        
        // Verify payment
        require(AssetId::base() == msg_asset_id(), AssetError::IncorrectAssetSent);
        require(
            storage.node_price.read() <= msg_amount(),
            AssetError::InsufficientPayment,
        );
        // do allocation
        do_allocation(_epoch, storage.node_price.read());

        //if benode after invited, then should add 1 in me, sub 1 from before node
        let before_node = storage.my_node.get(identity).try_read();
        if before_node.is_some() {
            let before_node_member_num = storage.my_node_member_num.get(before_node.unwrap()).try_read();
            if before_node_member_num.is_some() {
                let mut _before_node_member_num = before_node_member_num.unwrap();
                if _before_node_member_num > 0 {
                    _before_node_member_num = _before_node_member_num - 1;
                    storage.my_node_member_num.insert(before_node.unwrap(), _before_node_member_num);
                }
            }
        }

        //add node
        storage.my_node.insert(identity, identity);
        storage.node_eligible.insert(identity, true);

        //deal node member num 
        let record = storage.mymonster.get(identity).try_read();
        if record.is_some() {//has monster, should add 1 member for self
           storage.my_node_member_num.insert(identity, 1);
        }else{//dont has monster, member is 0
           storage.my_node_member_num.insert(identity, 0);
        }
        
        storage.my_node_level.insert(identity, 1);
        storage.inviter_eligible.insert(identity, true);
        storage.available_node_num.write(storage.available_node_num.read() + 1);

        //insert node name
        storage.node_name.insert(identity, StorageString{});
        storage.node_name.get(identity).write_slice(String::from_ascii_str(_community_name));
        log(BeNodeEvent{
            node: identity,
            name: _community_name,
            level: 1,
            time: timestamp(),
        });
    }

    #[payable]
    #[storage(read, write)]
    fn mint_monster(_inviter: Identity){
        //check inviter eligible
        let _inviter_eligible = storage.inviter_eligible.get(_inviter).try_read();
        require(_inviter_eligible.is_some(),
            EligibleError::InviterNotAvailable,
        );
        require(_inviter_eligible.unwrap(),
            EligibleError::InviterNotAvailable,
        );
        //check node eligible
        let _node = storage.my_node.get(_inviter).try_read();
        require(
            _node.is_some(),
            EligibleError::NodeNotAvailable,
        );
        let _node_eligible = storage.node_eligible.get(_node.unwrap()).try_read();
        require(_node_eligible.is_some(),
            EligibleError::NodeNotAvailable,
        );
        require(_node_eligible.unwrap(),
            AvailableError::NotAvailable,
        );

        let identity = msg_sender().unwrap();
        let record = storage.mymonster.get(identity).try_read();
        require(record.is_none(),
            MintError::AlreadyMinted,
        );

        //check and deal epoch
        check_deal_epoch();

        let _epoch = storage.epoch.read();
        
        // Verify payment
        require(AssetId::base() == msg_asset_id(), AssetError::IncorrectAssetSent);
        require(
            storage.monster_price.read() <= msg_amount(),
            AssetError::InsufficientPayment,
        );

        // do allocation
        do_allocation(_epoch, storage.monster_price.read());
        
       // Omitting the processing algorithm for random numbers
        let _geni = 12020329928232323;
        let _bonus = 5; 
        let _expiry = 3;
        // Omitting the processing algorithm for random numbers

        // Store monster
        let monster = Monster{gene: _geni.unwrap(), starttime: timestamp(), genetime:timestamp(), cardtime: timestamp(), turntabletime: timestamp(), expiry: timestamp()+ storage.one_day.read()*_expiry, bonus: _mybonus};
        storage.mymonster.insert(identity, monster);
        
        //add 10 point
        let airdropphase = storage.airdrop_phase.read();
        let point = storage.mypoints.get((identity, airdropphase)).try_read();
        if(point.is_some()){
            let mut _point = point.unwrap();
            _point = _point + 10;
            //update
            storage.mypoints.insert((identity, airdropphase), _point);
        }else{
            storage.mypoints.insert((identity, airdropphase), 10);
        }
        //add total point
        let totalpoint = storage.total_point.get(airdropphase).try_read();
        if totalpoint.is_some(){
            let mut _totalpoint = totalpoint.unwrap();
            _totalpoint = _totalpoint + 10;
            storage.total_point.insert(airdropphase, _totalpoint);
        }else{
            storage.total_point.insert(airdropphase, 10);
        }

        //deal inviter
        let myinviter = storage.my_inviter.get(identity).try_read();
        if myinviter.is_none() {
            storage.my_inviter.insert(identity, _inviter);
            let _my_eigible = storage.inviter_eligible.get(identity).try_read();
            if _my_eigible.is_none() {
                storage.inviter_eligible.insert(identity, true);
            }
            deal_inviter(_epoch, _inviter);
             //deal node, add my node info 
            let mynode =storage.my_node.get(identity).try_read();
            let mut _mynode = _node.unwrap();
            if mynode.is_none() {
                storage.my_node.insert(identity, _node.unwrap());
            }else{//already node, but use other inviter
                _mynode = mynode.unwrap();
            }
            deal_node(_mynode);
            log(InviteEvent{
                inviter: _inviter,
                invitee: identity,
                node: _mynode,
                epoch: _epoch,
                time: timestamp(),
            });
            //give inviter 8h accelerator_card
            let accelerator = storage.myaccelerator.get(_inviter).try_read();
            if accelerator.is_some() {
                let mut _accelerator = accelerator.unwrap();
                _accelerator.eight_add = _accelerator.eight_add + 1;
                //update
                storage.myaccelerator.insert(_inviter, _accelerator);
            }else {
                let _accelerator = Accelerator{eight_add: 1, sixteen_add: 0, twentyfour_add: 0};
                storage.myaccelerator.insert(_inviter, _accelerator);
            }
        }      
    }

    #[storage(read, write)]
    fn free_mint_monster(_inviter: Identity){
        //check inviter eligible
        let _inviter_eligible = storage.inviter_eligible.get(_inviter).try_read();
        require(_inviter_eligible.is_some(),
            EligibleError::InviterNotAvailable,
        );
        require(_inviter_eligible.unwrap(),
            EligibleError::InviterNotAvailable,
        );
        //check node eligible
        let _node = storage.my_node.get(_inviter).try_read();
        require(
            _node.is_some(),
            EligibleError::NodeNotAvailable,
        );
        let _node_eligible = storage.node_eligible.get(_node.unwrap()).try_read();
        require(_node_eligible.is_some(),
            EligibleError::NodeNotAvailable,
        );
        require(_node_eligible.unwrap(),
            AvailableError::NotAvailable,
        );

        let identity = msg_sender().unwrap();
        let record = storage.mymonster.get(identity).try_read();
        require(
            record.is_none(),
            MintError::AlreadyMinted,
        );

        require(
            storage.free_mint.read(),
            MintError::FreeMintNotOpen,
        );

        let third_contract = abi(ThirdContract, storage.third_contract_id.read());
        let _myeligible = third_contract.get_eligible(identity);
        require(
            _myeligible,
            AvailableError::NotAvailable,
        );

        //check and deal epoch
        check_deal_epoch();
        let _epoch = storage.epoch.read();


        // Omitting the processing algorithm for random numbers
        let _geni = 12020329928232323;
        let _bonus = 5; 
        let _expiry = 3;
        // Omitting the processing algorithm for random numbers

        // Store monster
        let monster = Monster{gene: _geni.unwrap(), starttime: timestamp(), genetime:timestamp(), cardtime: timestamp(), turntabletime: timestamp(), expiry: timestamp()+ storage.one_day.read()*_expiry, bonus: _bonus};
        storage.mymonster.insert(identity, monster);

        //deal inviter
        let myinviter = storage.my_inviter.get(identity).try_read();
        if myinviter.is_none() {
            storage.my_inviter.insert(identity, _inviter);
            let _my_eigible = storage.inviter_eligible.get(identity).try_read();
            if _my_eigible.is_none() {
                storage.inviter_eligible.insert(identity, true);
            }
            deal_inviter(_epoch, _inviter);
             //deal node, add my node info 
            let mynode =storage.my_node.get(identity).try_read();
            let mut _mynode = _node.unwrap();
            if mynode.is_none() {
                storage.my_node.insert(identity, _node.unwrap());
            }else{//already node, but use other inviter
                _mynode = mynode.unwrap();
            }
            deal_node(_mynode);
            log(InviteEvent{
                inviter: _inviter,
                invitee: identity,
                node: _mynode,
                epoch: _epoch,
                time: timestamp(),
            });
            //give inviter 8h accelerator_card
            let accelerator = storage.myaccelerator.get(_inviter).try_read();
            if accelerator.is_some() {
                let mut _accelerator = accelerator.unwrap();
                _accelerator.eight_add = _accelerator.eight_add + 1;
                //update
                storage.myaccelerator.insert(_inviter, _accelerator);
            }else {
                let _accelerator = Accelerator{eight_add: 1, sixteen_add: 0, twentyfour_add: 0};
                storage.myaccelerator.insert(_inviter, _accelerator);
            }
        }
        
    }

    //add airdrop_phase
    #[storage(read)]
    fn get_my_info(_identity: Identity)->(Option<Monster>, Option<Fruit>, Option<Constellation>, Option<Accelerator>, EpochRef, BattleBonus, InviteBonus, CommunityBonus) {

        let _epoch = storage.epoch.read();
        let epochref = EpochRef{
                                airdrop_phase: storage.airdrop_phase.read(), 
                                epoch: storage.epoch.read(), 
                                epoch_time: storage.epoch_time.read(), 
                                mypoint: storage.mypoints.get((_identity, storage.airdrop_phase.read())).try_read(), 
                                my_node_member_num: storage.my_node_member_num.get(_identity).try_read(),
                                my_node_level: storage.my_node_level.get(_identity).try_read(),
                                node_name: storage.node_name.get(_identity).read_slice(),
                                my_communitybattle_epoch_pair: storage.my_communitybattle_epoch_pair.get((_identity, _epoch)).try_read(),
                                my_invite_total_num: storage.my_invite_total_num.get(_identity).try_read(),
                                my_invite_eligible: storage.inviter_eligible.get(_identity).try_read(),
                                my_buy_coin: storage.my_buy_coin_amount.get(_identity).try_read(), 
                                my_battle_pool: storage.my_battle_pool.get(_identity).try_read()
                                };

        if _epoch < 1 {
            let battlebonus = BattleBonus{battle_epoch_should_bonus: 0, 
                    battle_epoch_total_weight: storage.battle_epoch_total_weight.get(_epoch).try_read(), 
                    my_battle_epoch_weight: storage.my_battle_epoch_weight.get((_identity, _epoch)).try_read(), 
                    left_bonus: 0
                    };
            let invitebonus = InviteBonus{invite_epoch_should_bonus: 0, 
                invite_epoch_total_num: storage.invite_epoch_total_num.get(_epoch).try_read(), 
                my_invite_epoch_num: storage.my_invite_epoch_num.get((_identity, _epoch)).try_read(), 
                left_bonus: 0
                };

            let communitybonus = CommunityBonus{community_epoch_should_bonus: 0, 
                community_epoch_total_cpoints: storage.community_epoch_total_cpoints.get(_epoch).try_read(), 
                my_cpoints: storage.my_cpoints.get((_identity, _epoch)).try_read(), 
                left_bonus: 0
                };
            
            return  (storage.mymonster.get(_identity).try_read(), 
                    storage.myfruit.get(_identity).try_read(), 
                    storage.myconstellation.get((_identity, _epoch)).try_read(), 
                    storage.myaccelerator.get(_identity).try_read(),
                    epochref,
                    battlebonus,
                    invitebonus,
                    communitybonus
                    );

        }else{
            let _battle_epoch_total_bonus = storage.battle_epoch_total_bonus.get(_epoch).try_read();//if no new address mint, then is null, so there should check!!
            let _invite_epoch_total_bonus = storage.invite_epoch_total_bonus.get(_epoch).try_read();
            let _community_epoch_total_bonus = storage.community_epoch_total_bonus.get(_epoch).try_read();
            let mut _battle_epoch_should_bonus :u64 = 0;
            let mut _invite_epoch_should_bonus :u64 = 0;
            let mut _community_epoch_should_bonus :u64 = 0;
            if _battle_epoch_total_bonus.is_some() {
                let _total_bonus = storage.battle_total_bonus.read() - _battle_epoch_total_bonus.unwrap()/2;
                let should_bonus = _battle_epoch_total_bonus.unwrap() / 2 + _total_bonus*20 /100 ;
                _battle_epoch_should_bonus = should_bonus;         
            }
            if _invite_epoch_total_bonus.is_some() {
                let _total_bonus = storage.invite_total_bonus.read() - _invite_epoch_total_bonus.unwrap()/2;
                let should_bonus = _invite_epoch_total_bonus.unwrap() / 2 + _total_bonus*20 /100 ;
                _invite_epoch_should_bonus = should_bonus;         
            }
            if _community_epoch_total_bonus.is_some() {
                let _total_bonus = storage.community_total_bonus.read() - _community_epoch_total_bonus.unwrap()/2;
                let should_bonus = _community_epoch_total_bonus.unwrap() / 2 + _total_bonus*20 /100 ;
                _community_epoch_should_bonus = should_bonus;         
            }

            let battlebonus = BattleBonus{battle_epoch_should_bonus: _battle_epoch_should_bonus, 
                battle_epoch_total_weight: storage.battle_epoch_total_weight.get(_epoch).try_read(), 
                my_battle_epoch_weight: storage.my_battle_epoch_weight.get((_identity, _epoch)).try_read(), 
                left_bonus: storage.battle_total_bonus.read()
                };

            let invitebonus = InviteBonus{invite_epoch_should_bonus: _invite_epoch_should_bonus, 
                invite_epoch_total_num: storage.invite_epoch_total_num.get(_epoch).try_read(), 
                my_invite_epoch_num: storage.my_invite_epoch_num.get((_identity, _epoch)).try_read(), 
                left_bonus: storage.invite_total_bonus.read()
                };

            let communitybonus = CommunityBonus{community_epoch_should_bonus: _community_epoch_should_bonus, 
                community_epoch_total_cpoints: storage.community_epoch_total_cpoints.get(_epoch).try_read(), 
                my_cpoints: storage.my_cpoints.get((_identity, _epoch)).try_read(), 
                left_bonus: storage.community_total_bonus.read()
                };
        
            return  (storage.mymonster.get(_identity).try_read(), 
                    storage.myfruit.get(_identity).try_read(), 
                    storage.myconstellation.get((_identity, _epoch)).try_read(), 
                    storage.myaccelerator.get(_identity).try_read(),
                    epochref,
                    battlebonus,
                    invitebonus,
                    communitybonus
                    );
        }
    }

    #[storage(read)]
    fn get_total_point(_airdrop_phase: u64)->Option<u64>{
        storage.total_point.get((_airdrop_phase)).try_read()
    }

    #[storage(read)]
    fn get_share_bonus_list(_identity: Identity) -> Vec<BonusList>{
        let _epoch = storage.epoch.read();
        if _epoch < 2{
            return Vec::new();
        }else{
            let mut counter = _epoch;
            let mut _bonuslist = Vec::new();
            while counter > 1 {
                counter -= 1;
                let bonuslist = BonusList{epoch_should_bonus: storage.battle_epoch_should_bonus.get(counter).try_read(), 
                                epoch_total_weight: storage.battle_epoch_total_weight.get(counter).try_read(), 
                                my_epoch_weight: storage.my_battle_epoch_weight.get((_identity, counter)).try_read(), 
                                epoch: counter,
                                has_claimed: storage.my_battle_claimed.get((_identity, counter)).try_read(), 
                                };
                _bonuslist.push(bonuslist);
            }
            return _bonuslist;
        }
    }

    #[storage(read)]
    fn get_invite_bonus_list(_identity: Identity) -> Vec<BonusList>{
        let _epoch = storage.epoch.read();
        if _epoch < 2{
            return Vec::new();
        }else{
            let mut counter = _epoch;
            let mut _bonuslist = Vec::new();
            while counter > 1 {
                counter -= 1;
                let bonuslist = BonusList{epoch_should_bonus: storage.invite_epoch_should_bonus.get(counter).try_read(), 
                                epoch_total_weight: storage.invite_epoch_total_num.get(counter).try_read(), 
                                my_epoch_weight: storage.my_invite_epoch_num.get((_identity, counter)).try_read(), 
                                epoch: counter,
                                has_claimed: storage.my_invite_claimed.get((_identity, counter)).try_read(), 
                                };
                _bonuslist.push(bonuslist);
            }
            return _bonuslist;
        }
    }

    #[storage(read)]
    fn get_community_bonus_list(_identity: Identity) -> Vec<BonusList>{
        let _epoch = storage.epoch.read();
        if _epoch < 2{
            return Vec::new();
        }else{
            let mut counter = _epoch;
            let mut _bonuslist = Vec::new();
            while counter > 1 {
                counter -= 1;
                let my_c_epoch_pair = storage.my_communitybattle_epoch_pair.get((_identity, counter)).try_read();
                if my_c_epoch_pair.is_some() {
                    let mycpoint = storage.my_cpoints.get((_identity, counter)).try_read();
                    let sidecpoint = storage.my_cpoints.get((my_c_epoch_pair.unwrap(), counter)).try_read();
                    //check try
                    if mycpoint.is_some() && sidecpoint.is_some() {
                        let mut _mycpoint = mycpoint.unwrap();
                        if mycpoint.unwrap() > sidecpoint.unwrap() {
                            _mycpoint = _mycpoint + sidecpoint.unwrap();
                        }else if mycpoint.unwrap() < sidecpoint.unwrap() {
                            _mycpoint = 0;
                        }

                        let bonuslist = BonusList{epoch_should_bonus: storage.community_epoch_should_bonus.get(counter).try_read(), 
                                    epoch_total_weight: storage.community_epoch_total_cpoints.get(counter).try_read(), 
                                    my_epoch_weight: Some(_mycpoint), 
                                    epoch: counter,
                                    has_claimed: storage.my_community_claimed.get((_identity, counter)).try_read(), 
                                    };
                        _bonuslist.push(bonuslist);
                    }else{
                        let bonuslist = BonusList{epoch_should_bonus: storage.community_epoch_should_bonus.get(counter).try_read(), 
                                epoch_total_weight: storage.community_epoch_total_cpoints.get(counter).try_read(), 
                                my_epoch_weight: storage.my_cpoints.get((_identity, counter)).try_read(), 
                                epoch: counter,
                                has_claimed: storage.my_community_claimed.get((_identity, counter)).try_read(), 
                                };
                        _bonuslist.push(bonuslist);
                    }
                    
                }else{
                    let bonuslist = BonusList{epoch_should_bonus: storage.community_epoch_should_bonus.get(counter).try_read(), 
                                epoch_total_weight: storage.community_epoch_total_cpoints.get(counter).try_read(), 
                                my_epoch_weight: storage.my_cpoints.get((_identity, counter)).try_read(), 
                                epoch: counter,
                                has_claimed: storage.my_community_claimed.get((_identity, counter)).try_read(), 
                                };
                    _bonuslist.push(bonuslist);

                }
                
            }
            return _bonuslist;
        }
    }


    #[storage(read)]
    fn get_lucky_banana_universal(_epoch: u64)->(Option<u64>, Option<u64>){
        (storage.lucky_banana.get(_epoch).try_read(),
         storage.lucky_universal.get(_epoch).try_read())
    }

    #[storage(read)]
    fn get_dev_airdrop_balance()->(u64, u64){
        (storage.dev_balance.read(), storage.airdrop_balance.read())
    }

    #[payable]
    #[storage(read, write)]
    fn buy_fruit(_styles: u8, _amount: u16){
        let identity = msg_sender().unwrap();
        let fruit = storage.myfruit.get(identity).try_read();
        let monster = storage.mymonster.get(identity).try_read();
        require(monster.is_some(),
            AvailableError::NotAvailable,
        );
        require(
            _amount > 0,
            AmountError::NeedAboveZero,
        );
        // Verify payment
        require(AssetId::base() == msg_asset_id(), AssetError::IncorrectAssetSent);
        if _styles == 1 {
            require(
                storage.apple_price.read() <= msg_amount(),
                AssetError::InsufficientPayment,
            );
        }else if _styles == 2{
            require(
                storage.banana_price.read() <= msg_amount(),
                AssetError::InsufficientPayment,
            );
        }else{
            require(
                storage.ananas_price.read() <= msg_amount(),
                AssetError::InsufficientPayment,
            );
        }
        
        //check and deal epoch
        check_deal_epoch();

        let _epoch = storage.epoch.read();
        
        // do allocation
        do_allocation(_epoch, msg_amount());

        if fruit.is_some() {
            let mut _fruit = fruit.unwrap();
            if _styles == 1 {
                _fruit.apple = _fruit.apple + _amount;
            }else if _styles == 2{
                _fruit.banana = _fruit.banana + _amount;
            }else{
                _fruit.ananas = _fruit.ananas + _amount;
            }
            //update
            storage.myfruit.insert(identity, _fruit);

        }else{
            
            if _styles == 1 {
                let _fruit = Fruit{apple: _amount, banana: 0, ananas: 0};
                storage.myfruit.insert(identity, _fruit);
            }else if _styles == 2{
                let _fruit = Fruit{apple: 0, banana: _amount, ananas: 0};
                storage.myfruit.insert(identity, _fruit);
            }else{
                let _fruit = Fruit{apple: 0, banana: 0, ananas: _amount};
                storage.myfruit.insert(identity, _fruit);
            }
        }
    }

    #[storage(read, write)]
    fn feed_fruit(_styles: u8){
        let identity = msg_sender().unwrap();
        let fruit = storage.myfruit.get(identity).try_read();
        let monster = storage.mymonster.get(identity).try_read();
        require(fruit.is_some(),
            AvailableError::NotAvailable,
        );
        require(monster.is_some(),
            AvailableError::NotAvailable,
        );
        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );
        let mut _fruit = fruit.unwrap();
        let mut _monster = monster.unwrap();
        if _styles == 1 {
            require(
                _fruit.apple > 0,
                AmountError::NeedAboveZero,
            );
            _fruit.apple = _fruit.apple - 1;
            _monster.expiry = timestamp() + storage.one_day.read();
        }else if _styles == 2{
            require(
                _fruit.banana > 0,
                AmountError::NeedAboveZero,
            );
            _fruit.banana = _fruit.banana - 1;
            _monster.expiry = timestamp() + storage.two_days.read();
        }else{
            require(
                _fruit.ananas > 0,
                AmountError::NeedAboveZero,
            );
            _fruit.ananas = _fruit.ananas - 1;
            _monster.expiry = timestamp() + storage.five_days.read();
        }
        //update
        storage.myfruit.insert(identity, _fruit);
        storage.mymonster.insert(identity, _monster);

    }

    #[storage(read, write)]
    fn using_accelerator_card(_styles: u8){
        let identity = msg_sender().unwrap();
        let accelerator = storage.myaccelerator.get(identity).try_read();
        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );
        require(
            accelerator.is_some(),
            AvailableError::NotAvailable,
        );

        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );

        let mut _accelerator = accelerator.unwrap();
        let mut _monster = monster.unwrap();
        if _styles == 1 {
            require(
                _accelerator.eight_add > 0,
                AmountError::NeedAboveZero,
            );
            _accelerator.eight_add = _accelerator.eight_add - 1;
            _monster.cardtime = _monster.cardtime - storage.add_eight_hour.read();
        }else if _styles == 2 {
            require(
                _accelerator.sixteen_add > 0,
                AmountError::NeedAboveZero,
            );
            _accelerator.sixteen_add = _accelerator.sixteen_add - 1;
            _monster.cardtime = _monster.cardtime - storage.add_sixteen_hour.read();
        }else {
            require(
                _accelerator.twentyfour_add > 0,
                AmountError::NeedAboveZero,
            );
            _accelerator.twentyfour_add = _accelerator.twentyfour_add - 1;
            _monster.cardtime = _monster.cardtime - storage.add_oneday_hour.read();
        }
        //update
        storage.myaccelerator.insert(identity, _accelerator);
        storage.mymonster.insert(identity, _monster);

    }

    #[storage(read, write)]
    fn claim_constellation()->u8{
        let identity = msg_sender().unwrap();
        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );
        require(
            timestamp() > monster.unwrap().cardtime + storage.one_day.read(),
            TimeError::NotEnoughTime,
        );

        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );

        //check and deal epoch
        check_deal_epoch();

        let _epoch = storage.epoch.read();

         // Omitting the processing algorithm for random numbers
        let random = 3;
        // Omitting the processing algorithm for random numbers

        let mut _result: u8 = 1;
        let constellation = storage.myconstellation.get((identity, _epoch)).try_read();
        if constellation.is_some() {
            let mut _constellation = constellation.unwrap();
            if random == 1 {
                _constellation.aries = _constellation.aries + 1;
            }else if random == 2 {
                _constellation.taurus = _constellation.taurus + 1;
            }else if random == 3 {
                _constellation.gemini = _constellation.gemini + 1;
            }else if random == 4 {
                _constellation.cancer = _constellation.cancer + 1;
            }else if random == 5 {
                _constellation.leo = _constellation.leo + 1;
            }else if random == 6 {
                _constellation.virgo = _constellation.virgo + 1;
            }else if random == 7 {
                _constellation.libra = _constellation.libra + 1;
            }else if random == 8 {
                _constellation.scorpio = _constellation.scorpio + 1;
            }else if random == 9 {
                _constellation.sagittarius = _constellation.sagittarius + 1;
            }else if random == 10 {
                _constellation.capricornus = _constellation.capricornus + 1;
            }else if random == 11 {
                _constellation.aquarius = _constellation.aquarius + 1;
            }else {
                _constellation.pisces = _constellation.pisces + 1;
            }
            //update
            storage.myconstellation.insert((identity, _epoch), _constellation);

        }else{
            if random == 1 {
                let _constellation = Constellation{aries: 1, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }else if random == 2 {
                let _constellation = Constellation{aries: 0, taurus: 1, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }else if random == 3 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 1, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }else if random == 4 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 1, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }else if random == 5 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 1, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }else if random == 6 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 1, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }else if random == 7 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 1, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }else if random == 8 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 1, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }else if random == 9 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 1, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }else if random == 10 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 1, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }else if random == 11 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 1, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }else {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 1, angel: 0, universal: 0};
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }
        }
        _result = random;
        let mut _monster = monster.unwrap();
        _monster.cardtime = timestamp();
        //update
        storage.mymonster.insert(identity, _monster);

        //return random, so front can konw which constella got
        return _result;

    }

    #[payable]
    #[storage(read, write)]
    fn combine_constellation(){//combine first, then update epoch
        let identity = msg_sender().unwrap();
        let _epoch = storage.epoch.read();
        let constellation = storage.myconstellation.get((identity, _epoch)).try_read();
        let airdropphase = storage.airdrop_phase.read();
        let point = storage.mypoints.get((identity, airdropphase)).try_read();
        // let point = storage.mypoints.get(identity).try_read();
        require(
            constellation.is_some(),
            AvailableError::NotAvailable,
        );

        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );

        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );

        //get asset id
        // let token_contract = abi(Token, storage.token_contract_id.read());
        // let asset_id = token_contract.getAssetId(); 

        // Verify payment
        require(AssetId::from(storage.asset_id.read()) == msg_asset_id(), AssetError::IncorrectAssetSent);
        require(
            storage.combine_price.read() <= msg_amount(),
            AssetError::InsufficientPayment,
        );

        //do bonus, add epoch total shares
        let _my_share = storage.my_battle_epoch_weight.get((identity, _epoch)).try_read();
        if _my_share.is_some() {
          let mut my_share = _my_share.unwrap();
          my_share = my_share + monster.unwrap().bonus;
          storage.my_battle_epoch_weight.insert((identity, _epoch), my_share);
          log(UpdateWeightPoolEvent{
                owner: identity,
                weight: my_share,
                epoch: _epoch,
                time: timestamp(),
            });
        }else{
          storage.my_battle_epoch_weight.insert((identity, _epoch), monster.unwrap().bonus);
          log(EnterPoolEvent{
                owner: identity,
                weight: monster.unwrap().bonus,
                epoch: _epoch,
                time: timestamp(),
            });
        }
        let _total_share = storage.battle_epoch_total_weight.get(_epoch).try_read();
        if _total_share.is_some() {
            let mut total_share = _total_share.unwrap();
            total_share = total_share + monster.unwrap().bonus;
            //update
            storage.battle_epoch_total_weight.insert(_epoch, total_share);
        }else{
            storage.battle_epoch_total_weight.insert(_epoch, monster.unwrap().bonus);
        }


        let mut _constellation = constellation.unwrap();
        require(
            _constellation.aries > 0 && _constellation.taurus > 0 && _constellation.gemini > 0 && _constellation.cancer > 0 && _constellation.leo > 0 && _constellation.virgo > 0 && _constellation.libra > 0 && _constellation.scorpio > 0 && _constellation.sagittarius > 0  && _constellation.capricornus > 0  && _constellation.aquarius > 0  && _constellation.pisces > 0,
            AmountError::NeedAboveZero,
        );
        _constellation.aries = _constellation.aries - 1;
        _constellation.taurus = _constellation.taurus - 1;
        _constellation.gemini = _constellation.gemini - 1;
        _constellation.cancer = _constellation.cancer - 1;
        _constellation.leo = _constellation.leo - 1;
        _constellation.virgo = _constellation.virgo - 1;
        _constellation.libra = _constellation.libra - 1;
        _constellation.scorpio = _constellation.scorpio - 1;
        _constellation.sagittarius = _constellation.sagittarius - 1;
        _constellation.capricornus = _constellation.capricornus - 1;
        _constellation.aquarius = _constellation.aquarius - 1;
        _constellation.pisces = _constellation.pisces - 1;
        _constellation.zodiac = _constellation.zodiac + 1;
        //update
        storage.myconstellation.insert((identity, _epoch), _constellation);

        //update point
        if(point.is_some()){
            let mut _point = point.unwrap();
            _point = _point + 10;
            //update
            storage.mypoints.insert((identity, airdropphase), _point);
        }else{
            storage.mypoints.insert((identity, airdropphase), 10);
        }

        //update cpoints
        let mynode = storage.my_node.get(identity).try_read();
        if mynode.is_some() {
            let mycpoint = storage.my_cpoints.get((mynode.unwrap(), _epoch)).try_read();
            if mycpoint.is_some() {
                let mut _mycpoint = mycpoint.unwrap();
                _mycpoint = _mycpoint + 10;
                storage.my_cpoints.insert((mynode.unwrap(), _epoch), _mycpoint);
                log(UpdateCPointsEvent{
                    node: mynode.unwrap(),
                    from: identity,
                    total_cpoints: _mycpoint,
                    add_cpoints: 10,
                    epoch: _epoch,
                    time: timestamp(),
                });
            }else{
                storage.my_cpoints.insert((mynode.unwrap(), _epoch), 10);
                log(GetCPointsEvent{
                    node: mynode.unwrap(),
                    from: identity,
                    total_cpoints: 10,
                    add_cpoints: 10,
                    epoch: _epoch,
                    time: timestamp(),
                });
            }
            let c_epoch_total_cpoints = storage.community_epoch_total_cpoints.get(_epoch).try_read();
            if c_epoch_total_cpoints.is_some() {
                let mut _c_epoch_total_cpoints = c_epoch_total_cpoints.unwrap();
                _c_epoch_total_cpoints = _c_epoch_total_cpoints + 10;
                storage.community_epoch_total_cpoints.insert(_epoch, _c_epoch_total_cpoints);
            }else{
                storage.community_epoch_total_cpoints.insert(_epoch, 10);
            }
            //add 10% point for noder
            let _mypoints = storage.mypoints.get((mynode.unwrap(), airdropphase)).try_read();
            if _mypoints.is_some() {
                let mut mypoints_ = _mypoints.unwrap();
                mypoints_ = mypoints_ + 1;
                storage.mypoints.insert((mynode.unwrap(), airdropphase), mypoints_);
            }else{
                storage.mypoints.insert((mynode.unwrap(), airdropphase), 1);
            }
        }

        //add 20% point for inviter
        let myinviter = storage.my_inviter.get(identity).try_read();
        if myinviter.is_some() {
            let _mypoints = storage.mypoints.get((myinviter.unwrap(), airdropphase)).try_read();
            if _mypoints.is_some() {
                let mut mypoints_ = _mypoints.unwrap();
                mypoints_ = mypoints_ + 2;
                storage.mypoints.insert((myinviter.unwrap(), airdropphase), mypoints_);
            }else{
                storage.mypoints.insert((myinviter.unwrap(), airdropphase), 2);
            }
        }

        //add total point
        let totalpoint = storage.total_point.get(airdropphase).try_read();
        if totalpoint.is_some(){
            let mut _totalpoint = totalpoint.unwrap();
            _totalpoint = _totalpoint + 13;
            storage.total_point.insert(airdropphase, _totalpoint);
        }else{
            storage.total_point.insert(airdropphase, 13);
        }

        //check and deal epoch
        check_deal_epoch();
    }

    #[storage(read, write)]
    fn swap_constellation_to_coin(_use_styles: u8, _amount: u16){
        let identity = msg_sender().unwrap();
        let _epoch = storage.epoch.read();
        let constellation = storage.myconstellation.get((identity, _epoch)).try_read();
        require(
            _amount > 0,
            AmountError::NeedAboveZero,
        );
        require(
            constellation.is_some(),
            AvailableError::NotAvailable,
        );
        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );

        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );

        let mut _my_constellation = constellation.unwrap();

        if _use_styles == 1 {
            require(
                _my_constellation.aries >= _amount,
                AmountError::NeedAboveZero,
            );
            _my_constellation.aries = _my_constellation.aries - _amount;
        }else if _use_styles == 2 {
            require(
                _my_constellation.taurus >= _amount,
                AmountError::NeedAboveZero,
            );
            _my_constellation.taurus = _my_constellation.taurus - _amount;
        }else if _use_styles == 3 {
            require(
                _my_constellation.gemini >= _amount,
                AmountError::NeedAboveZero,
            );
            _my_constellation.gemini = _my_constellation.gemini - _amount;
        }else if _use_styles == 4 {
            require(
                _my_constellation.cancer >= _amount,
                AmountError::NeedAboveZero,
            );
            _my_constellation.cancer = _my_constellation.cancer - _amount;
        }else if _use_styles == 5 {
            require(
                _my_constellation.leo >= _amount,
                AmountError::NeedAboveZero,
            );
            _my_constellation.leo = _my_constellation.leo - _amount;
        }else if _use_styles == 6 {
            require(
                _my_constellation.virgo >= _amount,
                AmountError::NeedAboveZero,
            );
            _my_constellation.virgo = _my_constellation.virgo - _amount;
        }else if _use_styles == 7 {
            require(
                _my_constellation.libra >= _amount,
                AmountError::NeedAboveZero,
            );
            _my_constellation.libra = _my_constellation.libra - _amount;
        }else if _use_styles == 8 {
            require(
                _my_constellation.scorpio >= _amount,
                AmountError::NeedAboveZero,
            );
            _my_constellation.scorpio = _my_constellation.scorpio - _amount;
        }else if _use_styles == 9 {
            require(
                _my_constellation.sagittarius >= _amount,
                AmountError::NeedAboveZero,
            );
            _my_constellation.sagittarius = _my_constellation.sagittarius - _amount;
        }else if _use_styles == 10 {
            require(
                _my_constellation.capricornus >= _amount,
                AmountError::NeedAboveZero,
            );
            _my_constellation.capricornus = _my_constellation.capricornus - _amount;
        }else if _use_styles == 11 {
            require(
                _my_constellation.aquarius >= _amount,
                AmountError::NeedAboveZero,
            );
            _my_constellation.aquarius = _my_constellation.aquarius - _amount;
        }else {
            require(
                _my_constellation.pisces >= _amount,
                AmountError::NeedAboveZero,
            );
            _my_constellation.pisces = _my_constellation.pisces - _amount;
        }
        //update
        storage.myconstellation.insert((identity, _epoch), _my_constellation);

        let token_contract = abi(Token, storage.token_contract_id.read());
        token_contract.mint(msg_sender().unwrap(), DEFAULT_SUB_ID, (_amount.as_u64()) * (storage.constellation_price.read())); 

    }

    #[storage(read, write)]
    fn claim_battle_bonus(_epoch: u64){
        let current_epoch = storage.epoch.read();
        require(
            _epoch > 0 && _epoch < current_epoch,
            AvailableError::NotAvailable,
        );
        let identity = msg_sender().unwrap();
        let _my_share = storage.my_battle_epoch_weight.get((identity, _epoch)).try_read();
        let _total_share = storage.battle_epoch_total_weight.get(_epoch).try_read();
        let my_b_claimed = storage.my_battle_claimed.get((identity, _epoch)).try_read();
        require(
            my_b_claimed.is_none(),
            AvailableError::NotAvailable,
        );
        require(
            _my_share.is_some() && _total_share.is_some(),
            AvailableError::NotAvailable,
        );
        require(
            _my_share.unwrap() > 0 && _total_share.unwrap() > 0,
            AvailableError::NotAvailable,
        );
        let _should_bonus = storage.battle_epoch_should_bonus.get(_epoch).try_read();
        // let _epoch_total_bonus = storage.epoch_total_bonus.get(_epoch).try_read();
        // require(
        //     _epoch_total_bonus.is_some() && _should_bonus.is_some(),
        //     AvailableError::NotAvailable,
        // );
        require(
            _should_bonus.is_some(),
            AvailableError::NotAvailable,
        );
        
        let each_share = _should_bonus.unwrap() / _total_share.unwrap();//already checked
        let my_bonus = each_share * _my_share.unwrap();
        // storage.my_battle_epoch_weight.insert((identity, _epoch), 0);// clear
        storage.my_battle_claimed.insert((identity, _epoch), true); //has claimed
        transfer(identity, AssetId::base(), my_bonus);

    }

    #[storage(read, write)]
    fn claim_invite_bonus(_epoch: u64){
        let current_epoch = storage.epoch.read();
        require(
            _epoch > 0 && _epoch < current_epoch,
            AvailableError::NotAvailable,
        );
        let identity = msg_sender().unwrap();
        let _my_share = storage.my_invite_epoch_num.get((identity, _epoch)).try_read();
        let _total_share = storage.invite_epoch_total_num.get(_epoch).try_read();
        let my_i_claimed = storage.my_invite_claimed.get((identity, _epoch)).try_read();
        require(
            my_i_claimed.is_none(),
            AvailableError::NotAvailable,
        );
        require(
            _my_share.is_some() && _total_share.is_some(),
            AvailableError::NotAvailable,
        );
        require(
            _my_share.unwrap() > 0 && _total_share.unwrap() > 0,
            AvailableError::NotAvailable,
        );
        let _should_bonus = storage.invite_epoch_should_bonus.get(_epoch).try_read();
        require(
            _should_bonus.is_some(),
            AvailableError::NotAvailable,
        );
        
        let each_share = _should_bonus.unwrap() / _total_share.unwrap();//already checked
        let my_bonus = each_share * _my_share.unwrap();
        // storage.my_invite_epoch_num.insert((identity, _epoch), 0);//clear
        storage.my_invite_claimed.insert((identity, _epoch), true); //has claimed
        transfer(identity, AssetId::base(), my_bonus);

    }

    #[storage(read, write)]
    fn claim_node_bonus(_epoch: u64){
        let current_epoch = storage.epoch.read();
        require(
            _epoch > 0 && _epoch < current_epoch,
            AvailableError::NotAvailable,
        );
        let identity = msg_sender().unwrap();
        let mynode_eligible = storage.node_eligible.get(identity).try_read();
        let my_c_claimed = storage.my_community_claimed.get((identity, _epoch)).try_read();
        require(
            my_c_claimed.is_none(),
            AvailableError::NotAvailable,
        );
        require(
            mynode_eligible.is_some() && mynode_eligible.unwrap(),
            EligibleError::NodeNotAvailable,
        );
        let my_c_epoch_pair = storage.my_communitybattle_epoch_pair.get((identity, _epoch)).try_read();
        let c_epoch_total_cpoints = storage.community_epoch_total_cpoints.get(_epoch).try_read();
        let c_epoch_should_bonus = storage.community_epoch_should_bonus.get(_epoch).try_read();
        require(
            c_epoch_total_cpoints.is_some() && c_epoch_should_bonus.is_some(),
            AvailableError::NotAvailable,
        );
        require(
            c_epoch_total_cpoints.unwrap() > 0 && c_epoch_should_bonus.unwrap() > 0,
            AvailableError::NotAvailable,
        );//add
        if my_c_epoch_pair.is_some() {//has battle
            let mycpoints = storage.my_cpoints.get((identity, _epoch)).try_read();
            let sidecpoins = storage.my_cpoints.get((my_c_epoch_pair.unwrap(), _epoch)).try_read();
            if mycpoints.is_some() && sidecpoins.is_some() {
                if mycpoints.unwrap() > sidecpoins.unwrap() {
                    //get all
                    let each_share = c_epoch_should_bonus.unwrap() / c_epoch_total_cpoints.unwrap();//already checked
                    let my_bonus = each_share * (mycpoints.unwrap() + sidecpoins.unwrap());
                    storage.my_cpoints.insert((identity, _epoch), 0);//has claimed
                    // storage.my_cpoints.insert((my_c_epoch_pair.unwrap(), _epoch), 0);//clear
                    storage.my_community_claimed.insert((identity, _epoch), true); //has claimed
                    transfer(identity, AssetId::base(), my_bonus);
                    
                }else if mycpoints.unwrap() == sidecpoins.unwrap() {
                    //get myself
                    let each_share = c_epoch_should_bonus.unwrap() / c_epoch_total_cpoints.unwrap();//already checked
                    let my_bonus = each_share * mycpoints.unwrap();
                    // storage.my_cpoints.insert((identity, _epoch), 0);//clear
                    storage.my_community_claimed.insert((identity, _epoch), true); //has claimed
                    transfer(identity, AssetId::base(), my_bonus);
                }
                
            }

        }else{
            //get myself
            let mycpoints = storage.my_cpoints.get((identity, _epoch)).try_read();
            if mycpoints.is_some() {
                let each_share = c_epoch_should_bonus.unwrap() / c_epoch_total_cpoints.unwrap();//already checked
                let my_bonus = each_share * mycpoints.unwrap();
                // storage.my_cpoints.insert((identity, _epoch), 0);//has claimed
                storage.my_community_claimed.insert((identity, _epoch), true); //has claimed
                transfer(identity, AssetId::base(), my_bonus);
            }
            

        }

    }

    #[payable]
    #[storage(read, write)]
    fn regenerate_gene(){
        let identity = msg_sender().unwrap();
        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );
        require(
            timestamp() > monster.unwrap().genetime + storage.one_day.read(),
            TimeError::NotEnoughTime,
        );

        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );

        // Verify payment
        require(AssetId::base() == msg_asset_id(), AssetError::IncorrectAssetSent);
        require(
            storage.gene_price.read() <= msg_amount(),
            AssetError::InsufficientPayment,
        );

        //check and deal epoch
        check_deal_epoch();
        
        let _epoch = storage.epoch.read();

        // do allocation
        do_allocation(_epoch, storage.gene_price.read());

        // Omitting the processing algorithm for random numbers
        let _geni = 12020329928232323;
        let _mybonus = 5;
        // Omitting the processing algorithm for random numbers

        //generate bonus
        let _mybonus =  _geni.unwrap() % 5 + 4;
        let mut _monster = monster.unwrap();
        _monster.gene = _geni.unwrap();
        _monster.bonus = _mybonus;
        _monster.genetime = timestamp();

        //update
        storage.mymonster.insert(identity, _monster);

    }

    #[payable]
    #[storage(read, write)]
    fn rebirth(){
        let identity = msg_sender().unwrap();
        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );
        require(
            timestamp() > monster.unwrap().expiry,
            TimeError::NotEnoughTime,
        );

        // Verify payment
        require(AssetId::base() == msg_asset_id(), AssetError::IncorrectAssetSent);
        require(
            storage.rebirth_price.read() <= msg_amount(),
            AssetError::InsufficientPayment,
        );

        //check and deal epoch
        check_deal_epoch();

        let _epoch = storage.epoch.read();

        // do allocation
        do_allocation(_epoch, storage.rebirth_price.read());


        // Omitting the processing algorithm for random numbers
        let _expiry = 3;
        // Omitting the processing algorithm for random numbers

        let mut _monster = monster.unwrap();
        _monster.expiry = timestamp()+ storage.one_day.read()*_expiry;
        //update
        storage.mymonster.insert(identity, _monster);

    }

    #[payable]
    #[storage(read, write)]
    fn list_constellation(_styles: u8) -> b256 {
        let identity = msg_sender().unwrap();

        //check and deal epoch
        check_deal_epoch();

        let _epoch = storage.epoch.read();

        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );

        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );

        //get asset id
        // let token_contract = abi(Token, storage.token_contract_id.read());
        // let asset_id = token_contract.getAssetId(); 

        // Verify payment
        require(AssetId::from(storage.asset_id.read()) == msg_asset_id(), AssetError::IncorrectAssetSent);
        require(
            storage.list_price.read() <= msg_amount(),
            AssetError::InsufficientPayment,
        );

        //sub constella
        let constellation = storage.myconstellation.get((identity, _epoch)).try_read();
        require(
            constellation.is_some(),
            AvailableError::NotAvailable,
        );

        let mut _constellation = constellation.unwrap();
        if _styles == 1 {
            require(
                _constellation.aries > 0,
                AmountError::NeedAboveZero,
            );
            _constellation.aries = _constellation.aries - 1;
        }else if _styles == 2 {
            require(
                _constellation.taurus > 0,
                AmountError::NeedAboveZero,
            );
            _constellation.taurus = _constellation.taurus - 1;
        }else if _styles == 3 {
            require(
                _constellation.gemini > 0,
                AmountError::NeedAboveZero,
            );
            _constellation.gemini = _constellation.gemini - 1;
        }else if _styles == 4 {
            require(
                _constellation.cancer > 0,
                AmountError::NeedAboveZero,
            );
            _constellation.cancer = _constellation.cancer - 1;
        }else if _styles == 5 {
            require(
                _constellation.leo > 0,
                AmountError::NeedAboveZero,
            );
            _constellation.leo = _constellation.leo - 1;
        }else if _styles == 6 {
            require(
                _constellation.virgo > 0,
                AmountError::NeedAboveZero,
            );
            _constellation.virgo = _constellation.virgo - 1;
        }else if _styles == 7 {
            require(
                _constellation.libra > 0,
                AmountError::NeedAboveZero,
            );
            _constellation.libra = _constellation.libra - 1;
        }else if _styles == 8 {
            require(
                _constellation.scorpio > 0,
                AmountError::NeedAboveZero,
            );
            _constellation.scorpio = _constellation.scorpio - 1;
        }else if _styles == 9 {
            require(
                _constellation.sagittarius > 0,
                AmountError::NeedAboveZero,
            );
            _constellation.sagittarius = _constellation.sagittarius - 1;
        }else if _styles == 10 {
            require(
                _constellation.capricornus > 0,
                AmountError::NeedAboveZero,
            );
            _constellation.capricornus = _constellation.capricornus - 1;
        }else if _styles == 11 {
            require(
                _constellation.aquarius > 0,
                AmountError::NeedAboveZero,
            );
            _constellation.aquarius = _constellation.aquarius - 1;
        }else {
            require(
                _constellation.pisces > 0,
                AmountError::NeedAboveZero,
            );
            _constellation.pisces = _constellation.pisces - 1;
        }

        //update
        storage.myconstellation.insert((identity, _epoch), _constellation);

        // Omitting the processing algorithm for random numbers
        let random = 10;
        // Omitting the processing algorithm for random numbers

        let listid: b256 = sha256((timestamp(), msg_sender().unwrap(), random, _styles));
        
        // Store Market
        let market = Market{owner: identity, ownergene: monster.unwrap().gene, bonus: monster.unwrap().bonus, constella: _styles.as_u16(), epoch: _epoch};
        storage.markets.insert(listid, market);
        log(ListEvent {
            owner: identity,
            ownergene: monster.unwrap().gene,
            bonus: monster.unwrap().bonus,
            constella: _styles.as_u16(),
            epoch: _epoch,
            id: listid,
            time: timestamp(),
        });
        listid
    }

    #[storage(read, write)]
    fn delist_constellation(_listid: b256){//when epoch update, still can get back the card and token
        let identity = msg_sender().unwrap();
        // let _epoch = storage.epoch.read();
        let market = storage.markets.get(_listid).try_read();

        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );

        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );

        require(
            market.is_some(),
            AvailableError::NotAvailable,
        );
        require(
            market.unwrap().constella > 0 && market.unwrap().owner == identity,
            AvailableError::NotAvailable,
        );
        let _epoch = market.unwrap().epoch;
        let my_constellation = storage.myconstellation.get((identity, _epoch)).try_read();
        require(
            my_constellation.is_some(),
            AvailableError::NotAvailable,
        );
        let mut _my_constellation = my_constellation.unwrap();
        let _market = market.unwrap();

        if _market.constella == 1 {
            _my_constellation.aries = _my_constellation.aries + 1;
        }else if _market.constella == 2 {
            _my_constellation.taurus = _my_constellation.taurus + 1;
        }else if _market.constella == 3 {
            _my_constellation.gemini = _my_constellation.gemini + 1;
        }else if _market.constella == 4 {
            _my_constellation.cancer = _my_constellation.cancer + 1;
        }else if _market.constella == 5 {
            _my_constellation.leo = _my_constellation.leo + 1;
        }else if _market.constella == 6 {
            _my_constellation.virgo = _my_constellation.virgo + 1;
        }else if _market.constella == 7 {
            _my_constellation.libra = _my_constellation.libra + 1;
        }else if _market.constella == 8 {
            _my_constellation.scorpio = _my_constellation.scorpio + 1;
        }else if _market.constella == 9 {
            _my_constellation.sagittarius = _my_constellation.sagittarius + 1;
        }else if _market.constella == 10 {
            _my_constellation.capricornus = _my_constellation.capricornus + 1;
        }else if _market.constella == 11 {                
            _my_constellation.aquarius = _my_constellation.aquarius + 1;
        }else {
            _my_constellation.pisces = _my_constellation.pisces + 1;
        }

        //update
        storage.myconstellation.insert((identity, _epoch), _my_constellation);

        // let newmarket = Market{owner: Identity::Address(Address::zero()), ownergene: 0, constella: 0};
        // storage.markets.insert(_listid, newmarket);

        storage.markets.remove(_listid);

        //get asset id
        // let token_contract = abi(Token, storage.token_contract_id.read());
        // let asset_id = token_contract.getAssetId(); 

        //tranfer token to owner back
        transfer(identity, AssetId::from(storage.asset_id.read()), storage.list_price.read());
        
        log(DeListEvent {
            owner: identity,
            constella: _market.constella,
            epoch: _epoch,
            id: _listid,
            time: timestamp(),
        });

    }

    // #[storage(read)]
    // fn get_market(_listid: b256) -> Option<Market>{
    //     storage.markets.get(_listid).try_read()
    // }

    #[payable]
    #[storage(read, write)]
    fn battle(_use_styles: u8, _listid: b256) -> bool{//battle first, then update the epoch
        let identity = msg_sender().unwrap();
        let _epoch = storage.epoch.read();
        let monster = storage.mymonster.get(identity).try_read();
        let market = storage.markets.get(_listid).try_read();
        let mut _true_false: bool = false;
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );
        require(
            market.is_some(),
            AvailableError::NotAvailable,
        );

        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );

        //get asset id
        // let token_contract = abi(Token, storage.token_contract_id.read());
        // let asset_id = token_contract.getAssetId(); 

        // Verify payment
        require(AssetId::from(storage.asset_id.read()) == msg_asset_id(), AssetError::IncorrectAssetSent);
        require(
            storage.battle_price.read() <= msg_amount(),
            AssetError::InsufficientPayment,
        );

        //check user has card
        let my_constellation = storage.myconstellation.get((identity, _epoch)).try_read();
        require(
                my_constellation.is_some(),
                AvailableError::NotAvailable,
        );
        let mut _my_constellation = my_constellation.unwrap();

        if _use_styles == 1 {
            require(
                _my_constellation.aries > 0,
                AmountError::NeedAboveZero,
            );
        }else if _use_styles == 2 {
            require(
                _my_constellation.taurus > 0,
                AmountError::NeedAboveZero,
            );
        }else if _use_styles == 3 {
            require(
                _my_constellation.gemini > 0,
                AmountError::NeedAboveZero,
            );
        }else if _use_styles == 4 {
            require(
                _my_constellation.cancer > 0,
                AmountError::NeedAboveZero,
            );
        }else if _use_styles == 5 {
            require(
                _my_constellation.leo > 0,
                AmountError::NeedAboveZero,
            );
        }else if _use_styles == 6 {
            require(
                _my_constellation.virgo > 0,
                AmountError::NeedAboveZero,
            );
        }else if _use_styles == 7 {
            require(
                _my_constellation.libra > 0,
                AmountError::NeedAboveZero,
            );
        }else if _use_styles == 8 {
            require(
                _my_constellation.scorpio > 0,
                AmountError::NeedAboveZero,
            );
        }else if _use_styles == 9 {
            require(
                _my_constellation.sagittarius > 0,
                AmountError::NeedAboveZero,
            );
        }else if _use_styles == 10 {
            require(
                _my_constellation.capricornus > 0,
                AmountError::NeedAboveZero,
            );
        }else if _use_styles == 11 {
            require(
                _my_constellation.aquarius > 0,
                AmountError::NeedAboveZero,
            );
        }else {
            require(
                _my_constellation.pisces > 0,
                AmountError::NeedAboveZero,
            );
        }

        //check market info, styles > 0
        require(
            market.unwrap().constella > 0 && market.unwrap().epoch == _epoch && market.unwrap().owner != identity,
            AvailableError::NotAvailable,
        );

         // Omitting the processing algorithm for random numbers
        let _random = 1;
        // Omitting the processing algorithm for random numbers

        if _random <= market.unwrap().bonus {
            //you fail
            //add card to owner, delete card from you, delist owner card, and transfer token to you
            let owner_constellation = storage.myconstellation.get((market.unwrap().owner, _epoch)).try_read();
            require(
                owner_constellation.is_some(),
                AvailableError::NotAvailable,
            );
            
            let mut _owner_constellation = owner_constellation.unwrap();
            
            if _use_styles == 1 {
                _my_constellation.aries = _my_constellation.aries - 1;
                _owner_constellation.aries = _owner_constellation.aries + 1;
            }else if _use_styles == 2 {
                _my_constellation.taurus = _my_constellation.taurus - 1;
                _owner_constellation.taurus = _owner_constellation.taurus + 1;
            }else if _use_styles == 3 {
                _my_constellation.gemini = _my_constellation.gemini - 1;
                _owner_constellation.gemini = _owner_constellation.gemini + 1;
            }else if _use_styles == 4 {
                _my_constellation.cancer = _my_constellation.cancer - 1;
                _owner_constellation.cancer = _owner_constellation.cancer + 1;
            }else if _use_styles == 5 {
                _my_constellation.leo = _my_constellation.leo - 1;
                _owner_constellation.leo = _owner_constellation.leo + 1;
            }else if _use_styles == 6 {
                _my_constellation.virgo = _my_constellation.virgo - 1;
                _owner_constellation.virgo = _owner_constellation.virgo + 1;
            }else if _use_styles == 7 {
                _my_constellation.libra = _my_constellation.libra - 1;
                _owner_constellation.libra = _owner_constellation.libra + 1;
            }else if _use_styles == 8 {
                _my_constellation.scorpio = _my_constellation.scorpio - 1;
                _owner_constellation.scorpio = _owner_constellation.scorpio + 1;
            }else if _use_styles == 9 {
                _my_constellation.sagittarius = _my_constellation.sagittarius - 1;
                _owner_constellation.sagittarius = _owner_constellation.sagittarius + 1;
            }else if _use_styles == 10 {
                _my_constellation.capricornus = _my_constellation.capricornus - 1;
                _owner_constellation.capricornus = _owner_constellation.capricornus + 1;
            }else if _use_styles == 11 {
                _my_constellation.aquarius = _my_constellation.aquarius - 1;
                _owner_constellation.aquarius = _owner_constellation.aquarius + 1;
            }else {
                _my_constellation.pisces = _my_constellation.pisces - 1;
                _owner_constellation.pisces = _owner_constellation.pisces + 1;
            }

            let _market = market.unwrap();

            if _market.constella == 1 {
                _owner_constellation.aries = _owner_constellation.aries + 1;
            }else if _market.constella == 2 {
                _owner_constellation.taurus = _owner_constellation.taurus + 1;
            }else if _market.constella == 3 {
                _owner_constellation.gemini = _owner_constellation.gemini + 1;
            }else if _market.constella == 4 {
                _owner_constellation.cancer = _owner_constellation.cancer + 1;
            }else if _market.constella == 5 {
                _owner_constellation.leo = _owner_constellation.leo + 1;
            }else if _market.constella == 6 {
                _owner_constellation.virgo = _owner_constellation.virgo + 1;
            }else if _market.constella == 7 {
                _owner_constellation.libra = _owner_constellation.libra + 1;
            }else if _market.constella == 8 {
                _owner_constellation.scorpio = _owner_constellation.scorpio + 1;
            }else if _market.constella == 9 {
                _owner_constellation.sagittarius = _owner_constellation.sagittarius + 1;
            }else if _market.constella == 10 {
                _owner_constellation.capricornus = _owner_constellation.capricornus + 1;
            }else if _market.constella == 11 {                
                _owner_constellation.aquarius = _owner_constellation.aquarius + 1;
            }else {
                _owner_constellation.pisces = _owner_constellation.pisces + 1;
            }
            //update
            storage.myconstellation.insert((identity, _epoch), _my_constellation);
            storage.myconstellation.insert((market.unwrap().owner, _epoch), _owner_constellation);



            //tranfer token to loser, then remove market
            // transfer(identity, AssetId::from(storage.asset_id.read()), ((storage.battle_price.read()*90)/100) * 2);
            let battlepool = storage.my_battle_pool.get(identity).try_read();
            if battlepool.is_some() {
                let mut _battlepool = battlepool.unwrap();
                _battlepool = _battlepool + ((storage.list_price.read()*90)/100) + storage.battle_price.read();
                //update
                storage.my_battle_pool.insert(identity, _battlepool);
            }else{
                storage.my_battle_pool.insert(identity, ((storage.list_price.read()*90)/100) + storage.battle_price.read());
            }

            storage.markets.remove(_listid);
            _true_false = false;
            log(BattleEvent {
                winer: market.unwrap().owner,
                loser: identity,
                winer_back: _market.constella, //constellation type
                winer_win: _use_styles.as_u16(),  //constellation type
                loser_get: ((storage.list_price.read()*90)/100), //token
                epoch: _epoch,
                id: _listid, //delist id
                time: timestamp(),
            });

        }else {
            //you win
            //add card to you, remove card from market, transfer token to owner
            let _market = market.unwrap();

            if _market.constella == 1 {
                _my_constellation.aries = _my_constellation.aries + 1;
            }else if _market.constella == 2 {
                _my_constellation.taurus = _my_constellation.taurus + 1;
            }else if _market.constella == 3 {
                _my_constellation.gemini = _my_constellation.gemini + 1;
            }else if _market.constella == 4 {
                _my_constellation.cancer = _my_constellation.cancer + 1;
            }else if _market.constella == 5 {
                _my_constellation.leo = _my_constellation.leo + 1;
            }else if _market.constella == 6 {
                _my_constellation.virgo = _my_constellation.virgo + 1;
            }else if _market.constella == 7 {
                _my_constellation.libra = _my_constellation.libra + 1;
            }else if _market.constella == 8 {
                _my_constellation.scorpio = _my_constellation.scorpio + 1;
            }else if _market.constella == 9 {
                _my_constellation.sagittarius = _my_constellation.sagittarius + 1;
            }else if _market.constella == 10 {
                _my_constellation.capricornus = _my_constellation.capricornus + 1;
            }else if _market.constella == 11 {                
                _my_constellation.aquarius = _my_constellation.aquarius + 1;
            }else {
                _my_constellation.pisces = _my_constellation.pisces + 1;
            }

            // let newmarket = Market{owner: Identity::Address(Address::zero()), ownergene: 0, constella: 0};
            // storage.markets.insert(_listid, newmarket);
            

            //update
            storage.myconstellation.insert((identity, _epoch), _my_constellation);

            //tranfer token to loser, then remove market
            // transfer(market.unwrap().owner, AssetId::from(storage.asset_id.read()), ((storage.battle_price.read()*90)/100) * 2);
            let battlepool = storage.my_battle_pool.get(market.unwrap().owner).try_read();
            if battlepool.is_some() {
                let mut _battlepool = battlepool.unwrap();
                _battlepool = _battlepool + ((storage.battle_price.read()*90)/100) + storage.list_price.read();
                //update
                storage.my_battle_pool.insert(market.unwrap().owner, _battlepool);
            }else{
                storage.my_battle_pool.insert(market.unwrap().owner, ((storage.battle_price.read()*90)/100) + storage.list_price.read());
            }

            storage.markets.remove(_listid);
            // return true;
            _true_false = true;

            log(BattleEvent {
                winer: identity,
                loser: market.unwrap().owner,
                winer_back: _use_styles.as_u16(), //constellation type
                winer_win: _market.constella,  //constellation type
                loser_get: ((storage.battle_price.read()*90)/100), //token
                epoch: _epoch,
                id: _listid, //delist id
                time: timestamp(),
            });
        }
        
        //update point
        let airdropphase = storage.airdrop_phase.read();
        let owner_point = storage.mypoints.get((market.unwrap().owner, airdropphase)).try_read();
        let user_point = storage.mypoints.get((identity, airdropphase)).try_read();
        if(owner_point.is_some()){
            let mut _point = owner_point.unwrap();
            _point = _point + 1;
            //update
            storage.mypoints.insert((market.unwrap().owner, airdropphase), _point);
        }else{
            storage.mypoints.insert((market.unwrap().owner, airdropphase), 1);
        }

        if(user_point.is_some()){
            let mut _point = user_point.unwrap();
            _point = _point + 1;
            //update
            storage.mypoints.insert((identity, airdropphase), _point);
        }else{
            storage.mypoints.insert((identity, airdropphase), 1);
        }

        //update cpoints
        let user_node = storage.my_node.get(identity).try_read();
        if user_node.is_some() {
            let mycpoint = storage.my_cpoints.get((user_node.unwrap(), _epoch)).try_read();
            if mycpoint.is_some() {
                let mut _mycpoint = mycpoint.unwrap();
                _mycpoint = _mycpoint + 1;
                storage.my_cpoints.insert((user_node.unwrap(), _epoch), _mycpoint);
                log(UpdateCPointsEvent{
                    node: user_node.unwrap(),
                    from: identity,
                    total_cpoints: _mycpoint,
                    add_cpoints: 1,
                    epoch: _epoch,
                    time: timestamp(),
                });
            }else{
                storage.my_cpoints.insert((user_node.unwrap(), _epoch), 1);
                log(GetCPointsEvent{
                    node: user_node.unwrap(),
                    from: identity,
                    total_cpoints: 1,
                    add_cpoints: 1,
                    epoch: _epoch,
                    time: timestamp(),
                });
            }

            let c_epoch_total_cpoints = storage.community_epoch_total_cpoints.get(_epoch).try_read();
            if c_epoch_total_cpoints.is_some() {
                let mut _c_epoch_total_cpoints = c_epoch_total_cpoints.unwrap();
                _c_epoch_total_cpoints = _c_epoch_total_cpoints + 1;
                storage.community_epoch_total_cpoints.insert(_epoch, _c_epoch_total_cpoints);
            }else{
                storage.community_epoch_total_cpoints.insert(_epoch, 1);
            }
        }
        let owner_node = storage.my_node.get(market.unwrap().owner).try_read();
        if owner_node.is_some() {
            let mycpoint = storage.my_cpoints.get((owner_node.unwrap(), _epoch)).try_read();
            if mycpoint.is_some() {
                let mut _mycpoint = mycpoint.unwrap();
                _mycpoint = _mycpoint + 1;
                storage.my_cpoints.insert((owner_node.unwrap(), _epoch), _mycpoint);
                log(UpdateCPointsEvent{
                    node: owner_node.unwrap(),
                    from: market.unwrap().owner,
                    total_cpoints: _mycpoint,
                    add_cpoints: 1,
                    epoch: _epoch,
                    time: timestamp(),
                });
                
            }else{
                storage.my_cpoints.insert((owner_node.unwrap(), _epoch), 1);
                log(GetCPointsEvent{
                    node: owner_node.unwrap(),
                    from: market.unwrap().owner,
                    total_cpoints: 1,
                    add_cpoints: 1,
                    epoch: _epoch,
                    time: timestamp(),
                });
            }

            let c_epoch_total_cpoints = storage.community_epoch_total_cpoints.get(_epoch).try_read();
            if c_epoch_total_cpoints.is_some() {
                let mut _c_epoch_total_cpoints = c_epoch_total_cpoints.unwrap();
                _c_epoch_total_cpoints = _c_epoch_total_cpoints + 1;
                storage.community_epoch_total_cpoints.insert(_epoch, _c_epoch_total_cpoints);
            }else{
                storage.community_epoch_total_cpoints.insert(_epoch, 1);
            }
        }

        //add total point
        let totalpoint = storage.total_point.get(airdropphase).try_read();
        if totalpoint.is_some(){
            let mut _totalpoint = totalpoint.unwrap();
            _totalpoint = _totalpoint + 2;
            storage.total_point.insert(airdropphase, _totalpoint);
        }else{
            storage.total_point.insert(airdropphase, 2);
        }

        //check and deal epoch
        check_deal_epoch();

        return _true_false;

    }

    #[storage(read, write)]
    fn launch_community_battle(_node_side: Identity){
        let identity = msg_sender().unwrap();
        let _epoch = storage.epoch.read();
        let mynode_eligible = storage.node_eligible.get(identity).try_read();
        let side_node_eligible = storage.node_eligible.get(_node_side).try_read();
        require(
            mynode_eligible.is_some() && mynode_eligible.unwrap(),
            EligibleError::NodeNotAvailable,
        );
        require(
            side_node_eligible.is_some() && side_node_eligible.unwrap(),
            EligibleError::NodeNotAvailable,
        );
        let mynode_level = storage.my_node_level.get(identity).try_read();
        let side_node_level = storage.my_node_level.get(_node_side).try_read();
        require(
            mynode_level.is_some() && side_node_level.is_some() && mynode_level.unwrap() == side_node_level.unwrap(),
            EligibleError::NodeLevelNotSame,
        );
        let my_c_epoch_pair = storage.my_communitybattle_epoch_pair.get((identity, _epoch)).try_read();
        let side_c_epoch_pair = storage.my_communitybattle_epoch_pair.get((_node_side, _epoch)).try_read();
        require(
            my_c_epoch_pair.is_none() && side_c_epoch_pair.is_none(),
            EligibleError::NodeNotAvailable,
        );
        storage.my_communitybattle_epoch_pair.insert((identity, _epoch), _node_side);
        storage.my_communitybattle_epoch_pair.insert((_node_side, _epoch), identity);
        log(CommunityBattleEvent{
                challenger: identity,
                challenged: _node_side,
                epoch: _epoch,
                time: timestamp(),
            }
        );
    }

    #[storage(read, write)]
    fn add_accelerator(){
        let identity = msg_sender().unwrap();
        let third_contract = abi(ThirdContract, storage.third_contract_id.read());
        let _myeligible = third_contract.get_eligible(identity);
        require(
            _myeligible,
            AvailableError::NotAvailable,
        );
        let _epoch = storage.epoch.read();
        let mynameaccelerator = storage.my_name_accelerator.get((identity, _epoch)).try_read();
        require(
            mynameaccelerator.is_none(),
            AvailableError::NotAvailable,
        );
        storage.my_name_accelerator.insert((identity, _epoch), true);
        let accelerator = storage.myaccelerator.get(identity).try_read();
        if accelerator.is_some() {
            let mut _accelerator = accelerator.unwrap();
            _accelerator.twentyfour_add = _accelerator.twentyfour_add + 1;
            //update
            storage.myaccelerator.insert(identity, _accelerator);
        }else{
            let _accelerator = Accelerator{eight_add: 0, sixteen_add: 0, twentyfour_add: 1};
            storage.myaccelerator.insert(identity, _accelerator);
        }

    }

    #[payable]
    #[storage(read, write)]
    fn lucky_turntable() -> u8 {
        let identity = msg_sender().unwrap();
        let monster = storage.mymonster.get(identity).try_read();
        let mut _result: u8 = 1;
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );

        require(
            timestamp() > monster.unwrap().turntabletime + storage.one_day.read(),
            TimeError::NotEnoughTime,
        );

        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );

        //check and deal epoch
        check_deal_epoch();

        let _epoch = storage.epoch.read();

        //get asset id
        // let token_contract = abi(Token, storage.token_contract_id.read());
        // let asset_id = token_contract.getAssetId(); 

        // Verify payment
        require(AssetId::from(storage.asset_id.read()) == msg_asset_id(), AssetError::IncorrectAssetSent);
        require(
            storage.lucky_price.read() <= msg_amount(),
            AssetError::InsufficientPayment,
        );

        // Omitting the processing algorithm for random numbers
        let _random = 3;
        // Omitting the processing algorithm for random numbers

        let mut _monster = monster.unwrap();
        _monster.turntabletime = timestamp();
        storage.mymonster.insert(identity, _monster);
        if _random == 1 {
            //add apple
            let fruit = storage.myfruit.get(identity).try_read();
            if fruit.is_some() {
                let mut _fruit = fruit.unwrap();
                _fruit.apple = _fruit.apple + 1;
                //update
                storage.myfruit.insert(identity, _fruit);
            }else {
                let _fruit = Fruit{apple: 1, banana: 0, ananas: 0};
                storage.myfruit.insert(identity, _fruit);
            }
            _result = 1;            
        }else if _random == 2 {
            //add banana
            let luckybanaba = storage.lucky_banana.get(_epoch).try_read();
            if luckybanaba.is_some() {
                if luckybanaba.unwrap() < storage.max_banana.read() {
                    let fruit = storage.myfruit.get(identity).try_read();
            
                    if fruit.is_some() {
                        let mut _fruit = fruit.unwrap();
                        _fruit.banana = _fruit.banana + 1;
                        //update
                        storage.myfruit.insert(identity, _fruit);
                    }else {
                        let _fruit = Fruit{apple: 0, banana: 1, ananas: 0};
                        storage.myfruit.insert(identity, _fruit);
                    }
                    _result = 2;
                    storage.lucky_banana.insert(_epoch, luckybanaba.unwrap() + 1);
                }else{
                    //add accelerator_card 8
                    let accelerator = storage.myaccelerator.get(identity).try_read();
                    if accelerator.is_some() {
                        let mut _accelerator = accelerator.unwrap();
                        _accelerator.eight_add = _accelerator.eight_add + 1;
                        //update
                        storage.myaccelerator.insert(identity, _accelerator);
                    }else {
                        let _accelerator = Accelerator{eight_add: 1, sixteen_add: 0, twentyfour_add: 0};
                        storage.myaccelerator.insert(identity, _accelerator);
                    }
                    _result = 3;
                }

            }else{
                let fruit = storage.myfruit.get(identity).try_read();
            
                if fruit.is_some() {
                    let mut _fruit = fruit.unwrap();
                    _fruit.banana = _fruit.banana + 1;
                    //update
                    storage.myfruit.insert(identity, _fruit);
                }else {
                    let _fruit = Fruit{apple: 0, banana: 1, ananas: 0};
                    storage.myfruit.insert(identity, _fruit);
                }
                storage.lucky_banana.insert(_epoch, 1);
                _result = 2;

            }            
            
        }else if _random == 3 {
            //add accelerator_card 8
            let accelerator = storage.myaccelerator.get(identity).try_read();
            if accelerator.is_some() {
                let mut _accelerator = accelerator.unwrap();
                _accelerator.eight_add = _accelerator.eight_add + 1;
                //update
                storage.myaccelerator.insert(identity, _accelerator);
            }else {
                let _accelerator = Accelerator{eight_add: 1, sixteen_add: 0, twentyfour_add: 0};
                storage.myaccelerator.insert(identity, _accelerator);
            }
            _result = 3;
        }else if _random == 4 {
            //add accelerator_card 16
            let accelerator = storage.myaccelerator.get(identity).try_read();
            if accelerator.is_some() {
                let mut _accelerator = accelerator.unwrap();
                _accelerator.sixteen_add = _accelerator.sixteen_add + 1;
                //update
                storage.myaccelerator.insert(identity, _accelerator);
            }else {
                let _accelerator = Accelerator{eight_add: 0, sixteen_add: 1, twentyfour_add: 0};
                storage.myaccelerator.insert(identity, _accelerator);
            }
            _result = 4;
        }else if _random == 5 {
            //add accelerator_card 24
            let accelerator = storage.myaccelerator.get(identity).try_read();
            if accelerator.is_some() {
                let mut _accelerator = accelerator.unwrap();
                _accelerator.twentyfour_add = _accelerator.twentyfour_add + 1;
                //update
                storage.myaccelerator.insert(identity, _accelerator);
            }else{
                let _accelerator = Accelerator{eight_add: 0, sixteen_add: 0, twentyfour_add: 1};
                storage.myaccelerator.insert(identity, _accelerator);
            }
            _result = 5;
        }else{
            //add universal card
            let luckyuniversal = storage.lucky_universal.get(_epoch).try_read();
            if luckyuniversal.is_some() {
                if luckyuniversal.unwrap() < storage.max_universal.read() {
                    let constellation = storage.myconstellation.get((identity, _epoch)).try_read();
                    if constellation.is_some() {
                        let mut _constellation = constellation.unwrap();
                        _constellation.universal = _constellation.universal + 1;
                        //update
                        storage.myconstellation.insert((identity, _epoch), _constellation);
                    }else{
                        let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, zodiac: 0, universal: 1};
                        storage.myconstellation.insert((identity, _epoch), _constellation);
                    }
                    _result = 6;
                    storage.lucky_universal.insert(_epoch, luckyuniversal.unwrap() + 1);
                }else{
                    //add accelerator_card 8
                    let accelerator = storage.myaccelerator.get(identity).try_read();
                    if accelerator.is_some() {
                        let mut _accelerator = accelerator.unwrap();
                        _accelerator.eight_add = _accelerator.eight_add + 1;
                        //update
                        storage.myaccelerator.insert(identity, _accelerator);
                    }else {
                        let _accelerator = Accelerator{eight_add: 1, sixteen_add: 0, twentyfour_add: 0};
                        storage.myaccelerator.insert(identity, _accelerator);
                    }
                    _result = 3;
                }

            }else{
                let constellation = storage.myconstellation.get((identity, _epoch)).try_read();
                if constellation.is_some() {
                    let mut _constellation = constellation.unwrap();
                    _constellation.universal = _constellation.universal + 1;
                    //update
                    storage.myconstellation.insert((identity, _epoch), _constellation);
                }else{
                    let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, zodiac: 0, universal: 1};
                    storage.myconstellation.insert((identity, _epoch), _constellation);
                }
                _result = 6;
                storage.lucky_universal.insert(_epoch, 1);
            }
        }
        return _result;
    }

    #[storage(read, write)]
    fn use_universal_card(_styles: u8){
        let identity = msg_sender().unwrap();

        //check and deal epoch
        check_deal_epoch();

        let _epoch = storage.epoch.read();

        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );
        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );

        let constellation = storage.myconstellation.get((identity, _epoch)).try_read();
        require(
            constellation.is_some(),
            AvailableError::NotAvailable,
        );
        let mut _constellation = constellation.unwrap();
        require(
            _constellation.universal > 0,
            AmountError::NeedAboveZero,
        );
        _constellation.universal = _constellation.universal - 1;
        if _styles == 1 {
            _constellation.aries = _constellation.aries + 1;
        }else if _styles == 2 {
            _constellation.taurus = _constellation.taurus + 1;
        }else if _styles == 3 {
            _constellation.gemini = _constellation.gemini + 1;
        }else if _styles == 4 {
            _constellation.cancer = _constellation.cancer + 1;
        }else if _styles == 5 {
            _constellation.leo = _constellation.leo + 1;
        }else if _styles == 6 {
            _constellation.virgo = _constellation.virgo + 1;
        }else if _styles == 7 {
            _constellation.libra = _constellation.libra + 1;
        }else if _styles == 8 {
            _constellation.scorpio = _constellation.scorpio + 1;
        }else if _styles == 9 {
            _constellation.sagittarius = _constellation.sagittarius + 1;
        }else if _styles == 10 {
            _constellation.capricornus = _constellation.capricornus + 1;
        }else if _styles == 11 {                
            _constellation.aquarius = _constellation.aquarius + 1;
        }else {
            _constellation.pisces = _constellation.pisces + 1;
        }
        //update
        storage.myconstellation.insert((identity, _epoch), _constellation);
    }

    #[payable]
    #[storage(read, write)]
    fn buy_coin(amount: u64){
        let identity = msg_sender().unwrap();
        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );
        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );

        // Verify payment
        require(AssetId::base() == msg_asset_id(), AssetError::IncorrectAssetSent);
        require(
            (amount/(storage.token_price.read())) <= msg_amount(),
            AssetError::InsufficientPayment,
        );
        require(
            amount <= storage.max_buy_coin_foreach.read(),
            AmountError::AmountNotAllow,
        );

        //check and deal epoch
        check_deal_epoch();

        //check max mint for each one
        let _buy_amount = storage.my_buy_coin_amount.get(identity).try_read();
        if _buy_amount.is_some() {
            require(
                (_buy_amount.unwrap() + amount) <= storage.max_buy_coin_foreach.read(),
                AmountError::AmountNotAllow,
            );
            storage.my_buy_coin_amount.insert(identity, _buy_amount.unwrap() + amount);
        }else{        
            storage.my_buy_coin_amount.insert(identity, amount);
        }

        //caculate bonus
        let _epoch = storage.epoch.read();        
        do_allocation(_epoch, msg_amount());

        let token_contract = abi(Token, storage.token_contract_id.read());
        token_contract.mint(msg_sender().unwrap(), DEFAULT_SUB_ID, amount); 
    }

    #[storage(read, write)]
    fn claim_point(_identity: Identity, _airdrop_phase: u64, amount: u64){
        require(
            msg_sender().unwrap() == storage.point_owner.read(), 
            AuthorizationError::SenderNotOwner,
        );
        let point = storage.mypoints.get((_identity, _airdrop_phase)).try_read();
        require(
            point.is_some() && point.unwrap() >= amount,
            AvailableError::NotAvailable,
        );
        
        let mut _point = point.unwrap();
        _point = _point - amount;
        //update
        storage.mypoints.insert((_identity, _airdrop_phase), _point);
    }

    #[storage(read, write)]
    fn claim_battle_pool(_amount: u64){
        let identity = msg_sender().unwrap();
        let battlepool = storage.my_battle_pool.get(identity).try_read();
        require(
            battlepool.is_some(),
            AvailableError::NotAvailable,
        );
        require(battlepool.unwrap() >= _amount,
            AmountError::AmountNotAllow,
        );
        let mut _battlepool = battlepool.unwrap();
        _battlepool = _battlepool - _amount;
        storage.my_battle_pool.insert(identity, _battlepool);
        transfer(identity, AssetId::from(storage.asset_id.read()), _amount);
    }

    #[storage(read, write)]
    fn claim(_amount: u64, _styles: u8){
        only_proxy_owner();
        if _styles == 1 {
            transfer(msg_sender().unwrap(), AssetId::base(), _amount);
        }else{
            transfer(msg_sender().unwrap(), AssetId::from(storage.asset_id.read()), _amount);
        }        
    }

    #[storage(read, write)]
    fn dev_claim(_amount: u64){
        only_proxy_owner();
        require(
            _amount <= storage.dev_balance.read(),
            AmountError::AmountNotAllow,

        );
        storage.dev_balance.write(storage.dev_balance.read() - _amount);
        transfer(msg_sender().unwrap(), AssetId::base(), _amount);
    }

    #[storage(read, write)]
    fn airdrop_claim(_amount: u64){
        require(
            msg_sender().unwrap() == AIRDROP, 
            AuthorizationError::SenderNotOwner,
        );
        require(
            _amount <= storage.airdrop_balance.read(),
            AmountError::AmountNotAllow,

        );
        storage.airdrop_balance.write(storage.airdrop_balance.read() - _amount);
        transfer(msg_sender().unwrap(), AssetId::base(), _amount);
    }

    #[storage(read, write)]
    fn add_constellation_for_test(_identity: Identity){//delete when deploy on mainnet
        only_proxy_owner();
        let monster = storage.mymonster.get(_identity).try_read();
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );
        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );
        let _epoch = storage.epoch.read();

        let constellation = storage.myconstellation.get((_identity, _epoch)).try_read();
        if constellation.is_some() {
            let mut _constellation = constellation.unwrap();
                _constellation.aries = _constellation.aries + 1;
                _constellation.taurus = _constellation.taurus + 1;
                _constellation.gemini = _constellation.gemini + 1;
                _constellation.cancer = _constellation.cancer + 1;
                _constellation.leo = _constellation.leo + 1;
                _constellation.virgo = _constellation.virgo + 1;
                _constellation.libra = _constellation.libra + 1;
                _constellation.scorpio = _constellation.scorpio + 1;
                _constellation.sagittarius = _constellation.sagittarius + 1;
                _constellation.capricornus = _constellation.capricornus + 1;
                _constellation.aquarius = _constellation.aquarius + 1;
                _constellation.pisces = _constellation.pisces + 1;
                _constellation.universal = _constellation.universal + 1;
            //update
            storage.myconstellation.insert((_identity, _epoch), _constellation);

        }else{
            let _constellation = Constellation{aries: 1, taurus: 1, gemini: 1, cancer: 1, leo: 1, virgo: 1, libra: 1, scorpio: 1, sagittarius: 1, capricornus: 1, aquarius: 1, pisces: 1, zodiac: 0, universal: 1};
            storage.myconstellation.insert((_identity, _epoch), _constellation);
        }
    }

}

#[storage(read, write)]
fn check_deal_epoch(){
    if storage.epoch.read() == 0 {
        storage.epoch.write(1);
        storage.epoch_time.write(timestamp());
    }else{
        //check epoch time and update
        let _epoch_time = storage.epoch_time.read();
        if (timestamp() > _epoch_time + storage.epoch_diff.read()) && (storage.epoch.read() > 0) {
            storage.epoch_time.write(timestamp());
            let last_epoch = storage.epoch.read();
            storage.epoch.write(storage.epoch.read() + 1);
            deal_bonus(last_epoch);
        }
    }
}

#[storage(read, write)]
fn do_allocation(_epoch: u64, _amount: u64){
    storage.dev_balance.write(storage.dev_balance.read() + (_amount*10)/100);
    storage.airdrop_balance.write(storage.airdrop_balance.read() + (_amount*30)/100);

    //caculate bonus
    storage.community_total_bonus.write(storage.community_total_bonus.read() + (_amount*20)/100);
    let c_bonus = storage.community_epoch_total_bonus.get(_epoch).try_read();
    if c_bonus.is_some() {
        let mut _cbonus = c_bonus.unwrap();
        _cbonus = _cbonus + (_amount*20)/100;
        storage.community_epoch_total_bonus.insert(_epoch, _cbonus);
    }else{
        storage.community_epoch_total_bonus.insert(_epoch, (_amount*20)/100);
    }
    storage.invite_total_bonus.write(storage.invite_total_bonus.read() + (_amount*10)/100);
    let i_bonus = storage.invite_epoch_total_bonus.get(_epoch).try_read();
    if i_bonus.is_some() {
        let mut _i_bonus = i_bonus.unwrap();
        _i_bonus = _i_bonus + (_amount*10)/100;
        storage.invite_epoch_total_bonus.insert(_epoch, _i_bonus);
    }else{
        storage.invite_epoch_total_bonus.insert(_epoch, (_amount*10)/100);
    }
    storage.battle_total_bonus.write(storage.battle_total_bonus.read() + (_amount*30)/100);
    let battle_bonus = storage.battle_epoch_total_bonus.get(_epoch).try_read();
    if battle_bonus.is_some() {
        let mut _bbonus = battle_bonus.unwrap();
        _bbonus = _bbonus + (_amount*30)/100;
        storage.battle_epoch_total_bonus.insert(_epoch, _bbonus);
    }else{
        storage.battle_epoch_total_bonus.insert(_epoch, (_amount*30)/100);
    }

}


#[storage(read, write)]
fn deal_bonus(_epoch: u64){
    
    let current_epoch = storage.epoch.read();
    require(
            (_epoch > 0) && (_epoch + 1 == current_epoch),
            AvailableError::NotAvailable,
        );

    let _epoch_total_bonus = storage.battle_epoch_total_bonus.get(_epoch).try_read();//need to check _epoch_total_bonus is_some
    if _epoch_total_bonus.is_some() {
        storage.battle_total_bonus.write(storage.battle_total_bonus.read() - _epoch_total_bonus.unwrap()/2);
        let _total_bonus = storage.battle_total_bonus.read();
        let should_bonus = _epoch_total_bonus.unwrap() / 2 + _total_bonus*20 /100 ;
        storage.battle_total_bonus.write(_total_bonus * 80 / 100);
        storage.battle_epoch_should_bonus.insert(_epoch, should_bonus);
    }//if none, don't calculate

    let _c_epoch_total_bonus = storage.community_epoch_total_bonus.get(_epoch).try_read();
    if _c_epoch_total_bonus.is_some() {
        storage.community_total_bonus.write(storage.community_total_bonus.read() - _c_epoch_total_bonus.unwrap()/2);
        let _c_total_bonus = storage.community_total_bonus.read();
        let _c_should_bonus = _c_epoch_total_bonus.unwrap() / 2 + _c_total_bonus*20 /100 ;
        storage.community_total_bonus.write(_c_total_bonus * 80 / 100);
        storage.community_epoch_should_bonus.insert(_epoch, _c_should_bonus);
    }

    let _i_epoch_total_bonus = storage.invite_epoch_total_bonus.get(_epoch).try_read();
    if _i_epoch_total_bonus.is_some() {
        storage.invite_total_bonus.write(storage.invite_total_bonus.read() - _i_epoch_total_bonus.unwrap()/2);
        let _i_total_bonus = storage.invite_total_bonus.read();
        let _i_should_bonus = _i_epoch_total_bonus.unwrap() / 2 + _i_total_bonus*20 /100 ;
        storage.invite_total_bonus.write(_i_total_bonus * 80 / 100);
        storage.invite_epoch_should_bonus.insert(_epoch, _i_should_bonus);
    }
    
}

#[storage(read, write)]
fn deal_inviter(_epoch: u64, _indentity: Identity){
    let _my_invite_epoch_num = storage.my_invite_epoch_num.get((_indentity, _epoch)).try_read();
    if _my_invite_epoch_num.is_some() {
        let mut my_invite_epoch_num_ = _my_invite_epoch_num.unwrap();
        my_invite_epoch_num_ = my_invite_epoch_num_ + 1;
        storage.my_invite_epoch_num.insert((_indentity, _epoch), my_invite_epoch_num_);
    }else{
        storage.my_invite_epoch_num.insert((_indentity, _epoch), 1);
    }
    //add total invite_epoch_num
    let i_epoch_total_num = storage.invite_epoch_total_num.get(_epoch).try_read();
    if i_epoch_total_num.is_some() {
        let mut _i_epoch_total_num = i_epoch_total_num.unwrap();
        _i_epoch_total_num = _i_epoch_total_num + 1;
        storage.invite_epoch_total_num.insert(_epoch, _i_epoch_total_num);
    }else{
        storage.invite_epoch_total_num.insert(_epoch, 1);
    }

    //add total invite num
    let i_total_num = storage.my_invite_total_num.get(_indentity).try_read();
    if i_total_num.is_some() {
        let mut _i_total_num = i_total_num.unwrap();
        _i_total_num = _i_total_num + 1;
        storage.my_invite_total_num.insert(_indentity, _i_total_num);
    }else{
        storage.my_invite_total_num.insert(_indentity, 1);
    }

    
}

#[storage(read, write)]
fn deal_node(_indentity: Identity){
    let _my_node_member_num = storage.my_node_member_num.get(_indentity).try_read();
    if _my_node_member_num.is_some() {
        let mut my_node_member_num_ = _my_node_member_num.unwrap();
        my_node_member_num_ = my_node_member_num_ + 1;
        storage.my_node_member_num.insert(_indentity, my_node_member_num_);

        // deal node level
        let _my_node_level = storage.my_node_level.get(_indentity).try_read();
        if _my_node_level.is_some() {
           let level_membernum = storage.node_level_map_membernum.get(_my_node_level.unwrap()).try_read();
           if level_membernum.is_some() {
               if my_node_member_num_ > level_membernum.unwrap() {
                  let mut my_node_level_ = _my_node_level.unwrap();
                  my_node_level_ = my_node_level_ + 1;
                  storage.my_node_level.insert(_indentity, my_node_level_);
                  log(NodeLevelUpdateEvent{
                        node: _indentity,
                        level: my_node_level_,
                        time: timestamp(),
                    });
               }
           }
        }
    }else{
        storage.my_node_member_num.insert(_indentity, 1);
    }

}
