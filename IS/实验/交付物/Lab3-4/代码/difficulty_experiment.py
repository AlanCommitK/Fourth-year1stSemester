"""
difficulty_experiment.py - how the work grows with the difficulty (extension, for the report).

For difficulty d (number of leading hex zeros) each hash meets the target with
probability (1/16)**d, so the number of hashes until success is geometric with
mean 16**d. This script mines several blocks at each difficulty and compares the
measured mean number of hashes with 16**d.

Run:  python difficulty_experiment.py            (difficulties 1-4, 20 blocks each)
      python difficulty_experiment.py 5 10       (difficulties 1-5, 10 blocks each)
Writes difficulty_results.csv next to the script.
"""

import csv
import os
import statistics
import sys
import time

from blockchain import Blockchain


def measure_difficulty(difficulty, blocks_per_level):
    """Mine blocks_per_level blocks at one difficulty and collect statistics.

    Args:
        difficulty (int): number of leading hex zeros required.
        blocks_per_level (int): how many blocks to mine.

    Returns:
        dict: difficulty, expected and measured mean hashes, mean seconds per block.
    """
    test_chain = Blockchain(difficulty=difficulty)
    hash_counts = []
    block_seconds = []
    for block_number in range(blocks_per_level):
        start_time = time.perf_counter()
        mined_block = test_chain.mine_block(f"experiment block {block_number}")
        block_seconds.append(time.perf_counter() - start_time)
        hash_counts.append(mined_block["proof"] + 1)
    return {"difficulty": difficulty,
            "expected_hashes": 16 ** difficulty,
            "mean_hashes": round(statistics.mean(hash_counts), 1),
            "min_hashes": min(hash_counts),
            "max_hashes": max(hash_counts),
            "mean_seconds": round(statistics.mean(block_seconds), 4)}


def main():
    """Run the experiment and save a CSV table.

    Args:
        None (optional: maximum difficulty and blocks per level on the command line).

    Returns:
        None.
    """
    max_difficulty = int(sys.argv[1]) if len(sys.argv) > 1 else 4
    blocks_per_level = int(sys.argv[2]) if len(sys.argv) > 2 else 20
    results = [measure_difficulty(level, blocks_per_level)
               for level in range(1, max_difficulty + 1)]

    header = list(results[0].keys())
    print(" | ".join(header))
    for row in results:
        print(" | ".join(str(row[key]) for key in header))

    output_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                               "difficulty_results.csv")
    with open(output_path, "w", newline="") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=header)
        writer.writeheader()
        writer.writerows(results)
    print("\nSaved", output_path)


if __name__ == "__main__":
    main()
