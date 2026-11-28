"""Show what the hash links and the proof of work each detect when a block is edited.

This script is an analysis aid for the report; it only reads blockchain.py.
Usage: python tamper_experiment.py
"""

from copy import deepcopy

from blockchain import Blockchain


def links_match(chain: Blockchain) -> bool:
    """Return whether every previous_hash equals the hash of the block before it."""
    return all(
        current["previous_hash"] == chain.hash(previous)
        for previous, current in zip(chain.chain, chain.chain[1:])
    )


def report(label: str, chain: Blockchain) -> None:
    """Print the link check and the full validator result for one chain copy."""
    links = links_match(chain)
    valid = chain.is_chain_valid()
    print(f"{label:<44} links match: {links!s:<5}  is_chain_valid: {valid}")


def main() -> None:
    """Mine two blocks, then test three kinds of edit on separate copies."""
    original = Blockchain()
    for data in ("Transaction A", "Transaction B"):
        original.mine_block(data)
    report("Original chain", original)

    edited = deepcopy(original)
    edited.chain[1]["data"] = "Transaction A (forged)"
    report("Block 1 data edited", edited)

    relinked = deepcopy(edited)
    # The forger repairs the broken link by storing the new hash of block 1 in block 2.
    relinked.chain[2]["previous_hash"] = relinked.hash(relinked.chain[1])
    report("Block 1 edited, block 2 relinked", relinked)
    print(f"  new hash of block 1: {relinked.hash(relinked.chain[1])}")

    last = deepcopy(original)
    last.chain[2]["data"] = "Transaction B (forged)"
    report("Last block (block 2) data edited", last)


if __name__ == "__main__":
    main()
