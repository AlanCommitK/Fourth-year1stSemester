"""
blockchain.py - a minimal Proof-of-Work blockchain (Lab 3 and Lab 4, Blockchain part).

Lab 3 (Part II, Lab 1), Tasks 2-3: the Blockchain class, the genesis block,
    recording new blocks and reading the previous block.
Lab 4 (Part II, Lab 2), Task 3: hashing a block with json + SHA-256, the
    proof_of_work() puzzle, mining new blocks and (optional) validating the chain.

Every block is a dict with five keys:
    index          position of the block in the chain (the chain length when it was made)
    timestamp      date and time the block was created or mined
    data           the information recorded in the block
    proof          the proof of work (a nonce) found by the miner
    previous_hash  SHA-256 hash of the block before it ('0' for the genesis block)

The puzzle: find the smallest proof such that the SHA-256 hash of the whole
block (all five keys, encoded with json.dumps) starts with DIFFICULTY zeros.
Because the hash covers the data and previous_hash too, changing anything in a
block breaks its proof, and the attacker has to redo the work for that block and
for every block after it.
"""

import datetime
import hashlib
import json

DEFAULT_DIFFICULTY = 4          # number of leading hex zeros a block hash must have
GENESIS_DATA = "Hello World!"   # data of block 0, as given in the lab sheet
GENESIS_PROOF = 0               # the genesis block is not mined
GENESIS_PREVIOUS_HASH = "0"     # nothing comes before the genesis block


class Blockchain:
    """A list of blocks linked by hashes and secured by Proof of Work."""

    def __init__(self, difficulty=DEFAULT_DIFFICULTY):
        """Create the chain and its genesis block (Task 3.1).

        Args:
            difficulty (int): required number of leading '0' hex digits in a
                mined block's hash. 4 gives about 16**4 = 65 536 tries per block.

        Returns:
            None.
        """
        self.chain = []                       # every block, oldest first
        self.difficulty = difficulty
        self.target_prefix = "0" * difficulty  # e.g. "0000" when difficulty = 4
        self.create_block(data=GENESIS_DATA,
                          proof=GENESIS_PROOF,
                          previous_hash=GENESIS_PREVIOUS_HASH)

    # ------------------------------------------------------------------ Lab 3
    def create_block(self, data, proof, previous_hash, timestamp=None):
        """Build a block from its fields and append it to the chain (Task 3.1).

        Args:
            data: the information to record (any JSON-serialisable value).
            proof (int): the proof of work for this block.
            previous_hash (str): hash of the previous block.
            timestamp (str | None): creation time; the current time if None.

        Returns:
            dict: the block that was appended.
        """
        block = {
            "index": len(self.chain),          # chain length = position of the new block
            "timestamp": timestamp or str(datetime.datetime.now()),
            "data": data,
            "proof": proof,
            "previous_hash": previous_hash,
        }
        self.chain.append(block)
        return block

    def add_block(self, data):
        """Record new information in a block without mining it (Task 3.2).

        This is the Lab 3 version, written before Proof of Work exists: the
        block is linked to the previous one by its hash, but its proof is 0.
        Lab 4 replaces it with mine_block().

        Args:
            data: the information to record.

        Returns:
            dict: the block that was appended.
        """
        previous_hash = self.hash_block(self.get_previous_block())
        return self.create_block(data=data, proof=0, previous_hash=previous_hash)

    def get_previous_block(self):
        """Return the last block in the chain (Task 3.3).

        Args:
            None.

        Returns:
            dict: the most recent block.
        """
        return self.chain[-1]

    # ------------------------------------------------------------------ Lab 4
    @staticmethod
    def hash_block(block):
        """Return the SHA-256 hash of a block (Lab 4, Task 3.2).

        json.dumps(..., sort_keys=True) turns the dict into one fixed string,
        so the same block always gives the same hash whatever the key order.

        Args:
            block (dict): the block to hash.

        Returns:
            str: 64 hexadecimal digits.
        """
        encoded_block = json.dumps(block, sort_keys=True).encode()
        return hashlib.sha256(encoded_block).hexdigest()

    def proof_of_work(self, index, timestamp, data, previous_hash):
        """Search for a proof that makes the block hash meet the target (Tasks 3.1, 3.3, 3.4).

        Args:
            index (int): index the new block will have.
            timestamp (str): timestamp the new block will have (fixed during the search).
            data: data the new block will carry.
            previous_hash (str): hash of the block before it.

        Returns:
            tuple[int, str]: the proof found, and the hash it produces.
        """
        new_proof = 0            # Task 3.3: the proof submitted by the miner
        check_proof = False      # Task 3.3: status of the search, False until solved
        while check_proof is False:
            candidate_block = {"index": index, "timestamp": timestamp, "data": data,
                               "proof": new_proof, "previous_hash": previous_hash}
            hash_operation = self.hash_block(candidate_block)   # Task 3.4
            if hash_operation[:self.difficulty] == self.target_prefix:
                check_proof = True                # puzzle solved
            else:
                new_proof += 1                    # try the next proof
        return new_proof, hash_operation

    def mine_block(self, data):
        """Mine a new block with Proof of Work and append it to the chain.

        Args:
            data: the information to record.

        Returns:
            dict: the mined block.
        """
        previous_block = self.get_previous_block()
        previous_hash = self.hash_block(previous_block)
        index = len(self.chain)
        timestamp = str(datetime.datetime.now())
        proof, _ = self.proof_of_work(index, timestamp, data, previous_hash)
        return self.create_block(data=data, proof=proof,
                                 previous_hash=previous_hash, timestamp=timestamp)

    def is_chain_valid(self, check_work=True):
        """Check every link and (optionally) every proof (optional validation task).

        Args:
            check_work (bool): also require each non-genesis block hash to meet
                the difficulty target. Set False for a Lab 3 chain built with
                add_block(), whose blocks were never mined.

        Returns:
            tuple[bool, str]: (True, "valid") or (False, reason for the failure).
        """
        for position in range(1, len(self.chain)):
            previous_block = self.chain[position - 1]
            current_block = self.chain[position]
            if current_block["previous_hash"] != self.hash_block(previous_block):
                return False, (f"block {position}: previous_hash does not match "
                               f"the hash of block {position - 1}")
            if current_block["index"] != position:
                return False, f"block {position}: index is {current_block['index']}"
            if check_work and not self.hash_block(current_block).startswith(self.target_prefix):
                return False, f"block {position}: hash does not meet the PoW target"
        return True, "valid"

    def print_chain(self):
        """Print every block together with its own hash.

        Args:
            None.

        Returns:
            None.
        """
        for block in self.chain:
            print(json.dumps(block, indent=2))
            print(f"  -> hash() -> {self.hash_block(block)}\n")
