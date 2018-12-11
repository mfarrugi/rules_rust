#[no_mangle]
pub extern fn my_favorite_number() -> i32 {
    4
}

#[no_mangle]
pub extern fn triple_it(x: i32) -> i32 {
    x * 3
}