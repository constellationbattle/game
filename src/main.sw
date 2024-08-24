contract;

abi Game {
    #[storage(read, write)]
    fn set_free_mint(_true_false: bool);

    #[storage(read, write)]
    fn set_random_contract(_contract_id: b256);

    #[storage(read, write)]
    fn set_token_contract(_contract_id: b256);

    #[storage(read, write)]
    fn set_third_contract(_contract_id: b256);

    #[storage(read, write)]
    fn set_point_owner(_indentity: Identity);

    #[storage(read, write)]
    fn set_asset_id(_asset_id: b256);

    #[storage(read, write)]
    fn set_fruit_price(_apple_price: u64, _banana_price: u64, _ananas_price: u64);

    #[storage(read, write)]
    fn set_lucky_price(_lucky_price: u64);

    #[storage(read, write)]
    fn set_combine_price(_combine_price: u64);

    #[storage(read, write)]
    fn set_battle_price(_battle_price: u64);

    #[storage(read, write)]
    fn set_monster_price(_monster_price: u64);

    #[storage(read, write)]
    fn set_rebirth_price(_rebirth_price: u64);

    #[storage(read, write)]
    fn set_gene_price(_gene_price: u64);

    #[storage(read, write)]
    fn add_airdrop_phase();

    #[storage(read, write)]
    fn set_token_price(_token_price: u64);

    #[payable, storage(read, write)]
    fn mint_monster();

    #[storage(read, write)]
    fn free_mint_monster();

    #[storage(read)]
    fn get_my_info()->(Option<Monster>, Option<Fruit>, Option<Constellation>, Option<Accelerator>, Option<u64>, u64, u64);

    #[storage(read)]
    fn get_my_point(_indentity: Identity, _airdrop_phase: u64)->Option<u64>;

    #[payable, storage(read, write)]
    fn buy_fruit(_styles: u8, _amount: u16);

    #[storage(read, write)]
    fn feed_fruit(_styles: u8);

    #[storage(read, write)]
    fn using_accelerator_card(_styles: u8);

    #[storage(read, write)]
    fn claim_constellation();

    #[payable, storage(read, write)]
    fn combine_constellation();

    #[storage(read, write)]
    fn claim_bonus(_epoch: u64);

    #[payable, storage(read, write)]
    fn regenerate_gene();

    #[payable, storage(read, write)]
    fn rebirth();

    #[payable, storage(read, write)]
    fn list_constellation(_styles: u8) -> b256;

    #[payable, storage(read, write)]
    #[storage(read, write)]
    fn delist_constellation(_listid: b256);

    #[storage(read)]
    fn get_market(_listid: b256) -> Option<Market>;

    #[payable, storage(read, write)]
    fn battle(_use_styles: u8, _listid: b256) -> bool;

    #[storage(read, write)]
    fn add_accelerator();

    #[payable, storage(read, write)]
    fn lucky_turntable();

    #[storage(read, write)]
    fn use_universal_card(_styles: u8);

    #[payable, storage(read, write)]
    fn buy_coin(amount: u64);

    #[storage(read, write)]
    fn claim_point(_identity: Identity, _airdrop_phase: u64, amount: u64);

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
}

enum AvailableError {
    NotAvailable: (),
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
    angel: u16,
    universal: u16,
}

struct Market{
    owner: Identity,
    ownergene: u64,
    bonus: u64,
    constella: u16,
    epoch: u64,
}


configurable {
    ADMIN: Identity = Identity::Address(Address::from(0xb9d62dec6e8b87e495772cd81862db31394bfc3b4d1cb6e04c530f21e3ac1f80)),
    AIRDROP: Identity = Identity::Address(Address::from(0xb9d62dec6e8b87e495772cd81862db31394bfc3b4d1cb6e04c530f21e3ac1f80)),
    ONEDAY: u64 = 60*5*1,
    TWODAYS: u64 = 60*5*2,
    THREEDAYS: u64 = 60*5*3,
    FIVEDAYS: u64 = 60*5*5,
    ADDEIGHT: u64 = 60*2,
    ADDSIXTEEN: u64 = 60*3,
    ADDONEDAY: u64 = 60*5,
    EPOCHDIFF: u64 = 60*75,
}

storage {
    free_mint: bool = false,
    epoch: u64 = 0,
    epoch_time: u64 = 0,
    airdrop_phase: u64 = 1,
    monster_price: u64 = 100000,
    rebirth_price: u64 = 100000,
    gene_price: u64 = 100000,
    apple_price: u64 = 100000,
    banana_price: u64 = 200000,
    ananas_price: u64 = 400000,
    lucky_price: u64 = 100*1000000000,
    combine_price: u64 = 500*1000000000,
    battle_price: u64 = 10*1000000000,
    token_price: u64 = 1000000, //1000000 token/eth
    total_bonus: u64 = 0,
    total_point: StorageMap<u64, u64> = StorageMap {},
    mymonster: StorageMap<Identity, Monster> = StorageMap {},
    myfruit: StorageMap<Identity, Fruit> = StorageMap {},
    myconstellation: StorageMap<(Identity, u64), Constellation> = StorageMap {},
    my_share_bonus: StorageMap<(Identity, u64), u64> = StorageMap {},
    my_name_accelerator: StorageMap<(Identity, u64), bool> = StorageMap {},
    epoch_total_share: StorageMap<u64, u64> = StorageMap {}, // epoch_should_bonus/epoch_total_share for one share bonus
    epoch_should_bonus: StorageMap<u64, u64> = StorageMap {},
    epoch_total_bonus: StorageMap<u64, u64> = StorageMap {},
    myaccelerator: StorageMap<Identity, Accelerator> = StorageMap {},
    mypoints: StorageMap<(Identity, u64), u64> = StorageMap {},
    markets: StorageMap<b256, Market> = StorageMap {},
    random_contract_id: b256 = 0xb9d62dec6e8b87e495772cd81862db31394bfc3b4d1cb6e04c530f21e3ac1f80,
    token_contract_id: b256 = 0xb9d62dec6e8b87e495772cd81862db31394bfc3b4d1cb6e04c530f21e3ac1f80,
    third_contract_id: b256 = 0xb9d62dec6e8b87e495772cd81862db31394bfc3b4d1cb6e04c530f21e3ac1f80,
    asset_id: b256 = 0xb9d62dec6e8b87e495772cd81862db31394bfc3b4d1cb6e04c530f21e3ac1f80,
    point_owner: Identity = Identity::ContractId(ContractId::from(0xb9d62dec6e8b87e495772cd81862db31394bfc3b4d1cb6e04c530f21e3ac1f80)),
}

impl Game for Contract {
    #[storage(read, write)]
    fn set_free_mint(_true_false: bool){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.free_mint.write(_true_false);
    }

    #[storage(read, write)]
    fn set_random_contract(_contract_id: b256){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.random_contract_id.write(_contract_id);
    }

    #[storage(read, write)]
    fn set_token_contract(_contract_id: b256){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.token_contract_id.write(_contract_id);
    }

    #[storage(read, write)]
    fn set_third_contract(_contract_id: b256){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.third_contract_id.write(_contract_id);
    }

     #[storage(read, write)]
    fn set_point_owner(_indentity: Identity){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.point_owner.write(_indentity);
    }

    #[storage(read, write)]
    fn set_asset_id(_asset_id: b256){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.asset_id.write(_asset_id);
    }

    #[storage(read, write)]
    fn set_fruit_price(_apple_price: u64, _banana_price: u64, _ananas_price: u64){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        require(
            _apple_price > 0 && _banana_price > 0 && _ananas_price > 0, 
            AmountError::NeedAboveZero,
        );
        storage.apple_price.write(_apple_price);
        storage.banana_price.write(_banana_price);
        storage.ananas_price.write(_ananas_price);
    }

    #[storage(read, write)]
    fn set_lucky_price(_lucky_price: u64){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.lucky_price.write(_lucky_price);
    }

    #[storage(read, write)]
    fn set_combine_price(_combine_price: u64){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.combine_price.write(_combine_price);
    }

    #[storage(read, write)]
    fn set_battle_price(_battle_price: u64){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.battle_price.write(_battle_price);
    }

    #[storage(read, write)]
    fn set_monster_price(_monster_price: u64){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.monster_price.write(_monster_price);
    }

    #[storage(read, write)]
    fn set_rebirth_price(_rebirth_price: u64){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.rebirth_price.write(_rebirth_price);
    }

    #[storage(read, write)]
    fn set_gene_price(_gene_price: u64){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.gene_price.write(_gene_price);
    }

    #[storage(read, write)]
    fn add_airdrop_phase(){
         require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.airdrop_phase.write(storage.airdrop_phase.read() + 1);
    }

    #[storage(read, write)]
    fn set_token_price(_token_price: u64){
        require(
            msg_sender().unwrap() == ADMIN, 
            AuthorizationError::SenderNotOwner,
        );
        storage.token_price.write(_token_price);
    }

    #[payable]
    #[storage(read, write)]
    fn mint_monster(){
        let identity = msg_sender().unwrap();
        let record = storage.mymonster.get(identity).try_read();
        require(record.is_none(),
            MintError::AlreadyMinted,
        );

        if storage.epoch.read() == 0 {
            storage.epoch.write(1);
            storage.epoch_time.write(timestamp());
        }else{
            //check epoch time and update
            let _epoch_time = storage.epoch_time.read();
            if (timestamp() > _epoch_time + EPOCHDIFF) && (storage.epoch.read() > 0) {
                storage.epoch_time.write(timestamp());
                let last_epoch = storage.epoch.read();
                storage.epoch.write(storage.epoch.read() + 1);
                deal_bonus(last_epoch);
            }
        }
        let _epoch = storage.epoch.read();
        
        // Verify payment
        require(AssetId::base() == msg_asset_id(), AssetError::IncorrectAssetSent);
        require(
            storage.monster_price.read() <= msg_amount(),
            AssetError::InsufficientPayment,
        );
        // do allocation
        transfer(ADMIN, AssetId::base(), (msg_amount()*10)/100);
        transfer(AIRDROP, AssetId::base(), (msg_amount()*40)/100);

        //caculate bonus
        storage.total_bonus.write(storage.total_bonus.read() + storage.monster_price.read());
        let bonus = storage.epoch_total_bonus.get(_epoch).try_read();
        let mut _bonus = bonus.unwrap();
        _bonus = _bonus + storage.monster_price.read();
        storage.epoch_total_bonus.insert(_epoch, _bonus);


        // Omitting the processing algorithm for random numbers
        let _geni = 12020329928232323;
        let _bonus = 5; 
        let _expiry = 3;
        // Omitting the processing algorithm for random numbers

        // Store monster
        let monster = Monster{gene: _geni.unwrap(), starttime: timestamp(), genetime:timestamp(), cardtime: timestamp(), turntabletime: timestamp(), expiry: timestamp()+ ONEDAY*_expiry, bonus: _bonus};
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
        
    }

    #[storage(read, write)]
    fn free_mint_monster(){
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

        if storage.epoch.read() == 0 {
            storage.epoch.write(1);
            storage.epoch_time.write(timestamp());
        }else{
            //check epoch time and update
            let _epoch_time = storage.epoch_time.read();
            if (timestamp() > _epoch_time + EPOCHDIFF) && (storage.epoch.read() > 0) {
                storage.epoch_time.write(timestamp());
                let last_epoch = storage.epoch.read();
                storage.epoch.write(storage.epoch.read() + 1);
                deal_bonus(last_epoch);
            }
        }


        // Omitting the processing algorithm for random numbers
        let _geni = 12020329928232323;
        let _bonus = 5; 
        let _expiry = 3;
        // Omitting the processing algorithm for random numbers

        // Store monster
        let monster = Monster{gene: _geni.unwrap(), starttime: timestamp(), genetime:timestamp(), cardtime: timestamp(), turntabletime: timestamp(), expiry: timestamp()+ ONEDAY*_expiry, bonus: _bonus};
        storage.mymonster.insert(identity, monster);
    }

    #[storage(read)]
    fn get_my_info()->(Option<Monster>, Option<Fruit>, Option<Constellation>, Option<Accelerator>, Option<u64>, u64, u64) {
        let identity = msg_sender().unwrap();
        let _epoch = storage.epoch.read();
        (storage.mymonster.get(identity).try_read(), 
         storage.myfruit.get(identity).try_read(), 
         storage.myconstellation.get((identity, _epoch)).try_read(), 
         storage.myaccelerator.get(identity).try_read(),
         storage.mypoints.get((identity, storage.airdrop_phase.read())).try_read(),
         storage.epoch.read(),
         storage.epoch_time.read(),
        )

    }

    #[storage(read)]
    fn get_my_point(_indentity: Identity, _airdrop_phase: u64)->Option<u64>{
        storage.mypoints.get((_indentity, _airdrop_phase)).try_read()
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
        // do allocation
        transfer(ADMIN, AssetId::base(), (msg_amount()*10)/100);
        transfer(AIRDROP, AssetId::base(), (msg_amount()*40)/100);
        
        if storage.epoch.read() == 0 {
            storage.epoch.write(1);
            storage.epoch_time.write(timestamp());
        }else{
            //check epoch time and update
            let _epoch_time = storage.epoch_time.read();
            if (timestamp() > _epoch_time + EPOCHDIFF) && (storage.epoch.read() > 0) {
                storage.epoch_time.write(timestamp());
                storage.epoch.write(storage.epoch.read() + 1);
            }
        }
        let _epoch = storage.epoch.read();
        
        //caculate bonus
        storage.total_bonus.write(storage.total_bonus.read() + msg_amount());
        let bonus = storage.epoch_total_bonus.get(_epoch).try_read();
        let mut _bonus = bonus.unwrap();
        _bonus = _bonus + msg_amount();
        storage.epoch_total_bonus.insert(_epoch, _bonus);

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
            _monster.expiry = timestamp() + TWODAYS;
        }else if _styles == 2{
            require(
                _fruit.banana > 0,
                AmountError::NeedAboveZero,
            );
            _fruit.banana = _fruit.banana - 1;
            _monster.expiry = timestamp() + THREEDAYS;
        }else{
            require(
                _fruit.ananas > 0,
                AmountError::NeedAboveZero,
            );
            _fruit.ananas = _fruit.ananas - 1;
            _monster.expiry = timestamp() + FIVEDAYS;
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
            _monster.cardtime = _monster.cardtime - ADDEIGHT;
        }else if _styles == 2 {
            require(
                _accelerator.sixteen_add > 0,
                AmountError::NeedAboveZero,
            );
            _accelerator.sixteen_add = _accelerator.sixteen_add - 1;
            _monster.cardtime = _monster.cardtime - ADDSIXTEEN;
        }else {
            require(
                _accelerator.twentyfour_add > 0,
                AmountError::NeedAboveZero,
            );
            _accelerator.twentyfour_add = _accelerator.twentyfour_add - 1;
            _monster.cardtime = _monster.cardtime - ADDONEDAY;
        }
        //update
        storage.myaccelerator.insert(identity, _accelerator);
        storage.mymonster.insert(identity, _monster);

    }

    #[storage(read, write)]
    fn claim_constellation(){
        let identity = msg_sender().unwrap();
        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );
        require(
            timestamp() > monster.unwrap().cardtime + ONEDAY,
            TimeError::NotEnoughTime,
        );

        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );

        //check epoch time and update
        let _epoch_time = storage.epoch_time.read();
        if (timestamp() > _epoch_time + EPOCHDIFF) && (storage.epoch.read() > 0) {
            storage.epoch_time.write(timestamp());
            let last_epoch = storage.epoch.read();
            storage.epoch.write(storage.epoch.read() + 1);
            deal_bonus(last_epoch);
        }

        let _epoch = storage.epoch.read();

        // Omitting the processing algorithm for random numbers
        let random = 3;
        // Omitting the processing algorithm for random numbers

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
        let mut _monster = monster.unwrap();
        _monster.cardtime = timestamp();
        //update
        storage.mymonster.insert(identity, _monster);

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
        let _my_share = storage.my_share_bonus.get((identity, _epoch)).try_read();
        if _my_share.is_some() {
          let mut my_share = _my_share.unwrap();
          my_share = my_share + monster.unwrap().bonus;
          storage.my_share_bonus.insert((identity, _epoch), my_share);
        }else{
          storage.my_share_bonus.insert((identity, _epoch), monster.unwrap().bonus);
        }
        let _total_share = storage.epoch_total_share.get(_epoch).try_read();
        if _total_share.is_some() {
            let mut total_share = _total_share.unwrap();
            total_share = total_share + monster.unwrap().bonus;
        }else{
            storage.epoch_total_share.insert(_epoch, monster.unwrap().bonus);
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
        _constellation.angel = _constellation.angel + 1;
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
        //add total point
        let totalpoint = storage.total_point.get(airdropphase).try_read();
        if totalpoint.is_some(){
            let mut _totalpoint = totalpoint.unwrap();
            _totalpoint = _totalpoint + 10;
            storage.total_point.insert(airdropphase, _totalpoint);
        }else{
            storage.total_point.insert(airdropphase, 10);
        }

         //check epoch time and update
        let _epoch_time = storage.epoch_time.read();
        if (timestamp() > _epoch_time + EPOCHDIFF) && (_epoch > 0) {
            storage.epoch_time.write(timestamp());
            // storage.epoch.write(_epoch + 1);
            let last_epoch = storage.epoch.read();
            storage.epoch.write(storage.epoch.read() + 1);
            deal_bonus(last_epoch);
            
        }
    }

    #[storage(read, write)]
    fn claim_bonus(_epoch: u64){
        let current_epoch = storage.epoch.read();
        require(
            _epoch > 0 && _epoch < current_epoch,
            AvailableError::NotAvailable,
        );
        let identity = msg_sender().unwrap();
        let _my_share = storage.my_share_bonus.get((identity, _epoch)).try_read();
        let _total_share = storage.epoch_total_share.get(_epoch).try_read();
        require(
            _my_share.is_some() && _total_share.is_some(),
            AvailableError::NotAvailable,
        );
        let _should_bonus = storage.epoch_should_bonus.get(_epoch).try_read();
        let _epoch_total_bonus = storage.epoch_total_bonus.get(_epoch).try_read();
        require(
            _epoch_total_bonus.is_some() && _should_bonus.is_some(),
            AvailableError::NotAvailable,
        );
        
        let each_share = _should_bonus.unwrap() / _total_share.unwrap();
        let my_bonus = each_share * _my_share.unwrap();
        storage.my_share_bonus.remove((identity, _epoch));
        transfer(identity, AssetId::base(), my_bonus);

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
            timestamp() > monster.unwrap().genetime + ONEDAY,
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
        // do allocation
        transfer(ADMIN, AssetId::base(), (msg_amount()*10)/100);
        transfer(AIRDROP, AssetId::base(), (msg_amount()*40)/100);

        //check epoch time and update
        let _epoch_time = storage.epoch_time.read();
        if (timestamp() > _epoch_time + EPOCHDIFF) && (storage.epoch.read() > 0) {
            storage.epoch_time.write(timestamp());
            let last_epoch = storage.epoch.read();
            storage.epoch.write(storage.epoch.read() + 1);
            deal_bonus(last_epoch);
        }

        //caculate bonus
        let _epoch = storage.epoch.read();
        
        storage.total_bonus.write(storage.total_bonus.read() + storage.gene_price.read());
        let bonus = storage.epoch_total_bonus.get(_epoch).try_read();
        let mut _bonus = bonus.unwrap();
        _bonus = _bonus + storage.gene_price.read();
        storage.epoch_total_bonus.insert(_epoch, _bonus);

         // Omitting the processing algorithm for random numbers
        let _geni = 12020329928232323;
        let _mybonus = 5;
        // Omitting the processing algorithm for random numbers

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
        // do allocation
        transfer(ADMIN, AssetId::base(), (msg_amount()*10)/100);
        transfer(AIRDROP, AssetId::base(), (msg_amount()*40)/100);

        //check epoch time and update
        let _epoch_time = storage.epoch_time.read();
        if (timestamp() > _epoch_time + EPOCHDIFF) && (storage.epoch.read() > 0) {
            storage.epoch_time.write(timestamp());
            storage.epoch.write(storage.epoch.read() + 1);
        }

        //caculate bonus
        let _epoch = storage.epoch.read();
        storage.total_bonus.write(storage.total_bonus.read() + storage.monster_price.read());
        let bonus = storage.epoch_total_bonus.get(_epoch).try_read();
        let mut _bonus = bonus.unwrap();
        _bonus = _bonus + storage.monster_price.read();
        storage.epoch_total_bonus.insert(_epoch, _bonus);


         // Omitting the processing algorithm for random numbers
        let _expiry = 3;
        // Omitting the processing algorithm for random numbers

        let mut _monster = monster.unwrap();
        _monster.expiry = timestamp()+ ONEDAY*_expiry;
        //update
        storage.mymonster.insert(identity, _monster);

    }

    #[payable]
    #[storage(read, write)]
    fn list_constellation(_styles: u8) -> b256 {
        let identity = msg_sender().unwrap();
        //check epoch time and update
        let _epoch_time = storage.epoch_time.read();
        if (timestamp() > _epoch_time + EPOCHDIFF) && (storage.epoch.read() > 0) {
            storage.epoch_time.write(timestamp());
            let last_epoch = storage.epoch.read();
            storage.epoch.write(storage.epoch.read() + 1);
            deal_bonus(last_epoch);
        }
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
            storage.battle_price.read() <= msg_amount(),
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
        listid
    }

    #[payable]
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
        transfer(identity, AssetId::from(storage.asset_id.read()), storage.battle_price.read());


    }

    #[storage(read)]
    fn get_market(_listid: b256) -> Option<Market>{
        storage.markets.get(_listid).try_read()
    }

    #[payable]
    #[storage(read, write)]
    fn battle(_use_styles: u8, _listid: b256) -> bool{//battle first, then update the epoch
        let identity = msg_sender().unwrap();
        let _epoch = storage.epoch.read();
        let monster = storage.mymonster.get(identity).try_read();
        let market = storage.markets.get(_listid).try_read();
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
            // add card to owner, delete card from you
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
            //update
            storage.myconstellation.insert((identity, _epoch), _my_constellation);
            storage.myconstellation.insert((market.unwrap().owner, _epoch), _owner_constellation);

            //tranfer token to winner
            transfer(market.unwrap().owner, AssetId::from(storage.asset_id.read()), storage.battle_price.read());

        }else {
            //you win
            // add card to you, init card from market
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
            storage.markets.remove(_listid);

            //update
            storage.myconstellation.insert((identity, _epoch), _my_constellation);

            //tranfer token to winner
            transfer(market.unwrap().owner, AssetId::from(storage.asset_id.read()), storage.battle_price.read() * 2);

            // return true;
        }
        
        //update point
        let airdropphase = storage.airdrop_phase.read();
        let owner_point = storage.mypoints.get((market.unwrap().owner, airdropphase)).try_read();
        let use_point = storage.mypoints.get((identity, airdropphase)).try_read();
        if(owner_point.is_some()){
            let mut _point = owner_point.unwrap();
            _point = _point + 1;
            //update
            storage.mypoints.insert((market.unwrap().owner, airdropphase), _point);
        }else{
            storage.mypoints.insert((market.unwrap().owner, airdropphase), 1);
        }

        if(use_point.is_some()){
            let mut _point = use_point.unwrap();
            _point = _point + 1;
            //update
            storage.mypoints.insert((identity, airdropphase), _point);
        }else{
            storage.mypoints.insert((identity, airdropphase), 1);
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

        //check epoch time and update
        let _epoch_time = storage.epoch_time.read();
        if (timestamp() > _epoch_time + EPOCHDIFF) && (_epoch > 0) {
            storage.epoch_time.write(timestamp());
            let last_epoch = storage.epoch.read();
            storage.epoch.write(_epoch + 1);
            deal_bonus(last_epoch);
        }

        return _random != 1;

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
    fn lucky_turntable(){
        let identity = msg_sender().unwrap();
        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            AvailableError::NotAvailable,
        );

        require(
            timestamp() > monster.unwrap().turntabletime + ONEDAY,
            TimeError::NotEnoughTime,
        );

        //check expiry
        require(monster.unwrap().expiry > timestamp(),
            TimeError::Expiry,
        );

        //check epoch time and update
        let _epoch_time = storage.epoch_time.read();
        if (timestamp() > _epoch_time + EPOCHDIFF) && (storage.epoch.read() > 0) {
            storage.epoch_time.write(timestamp());
            let last_epoch = storage.epoch.read();
            storage.epoch.write(storage.epoch.read() + 1);
            deal_bonus(last_epoch);
        }
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
            
        }else if _random == 2 {
            //add banana
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
        }else if (_random > 2) && (_random < 8) {
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
            
        }else if _random == 8 {
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
            
        }else if _random == 9 {
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
            
        }else{
            //add universal card
            let constellation = storage.myconstellation.get((identity, _epoch)).try_read();
            if constellation.is_some() {
                let mut _constellation = constellation.unwrap();
                _constellation.universal = _constellation.universal + 1;
                //update
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }else{
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 1};
                storage.myconstellation.insert((identity, _epoch), _constellation);
            }
            
        }

    }

    #[storage(read, write)]
    fn use_universal_card(_styles: u8){
        let identity = msg_sender().unwrap();

        //check epoch time and update
        let _epoch_time = storage.epoch_time.read();
        if (timestamp() > _epoch_time + EPOCHDIFF) && (storage.epoch.read() > 0) {
            storage.epoch_time.write(timestamp());
            let last_epoch = storage.epoch.read();
            storage.epoch.write(storage.epoch.read() + 1);
            deal_bonus(last_epoch);
        }
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

         //check epoch time and update
        let _epoch_time = storage.epoch_time.read();
        if (timestamp() > _epoch_time + EPOCHDIFF) && (storage.epoch.read() > 0) {
            storage.epoch_time.write(timestamp());
            storage.epoch.write(storage.epoch.read() + 1);
        }

        //caculate bonus
        let _epoch = storage.epoch.read();
        storage.total_bonus.write(storage.total_bonus.read() + msg_amount());
        let bonus = storage.epoch_total_bonus.get(_epoch).try_read();
        let mut _bonus = bonus.unwrap();
        _bonus = _bonus + msg_amount();
        storage.epoch_total_bonus.insert(_epoch, _bonus);


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

}

#[storage(read, write)]
fn deal_bonus(_epoch: u64){
    
    let current_epoch = storage.epoch.read();
    require(
            _epoch > 0 && _epoch + 1 == current_epoch,
            AvailableError::NotAvailable,
        );
    let _should_bonus = storage.epoch_should_bonus.get(_epoch).try_read();
    let _epoch_total_bonus = storage.epoch_total_bonus.get(_epoch).try_read();

    storage.total_bonus.write(storage.total_bonus.read() - _epoch_total_bonus.unwrap()/2);
    let _total_bonus = storage.total_bonus.read();
    let should_bonus = _epoch_total_bonus.unwrap() / 2 + _total_bonus*20 /100 ;
    storage.total_bonus.write(_total_bonus * 80 / 100);
    storage.epoch_should_bonus.insert(_epoch, should_bonus);
}
