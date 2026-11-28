"""
lab3_demo.py - Lab 3 (Part II, Lab 1) demonstration, Tasks 3.1-3.3.

Creates the chain (the genesis block appears on instantiation), records two
blocks with add_block(), reads the previous block, and prints the chain with
the hash of every block so the hash links can be checked by eye.

Run:  python lab3_demo.py
"""

from blockchain import Blockchain


def main():
    """Run the Lab 3 demonstration.

    Args:
        None.

    Returns:
        None.
    """
    lab3_chain = Blockchain()                       # Task 3.1: genesis block created here
    print("Genesis block:", lab3_chain.chain[0], "\n")

    lab3_chain.add_block("Transaction A")           # Task 3.2: record information
    lab3_chain.add_block("Transaction B")

    print("Previous (latest) block:", lab3_chain.get_previous_block(), "\n")  # Task 3.3

    print("Whole chain:")
    lab3_chain.print_chain()

    # Links are checked; PoW is not, because these blocks were not mined yet.
    is_valid, reason = lab3_chain.is_chain_valid(check_work=False)
    print("Hash links valid:", is_valid, "-", reason)


if __name__ == "__main__":
    main()
