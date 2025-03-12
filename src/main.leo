// The 'dark_optimistic_oracle' program.
program dark_optimistic_oracle.aleo {
    transition main(public a: u32, b: u32) -> u32 {
        let c: u32 = a + b;
        return c;
    }
}
