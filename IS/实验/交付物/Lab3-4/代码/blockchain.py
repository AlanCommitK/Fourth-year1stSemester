"""Lab 3 block records and a local blockchain with Lab 4 proof of work."""

from datetime import datetime, timezone
import hashlib
import json


class BlockRecords:
    """Generate and display the ten records in the Lab 3 Python exercise."""

    def __init__(self) -> None:
        """Generate the exercise records on construction. Return nothing."""
        self.records = self.generate_records()

    @staticmethod
    def generate_records() -> list[dict]:
        """Return the ten indexed records. Each data field holds one value."""
        records = []
        for index, value in enumerate(range(100, 1001, 100)):
            records.append({"index": index, "data": [value]})
        return records

    def print_block(self, index: int) -> None:
        """Print the record at the zero-based index. Return nothing."""
        if not 0 <= index < len(self.records):
            raise IndexError("The block index must be between 0 and 9.")
        print(f"Requested record: {json.dumps(self.records[index])}")


class Blockchain:
    """An in-memory chain with SHA-256 links and a four-hex-zero PoW rule."""

    POW_PREFIX = "0000"

    def __init__(self) -> None:
        """Create an empty chain, then append the genesis block. Return nothing."""
        self.chain = []
        self.chain.append(self.create_block("Hello World!", 0, "0"))

    def create_block(self, data: str, proof: int, previous_hash: str) -> dict:
        """Return a block with data, proof and prior hash at the next index."""
        return {
            "index": len(self.chain),
            "timestamp": datetime.now(timezone.utc).isoformat(timespec="microseconds"),
            "data": data,
            "proof": proof,
            "previous_hash": previous_hash,
        }

    def get_previous_block(self) -> dict:
        """Return the current tip, which is the parent of the next block."""
        return self.chain[-1]

    @staticmethod
    def hash(block: dict) -> str:
        """Return the SHA-256 hex digest of the block's compact, sorted JSON."""
        encoded = json.dumps(block, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
        return hashlib.sha256(encoded.encode("utf-8")).hexdigest()

    def proof_of_work(self, block: dict) -> int:
        """Return the first positive proof that gives this block the required prefix."""
        candidate = block.copy()
        proof = 1
        proof_valid = False
        # Only the proof changes during the search. All other fields are fixed.
        while not proof_valid:
            candidate["proof"] = proof
            hash_operation = self.hash(candidate)
            proof_valid = hash_operation[:4] == self.POW_PREFIX
            if not proof_valid:
                proof += 1
        return proof

    def mine_block(self, data: str) -> dict:
        """Record data in a new mined block, then return the appended block."""
        previous_hash = self.hash(self.get_previous_block())
        block = self.create_block(data, 0, previous_hash)
        block["proof"] = self.proof_of_work(block)
        self.chain.append(block)
        return block

    def is_chain_valid(self) -> bool:
        """Return whether genesis, block indices, hash links and mining proofs pass."""
        if not self.chain:
            return False
        required_fields = {"index", "timestamp", "data", "proof", "previous_hash"}
        for index, block in enumerate(self.chain):
            if not isinstance(block, dict) or block.keys() != required_fields:
                return False
            if type(block["index"]) is not int or block["index"] != index:
                return False
            if not all(isinstance(block[field], str) for field in ("timestamp", "data", "previous_hash")):
                return False
            if type(block["proof"]) is not int:
                return False
            if index == 0:
                if (block["data"], block["proof"], block["previous_hash"]) != ("Hello World!", 0, "0"):
                    return False
            else:
                previous = self.chain[index - 1]
                if block["previous_hash"] != self.hash(previous):
                    return False
                if block["proof"] < 1 or not self.hash(block).startswith(self.POW_PREFIX):
                    return False
        return True
