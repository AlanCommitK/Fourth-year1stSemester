"""
test_blockchain.py - automatic checks for the Lab 3 / Lab 4 code.

Run:  python -m unittest test_blockchain -v
"""

import unittest

from blockchain import Blockchain
from task1_python_tutorial import BlockRecorder, build_block_list_with_loop


class TestTask1(unittest.TestCase):
    """Task 1: the warm-up records."""

    def test_loop_builds_ten_blocks_from_100_to_1000(self):
        block_list = build_block_list_with_loop()
        self.assertEqual(len(block_list), 10)
        self.assertEqual([record["data"] for record in block_list],
                         [[value] for value in range(100, 1001, 100)])
        self.assertTrue(all(isinstance(record["data"], list) for record in block_list))

    def test_class_prints_requested_block(self):
        recorder = BlockRecorder()
        recorder.record_blocks()
        self.assertEqual(recorder.print_block(3), {"index": 3, "data": [400]})
        self.assertIsNone(recorder.print_block(42))


class TestLab3Structure(unittest.TestCase):
    """Lab 3: genesis block, recording, previous block."""

    def setUp(self):
        self.chain = Blockchain(difficulty=2)

    def test_genesis_block(self):
        genesis = self.chain.chain[0]
        self.assertEqual(genesis["index"], 0)
        self.assertEqual(genesis["data"], "Hello World!")
        self.assertEqual(genesis["proof"], 0)
        self.assertEqual(genesis["previous_hash"], "0")
        self.assertEqual(set(genesis), {"index", "timestamp", "data", "proof", "previous_hash"})

    def test_add_block_links_to_previous_hash(self):
        first_hash = Blockchain.hash_block(self.chain.chain[0])
        new_block = self.chain.add_block("Transaction A")
        self.assertEqual(new_block["index"], 1)
        self.assertEqual(new_block["previous_hash"], first_hash)
        self.assertIs(self.chain.get_previous_block(), new_block)
        self.assertEqual(self.chain.is_chain_valid(check_work=False), (True, "valid"))

    def test_hash_is_independent_of_key_order(self):
        block = {"b": 1, "a": 2}
        self.assertEqual(Blockchain.hash_block(block),
                         Blockchain.hash_block({"a": 2, "b": 1}))


class TestLab4ProofOfWork(unittest.TestCase):
    """Lab 4: proof of work, mining and validation."""

    def setUp(self):
        self.chain = Blockchain(difficulty=3)
        self.chain.mine_block("Transaction A")
        self.chain.mine_block("Transaction B")

    def test_mined_hash_meets_target(self):
        for block in self.chain.chain[1:]:
            self.assertTrue(Blockchain.hash_block(block).startswith("000"))

    def test_proof_is_the_smallest_one(self):
        block = self.chain.chain[1]
        for smaller_proof in range(block["proof"]):
            trial = dict(block, proof=smaller_proof)
            self.assertFalse(Blockchain.hash_block(trial).startswith("000"))

    def test_valid_chain(self):
        self.assertEqual(self.chain.is_chain_valid(), (True, "valid"))

    def test_tampered_data_is_detected(self):
        self.chain.chain[1]["data"] = "forged"
        is_valid, reason = self.chain.is_chain_valid()
        self.assertFalse(is_valid)
        self.assertIn("block", reason)

    def test_tampering_last_block_breaks_its_proof(self):
        self.chain.chain[2]["data"] = "forged"       # no later block to expose it
        is_valid, reason = self.chain.is_chain_valid()
        self.assertFalse(is_valid)
        self.assertIn("PoW target", reason)

    def test_unmined_block_fails_work_check(self):
        self.chain.add_block("not mined")
        self.assertFalse(self.chain.is_chain_valid()[0])
        self.assertTrue(self.chain.is_chain_valid(check_work=False)[0])


if __name__ == "__main__":
    unittest.main()
