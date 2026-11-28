"""Run the Lab 3 and Lab 4 demonstrations and verify the observed results."""

import argparse
from copy import deepcopy
import json
from pathlib import Path
import platform
import sys
from time import perf_counter

from blockchain import Blockchain, BlockRecords


def run_lab(record_index: int) -> dict:
    """Demonstrate record retrieval at record_index, mine two blocks and return evidence."""
    records = BlockRecords()
    blockchain = Blockchain()
    genesis = blockchain.get_previous_block()
    blocks = [{"block": genesis, "sha256": blockchain.hash(genesis)}]

    print(f"Python {platform.python_version()} | venv active: {sys.prefix != sys.base_prefix}")
    print("\nLab 3: Python records and chain architecture")
    for record in records.records:
        print(json.dumps(record))
    records.print_block(record_index)
    print(f"Genesis block: {json.dumps(genesis)}")
    print(f"Genesis SHA-256: {blocks[0]['sha256']}")

    print("\nLab 4: four-zero proof of work")
    for data in ("Transaction A", "Transaction B"):
        start = perf_counter()
        block = blockchain.mine_block(data)
        elapsed_seconds = perf_counter() - start
        digest = blockchain.hash(block)
        attempts = block["proof"]  # The search started at one and tried every integer.
        blocks.append({
            "block": block, "sha256": digest,
            "attempts": attempts, "elapsed_seconds": elapsed_seconds,
        })
        print(f"Mined block: {json.dumps(block)}")
        print(f"  SHA-256: {digest}")
        print(f"  Attempts: {attempts} | Mining time: {elapsed_seconds:.6f} s")

    # Change copies only, so each negative check operates on the verified chain.
    edited_record = deepcopy(blockchain)
    edited_record.chain[1]["data"] += " [edited]"
    edited_link = deepcopy(blockchain)
    edited_link.chain[-1]["previous_hash"] = "0"
    edited_proof = deepcopy(blockchain)
    edited_proof.chain[-1]["proof"] = 0

    checks = {
        "ten_records_in_order": records.records == [
            {"index": index, "data": [value]}
            for index, value in enumerate(range(100, 1001, 100))
        ],
        "genesis_fields": (genesis["index"], genesis["data"], genesis["proof"], genesis["previous_hash"])
        == (0, "Hello World!", 0, "0"),
        "previous_block_is_tip": blockchain.get_previous_block() is blockchain.chain[-1],
        "two_blocks_appended": len(blockchain.chain) == 3,
        "every_link_matches": all(
            current["previous_hash"] == blockchain.hash(previous)
            for previous, current in zip(blockchain.chain, blockchain.chain[1:])
        ),
        "both_mined_hashes_meet_target": all(
            evidence["sha256"].startswith(Blockchain.POW_PREFIX) for evidence in blocks[1:]
        ),
        "original_chain_accepted": blockchain.is_chain_valid(),
        "modified_middle_record_rejected": not edited_record.is_chain_valid(),
        "modified_final_link_rejected": not edited_link.is_chain_valid(),
        "invalid_final_proof_rejected": not edited_proof.is_chain_valid(),
    }
    print("\nVerification")
    for check, passed in checks.items():
        print(f"{'PASS' if passed else 'FAIL'}  {check}")
    if not all(checks.values()):
        raise RuntimeError("One or more lab checks failed.")
    print(f"{len(checks)}/{len(checks)} checks passed.")

    return {
        "python_version": platform.python_version(),
        "virtual_environment": sys.prefix != sys.base_prefix,
        "difficulty_hex_digits": len(Blockchain.POW_PREFIX),
        "records": records.records,
        "displayed_record_index": record_index,
        "blocks": blocks,
        "checks": checks,
    }


def main() -> None:
    """Run the demonstration using the requested index and optional JSON path."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--record-index", type=int, choices=range(10), default=4)
    parser.add_argument("--json-out", type=Path)
    args = parser.parse_args()
    results = run_lab(args.record_index)
    if args.json_out is not None:
        args.json_out.write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
