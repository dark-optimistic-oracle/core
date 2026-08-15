import dark_optimistic_oracle.aleo;

program test_oracle.aleo {
    @test
    fn majority_accepts_assertion() {
        assert(dark_optimistic_oracle.aleo::vote_accepts_assertion(3u64, 2u64));
    }

    @test
    fn tie_rejects_assertion() {
        assert(!dark_optimistic_oracle.aleo::vote_accepts_assertion(2u64, 2u64));
    }

    @test
    fn denial_majority_rejects() {
        assert(!dark_optimistic_oracle.aleo::vote_accepts_assertion(1u64, 4u64));
    }

    @test
    fn calculates_voter_award() {
        assert_eq(
            dark_optimistic_oracle.aleo::calculate_voter_award(1000u128),
            1010u128
        );
    }

    @test
    fn calculates_undisputed_award() {
        assert_eq(
            dark_optimistic_oracle.aleo::calculate_assertion_award(1000u128, false),
            900u128
        );
    }

    @test
    fn calculates_disputed_award() {
        assert_eq(
            dark_optimistic_oracle.aleo::calculate_assertion_award(1000u128, true),
            1900u128
        );
    }

    @test
    fn post_close_assertion_is_timely() {
        assert(dark_optimistic_oracle.aleo::assertion_is_newer_than(101u32, 100u32));
    }

    @test
    fn at_close_assertion_is_early() {
        assert(!dark_optimistic_oracle.aleo::assertion_is_newer_than(100u32, 100u32));
    }

    @test
    fn development_admin_is_authorized() {
        assert(dark_optimistic_oracle.aleo::caller_is_protocol_admin(
            aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px
        ));
    }

    @test
    fn unrelated_account_is_not_admin() {
        assert(!dark_optimistic_oracle.aleo::caller_is_protocol_admin(
            aleo1qk0xj2xcnx5n6f2d7wqjylf7ryda4gzypfcfh2mhqtynhz67x5xsswvcca
        ));
    }

    @test
    fn right_buy_open_at_cutoff() {
        assert(dark_optimistic_oracle.aleo::vote_right_buy_is_open(100u32, 110u32));
    }

    @test
    fn right_buy_closed_after_cutoff() {
        assert(!dark_optimistic_oracle.aleo::vote_right_buy_is_open(101u32, 110u32));
    }

    @test
    @should_fail
    fn rejects_too_small_voter_stake() {
        dark_optimistic_oracle.aleo::calculate_voter_award(99u128);
    }

    @test
    @should_fail
    fn rejects_unsafe_assertion_cost() {
        dark_optimistic_oracle.aleo::calculate_assertion_award(
            170141183460469231731687303715884106u128,
            true
        );
    }

    @noupgrade
    constructor() {}
}
