module prime_machin::registry {

    // === Imports ===

    use std::string::{Self};

    use sui::display::{Self};
    use sui::object::{Self, ID, UID};
    use sui::package::{Self};
    use sui::table::{Self, Table};
    use sui::transfer::{Self};
    use sui::tx_context::{Self, TxContext};

    use prime_machin::admin::{Self, AdminCap};
    use prime_machin::collection::{Self};

    // === Friends ===

    friend prime_machin::factory;

    struct REGISTRY has drop {}

    /// Stores a Prime Machin number: to ID mapping.
    /// 
    /// This object is used to maintain a stable mapping between a Prime Machin's
    /// number: and its object ID. When the contract is deployed, `is_initialized` is set to false.
    /// Once ADMIN initializes the registry with 3,333 Prime Machin, `is_initialized` will be set to
    /// true. At this point, the registry should be transformed into an immutable object.
    struct Registry has key {
        id: UID,
        pfps: Table<u16, ID>,
        is_initialized: bool,
        is_frozen: bool,
    }

    // === Constants ===

    const EInvalidPfpNumber: u64 = 1;
    const ERegistryNotIntialized: u64 = 2;
    const ERegistryAlreadyFrozen: u64 = 3;
    const ERegistryNotFrozen: u64 = 4;

    // === Init Function ===

    #[allow(unused_variable, lint(share_owned))]
    fun init(
        otw: REGISTRY,
        ctx: &mut TxContext,
    ) {
        let publisher = package::claim(otw, ctx);

        let registry = Registry {
            id: object::new(ctx),
            pfps: table::new(ctx),
            is_initialized: false,
            is_frozen: false,
        };

        let registry_display = display::new<Registry>(&publisher, ctx);
        display::add(&mut registry_display, string::utf8(b"name"), string::utf8(b"Prime Machin Registry"));
        display::add(&mut registry_display, string::utf8(b"description"), string::utf8(b"The official registry of the Prime Machin collection by Studio Mirai."));
        display::add(&mut registry_display, string::utf8(b"image_url"), string::utf8(b"https://prime.nozomi.world/images/registry.webp."));
        display::add(&mut registry_display, string::utf8(b"is_initialized"), string::utf8(b"{is_initialized}"));
        display::add(&mut registry_display, string::utf8(b"is_frozen"), string::utf8(b"{is_frozen}"));

        transfer::transfer(registry, tx_context::sender(ctx));

        transfer::public_transfer(registry_display, @sm_treasury);
        transfer::public_transfer(publisher, @sm_treasury);
    }

    public fun pfp_id_from_number(
        number: u16,
        registry: &Registry,
    ): ID {

        assert!(number >= 1 && number <= collection::size(), EInvalidPfpNumber);
        assert!(registry.is_frozen == true, ERegistryNotFrozen);

        *table::borrow(&registry.pfps, number)
    }

    // === Public-Friend Functions ===

    public(friend) fun add(
        number: u16,
        pfp_id: ID,
        registry: &mut Registry,
    ) {
        table::add(&mut registry.pfps, number, pfp_id);

        if ((table::length(&registry.pfps) as u16) == collection::size()) {
            registry.is_initialized = true;
        };
    }

    public(friend) fun is_frozen(
        registry: &Registry,
    ): bool {
        registry.is_frozen
    }

    public(friend) fun is_initialized(
        registry: &Registry,
    ): bool {
        registry.is_initialized
    }

    // === Admin Functions ===

    #[lint_allow(freeze_wrapped)]
    public fun admin_freeze_registry(
        cap: &AdminCap,
        registry: Registry,
        ctx: &TxContext,
    ) {
        admin::verify_admin_cap(cap, ctx);

        assert!(registry.is_frozen == false, ERegistryAlreadyFrozen);
        assert!(registry.is_initialized == true, ERegistryNotIntialized);
        registry.is_frozen = true;
        transfer::freeze_object(registry);
    }
}