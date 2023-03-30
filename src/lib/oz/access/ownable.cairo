
#[contract]
mod Ownable {
    use starknet::ContractAddress;
    use zeroable::Zeroable;

    use starknet::get_caller_address;

    struct Storage {
        _owner: ContractAddress, 
    }

    #[event]
    fn OwnershipTransferd(owner: ContractAddress, new_owner: ContractAddress) {}

    fn initializer(owner: ContractAddress) {
        _owner::write(owner);
    }

    fn owner() -> ContractAddress {
        _owner::read()
    }

    fn assert_only_owner() {
        assert(_owner::read() == get_caller_address(), 'Ownable : caller is not owner');
    }

    fn transfer_ownership(new_owner_: ContractAddress) {
        assert_only_owner();

        let owner = _owner::read();
        _owner::write(new_owner_);

        OwnershipTransferd(owner, new_owner_);
    }

    fn renounce_ownership() {
        transfer_ownership(Zeroable::zero());
    }
}
