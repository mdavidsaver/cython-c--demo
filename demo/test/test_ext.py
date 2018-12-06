
import unittest
import gc
import weakref

from .. import Holder

class Arbitrary(object):
    pass

class TestGC(unittest.TestCase):
    def setUp(self):
        self.assertEqual(Holder.count(), 0)

    def tearDown(self):
        self.assertEqual(Holder.count(), 0)

    def test_one(self):
        A = Arbitrary()
        H = Holder.make1(A)

        self.assertEqual(H.name, "Derived1")

        # complete the loop
        A.loop = H

        a = weakref.ref(A)
        h = weakref.ref(H)
        del A
        A = a()
        gc.collect()
        self.assertIsNot(A, None)
        self.assertIsNot(h(), None)

        del H
        gc.collect()
        H = h()
        self.assertIsNot(a(), None)
        self.assertIsNot(H, None)

        del A
        del H
        gc.collect()
        self.assertIs(a(), None)
        self.assertIs(h(), None)

    def test_two(self):
        H = Holder.make2()

        self.assertEqual(H.name, "Derived2")

        h = weakref.ref(H)
        del H
        gc.collect()
        self.assertIs(h(), None)

    def testOOPS(self):
        H = Holder.make2()

        with self.assertRaises(RuntimeError):
            H.oops()
