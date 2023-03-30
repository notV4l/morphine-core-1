/// @title: Registry
/// @author: Morphine team
/// @dev: this contract is like our registery where you can find all useful contract address
/// @custom: experimental This is an experimental contract.

use starknet::ContractAddress;

#[abi]
trait IRegistry {
    fn treasury() -> ContractAddress;
    fn drip_factory() -> ContractAddress;
    fn oracle_transit() -> ContractAddress;
    fn drip_hash() -> felt252;
    fn pools_length() -> usize;
    fn is_pool(address: ContractAddress) -> bool;
    fn id_to_pool(id: usize) -> ContractAddress;
    fn drip_managers_length() -> usize;
    fn is_drip_manager(address: ContractAddress) -> bool;
    fn id_to_drip_manager(id: usize) -> ContractAddress;
}

#[contract]
mod Registry {
    use super::ContractAddress;
    use super::IRegistry;
    use oz::access::Ownable;

    use zeroable::Zeroable;

    use starknet::contract_address::ContractAddressZeroable;
    use starknet::contract_address_const;
    use starknet::get_caller_address;

    struct Storage {
        _treasury: ContractAddress,
        _drip_factory: ContractAddress,
        _oracle_transit: ContractAddress,
        _drip_hash: felt252,
        _pools_length: usize,
        _is_pool: LegacyMap::<ContractAddress, bool>,
        _id_to_pool: LegacyMap::<usize, ContractAddress>,
        _drip_managers_length: usize,
        _is_drip_manager: LegacyMap::<ContractAddress, bool>,
        _id_to_drip_manager: LegacyMap::<usize, ContractAddress>,
    }


    // @notice: Constructor call only once when contract is deployed
    // @param: owner_: Owner of the contract
    // @param: treasury_: Address of the treasury contract
    // @param: oracle_transit_: Address of the oracle transit contract
    // @param: drip_hash_ : drip hash 
    #[constructor]
    fn constructor(
        owner_: ContractAddress,
        treasury_: ContractAddress,
        oracle_transit_: ContractAddress,
        drip_hash_: felt252
    ) {
        Ownable::initializer(owner_);
        _treasury::write(treasury_);
        _oracle_transit::write(oracle_transit_);
        _drip_hash::write(drip_hash_);
    }


    impl RegistryImpl of IRegistry {
        fn treasury() -> ContractAddress {
            _treasury::read()
        }
        fn drip_factory() -> ContractAddress {
            _drip_factory::read()
        }

        fn oracle_transit() -> ContractAddress {
            _oracle_transit::read()
        }

        fn drip_hash() -> felt252 {
            _drip_hash::read()
        }

        fn pools_length() -> usize {
            _pools_length::read()
        }

        fn is_pool(address: ContractAddress) -> bool {
            _is_pool::read(address)
        }

        fn id_to_pool(id: usize) -> ContractAddress {
            _id_to_pool::read(id)
        }

        fn drip_managers_length() -> usize {
            _drip_managers_length::read()
        }

        fn is_drip_manager(address: ContractAddress) -> bool {
            _is_drip_manager::read(address)
        }

        fn id_to_drip_manager(id: usize) -> ContractAddress {
            _id_to_drip_manager::read(id)
        }
    }

    //
    // Views
    //

    #[view]
    fn owner() -> ContractAddress {
        Ownable::owner()
    }

    #[view]
    fn treasury() -> ContractAddress {
        IRegistry::treasury()
    }

    #[view]
    fn drip_factory() -> ContractAddress {
        IRegistry::drip_factory()
    }

    #[view]
    fn oracle_transit() -> ContractAddress {
        IRegistry::oracle_transit()
    }

    #[view]
    fn drip_hash() -> felt252 {
        IRegistry::drip_hash()
    }

    #[view]
    fn pools_length() -> usize {
        IRegistry::pools_length()
    }

    #[view]
    fn is_pool(address: ContractAddress) -> bool {
        IRegistry::is_pool(address)
    }

    #[view]
    fn id_to_pool(id: usize) -> ContractAddress {
        IRegistry::id_to_pool(id)
    }

    #[view]
    fn drip_managers_length() -> usize {
        IRegistry::drip_managers_length()
    }

    #[view]
    fn is_drip_manager(address: ContractAddress) -> bool {
        IRegistry::is_drip_manager(address)
    }

    #[view]
    fn id_to_drip_manager(id: usize) -> ContractAddress {
        IRegistry::id_to_drip_manager(id)
    }


    //
    // Externals
    //

    #[external]
    fn set_owner(new_address_: ContractAddress) {// TODO: update wen OZ ready
        Ownable::transfer_ownership(new_address_);
    }

    #[external]
    fn set_treasury(new_address_: ContractAddress) {
        Ownable::assert_only_owner();
        
        assert(!new_address_.is_zero(), 'Treasury: address is zero');
        _treasury::write(new_address_);
    }

    #[external]
    fn set_drip_fatory(new_address_: ContractAddress) {
        Ownable::assert_only_owner();

        assert(!new_address_.is_zero(), 'Drip factory: address is zero');
        _drip_factory::write(new_address_);
    }

    #[external]
    fn set_oracle_transit(new_address_: ContractAddress) {
        Ownable::assert_only_owner();

        assert(!new_address_.is_zero(), 'Oracle transit: address is zero');
        _oracle_transit::write(new_address_);
    }

    #[external]
    fn set_drip_hash(new_hash_: felt252) {
        Ownable::assert_only_owner();

        assert(!new_hash_.is_zero(), 'Drip hash: hash is zero');
        _drip_hash::write(new_hash_);
    }

    #[external]
    fn add_pool(address_: ContractAddress) {
        Ownable::assert_only_owner();

        let exists = is_pool(address_);
        assert(!exists, 'Pool: already exist');
        assert(!address_.is_zero(), 'Pool: address is zero');

        _is_pool::write(address_, true);
        _id_to_pool::write(_pools_length::read(), address_);
        _pools_length::write(_pools_length::read() + 1_usize);
    }

    #[external]
    fn add_drip_manager(address_: ContractAddress) {
        Ownable::assert_only_owner();

        let exists = is_drip_manager(address_);
        assert(!exists, 'Drip manager: already exist');
        assert(!address_.is_zero(), 'Drip manager: address is zero');

        _is_drip_manager::write(address_, true);
        _id_to_drip_manager::write(_drip_managers_length::read(), address_);
        _drip_managers_length::write(_drip_managers_length::read() + 1_usize);
    }
}
