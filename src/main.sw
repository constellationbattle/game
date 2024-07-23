contract;

abi Game {
    #[storage(read, write)]
    fn mint_monster();

    #[storage(read)]
    fn get_my_monster()->Option<Monster>;

    #[storage(read, write)]
    fn buy_fruit(_styles: u8, _amount: u16);

    #[storage(read)]
    fn get_my_fruit()->Option<Fruit>;

    #[storage(read, write)]
    fn feed_fruit(_styles: u8);

    #[storage(read, write)]
    fn using_accelerator_card(_styles: u8);

    #[storage(read, write)]
    fn claim_constellation();

     #[storage(read, write)]
    fn combine_constellation();

    #[storage(read, write)]
    fn regenerate_gene();

    #[storage(read, write)]
    fn list_constellation(_styles: u8) -> b256;

    #[storage(read, write)]
    fn delist_constellation(_listid: b256);

     #[storage(read)]
    fn get_market(_listid: b256) -> Option<Market>;

    #[storage(read, write)]
    fn battle(_use_styles: u8, _listid: b256) -> bool;

    #[storage(read, write)]
    fn lucky_turntable();

    #[storage(read, write)]
    fn use_universal_card(_styles: u8);

    #[storage(read, write)]
    fn buy_coin();
}

use std::{
    auth::msg_sender,
    block::timestamp,
    call_frames::msg_asset_id,
    constants::ZERO_B256,
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
}

enum AmountError {
    NeedAboveZero: (),
}

enum FruitError {
    NotAvailable: (),
}

enum MonsterError {
    NotAvailable: (),
}

enum ConstellationError {
    NotAvailable: (),
}

enum AcceleratorError {
    NotAvailable: (),
}

enum MarketError {
    NotAvailable: (),
}

enum TimeError {
    NotEnoughTime: (),
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
    constella: u16,
}

storage {
    base_life: u64 = 3600*24*1,
    apple_price: u64 = 100000,
    banana_price: u64 = 200000,
    ananas_price: u64 = 300000,
    mymonster: StorageMap<Identity, Monster> = StorageMap {},
    myfruit: StorageMap<Identity, Fruit> = StorageMap {},
    myconstellation: StorageMap<Identity, Constellation> = StorageMap {},
    myaccelerator: StorageMap<Identity, Accelerator> = StorageMap {},
    markets: StorageMap<b256, Market> = StorageMap {},
}

impl Game for Contract {
    #[storage(read, write)]
    fn mint_monster(){
        let identity = msg_sender().unwrap();
        let record = storage.mymonster.get(identity).try_read();
        require(record.is_none(),
            MintError::AlreadyMinted,
        );

        // Omitting the processing algorithm for random numbers
        let _geni = 12020329928232323;
        let _bonus = 5; 
        let _expiry = 3;
        // Omitting the processing algorithm for random numbers

        // Store monster
        let monster = Monster{gene: _geni.unwrap(), starttime: timestamp(), genetime:timestamp(), cardtime: timestamp(), turntabletime: timestamp(), expiry: timestamp()+ 3600*24*_expiry, bonus: _bonus};
        storage.mymonster.insert(identity, monster);
    }

    #[storage(read)]
    fn get_my_monster()->Option<Monster>{
        storage.mymonster.get(msg_sender().unwrap()).try_read()
    }

    #[storage(read, write)]
    fn buy_fruit(_styles: u8, _amount: u16){
        let identity = msg_sender().unwrap();
        let fruit = storage.myfruit.get(identity).try_read();
        require(
            _amount > 0,
            AmountError::NeedAboveZero,
        );
        if fruit.is_some() {
            let mut _fruit = fruit.unwrap();
            if _styles == 1 {
                _fruit.apple = _fruit.apple + _amount;
            }else if _styles == 2{
                _fruit.banana = _fruit.banana + _amount;
            }else{
                _fruit.ananas = _fruit.ananas + _amount;
            }

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

    #[storage(read)]
    fn get_my_fruit()->Option<Fruit>{
        storage.myfruit.get(msg_sender().unwrap()).try_read()
    }

    #[storage(read, write)]
    fn feed_fruit(_styles: u8){
        let identity = msg_sender().unwrap();
        let fruit = storage.myfruit.get(identity).try_read();
        let monster = storage.mymonster.get(identity).try_read();
        //check if expiry todo
        require(fruit.is_some(),
            FruitError::NotAvailable,
        );
        require(monster.is_some(),
            MonsterError::NotAvailable,
        );
        let mut _fruit = fruit.unwrap();
        let mut _monster = monster.unwrap();
        if _styles == 1 {
            require(
                _fruit.apple > 0,
                AmountError::NeedAboveZero,
            );
            _fruit.apple = _fruit.apple - 1;
            _monster.expiry = timestamp() + 3600*24*2;
        }else if _styles == 2{
            require(
                _fruit.banana > 0,
                AmountError::NeedAboveZero,
            );
            _fruit.banana = _fruit.banana - 1;
            _monster.expiry = timestamp() + 3600*24*3;
        }else{
            require(
                _fruit.ananas > 0,
                AmountError::NeedAboveZero,
            );
            _fruit.ananas = _fruit.ananas - 1;
            _monster.expiry = timestamp() + 3600*24*5;
        }

    }

    #[storage(read, write)]
    fn using_accelerator_card(_styles: u8){
        let identity = msg_sender().unwrap();
        let accelerator = storage.myaccelerator.get(identity).try_read();
        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            MonsterError::NotAvailable,
        );
        require(
            accelerator.is_some(),
            AcceleratorError::NotAvailable,
        );
        let mut _accelerator = accelerator.unwrap();
        let mut _monster = monster.unwrap();
        if _styles == 1 {
            require(
                _accelerator.eight_add > 0,
                AmountError::NeedAboveZero,
            );
            _accelerator.eight_add = _accelerator.eight_add - 1;
            _monster.cardtime = _monster.cardtime + 3600*8;
        }else if _styles == 2 {
            require(
                _accelerator.sixteen_add > 0,
                AmountError::NeedAboveZero,
            );
            _accelerator.sixteen_add = _accelerator.sixteen_add - 1;
            _monster.cardtime = _monster.cardtime + 3600*16;
        }else {
            require(
                _accelerator.twentyfour_add > 0,
                AmountError::NeedAboveZero,
            );
            _accelerator.twentyfour_add = _accelerator.twentyfour_add - 1;
            _monster.cardtime = _monster.cardtime + 3600*24;
        }

    }

    #[storage(read, write)]
    fn claim_constellation(){
        let identity = msg_sender().unwrap();
        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            MonsterError::NotAvailable,
        );
        require(
            timestamp() > monster.unwrap().cardtime + 3600*24*1,
            TimeError::NotEnoughTime,
        );

        // Omitting the processing algorithm for random numbers
        let random = 3;
        // Omitting the processing algorithm for random numbers

        let constellation = storage.myconstellation.get(identity).try_read();
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

        }else{
            if random == 1 {
                let _constellation = Constellation{aries: 1, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert(identity, _constellation);
            }else if random == 2 {
                let _constellation = Constellation{aries: 0, taurus: 1, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert(identity, _constellation);
            }else if random == 3 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 1, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert(identity, _constellation);
            }else if random == 4 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 1, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert(identity, _constellation);
            }else if random == 5 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 1, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert(identity, _constellation);
            }else if random == 6 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 1, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert(identity, _constellation);
            }else if random == 7 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 1, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert(identity, _constellation);
            }else if random == 8 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 1, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert(identity, _constellation);
            }else if random == 9 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 1, capricornus: 0, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert(identity, _constellation);
            }else if random == 10 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 1, aquarius: 0, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert(identity, _constellation);
            }else if random == 11 {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 1, pisces: 0, angel: 0, universal: 0};
                storage.myconstellation.insert(identity, _constellation);
            }else {
                let _constellation = Constellation{aries: 0, taurus: 0, gemini: 0, cancer: 0, leo: 0, virgo: 0, libra: 0, scorpio: 0, sagittarius: 0, capricornus: 0, aquarius: 0, pisces: 1, angel: 0, universal: 0};
                storage.myconstellation.insert(identity, _constellation);
            }
        }
        let mut _monster = monster.unwrap();
        _monster.cardtime = timestamp();

    }

    #[storage(read, write)]
    fn combine_constellation(){
        let identity = msg_sender().unwrap();
        let constellation = storage.myconstellation.get(identity).try_read();
        require(
            constellation.is_some(),
            ConstellationError::NotAvailable,
        );
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
    }

    #[storage(read, write)]
    fn regenerate_gene(){
        let identity = msg_sender().unwrap();
        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            MonsterError::NotAvailable,
        );
        require(
            timestamp() > monster.unwrap().genetime + 3600*24*1,
            TimeError::NotEnoughTime,
        );

        // Omitting the processing algorithm for random numbers
        let _geni = 12020329928232323;
        let _bonus = 5;
        // Omitting the processing algorithm for random numbers

        let mut _monster = monster.unwrap();
        _monster.gene = _geni;
        _monster.bonus = _bonus;
        _monster.genetime = timestamp();

       //update todo

    }

    #[storage(read, write)]
    fn list_constellation(_styles: u8) -> b256 {
        let identity = msg_sender().unwrap();
        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            MonsterError::NotAvailable,
        );

        //sub constella
        let constellation = storage.myconstellation.get(identity).try_read();
        require(
            constellation.is_some(),
            ConstellationError::NotAvailable,
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

        //generate gene 
        let random = 10;
        let listid: b256 = sha256((timestamp(), msg_sender().unwrap(), random, _styles));
        
        // Store Market
        let market = Market{owner: identity, ownergene: monster.unwrap().gene, constella: _styles.as_u16()};
        storage.markets.insert(listid, market);
        listid
    }

    #[storage(read, write)]
    fn delist_constellation(_listid: b256){
        let identity = msg_sender().unwrap();
        let market = storage.markets.get(_listid).try_read();
        require(
            market.is_some(),
            MarketError::NotAvailable,
        );
        require(
            market.unwrap().constella > 0,
            MarketError::NotAvailable,
        );
        let my_constellation = storage.myconstellation.get(identity).try_read();
        require(
            my_constellation.is_some(),
            ConstellationError::NotAvailable,
        );
        let mut _my_constellation = my_constellation.unwrap();
        let mut _market = market.unwrap();

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

        let newmarket = Market{owner: Identity::Address(Address::zero()), ownergene: 0, constella: 0};
        storage.markets.insert(_listid, newmarket);


    }

    #[storage(read)]
    fn get_market(_listid: b256) -> Option<Market>{
        storage.markets.get(_listid).try_read()
    }

    #[storage(read, write)]
    fn battle(_use_styles: u8, _listid: b256) -> bool{
        let identity = msg_sender().unwrap();
        let monster = storage.mymonster.get(identity).try_read();
        let market = storage.markets.get(_listid).try_read();
        require(
            monster.is_some(),
            MonsterError::NotAvailable,
        );
        require(
            market.is_some(),
            MarketError::NotAvailable,
        );
        //check user has card
        let my_constellation = storage.myconstellation.get(identity).try_read();
        require(
                my_constellation.is_some(),
                ConstellationError::NotAvailable,
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
            market.unwrap().constella > 0,
            MarketError::NotAvailable,
        );

        // Omitting the processing algorithm for random numbers
        let _random = 1;
        // Omitting the processing algorithm for random numbers

        if _random == 1 {
            //you fail
            // add card to owner, delete card from you
            let owner_constellation = storage.myconstellation.get(market.unwrap().owner).try_read();
            require(
                owner_constellation.is_some(),
                ConstellationError::NotAvailable,
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

            return false;

        }else {
            //you win
            // add card to you, init card from market
            let mut _market = market.unwrap();

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

            let newmarket = Market{owner: Identity::Address(Address::zero()), ownergene: 0, constella: 0};
            storage.markets.insert(_listid, newmarket);

            return true;
        }


    }

    #[storage(read, write)]
    fn lucky_turntable(){
        let identity = msg_sender().unwrap();
        let monster = storage.mymonster.get(identity).try_read();
        require(
            monster.is_some(),
            MonsterError::NotAvailable,
        );

        require(
            timestamp() > monster.unwrap().turntabletime + 3600*24*1,
            TimeError::NotEnoughTime,
        );

        // Omitting the processing algorithm for random numbers
        let _random = 3;
        // Omitting the processing algorithm for random numbers

        let mut _monster = monster.unwrap();
        _monster.turntabletime = timestamp();
        if _random == 1 {
            //add apple
            let fruit = storage.myfruit.get(identity).try_read();
            require(
                fruit.is_some(),
                FruitError::NotAvailable,
            );
            let mut _fruit = fruit.unwrap();
            _fruit.apple = _fruit.apple + 1;
        }else if _random == 2 {
            //add banana
            let fruit = storage.myfruit.get(identity).try_read();
            require(
                fruit.is_some(),
                FruitError::NotAvailable,
            );
            let mut _fruit = fruit.unwrap();
            _fruit.banana = _fruit.banana + 1;
        }else if _random == 3 {
            //add accelerator_card 8
            let accelerator = storage.myaccelerator.get(identity).try_read();
            require(
                accelerator.is_some(),
                AcceleratorError::NotAvailable,
            );
            let mut _accelerator = accelerator.unwrap();
            _accelerator.eight_add = _accelerator.eight_add + 1;
        }else if _random == 4 {
            //add accelerator_card 16
            let accelerator = storage.myaccelerator.get(identity).try_read();
            require(
                accelerator.is_some(),
                AcceleratorError::NotAvailable,
            );
            let mut _accelerator = accelerator.unwrap();
            _accelerator.sixteen_add = _accelerator.sixteen_add + 1;
        }else if _random == 5 {
            //add accelerator_card 24
            let accelerator = storage.myaccelerator.get(identity).try_read();
            require(
                accelerator.is_some(),
                AcceleratorError::NotAvailable,
            );
            let mut _accelerator = accelerator.unwrap();
            _accelerator.twentyfour_add = _accelerator.twentyfour_add + 1;
        }else{
            //add universal card
            let constellation = storage.myconstellation.get(identity).try_read();
            require(
                constellation.is_some(),
                ConstellationError::NotAvailable,
            );
            let mut _constellation = constellation.unwrap();
            _constellation.universal = _constellation.universal + 1;
        }

    }

    #[storage(read, write)]
    fn use_universal_card(_styles: u8){
        let identity = msg_sender().unwrap();
        let constellation = storage.myconstellation.get(identity).try_read();
        require(
            constellation.is_some(),
            ConstellationError::NotAvailable,
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

    }

    #[storage(read, write)]
    fn buy_coin(){

    }
}
