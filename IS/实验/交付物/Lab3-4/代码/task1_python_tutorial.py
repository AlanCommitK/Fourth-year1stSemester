"""
Lab 3 (Blockchain Part II, Lab 1) - Task 1: Python warm-up.

Task 1.1  Build a list of 10 block records with a for loop. Each record is a
          dict holding an index and a data field; the data values go from 100
          to 1000 in equal steps of 100 and are stored as a list.
Task 1.2  Wrap the record creation in one function and the printing in another.
Task 1.3  Put both functions in a class and drive it from a main program.
Task 1.4  Every function carries a docstring stating its arguments and return.

Run:  python task1_python_tutorial.py            (prints all blocks)
      python task1_python_tutorial.py 3          (prints the block with index 3)
"""

import sys

FIRST_DATA_VALUE = 100   # data value stored in the first block
LAST_DATA_VALUE = 1000   # data value stored in the last block
DATA_STEP = 100          # equal step between consecutive data values


def build_block_list_with_loop():
    """Task 1.1: create the 10 block records with a plain for loop.

    Args:
        None.

    Returns:
        list[dict]: ten records such as {'index': 0, 'data': [100]}.
    """
    block_list = []                                   # start from an empty list
    data_values = range(FIRST_DATA_VALUE, LAST_DATA_VALUE + 1, DATA_STEP)
    for position, value in enumerate(data_values):    # position 0..9, value 100..1000
        block_record = {"index": position, "data": [value]}  # data kept as a list
        block_list.append(block_record)
    return block_list


class BlockRecorder:
    """Tasks 1.2 and 1.3: record simple blocks and print one by its index."""

    def __init__(self):
        """Create an empty record list.

        Args:
            None.

        Returns:
            None.
        """
        self.block_list = []

    def record_blocks(self, first_value=FIRST_DATA_VALUE,
                      last_value=LAST_DATA_VALUE, step=DATA_STEP):
        """Generate one block per data value and append it to the record list.

        Args:
            first_value (int): data value of the first block.
            last_value (int): data value of the last block (inclusive).
            step (int): difference between consecutive data values.

        Returns:
            list[dict]: the full record list after appending.
        """
        for value in range(first_value, last_value + 1, step):
            block_record = {"index": len(self.block_list),  # index = position in list
                            "data": [value]}
            self.block_list.append(block_record)
        return self.block_list

    def print_block(self, block_index):
        """Print the block whose index equals block_index.

        Args:
            block_index (int): index of the block to show.

        Returns:
            dict | None: the block that was printed, or None if no such block.
        """
        for block_record in self.block_list:
            if block_record["index"] == block_index:
                print(block_record)
                return block_record
        print(f"No block with index {block_index}; valid range is "
              f"0..{len(self.block_list) - 1}.")
        return None


def main():
    """Task 1.3 main program: build the records and print the requested block.

    Args:
        None (an optional block index may be given on the command line).

    Returns:
        None.
    """
    print("Task 1.1 (plain loop):")
    for block_record in build_block_list_with_loop():
        print(block_record)

    recorder = BlockRecorder()          # Task 1.3: one instance of the class
    recorder.record_blocks()
    print("\nTask 1.2/1.3 (class):")
    if len(sys.argv) > 1:               # user asked for a single block
        recorder.print_block(int(sys.argv[1]))
    else:                               # otherwise show every block in turn
        for block_index in range(len(recorder.block_list)):
            recorder.print_block(block_index)


if __name__ == "__main__":
    main()
