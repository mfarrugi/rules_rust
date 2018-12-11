import unittest

from examples.ffi.python_calling_rust.magic import rust_lib


class Rusty:
    get_number = rust_lib.my_favorite_number


class TestFFI(unittest.TestCase):
    def test_number(self):
        self.assertEquals(Rusty.get_number(), 4)


if __name__ == "__main__":
    unittest.main()
