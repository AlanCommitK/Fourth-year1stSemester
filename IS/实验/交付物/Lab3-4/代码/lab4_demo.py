"""
lab4_demo.py - Lab 4 (Part II, Lab 2) demonstration: mine two blocks with
Proof of Work, validate the chain, then show what tampering does.

Run:  python lab4_demo.py            (difficulty 4, as in the lab sheet)
      python lab4_demo.py 5          (any other difficulty)
"""

import sys
import time

from blockchain import Blockchain


def mine_and_report(target_chain, data):
    """Mine one block and print how much work it took.

    Args:
        target_chain (Blockchain): the chain to extend.
        data: the information to record.

    Returns:
        dict: the mined block.
    """
    start_time = time.perf_counter()
    mined_block = target_chain.mine_block(data)
    elapsed_seconds = time.perf_counter() - start_time
    attempts = mined_block["proof"] + 1      # proofs 0..proof were all tried
    print(f"Mined block {mined_block['index']} ({data!r}): proof = {mined_block['proof']}, "
          f"{attempts} hashes in {elapsed_seconds:.3f} s")
    return mined_block


def main():
    """Run the Lab 4 demonstration.

    Args:
        None (an optional difficulty may be given on the command line).

    Returns:
        None.
    """
    difficulty = int(sys.argv[1]) if len(sys.argv) > 1 else 4
    pow_chain = Blockchain(difficulty=difficulty)
    print(f"Difficulty: {difficulty} leading zeros "
          f"(expected about {16 ** difficulty} hashes per block)\n")

    mine_and_report(pow_chain, "Transaction A")    # "Mine New Block": two blocks
    mine_and_report(pow_chain, "Transaction B")
    print()
    pow_chain.print_chain()

    print("Chain valid:", *pow_chain.is_chain_valid())   # optional validation step

    # Tamper with block 1 and check again: its hash no longer meets the target,
    # and block 2's previous_hash no longer matches it.
    print("\nTampering: block 1 data -> 'Transaction A (forged)'")
    pow_chain.chain[1]["data"] = "Transaction A (forged)"
    print("Chain valid:", *pow_chain.is_chain_valid())


if __name__ == "__main__":
    main()
