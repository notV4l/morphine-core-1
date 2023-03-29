use array::ArrayTrait;
use zeroable::Zeroable;


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

impl U256TruncatedDiv of Div::<u256> {
    fn div(a: u256, b: u256) -> u256 {
        assert(a.high == 0_u128 & b.high == 0_u128, 'u256 too large');
        u256 { low: a.low / b.low, high: 0_u128 }
    }
}

fn test_u256_helper() -> u256 {
    u256 { low: 3_u128, high: 0_u128 }
}

#[test]
fn test_array() {
    let number = test_u256_helper();
    assert(number.low == 3_u128, 'not correct');
    assert(number.high == 0_u128, 'not correct');
    assert(number == u256 { low: 3_u128, high: 0_u128 }, 'not');
    assert(number.is_zero() == false, 'ez');
    assert(Zeroable::zero() == u256 { low: 0_u128, high: 0_u128 }, 'okk');
    assert(
        Div::div(number, u256 { low: 3_u128, high: 0_u128 }) == u256 { low: 1_u128, high: 0_u128 },
        'mulll'
    );
}

