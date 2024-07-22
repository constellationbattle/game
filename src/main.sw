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
    fn using_accelerator_card();

    #[storage(read, write)]
    fn claim_constellation();

     #[storage(read, write)]
    fn combine_constellation();

    #[storage(read, write)]
    fn regenerate_gene();

    #[storage(read, write)]
    fn list_constellation();

    #[storage(read, write)]
    fn battle();

    #[storage(read, write)]
    fn lucky_turntable();

    #[storage(read, write)]
    fn buy_coin();
}

use std::{
    auth::msg_sender,
    block::timestamp,
    call_frames::msg_asset_id,
    constants::ZERO_B256,
    context::msg_amount,
    hash::{
        Hash,
        sha256,
    },
    storage::{
        storage_bytes::*,
        storage_string::*,
        storage_vec::*,
    },
    asset::*,
    string::String,
};
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

struct Monster {
    gene: u64,
    starttime: u64,
    genetime: u64,
    cardtime: u64,
    expiry: u64,
    bonus: u8,
}

struct Fruit{
    apple: u16,
    banana: u16,
    ananas: u16,
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
}

storage {
    base_life: u64 = 3600*24*1,
    apple_price: u64 = 100000,
    banana_price: u64 = 200000,
    ananas_price: u64 = 300000,
    mymonster: StorageMap<Identity, Monster> = StorageMap {},
    myfruit: StorageMap<Identity, Fruit> = StorageMap {},
    myconstellation: StorageMap<Identity, Constellation> = StorageMap {},
}

impl Game for Contract {
    #[storage(read, write)]
    fn mint_monster(){
        let identity = msg_sender().unwrap();
        let record = storage.mymonster.get(identity).try_read();
        require(record.is_none(),
            MintError::AlreadyMinted,
        );

        //generate gene todo

        // Store monster
        let monster = Monster{gene: timestamp(), starttime: timestamp(), genetime:timestamp(), cardtime: timestamp(), expiry: timestamp()+ 3600*24*3, bonus: 5};
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
        //update todo
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
        //update todo

    }

    #[storage(read, write)]
    fn using_accelerator_card(){

    }

    #[storage(read, write)]
    fn claim_constellation(){

    }

    #[storage(read, write)]
    fn combine_constellation(){

    }

    #[storage(read, write)]
    fn regenerate_gene(){

    }

    #[storage(read, write)]
    fn list_constellation(){

    }

    #[storage(read, write)]
    fn battle(){

    }

    #[storage(read, write)]
    fn lucky_turntable(){

    }

    #[storage(read, write)]
    fn buy_coin(){

    }
}
