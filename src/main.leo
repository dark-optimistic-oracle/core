program dark_optimistic_oracle.aleo {
    // The following part is built on the pattern of secret voting,
    // however it is modified to be suitable for UMA-like assertions,
    // which have deadlines for dispute and dispute resolution.

    const ZERO_ADDRESS: address = aleo1ezamst4pjgj9zfxqq0fwfj8a4cjuqndmasgata3hggzqygggnyfq6kmyd4; // Fix this!!!

    const VOTER_REWARD_PER1000: u64 = 10u64; // 1% of the voter fee; minted privately
    const ASSERTER_PROTOCOL_FEE_PER1000: u64 = 100u64; // 10% of the asserter deposit

    mapping fees_collected: u8 => u64; // Total fees collected stored in the 0-th index

    mapping fee_collector: u8 => address; // owner (fee collector) of the contract stored in the 0-th index

    // Assertion details - all public
    struct Assertion {
        id: field,
        title: field,
        contentHash: field,
        cost: u64, // assuming asserter and disputer deposit are the same
        voterFee: u64,
        disputeDeadlineBlockHeight: u32,
        votingDeadlineBlockHeight: u32,
    }

    // Save all assertions' info publicly.
    mapping assertions: field => Assertion; // assertionId => Assertion

    // Deposits to vote (private)
    record VotingRight {
        owner: address,
        assertionId: field,
    }

    // For reward distribution
    record VotingReceipt {
        owner: address,
        assertionId: field,
        outcome: bool,
    }

    mapping asserters: field => address; // assertionId => asserter

    mapping disputers: field => address; // assertionId => disputer

    mapping confirm_votes: field => u64; // assertionId => confirming votes

    mapping dispute_votes: field => u64; // assertionId => disputing votes

    async transition initialize() -> (Future) {
        return finalize_initialize(self.caller);
    }
    async function finalize_initialize(o: address) {
        Mapping::set(fee_collector, 0u8, o);
    }

    // Propose a new proposal to vote on.
    async transition createAssertion(public assertion: Assertion) -> (field, Future) {
        // Anyone can make an assertion.
        // burn_public(assertion.cost);

        // Generate a new assertion id.
        let id: field = BHP256::hash_to_field(assertion.contentHash);

        // Finalize the proposal id.
        return (
            id,
            finalize_createAssertion (self.caller, id, assertion)
        );
    }
    async function finalize_createAssertion(sender: address, id: field, assertion: Assertion) {
        // Burn the cost of the assertion. Akin to finalize_burn_public.
        let current_amount: u64 = Mapping::get(account, sender); // may fail in case sender has not funds
        Mapping::set(account, sender, current_amount - assertion.cost);

        Mapping::set(asserters, id, sender);
        Mapping::set(confirm_votes, id, 0u64); // no confirmations yet
        Mapping::set(dispute_votes, id, 0u64); // no disputes yet

        Mapping::set(fees_collected, 0u8, Mapping::get_or_use(fees_collected, 0u8, 0u64) + assertion.cost * ASSERTER_PROTOCOL_FEE_PER1000 / 1000u64);
    }

    async transition disputeAssertion(assertionId: field) -> Future {
        return finalize_disputeAssertion(self.caller, assertionId);
    }
    async function finalize_disputeAssertion(sender: address, assertionId: field) {
        let assertion: Assertion = Mapping::get(assertions, assertionId); // may fail in case assertion does not exist;
        assert(assertion.disputeDeadlineBlockHeight <= block.height);
        assert_eq(Mapping::get_or_use(disputers, assertionId, ZERO_ADDRESS), ZERO_ADDRESS);

        // Burn the cost of the assertion. Akin to finalize_burn_public.
        let current_amount: u64 = Mapping::get(account, sender); // may fail in case sender has not funds
        Mapping::set(account, sender, current_amount - assertion.cost);

        Mapping::set(disputers, assertionId, sender);
    }

    // Create a new ticket to vote with.
    async transition new_voting_right(
        sender: token,
        assertionId: field,
        voter_fee: u64
    ) -> (VotingRight, token, Future) {
        let difference: u64 = sender.amount - voter_fee;

        return (
            VotingRight {owner: sender.owner, assertionId},
            token {owner: sender.owner, amount: difference},
            finalize_new_voting_right(sender.owner, assertionId, voter_fee)
        ); 
    }
    async function finalize_new_voting_right(sender: address, assertionId: field, voter_fee: u64) {
        let assertion: Assertion = Mapping::get(assertions, assertionId); // may fail in case assertion does not exist;
        assert_eq(assertion.voterFee, voter_fee); // !!! Check if this revert also reverts the spending of the records in the transition!!!
    }

    // Vote privately to agree with a proposal.
    async transition confirm(v: VotingRight) -> (VotingReceipt, Future) {
        // Finalize this vote
        return (
            VotingReceipt { owner: self.caller, assertionId: v.assertionId, outcome: true },
            finalize_confirm(v.assertionId)
        );
    }
    async function finalize_confirm(assertionId: field) {
        let assertion: Assertion = Mapping::get(assertions, assertionId); // may fail in case assertion does not exist;
        assert_neq(Mapping::get_or_use(disputers, assertionId, ZERO_ADDRESS), ZERO_ADDRESS); // Must be disputed;
        assert(assertion.votingDeadlineBlockHeight <= block.height);
        // Publicly increment the number of agree votes.
        let current: u64 = Mapping::get_or_use(confirm_votes, assertionId, 0u64);
        Mapping::set(confirm_votes, assertionId, current + 1u64);
    }

    // Vote privately to disagree with a proposal.
    async transition deny(v: VotingRight) -> (VotingReceipt, Future) {
        // Finalize this vote.
        return (
            VotingReceipt { owner: self.caller, assertionId: v.assertionId, outcome: false },
            finalize_deny(v.assertionId)
        );
    }
    async function finalize_deny(assertionId: field) {
        let assertion: Assertion = Mapping::get(assertions, assertionId); // may fail in case assertion does not exist;
        assert_neq(Mapping::get_or_use(disputers, assertionId, ZERO_ADDRESS), ZERO_ADDRESS); // Must be disputed;
        assert(assertion.votingDeadlineBlockHeight <= block.height);
        // Publicly increment the number of disagree votes.
        let current: u64 = Mapping::get_or_use(dispute_votes, assertionId, 0u64);
        Mapping::set(dispute_votes, assertionId, current + 1u64);
    }

    async transition collectVotingAward(award: u64, r: VotingReceipt) -> (token, Future) {
        // No need: assert(self.caller == r.owner);
        return (
            token {owner: self.caller, amount: award},
            finalize_collectVotingAward(award, r.assertionId, r.outcome)
        );
    }
    async function finalize_collectVotingAward(award: u64, assertionId: field, outcome: bool) {
        let assertion: Assertion = Mapping::get(assertions, assertionId); // may fail in case assertion does not exist;
        assert(assertion.votingDeadlineBlockHeight > block.height);
        let y: u64 = Mapping::get_or_use(confirm_votes, assertionId, 0u64);
        let n: u64 = Mapping::get_or_use(dispute_votes, assertionId, 0u64);
        assert(outcome ? y > n : y <=n); // Otherwise revert
        assert(award == assertion.voterFee * VOTER_REWARD_PER1000 / 1000u64);
    }

    async transition refundVotingRight(refund: u64, v: VotingRight) -> (token, Future) {
        // No need: assert(self.caller == r.owner);
        return (
            token {owner: self.caller, amount: refund},
            finalize_refundVotingRight(refund, v.assertionId)
        );
    }
    async function finalize_refundVotingRight(refund: u64, assertionId: field) {
        let assertion: Assertion = Mapping::get(assertions, assertionId); // may fail in case assertion does not exist;
        assert(assertion.votingDeadlineBlockHeight > block.height);
        assert(refund == assertion.voterFee);
    }

    async transition collectAssertionCost(assertionId: field) -> (Future) {
        return (finalize_collectAssertionCost(assertionId));
    }
    async function finalize_collectAssertionCost(assertionId: field) {
        let assertion: Assertion = Mapping::get(assertions, assertionId); // may fail in case assertion does not exist;
        assert(assertion.votingDeadlineBlockHeight > block.height);
        let asserter: address = Mapping::get(asserters, assertionId);
        let disputer: address = Mapping::get_or_use(disputers, assertionId, ZERO_ADDRESS);
        let y: u64 = Mapping::get_or_use(confirm_votes, assertionId, 0u64);
        let n: u64 = Mapping::get_or_use(dispute_votes, assertionId, 0u64);
        assert(disputer == ZERO_ADDRESS || y > n);

        let current_amount: u64 = Mapping::get_or_use(account, asserter, 0u64);
        Mapping::set(account, asserter, assertion.cost * (1000u64 - ASSERTER_PROTOCOL_FEE_PER1000) / 1000u64);
    }

    async transition collectDisputeAward(assertionId: field) -> (Future) {
        return (finalize_collectDisputeAward(assertionId));
    }
    async function finalize_collectDisputeAward(assertionId: field) {
        let assertion: Assertion = Mapping::get(assertions, assertionId); // may fail in case assertion does not exist;
        assert(assertion.votingDeadlineBlockHeight > block.height);
        let asserter: address = Mapping::get(asserters, assertionId);
        let disputer: address = Mapping::get_or_use(disputers, assertionId, ZERO_ADDRESS);
        let y: u64 = Mapping::get_or_use(confirm_votes, assertionId, 0u64);
        let n: u64 = Mapping::get_or_use(dispute_votes, assertionId, 0u64);
        assert(disputer == ZERO_ADDRESS || y <= n);

        let current_amount: u64 = Mapping::get_or_use(account, disputer, 0u64);
        Mapping::set(account, disputer, assertion.cost * (2000u64 - ASSERTER_PROTOCOL_FEE_PER1000) / 1000u64); // Deposit + Dispute award - Asserter protocol fee
    }

    async transition collectProtocolFees() -> (Future) {
        return (finalize_collectProtocolFees());
    }
    async function finalize_collectProtocolFees() {
        let fees: u64 = Mapping::get_or_use(fees_collected, 0u8, 0u64);
        Mapping::set(fees_collected, 0u8, 0u64);

        let o: address = Mapping::get(fee_collector, 0u8); // may fail in case contract is not initialized;

        // Akin to public minting.
        let current_amount: u64 = Mapping::get_or_use(account, o, 0u64);
        Mapping::set(account, o, current_amount + fees);
    }

// Token
//program token.aleo {
    // On-chain storage of an `account` map, with `address` as the key,
    // and `u64` as the value.
    mapping account: address => u64;

    record token {
        // The token owner.
        owner: address,
        // The token amount.
        amount: u64,
    }

    /* Mint */

    // The function `mint_public` issues the specified token amount for the token receiver publicly on the network.
    async transition mint_public(public receiver: address, public amount: u64) -> Future {
        // Mint the tokens publicly by invoking the computation on-chain.
        return finalize_mint_public(receiver, amount);
    }

    async function finalize_mint_public(public receiver: address, public amount: u64) {
        // Increments `account[receiver]` by `amount`.
        // If `account[receiver]` does not exist, it will be created.
        // If `account[receiver] + amount` overflows, `mint_public` is reverted.
        let current_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, current_amount + amount);
    }

    // The function `mint_private` initializes a new record with the specified amount of tokens for the receiver.
    transition mint_private(receiver: address, amount: u64) -> token {
        return token {
            owner: receiver,
            amount: amount,
        };
    }

    /* Burn */

    // !!! Make sure this cannot be called by just anyone!!!
    // The function `burn_public` destroys the specified token amount from the token sender publicly on the network.
    async transition burn_public(public sender: address, public amount: u64) -> Future {
        // Burn the tokens publicly by invoking the computation on-chain.
        return finalize_burn_public(sender, amount);
    }
    async function finalize_burn_public(public sender: address, public amount: u64) {
        // Decrements `account[sender]` by `amount`.
        // If `account[sender]` does not exist, it will be created.
        // If `account[sender] - amount` underflows, `burn_public` is reverted.
        let current_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
        Mapping::set(account, sender, current_amount - amount);
    }

    // The function `burn_private` destroys the specified token amount from the token record.
    transition burn_private(sender: token, amount: u64) -> token {
        // Checks the given token record has sufficient balance.
        // This `sub` operation is safe, and the proof will fail if an overflow occurs.
        // `difference` holds the change amount to be returned to sender.
        let difference: u64 = sender.amount - amount;

        // Produce a token record with the change amount for the sender.
        return token {
            owner: sender.owner,
            amount: difference,
        };
    }

    /* Transfer */
    async transition transfer_public(public receiver: address, public amount: u64) -> Future {
        // Transfer the tokens publicly, by invoking the computation on-chain.
        return finalize_transfer_public(self.caller, receiver, amount);
    }

    async function finalize_transfer_public(public sender: address, public receiver: address, public amount: u64) {
        // Decrements `account[sender]` by `amount`.
        // If `account[sender]` does not exist, it will be created.
        // If `account[sender] - amount` underflows, `transfer_public` is reverted.
        let sender_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
        Mapping::set(account, sender, sender_amount - amount);
        // Increments `account[receiver]` by `amount`.
        // If `account[receiver]` does not exist, it will be created.
        // If `account[receiver] + amount` overflows, `transfer_public` is reverted.
        let receiver_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, receiver_amount + amount);
    }

    // The function `transfer_private` sends the specified token amount to the token receiver from the specified token record.
    transition transfer_private(sender: token, receiver: address, amount: u64) -> (token, token) {
        // Checks the given token record has sufficient balance.
        // This `sub` operation is safe, and the proof will fail if an overflow occurs.
        // `difference` holds the change amount to be returned to sender.
        let difference: u64 = sender.amount - amount;

        // Produce a token record with the change amount for the sender.
        let remaining: token = token {
            owner: sender.owner,
            amount: difference,
        };

        // Produce a token record for the specified receiver.
        let transferred: token = token {
            owner: receiver,
            amount: amount,
        };

        // Output the sender's change record and the receiver's record.
        return (remaining, transferred);
    }

    // The function `transfer_private_to_public` turns a specified token amount from a token record into public tokens for the specified receiver.
    // This function preserves privacy for the sender's record, however it publicly reveals the token receiver and the token amount.
    async transition transfer_private_to_public(sender: token, public receiver: address, public amount: u64) -> (token, Future) {
        // Checks the given token record has a sufficient token amount.
        // This `sub` operation is safe, and the proof will fail if an underflow occurs.
        // `difference` holds the change amount for the caller.
        let difference: u64 = sender.amount - amount;

        // Produces a token record with the change amount for the caller.
        let remaining: token = token {
            owner: sender.owner,
            amount: difference,
        };

        // Output the sender's change record.
        // Increment the token amount publicly for the token receiver.
        return (remaining, finalize_transfer_priv_to_pub(receiver, amount));
    }

    async function finalize_transfer_priv_to_pub(public receiver: address, public amount: u64) {
        // Increments `account[receiver]` by `amount`.
        // If `account[receiver]` does not exist, it will be created.
        // If `account[receiver] + amount` overflows, `transfer_private_to_public` is reverted.
        let current_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, current_amount + amount);
    }

    // The function `transfer_public_to_private` turns a specified token amount from `account` into a token record for the specified receiver.
    // This function preserves privacy for the receiver's record, however it publicly reveals the caller and the specified token amount.
    async transition transfer_public_to_private(public receiver: address, public amount: u64) -> (token, Future) {
        // Produces a token record for the token receiver.
        let transferred: token = token {
            owner: receiver,
            amount: amount,
        };

        // Output the receiver's record.
        // Decrement the token amount of the caller publicly.
        return (transferred, finalize_transfer_pub_to_priv(self.caller, amount));
    }

    async function finalize_transfer_pub_to_priv(public sender: address, public amount: u64) {
        // Decrements `account[sender]` by `amount`.
        // If `account[sender]` does not exist, it will be created.
        // If `account[sender] - amount` underflows, `transfer_public_to_private` is reverted.
        let current_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
        Mapping::set(account, sender, current_amount - amount);
    }
}