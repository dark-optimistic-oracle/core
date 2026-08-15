import token_registry.aleo;

// Canonical in-field representation of the DOOR token ID.
const DOOR_TOKEN_ID: field = 346688784394585735039324415800163929700021701423791533632764818774905958305field;
const ZERO_ADDRESS: address = aleo1ezamst4pjgj9zfxqq0fwfj8a4cjuqndmasgata3hggzqygggnyfq6kmyd4;
const VOTER_REWARD_PER1000: u128 = 10u128; // 1% of the voter fee; minted privately
const ASSERTER_PROTOCOL_FEE_PER1000: u128 = 100u128; // 10% of the asserter deposit
const MIN_ASSERTION_COST: u128 = 10u128; // Keeps the protocol-fee calculation non-zero.
const MIN_VOTER_STAKE: u128 = 100u128; // Keeps the voter-reward calculation non-zero.
const MAX_BONDED_AMOUNT: u128 = 170141183460469231731687303715884105u128; // floor(u128::MAX / 2000)
const MIN_DISPUTE_WINDOW_BLOCKS: u32 = 10u32;
const MIN_VOTING_WINDOW_BLOCKS: u32 = 10u32;
// Development admin. Public deployment scripts replace this together with the
// constructor administrator so initialization and upgrades share one authority.
const PROTOCOL_ADMIN: address = aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px;

// Assertion details - all public
struct Assertion {
    id: field,
    title: field,
    content_hash: field,
    cost: u128, // assuming asserter and disputer deposit are the same
    voter_stake: u128,
    dispute_deadline_block_height: u32,
    voting_deadline_block_height: u32,
}

fn vote_accepts_assertion_logic(confirm_count: u64, deny_count: u64) -> bool {
    return confirm_count > deny_count;
}

fn calculate_voter_award_logic(voter_stake: u128) -> u128 {
    assert(voter_stake >= MIN_VOTER_STAKE);
    assert(voter_stake <= MAX_BONDED_AMOUNT);
    return voter_stake * (1000u128 + VOTER_REWARD_PER1000) / 1000u128;
}

fn calculate_assertion_award_logic(assertion_cost: u128, disputed: bool) -> u128 {
    assert(assertion_cost >= MIN_ASSERTION_COST);
    assert(assertion_cost <= MAX_BONDED_AMOUNT);
    return disputed
        ? assertion_cost * (2000u128 - ASSERTER_PROTOCOL_FEE_PER1000) / 1000u128
        : assertion_cost * (1000u128 - ASSERTER_PROTOCOL_FEE_PER1000) / 1000u128;
}

fn assertion_is_newer_than_logic(creation_height: u32, minimum_creation_height: u32) -> bool {
    return creation_height > minimum_creation_height;
}

fn caller_is_protocol_admin_logic(caller: address) -> bool {
    return caller == PROTOCOL_ADMIN;
}

fn vote_right_buy_is_open_logic(current_height: u32, voting_deadline: u32) -> bool {
    return current_height + MIN_VOTING_WINDOW_BLOCKS <= voting_deadline;
}

program dark_optimistic_oracle.aleo {
    // Development admin. Public deployment scripts must replace this address.

    // Leo 4 upgrade policy: only this admin can deploy upgrades.
    @admin(address="aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px")
    constructor() {}

    mapping fees_collected: u8 => u128; // Total fees collected stored in the 0-th index
    mapping fee_collector: u8 => address; // owner (fee collector) of the contract stored in the 0-th index
    mapping assertions: field => Assertion; // assertionId => Assertion
    mapping assertion_created_at: field => u32; // assertionId => creation height
    mapping asserters: field => address; // assertionId => asserter
    mapping disputers: field => address; // assertionId => disputer
    mapping confirm_votes: field => u64; // assertionId => confirming votes
    mapping deny_votes: field => u64; // assertionId => disputing votes
    mapping asserter_awards_claimed: field => bool;
    mapping disputer_awards_claimed: field => bool;

    // Deposits to vote (private)
    record VotingRight {
        owner: address,
        assertion_id: field,
    }

    // For reward distribution
    record VotingReceipt {
        owner: address,
        assertion_id: field,
        outcome: bool,
    }

    fn self_address() -> address {
        return self.address;
    }

    fn get_token_id() -> field {
        return DOOR_TOKEN_ID;
    }

    // Pure helpers are reused by finalize logic and exercised by Leo unit tests.
    fn vote_accepts_assertion(public confirm_count: u64, public deny_count: u64) -> bool {
        return vote_accepts_assertion_logic(confirm_count, deny_count);
    }

    fn calculate_voter_award(public voter_stake: u128) -> u128 {
        return calculate_voter_award_logic(voter_stake);
    }

    fn calculate_assertion_award(public assertion_cost: u128, public disputed: bool) -> u128 {
        return calculate_assertion_award_logic(assertion_cost, disputed);
    }

    fn assertion_is_newer_than(public creation_height: u32, public minimum_creation_height: u32) -> bool {
        return assertion_is_newer_than_logic(creation_height, minimum_creation_height);
    }

    fn caller_is_protocol_admin(public caller: address) -> bool {
        return caller_is_protocol_admin_logic(caller);
    }

    fn vote_right_buy_is_open(public current_height: u32, public voting_deadline: u32) -> bool {
        return vote_right_buy_is_open_logic(current_height, voting_deadline);
    }

    fn balance_key(public token_id: field, public account: address) -> public field {
        let owner: token_registry.aleo::TokenOwner = token_registry.aleo::TokenOwner {
            token_id: token_id,
            account: account
        };
        return BHP256::hash_to_field(owner);
    }

    fn initialize() -> Final {
        let initializer: address = self.signer;
        assert(caller_is_protocol_admin_logic(initializer));
        // Preserve the original finalize input while requiring a direct call by
        // the same administrator. Aleo upgrades require finalize interfaces to
        // remain compatible with the deployed edition.
        let caller: address = self.caller;
        assert(caller_is_protocol_admin_logic(caller));
        let name: u128 = 355052645276405935372531202689035365u128; // "Dark Opt Oracle" ascii encoded
        let symbol: u128 = 1146048338u128; // "DOOR" ascii encoded
        let decimals: u8 = 6u8;
        let max_supply: u128 = 10_000_000_000_000_000u128;
        let external_authorization_required: bool = false;
        let external_authorization_party: address = self.address;

        let f1: Final = token_registry.aleo::register_token(
            DOOR_TOKEN_ID,
            name,
            symbol,
            decimals,
            max_supply,
            external_authorization_required,
            external_authorization_party
        );

        // Distribute supply intended for treasury.
        let supply: u128 = max_supply / 10u128; // 10% of the supply is minted to the treasury. The rest is reserved for potential inflation.
        let f2: Final = token_registry.aleo::mint_public(DOOR_TOKEN_ID, caller, supply, 0u32);
        // The remaining registered supply is reserved for protocol-enforced rewards.

        return final {
            Mapping::set(fee_collector, 0u8, caller);
            f1.run();
            f2.run();
        };
    }

    // Propose a new proposal to vote on.
    // Anyone can make an assertion.
    fn create_assertion(public assertion: Assertion) -> Final {
        // Burn the cost of the assertion.
        let f: Final = token_registry.aleo::burn_public(DOOR_TOKEN_ID, self.caller, assertion.cost);
        let asserter: address = self.caller;

        return final {
            assert_eq(Mapping::get_or_use(asserters, assertion.id, ZERO_ADDRESS), ZERO_ADDRESS); // assertion does not exist yet
            assert(assertion.cost >= MIN_ASSERTION_COST);
            assert(assertion.cost <= MAX_BONDED_AMOUNT);
            assert(assertion.voter_stake >= MIN_VOTER_STAKE);
            assert(assertion.voter_stake <= MAX_BONDED_AMOUNT);
            assert(assertion.dispute_deadline_block_height >= block.height + MIN_DISPUTE_WINDOW_BLOCKS);
            assert(assertion.voting_deadline_block_height >= assertion.dispute_deadline_block_height + MIN_VOTING_WINDOW_BLOCKS);
            Mapping::set(asserters, assertion.id, asserter);
            Mapping::set(assertion_created_at, assertion.id, block.height);
            Mapping::set(confirm_votes, assertion.id, 0u64); // no confirmations yet
            Mapping::set(deny_votes, assertion.id, 0u64); // no disputes yet

            Mapping::set(assertions, assertion.id, assertion); // store the assertion
            Mapping::set(fees_collected, 0u8, Mapping::get_or_use(fees_collected, 0u8, 0u128) + assertion.cost * ASSERTER_PROTOCOL_FEE_PER1000 / 1000u128);
            f.run();
        };
    }

    fn dispute_assertion(public assertion_id: field, public assertion_cost: u128) -> Final {
        // Burn the cost of the assertion.
        let f: Final = token_registry.aleo::burn_public(DOOR_TOKEN_ID, self.caller, assertion_cost);
        let disputer: address = self.caller;
        return final {
            let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
            assert(assertion.cost == assertion_cost);
            assert(block.height <= assertion.dispute_deadline_block_height);
            assert_eq(Mapping::get_or_use(disputers, assertion_id, ZERO_ADDRESS), ZERO_ADDRESS);
            Mapping::set(disputers, assertion_id, disputer);
            f.run();
            // No fee is collected by the protocol for disputes.
        };
    }

    // Create a new ticket to vote with.
    fn new_voting_right(
        payment: token_registry.aleo::Token,
        public assertion_id: field,
        public voter_stake: u128
    ) -> (VotingRight, token_registry.aleo::Token, Final) {
        let (change, f): (token_registry.aleo::Token, Final) = token_registry.aleo::burn_private(payment, voter_stake);

        return (
            VotingRight {owner: payment.owner, assertion_id},
            change,
            final {
                let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
                assert_eq(assertion.voter_stake, voter_stake);
                assert_neq(Mapping::get_or_use(disputers, assertion_id, ZERO_ADDRESS), ZERO_ADDRESS);
                // Keep the last minimum voting window vote-only. This prevents
                // buying new influence after observing the final public tally.
                assert(vote_right_buy_is_open_logic(block.height, assertion.voting_deadline_block_height));
                f.run();
            }
        );
    }

    // Consume a private voting right to agree with a proposal. The record owner
    // is private, but the transition direction and aggregate count are public.
    fn confirm(v: VotingRight) -> (VotingReceipt, Final) {
        // Finalize this vote
        let assertion_id: field = v.assertion_id;
        return (
            VotingReceipt { owner: v.owner, assertion_id, outcome: true },
            final {
                let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
                assert_neq(Mapping::get_or_use(disputers, assertion_id, ZERO_ADDRESS), ZERO_ADDRESS); // must be disputed;
                assert(block.height <= assertion.voting_deadline_block_height);
                // Publicly increment the number of agree votes.
                let current: u64 = Mapping::get_or_use(confirm_votes, assertion_id, 0u64);
                Mapping::set(confirm_votes, assertion_id, current + 1u64);
            }
        );
    }

    // Consume a private voting right to disagree with a proposal. The record
    // owner is private, but the transition direction and aggregate count are public.
    fn deny(v: VotingRight) -> (VotingReceipt, Final) {
        // Finalize this vote.
        let assertion_id: field = v.assertion_id;
        return (
            VotingReceipt { owner: v.owner, assertion_id, outcome: false },
            final {
                let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
                assert_neq(Mapping::get_or_use(disputers, assertion_id, ZERO_ADDRESS), ZERO_ADDRESS); // Must be disputed;
                assert(block.height <= assertion.voting_deadline_block_height);
                // Publicly increment the number of disagree votes.
                let current: u64 = Mapping::get_or_use(deny_votes, assertion_id, 0u64);
                Mapping::set(deny_votes, assertion_id, current + 1u64);
            }
        );
    }

    fn collect_voting_award(public award_amount: u128, r: VotingReceipt) -> (token_registry.aleo::Token, Final) {
        // No need: assert(self.caller == r.owner);
        let owner: address = r.owner;
        let assertion_id: field = r.assertion_id;
        let outcome: bool = r.outcome;
        let (award, f) : (token_registry.aleo::Token, Final) = token_registry.aleo::mint_private(DOOR_TOKEN_ID, owner, award_amount, false, 0u32);
        return (
            award,
            final {
                let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
                assert(block.height > assertion.voting_deadline_block_height);
                let y: u64 = Mapping::get_or_use(confirm_votes, assertion_id, 0u64);
                let n: u64 = Mapping::get_or_use(deny_votes, assertion_id, 0u64);
                assert_eq(outcome, vote_accepts_assertion_logic(y, n));
                assert_eq(award_amount, calculate_voter_award_logic(assertion.voter_stake));
                f.run();
            }
        );
    }

    fn refund_voting_right(public refund_amount: u128, v: VotingRight) -> (token_registry.aleo::Token, Final) {
        // No need: assert(self.caller == r.owner);
        let owner: address = v.owner;
        let assertion_id: field = v.assertion_id;
        let (refund, f) : (token_registry.aleo::Token, Final) = token_registry.aleo::mint_private(DOOR_TOKEN_ID, owner, refund_amount, false, 0u32);
        return (
            refund,
            final {
                let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
                assert(block.height > assertion.voting_deadline_block_height);
                assert(refund_amount == assertion.voter_stake);
                f.run();
            }
        );
    }

    fn collect_assertion_award(public assertion_id: field, public payout_amount: u128) -> Final {
        let f: Final = token_registry.aleo::mint_public(DOOR_TOKEN_ID, self.caller, payout_amount, 0u32);
        let caller: address = self.caller;
        return final {
            let assertion: Assertion = Mapping::get(assertions, assertion_id);
            assert_eq(caller, Mapping::get(asserters, assertion_id));
            assert(!Mapping::get_or_use(asserter_awards_claimed, assertion_id, false));
            let disputer: address = Mapping::get_or_use(disputers, assertion_id, ZERO_ADDRESS);
            let y: u64 = Mapping::get_or_use(confirm_votes, assertion_id, 0u64);
            let n: u64 = Mapping::get_or_use(deny_votes, assertion_id, 0u64);
            if disputer == ZERO_ADDRESS {
                assert(block.height > assertion.dispute_deadline_block_height);
                assert_eq(payout_amount, calculate_assertion_award_logic(assertion.cost, false));
            } else {
                assert(block.height > assertion.voting_deadline_block_height);
                assert(vote_accepts_assertion_logic(y, n));
                assert_eq(payout_amount, calculate_assertion_award_logic(assertion.cost, true));
            }
            Mapping::set(asserter_awards_claimed, assertion_id, true);
            f.run();
        };
    }

    fn collect_dispute_award(public assertion_id: field, public payout_amount: u128) -> Final {
        let f: Final = token_registry.aleo::mint_public(DOOR_TOKEN_ID, self.caller, payout_amount, 0u32);
        let caller: address = self.caller;
        return final {
            let assertion: Assertion = Mapping::get(assertions, assertion_id);
            let disputer: address = Mapping::get(disputers, assertion_id);
            assert_eq(caller, disputer);
            assert(!Mapping::get_or_use(disputer_awards_claimed, assertion_id, false));
            assert(block.height > assertion.voting_deadline_block_height);
            let y: u64 = Mapping::get_or_use(confirm_votes, assertion_id, 0u64);
            let n: u64 = Mapping::get_or_use(deny_votes, assertion_id, 0u64);
            assert(!vote_accepts_assertion_logic(y, n));
            assert_eq(payout_amount, calculate_assertion_award_logic(assertion.cost, true));
            Mapping::set(disputer_awards_claimed, assertion_id, true);
            f.run();
        };
    }

    // Verifies a consumer-supplied outcome against the assertion lifecycle.
    // Undisputed assertions resolve true after the grace period. Disputed
    // assertions resolve from the public aggregate tally after voting closes.
    fn verify_assertion_outcome(
        public assertion_id: field,
        public expected_title: field,
        public expected_content_hash: field,
        public outcome: bool,
        public minimum_creation_height: u32
    ) -> Final {
        return final {
            let assertion: Assertion = Mapping::get(assertions, assertion_id);
            assert_eq(assertion.title, expected_title);
            assert_eq(assertion.content_hash, expected_content_hash);
            let creation_height: u32 = Mapping::get(assertion_created_at, assertion_id);
            assert(assertion_is_newer_than_logic(creation_height, minimum_creation_height));

            let disputer: address = Mapping::get_or_use(disputers, assertion_id, ZERO_ADDRESS);
            if disputer == ZERO_ADDRESS {
                assert(block.height > assertion.dispute_deadline_block_height);
                assert(outcome);
            } else {
                assert(block.height > assertion.voting_deadline_block_height);
                let y: u64 = Mapping::get_or_use(confirm_votes, assertion_id, 0u64);
                let n: u64 = Mapping::get_or_use(deny_votes, assertion_id, 0u64);
                assert_eq(outcome, vote_accepts_assertion_logic(y, n));
            }
        };
    }

    fn collect_protocol_fees(public fees_amount: u128) -> Final {
        let f: Final = token_registry.aleo::mint_public(DOOR_TOKEN_ID, self.caller, fees_amount, 0u32);
        let caller: address = self.caller;
        return final {
            let o: address = Mapping::get(fee_collector, 0u8); // may fail in case contract is not initialized;
            assert_eq(caller, o);

            let fees_coll: u128 = Mapping::get_or_use(fees_collected, 0u8, 0u128);
            assert(fees_amount <= fees_coll);
            Mapping::set(fees_collected, 0u8, fees_coll-fees_amount);
            f.run();
        };
    }
}
