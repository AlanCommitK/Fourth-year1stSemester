"""Measure how many attempts proof of work needs at several difficulties.

This script is an analysis aid for the report. It does not change blockchain.py:
it subclasses Blockchain and repeats the same search, only with a prefix length
that can be set, because the lab version fixes the target at four zeros.

Usage: python difficulty_experiment.py [max_difficulty] [blocks_per_difficulty]
"""

import csv
import statistics
import sys
from time import perf_counter

from blockchain import Blockchain


class VariableDifficultyChain(Blockchain):
    """A Blockchain whose PoW target is a prefix of `difficulty` zeros."""

    def __init__(self, difficulty: int) -> None:
        """Store the target prefix, then build the genesis block. Return nothing."""
        self.POW_PREFIX = "0" * difficulty  # instance value replaces the class constant
        super().__init__()

    def proof_of_work(self, block: dict) -> int:
        """Return the first proof from 1 upwards whose block hash has the prefix."""
        candidate = block.copy()
        proof = 1
        # Same loop as Blockchain.proof_of_work, but the prefix length is variable.
        while True:
            candidate["proof"] = proof
            if self.hash(candidate).startswith(self.POW_PREFIX):
                return proof
            proof += 1


def measure(difficulty: int, blocks: int) -> dict:
    """Mine `blocks` blocks at one difficulty and return attempt and time statistics."""
    chain = VariableDifficultyChain(difficulty)
    attempts, seconds = [], []
    for number in range(blocks):
        start = perf_counter()
        block = chain.mine_block(f"Block {number}")
        seconds.append(perf_counter() - start)
        attempts.append(block["proof"])  # the search starts at 1, so proof = attempts
    return {
        "difficulty": difficulty,
        "expected": 16 ** difficulty,
        "mean": statistics.mean(attempts),
        "min": min(attempts),
        "max": max(attempts),
        "mean_seconds": statistics.mean(seconds),
        "attempts": attempts,
    }


def main() -> None:
    """Run the experiment, print a table and save the raw attempts to CSV."""
    max_difficulty = int(sys.argv[1]) if len(sys.argv) > 1 else 4
    blocks = int(sys.argv[2]) if len(sys.argv) > 2 else 200
    rows = [measure(difficulty, blocks) for difficulty in range(1, max_difficulty + 1)]
    print(f"{'d':>2} {'16^d':>7} {'mean':>10} {'min':>7} {'max':>8} {'time/block':>11}")
    for row in rows:
        print(f"{row['difficulty']:>2} {row['expected']:>7} {row['mean']:>10.1f} "
              f"{row['min']:>7} {row['max']:>8} {row['mean_seconds']:>10.4f}s")
    with open("difficulty_results.csv", "w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(["difficulty", "block", "attempts"])
        for row in rows:
            for number, value in enumerate(row["attempts"]):
                writer.writerow([row["difficulty"], number, value])


if __name__ == "__main__":
    main()
