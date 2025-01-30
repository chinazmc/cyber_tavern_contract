/*
/// Module: cyber_tavern_contract
module cyber_tavern_contract::cyber_tavern_contract;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module cyber_tavern_contract::cyber_tavern_contract {
    use sui::clock::Clock;
    use std::string::{String, utf8};
    use sui::event;

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
        assert!(!blob_ids.is_empty(), EInvalidBlob);
        assert!(blob_ids.length() == blob_objs.length(), EInvalidLen);

        let card_id = object::new(ctx);

        // generate bottle msgs by blob_id and blob_obj
        let blobInfos = createBlobInfos(blob_ids, blob_objs);
        vector::append(&mut tavern.blobs, blobInfos);

        // create drift bottle object
        let card = CharacterCard {
            id: card_id,
            from: user_address,
            from_time: clock.timestamp_ms()/1000,
            open: true,
            blobs: blobInfos,
        };

        event::emit(CharacterCardEvent {
            from: user_address,
            card_id: card.id.to_inner(),
            action_type: utf8(b"create"),
        });

        transfer::transfer(card,ctx.sender())
    }
    
    // helper function
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

}