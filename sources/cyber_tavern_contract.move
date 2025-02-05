/*
/// Module: cyber_tavern_contract
module cyber_tavern_contract::cyber_tavern_contract;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module cyber_tavern_contract::cyber_tavern_contract {
    use sui::clock::Clock;
    use std::string::{String,utf8};
    use sui::event;
    #[test_only]
    use sui::test_scenario;

    const EInvalidBlob: u64 = 0;
    const EInvalidLen: u64 = 1;

    public struct CyberTavern has key,store {
        id: UID,
        blobs: vector<BlobInfo>
    }
    public struct CharacterCard has key,store {
        id: UID,
        from: address,
        from_time: u64,
        open: bool,
        blobs: vector<BlobInfo>,
    }

    public struct BlobInfo has store, copy, drop {
        blob_id: String,   // blob id on walrus
        blob_obj: address, // object id on sui chain
    }

    public struct CharacterCardEvent has copy, drop {
        from: address,
        card_id: ID,
        action_type: String,
    }
        // init a empty object 
    fun init(ctx: &mut TxContext) {
        let object = CyberTavern {
            id: object::new(ctx),
            blobs:vector::empty<BlobInfo>(),
        };
        transfer::share_object(object);
    }
    // create character card
    public entry fun createCard(tavern: &mut CyberTavern,blob_ids: vector<String>, blob_objs: vector<address>, clock: &Clock,user_address: address, ctx: &mut TxContext) {
        // assert!(!blob_ids.is_empty(), EInvalidBlob);
        // assert!(blob_ids.length() == blob_objs.length(), EInvalidLen);
        assert!(!vector::is_empty(&blob_ids), EInvalidBlob);
        assert!(vector::length(&blob_ids) == vector::length(&blob_objs), EInvalidLen);

        let card_id = object::new(ctx);

        // generate bottle msgs by blob_id and blob_obj
        let blobInfos = createBlobInfos(blob_ids, blob_objs);
        // 创建一个新的副本用于 tavern.blobs
        let new_blobInfos = cloneBlobInfos(&blobInfos);

        vector::append(&mut tavern.blobs, blobInfos);

        // create drift bottle object
        let card = CharacterCard {
            id: card_id,
            from: user_address,
            from_time: clock.timestamp_ms()/1000,
            open: true,
            blobs: new_blobInfos,
        };

        event::emit(CharacterCardEvent {
            from: user_address,
            card_id: card.id.to_inner(),
            action_type: utf8(b"create"),
        });

        transfer::public_transfer(card,user_address)
    }

    // Helper function to create BlobInfo vector
    public fun createBlobInfos(blob_ids: vector<String>, blob_objs: vector<address>): vector<BlobInfo> {
        let mut bottle_msg = vector::empty<BlobInfo>();
        let len = blob_ids.length();
        let mut i = 0;
        while( i < len) {
            bottle_msg.insert(
                BlobInfo {
                    blob_id: blob_ids[i],
                    blob_obj:blob_objs[i],
                   }, i);
            i = i + 1;
        };
        bottle_msg
    }
    // Helper function to clone BlobInfo vector
    public fun cloneBlobInfos(blob_infos: &vector<BlobInfo>): vector<BlobInfo> {
        let mut new_blob_infos = vector::empty<BlobInfo>();
        let len = vector::length(blob_infos);
        let mut i = 0;
        while (i < len) {
            let blob = vector::borrow(blob_infos, i);
            vector::push_back(&mut new_blob_infos, BlobInfo {
                blob_id: blob.blob_id,
                blob_obj: blob.blob_obj,
            });
            i = i + 1;
        };
        new_blob_infos
    }

    #[test]
    fun test_createCyberTavern() {
        use std::debug;
        use sui::clock;
        let alice = @0x1;
        let bob = @0x2;
        let mut scenario = test_scenario::begin(alice);
        {
            init(scenario.ctx());
        };
        scenario.next_tx(bob);
        {
            let mut my_clock = clock::create_for_testing(scenario.ctx());
            my_clock.set_for_testing(1000 * 10);

            let mut cyber_tavern = scenario.take_shared<CyberTavern>();
            let mut blob_ids = vector::empty<String>();
            let mut blob_objs = vector::empty<address>();

            blob_ids.push_back(utf8(b"5z_AD0YwCFUfoko2NfqiDjqavuEpQ2yrtKmGggG-cRM"));
            // blob_ids.push_back(utf8(b"9b7CO3EVPl9r3HXNC7zbnKOgo8Yprs7U4_jOVLX_huE"));

            blob_objs.push_back(@0x965f3cd3233616565ad858b4d102c80546774552111a5f3d2b67d61b20cf0223);
            // blob_objs.push_back(@0x965f3cd3233616565ad858b4d102c80546774552111a5f3d2b67d61b20cf0223);

            createCard(&mut cyber_tavern, blob_ids, blob_objs,&my_clock ,bob,scenario.ctx());
            test_scenario::return_shared(cyber_tavern);
            my_clock.destroy_for_testing();
        };
        scenario.next_tx(bob);
        {
            let card = test_scenario::take_from_address<CharacterCard>(& scenario,bob);
            debug::print(&card);
            test_scenario::return_to_sender(&scenario,card);
        };
        scenario.end();
    }
}