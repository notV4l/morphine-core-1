use zeroable::Zeroable;
use starknet::get_caller_address;
use starknet::get_contract_address;
use starknet::contract_address_const;
use starknet::ContractAddress;
use starknet::ContractAddressZeroable;
use integer::BoundedInt;

#[abi]
    trait IERC20 {
        fn get_name() -> felt252;
        fn get_symbol() -> felt252;
        fn get_decimals() -> u8;
        fn get_total_supply() -> u256;
        fn balance_of(account: ContractAddress) -> u256;
        fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256;
        fn transfer(recipient: ContractAddress, amount: u256);
        fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256);
        fn approve(spender: ContractAddress, amount: u256);
        fn increase_allowance(spender: ContractAddress, added_value: u256);
        fn decrease_allowance(spender: ContractAddress, subtracted_value: u256);
        fn mint(recipient: ContractAddress, amount: u256);
    }

#[contract]
mod ERC4626 {

    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;
    use starknet::ContractAddressZeroable;
    use integer::BoundedInt;
    use super::IERC20Dispatcher;
    use super::IERC20DispatcherTrait;


    impl U256TruncatedDiv of Div::<u256> {
        fn div(a: u256, b: u256) -> u256 {
            assert(a.high == 0_u128 & b.high == 0_u128, 'u256 too large');
            u256 { low: a.low / b.low, high: 0_u128 }
        }
    }

    impl U256Zeroable of Zeroable::<u256> {
        fn zero() -> u256 {
            u256 { low: 0_u128, high: 0_u128 }
        }

        fn is_zero(self: u256) -> bool {
            self == U256Zeroable::zero()
        }

        fn is_non_zero(self: u256) -> bool {
            !self.is_zero()
        }
    }


    struct Storage {
        name: felt252,
        symbol: felt252,
        decimals: u8,
        underlying: ContractAddress,
        total_supply: u256,
        balances: LegacyMap::<ContractAddress, u256>,
        allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>,
    }

    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, value: u256) {}

    #[event]
    fn Approval(owner: ContractAddress, spender: ContractAddress, value: u256) {}

    #[event]
    fn Deposit(caller: ContractAddress, owner: ContractAddress, assets: u256, shars: u256) {}

    #[event]
    fn Withdraw(
        caller: ContractAddress,
        receiver: ContractAddress,
        owner: ContractAddress,
        assets: u256,
        shares: u256
    ) {}


    #[constructor]
    fn constructor(name_: felt252, symbol_: felt252, underlying_: ContractAddress) {
        name::write(name_);
        symbol::write(symbol_);
        let token = IERC20Dispatcher { contract_address: underlying_ };
        decimals::write(token.get_decimals());
        underlying::write(underlying_);
    }

    //
    // ERC 4626
    //

    #[view]
    fn get_asset() -> ContractAddress {
        underlying::read()
    }

    // FUNCTIONS TO IMPLEMENT

    #[view]
    fn total_assets() -> u256 {
        Zeroable::zero()
    }


    // CONVERT FUNCTIONS

    #[view]
    fn convert_to_shares(assets: u256) -> u256 {
        if (total_supply::read().is_zero() == true) {
            assets
        } else {
            Div::div(assets * total_supply::read(), total_assets())
        }
    }

    #[view]
    fn convert_to_assets(shares: u256) -> u256 {
        if (total_supply::read().is_zero() == true) {
            shares
        } else {
            Div::div(shares * total_assets(), total_supply::read())
        }
    }

    // DEPOSIT

    #[view]
    fn max_deposit(receiver: ContractAddress) -> u256 {
        BoundedInt::max()
    }

    #[view]
    fn preview_deposit(assets: u256) -> u256 {
        convert_to_shares(assets)
    }

    #[external]
    fn deposit(assets: u256, receiver: ContractAddress) -> u256 {
        let shares = preview_deposit(assets);
        let token = IERC20Dispatcher { contract_address: underlying::read() };
        let caller = get_caller_address();
        let self = get_contract_address();
        token.transfer_from(caller, self, assets);
        _mint(receiver, shares);
        Deposit(caller, receiver, assets, shares);
        shares
    }

    // MINT

    #[view]
    fn max_mint(receiver: ContractAddress) -> u256 {
        BoundedInt::max()
    }

    #[view]
    fn preview_mint(shares: u256) -> u256 {
        if (total_supply::read().is_zero() == true) {
            shares
        } else {
            div_up(shares * total_assets(), total_supply::read())
        }
    }

    #[external]
    fn mint(shares: u256, receiver: ContractAddress) -> u256 {
        let assets = preview_mint(shares);
        let token = IERC20Dispatcher { contract_address: underlying::read() };
        let caller = get_caller_address();
        let self = get_contract_address();
        token.transfer_from(caller, self, assets);
        _mint(receiver, shares);
        Deposit(caller, receiver, assets, shares);
        shares
    }

    // WITHDDRAW

    #[view]
    fn max_withdraw(owner: ContractAddress) -> u256 {
        let owner_balance = balance_of(owner);
        convert_to_assets(owner_balance)
    }

    #[view]
    fn preview_withdraw(assets: u256) -> u256 {
        if (total_supply::read().is_zero() == true) {
            assets
        } else {
            div_up(assets * total_supply::read(), total_assets())
        }
    }

    #[external]
    fn withdraw(assets: u256, receiver: ContractAddress, owner: ContractAddress) -> u256 {
        let shares = preview_withdraw(assets);
        let caller = get_caller_address();

        if (caller != owner) {
            decrease_allowance_by_amount(owner, caller, shares);
        }

        _burn(owner, shares);
        let token = IERC20Dispatcher { contract_address: underlying::read() };
        token.transfer(receiver, assets);
        Withdraw(caller, receiver, owner, assets, shares);
        shares
    }

    // REDEEM

    #[view]
    fn max_redeem(owner: ContractAddress) -> u256 {
        balance_of(owner)
    }

    #[view]
    fn preview_redeem(shares: u256) -> u256 {
        convert_to_assets(shares)
    }

    #[external]
    fn redeem(shares: u256, receiver: ContractAddress, owner: ContractAddress) -> u256 {
        let assets = preview_redeem(shares);
        let caller = get_caller_address();

        if (caller != owner) {
            decrease_allowance_by_amount(owner, caller, shares);
        }

        _burn(owner, shares);
        let token = IERC20Dispatcher { contract_address: underlying::read() };
        token.transfer(receiver, assets);
        Withdraw(caller, receiver, owner, assets, shares);
        assets
    }

    // HELPER FUNCTIONS

    fn decrease_allowance_by_amount(
        owner: ContractAddress, spender: ContractAddress, amount: u256
    ) {
        if (allowances::read(
            (owner, spender)
        ) == BoundedInt::max()) {} else {
            if (allowances::read(
                (owner, spender)
            ) < amount) { 
                assert(1==2, 'not enough allowance');
            } else {
                allowances::write((owner, spender), allowances::read((owner, spender)) - amount);
            }
        }
    }

    fn div_up(a: u256, b: u256) -> u256 {
        assert(a.high == 0_u128 & b.high == 0_u128, 'u256 too large');
        let q = u256 { low: a.low / b.low, high: 0_u128 };
        let r = u256 { low: a.low % b.low, high: 0_u128 };
        if (r.is_zero() == true) {
            q
        } else {
            q + u256 { low: 1_u128, high: 0_u128 }
        }
    }


    // ERC20 IMPLEMENTATION

    #[view]
    fn get_name() -> felt252 {
        name::read()
    }

    #[view]
    fn get_symbol() -> felt252 {
        symbol::read()
    }

    #[view]
    fn get_decimals() -> u8 {
        decimals::read()
    }

    #[view]
    fn get_total_supply() -> u256 {
        total_supply::read()
    }

    #[view]
    fn balance_of(account: ContractAddress) -> u256 {
        balances::read(account)
    }

    #[view]
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256 {
        allowances::read((owner, spender))
    }

    #[external]
    fn transfer(recipient: ContractAddress, amount: u256) {
        let sender = get_caller_address();
        transfer_helper(sender, recipient, amount);
    }

    #[external]
    fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        spend_allowance(sender, caller, amount);
        transfer_helper(sender, recipient, amount);
    }

    #[external]
    fn _mint(recipient: ContractAddress, amount: u256) {
        total_supply::write(total_supply::read() + amount);
        balances::write(recipient, balances::read(recipient) + amount);
        Transfer(Zeroable::zero(), recipient, amount);
    }

    #[external]
    fn _burn(owner: ContractAddress, amount: u256) {
        total_supply::write(total_supply::read() - amount);
        balances::write(owner, balances::read(owner) - amount);
        Transfer(owner, Zeroable::zero(), amount);
    }

    #[external]
    fn approve(spender: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        approve_helper(caller, spender, amount);
    }

    #[external]
    fn increase_allowance(spender: ContractAddress, added_value: u256) {
        let caller = get_caller_address();
        approve_helper(caller, spender, allowances::read((caller, spender)) + added_value);
    }

    #[external]
    fn decrease_allowance(spender: ContractAddress, subtracted_value: u256) {
        let caller = get_caller_address();
        approve_helper(caller, spender, allowances::read((caller, spender)) - subtracted_value);
    }

    fn transfer_helper(sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        assert(!sender.is_zero(), 'ERC20: transfer from 0');
        assert(!recipient.is_zero(), 'ERC20: transfer to 0');
        balances::write(sender, balances::read(sender) - amount);
        balances::write(recipient, balances::read(recipient) + amount);
        Transfer(sender, recipient, amount);
    }

    fn spend_allowance(owner: ContractAddress, spender: ContractAddress, amount: u256) {
        let current_allowance = allowances::read((owner, spender));
        let ONES_MASK = 0xffffffffffffffffffffffffffffffff_u128;
        let is_unlimited_allowance =
            current_allowance.low == ONES_MASK & current_allowance.high == ONES_MASK;
        if !is_unlimited_allowance {
            approve_helper(owner, spender, current_allowance - amount);
        }
    }

    fn approve_helper(owner: ContractAddress, spender: ContractAddress, amount: u256) {
        assert(!spender.is_zero(), 'ERC20: approve from 0');
        allowances::write((owner, spender), amount);
        Approval(owner, spender, amount);
    }
}
