import unittest

from examples.ffi.python_calling_rust.magic import rusty


class TestFFI(unittest.TestCase):
    def test_number(self):
        self.assertEquals(rusty.my_favorite_number(), 4)


if __name__ == "__main__":
    unittest.main()
