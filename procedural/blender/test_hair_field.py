import unittest
import numpy as np
from hair_field import direction_field, trace_line


class HairFieldTests(unittest.TestCase):
    def test_constant_has_no_direction_evidence(self):
        f,c = direction_field(np.ones((64,64)))
        self.assertEqual(float(c.max()),0)
        self.assertEqual(trace_line(f,c,(32,32)),[])

    def test_stripes_follow_strand_not_cross_gradient(self):
        y,x = np.mgrid[:96,:96]
        for image,axis in ((np.cos(x*.6),1),(np.cos(y*.6),0)):
            f,c = direction_field(image)
            self.assertGreater(float(np.mean(np.abs(f[8:-8,8:-8,axis]))),.99)
            line = trace_line(f,c,(48,48),steps=20)
            self.assertGreater(len(line),30)
            self.assertLess(np.ptp(np.array(line)[:,1-axis]),1e-6)

    def test_sign_equivalence(self):
        y,x = np.mgrid[:64,:64]
        f,c = direction_field(np.cos(x*.6))
        a = trace_line(f,c,(32,32),steps=10)
        b = trace_line(-f,c,(32,32),steps=10)
        self.assertTrue(np.allclose(a,b[::-1]))

    def test_reject_invalid(self):
        for image in (np.ones((3,3)),np.full((32,32),np.nan)):
            with self.assertRaises(ValueError):
                direction_field(image)
        with self.assertRaises(ValueError):
            trace_line(None,None,(0,0),steps=100000)


if __name__ == '__main__':
    unittest.main()
