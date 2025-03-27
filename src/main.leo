import token_registry.aleo;

program dark_optimistic_oracle.aleo {
    // The following part is built on the pattern of secret voting,
    // however it is modified to be suitable for UMA-like assertions,
    // which have deadlines for dispute and dispute resolution.

    const DOOR_TOKEN_ID: field = 17235612283251326583536974293363256992451820371731919189503231730609724436387field;

    const ZERO_ADDRESS: address = aleo1ezamst4pjgj9zfxqq0fwfj8a4cjuqndmasgata3hggzqygggnyfq6kmyd4; // Fix this!!!

    const VOTER_REWARD_PER1000: u128 = 10u128; // 1% of the voter fee; minted privately
    const ASSERTER_PROTOCOL_FEE_PER1000: u128 = 100u128; // 10% of the asserter deposit

    mapping fees_collected: u8 => u128; // Total fees collected stored in the 0-th index

    mapping fee_collector: u8 => address; // owner (fee collector) of the contract stored in the 0-th index

    // Assertion details - all public
    struct Assertion {
        id: field,
        title: field,
        content_hash: field,
        cost: u128, // assuming asserter and disputer deposit are the same
        voter_fee: u128,
        dispute_deadline_block_height: u32,
        voting_deadline_block_height: u32,
    }

    // Save all assertions' info publicly.
    mapping assertions: field => Assertion; // assertionId => Assertion

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

    mapping asserters: field => address; // assertionId => asserter

    mapping disputers: field => address; // assertionId => disputer

    mapping confirm_votes: field => u64; // assertionId => confirming votes

    mapping dispute_votes: field => u64; // assertionId => disputing votes

    transition balance_key(private token_id: field, private account: address) -> private field {
        let owner: TokenOwner = TokenOwner {
            account: account,
            token_id: token_id
        };
        return BHP256::hash_to_field(owner);
    }

    async transition initialize() -> Future {
        let name: u128 = 355052645276405935372531202689035365u128; // "Dark Opt Oracle" ascii encoded
        let symbol: u128 = 1146048338u128; // "DOOR" ascii encoded
        let decimals: u8 = 6u8;
        let max_supply: u128 = 10_000_000_000_000_000u128;
        let external_authorization_required: bool = false;
        let external_authorization_party: address = self.address;

        let f: Future = token_registry.aleo/register_token(
        DOOR_TOKEN_ID,
        name,
        symbol,
        decimals,
        max_supply,
        external_authorization_required,
        external_authorization_party
        );

        return finalize_initialize(f);
        // To do: Distribute supply to treasury.
    }
    async function finalize_initialize(f: Future) {
        f.await();
    }


    // Propose a new proposal to vote on.
    // Anyone can make an assertion.
    async transition create_assertion(public assertion: Assertion) -> (field, Future) {
        // Burn the cost of the assertion.
        let f: Future = token_registry.aleo/burn_public(DOOR_TOKEN_ID, self.caller, assertion.cost);

        // Generate a new assertion id.
        let id: field = BHP256::hash_to_field(assertion.content_hash);

        return (id, finalize_create_assertion (f, self.caller, id, assertion));
    }
    async function finalize_create_assertion(f: Future, sender: address, id: field, assertion: Assertion) {
        f.await();

        Mapping::set(asserters, id, sender);
        Mapping::set(confirm_votes, id, 0u64); // no confirmations yet
        Mapping::set(dispute_votes, id, 0u64); // no disputes yet

        Mapping::set(fees_collected, 0u8, Mapping::get_or_use(fees_collected, 0u8, 0u128) + assertion.cost * ASSERTER_PROTOCOL_FEE_PER1000 / 1000u128);
    }

    async transition dispute_assertion(public assertion_id: field, private assertion_cost: u128) -> Future {
        // Burn the cost of the assertion.
        let f: Future = token_registry.aleo/burn_public(DOOR_TOKEN_ID, self.caller, assertion_cost);
        return finalize_dispute_assertion(f, self.caller, assertion_id, assertion_cost);
    }
    async function finalize_dispute_assertion(f: Future, sender: address, assertion_id: field, assertion_cost: u128) {
        f.await();

        let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
        assert(assertion.cost == assertion_cost);
        assert(assertion.dispute_deadline_block_height <= block.height);
        assert_eq(Mapping::get_or_use(disputers, assertion_id, ZERO_ADDRESS), ZERO_ADDRESS);

        Mapping::set(disputers, assertion_id, sender);
    }

    // Create a new ticket to vote with.
    async transition new_voting_right(
        private sender: token_registry.aleo/Token,
        private assertion_id: field,
        private voter_fee: u128
    ) -> (VotingRight, token_registry.aleo/Token, Future) {
        let (change, f): (token_registry.aleo/Token, Future) = token_registry.aleo/burn_private(sender, voter_fee);

        return (
            VotingRight {owner: sender.owner, assertion_id},
            change,
            finalize_new_voting_right(f, sender.owner, assertion_id, voter_fee)
        ); 
    }
    async function finalize_new_voting_right(f: Future, sender: address, assertion_id: field, voter_fee: u128) {
        f.await();
        let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
        assert_eq(assertion.voter_fee, voter_fee); // !!! Check if this revert also reverts the spending of the records in the transition!!!
    }

    // Vote privately to agree with a proposal.
    async transition confirm(private v: VotingRight) -> (VotingReceipt, Future) {
        // Finalize this vote
        return (
            VotingReceipt { owner: self.caller, assertion_id: v.assertion_id, outcome: true },
            finalize_confirm(v.assertion_id)
        );
    }
    async function finalize_confirm(assertion_id: field) {
        let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
        assert_neq(Mapping::get_or_use(disputers, assertion_id, ZERO_ADDRESS), ZERO_ADDRESS); // Must be disputed;
        assert(assertion.voting_deadline_block_height <= block.height);
        // Publicly increment the number of agree votes.
        let current: u64 = Mapping::get_or_use(confirm_votes, assertion_id, 0u64);
        Mapping::set(confirm_votes, assertion_id, current + 1u64);
    }

    // Vote privately to disagree with a proposal.
    async transition deny(private v: VotingRight) -> (VotingReceipt, Future) {
        // Finalize this vote.
        return (
            VotingReceipt { owner: self.caller, assertion_id: v.assertion_id, outcome: false },
            finalize_deny(v.assertion_id)
        );
    }
    async function finalize_deny(assertion_id: field) {
        let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
        assert_neq(Mapping::get_or_use(disputers, assertion_id, ZERO_ADDRESS), ZERO_ADDRESS); // Must be disputed;
        assert(assertion.voting_deadline_block_height <= block.height);
        // Publicly increment the number of disagree votes.
        let current: u64 = Mapping::get_or_use(dispute_votes, assertion_id, 0u64);
        Mapping::set(dispute_votes, assertion_id, current + 1u64);
    }

    async transition collect_voting_award(private award_amount: u128, private r: VotingReceipt) -> (token_registry.aleo/Token, Future) {
        // No need: assert(self.caller == r.owner);
        let (award, f) : (token_registry.aleo/Token, Future) = token_registry.aleo/mint_private(DOOR_TOKEN_ID, r.owner, award_amount, false, 0u32);
        return (
            award,
            finalize_collect_voting_award(f, award_amount, r.assertion_id, r.outcome)
        );
    }
    async function finalize_collect_voting_award(f: Future, award_amount: u128, assertion_id: field, outcome: bool) {
        f.await();
        let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
        assert(assertion.voting_deadline_block_height > block.height);
        let y: u64 = Mapping::get_or_use(confirm_votes, assertion_id, 0u64);
        let n: u64 = Mapping::get_or_use(dispute_votes, assertion_id, 0u64);
        assert(outcome ? y > n : y <=n); // Otherwise revert
        assert(award_amount == assertion.voter_fee * VOTER_REWARD_PER1000 / 1000u128);
    }

    async transition refund_voting_right(private refund_amount: u128, private v: VotingRight) -> (token_registry.aleo/Token, Future) {
        // No need: assert(self.caller == r.owner);
        let (refund, f) : (token_registry.aleo/Token, Future) = token_registry.aleo/mint_private(DOOR_TOKEN_ID, v.owner, refund_amount, false, 0u32);
        return (
            refund,
            finalize_refund_voting_right(f, refund_amount, v.assertion_id)
        );
    }
    async function finalize_refund_voting_right(f: Future, refund_amount: u128, assertion_id: field) {
        f.await();
        let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
        assert(assertion.voting_deadline_block_height > block.height);
        assert(refund_amount == assertion.voter_fee);
    }

    async transition collect_assertion_cost(private assertion_cost: u128, public assertion_id: field) -> (Future) {
        let f: Future = token_registry.aleo/mint_public(DOOR_TOKEN_ID, self.caller, assertion_cost * (1000u128 - ASSERTER_PROTOCOL_FEE_PER1000) / 1000u128, 0u32);
        return finalize_collect_assertion_cost(f, assertion_cost, assertion_id);
    }
    async function finalize_collect_assertion_cost(f: Future, assertion_cost: u128, assertion_id: field) {
        f.await();
        let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
        assert_eq(assertion_cost, assertion.cost);
        let asserter: address = Mapping::get(asserters, assertion_id);
        let disputer: address = Mapping::get_or_use(disputers, assertion_id, ZERO_ADDRESS);
        let y: u64 = Mapping::get_or_use(confirm_votes, assertion_id, 0u64);
        let n: u64 = Mapping::get_or_use(dispute_votes, assertion_id, 0u64);
        assert(disputer == ZERO_ADDRESS || y > n);
    }

    async transition collect_dispute_award(private assertion_cost: u128, public assertion_id: field) -> (Future) {
        let f: Future = token_registry.aleo/mint_public(DOOR_TOKEN_ID, self.caller, assertion_cost * (2000u128 - ASSERTER_PROTOCOL_FEE_PER1000) / 1000u128, 0u32);
        return finalize_collect_dispute_award(f, assertion_cost, assertion_id);
    }
    async function finalize_collect_dispute_award(f: Future, assertion_cost: u128, assertion_id: field) {
        f.await();
        let assertion: Assertion = Mapping::get(assertions, assertion_id); // may fail in case assertion does not exist;
        assert_eq(assertion_cost, assertion.cost);
        assert(assertion.voting_deadline_block_height > block.height);
        let asserter: address = Mapping::get(asserters, assertion_id);
        let disputer: address = Mapping::get_or_use(disputers, assertion_id, ZERO_ADDRESS);
        let y: u64 = Mapping::get_or_use(confirm_votes, assertion_id, 0u64);
        let n: u64 = Mapping::get_or_use(dispute_votes, assertion_id, 0u64);
        assert(disputer == ZERO_ADDRESS || y <= n);
    }

    async transition collect_protocol_fees(public fees_amount: u128) -> (Future) {
        let f: Future = token_registry.aleo/mint_public(DOOR_TOKEN_ID, self.caller, fees_amount, 0u32);
        return finalize_collect_protocol_fees(f, fees_amount, self.caller);
    }
    async function finalize_collect_protocol_fees(f: Future, fees_amount: u128, caller: address) {
        f.await();
        let fees: u128 = Mapping::get_or_use(fees_collected, 0u8, 0u128);
        Mapping::set(fees_collected, 0u8, 0u128);

        let o: address = Mapping::get(fee_collector, 0u8); // may fail in case contract is not initialized;
        assert_eq(caller, o);
    }
}