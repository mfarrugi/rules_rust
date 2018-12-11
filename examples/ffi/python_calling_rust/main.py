from __future__ import print_function

# Debug Stuff!
import os
import sys

cwd = os.getcwd()
print("CWD: " + cwd)

print("PYTHONPATH:")
[print(x) for x in sys.path]
print()
# end debug stuff

from ctypes import cdll

rusty = cdll.LoadLibrary(
        # @TODO This cannot possibly be the The Right Way to do this.
        # - needs to pick file extension per platform.
        # - The _solib path needs to make it to PYTHONPATH...
        '_solib_k8/_U@examples_S_Sffi_Spython_Ucalling_Urust_Cc_Uwrapper___Uexternal_Sexamples_Sffi_Spython_Ucalling_Urust/librusty.so')

get_number = rusty.my_favorite_number

import unittest

class TestFFI(unittest.TestCase):
    def test_number(self):
        self.assertEquals(get_number(), 4)

if __name__ == '__main__':
    unittest.main()
