import math
import unittest
from collections import Counter
from eye_geometry import construct_eye, hermite_profile


class EyeGeometryTests(unittest.TestCase):
    def test_closed_oriented_outer(self):
        mesh = construct_eye()['outer']
        edges = Counter()
        directed = Counter()
        for f in mesh['faces']:
            for i, a in enumerate(f):
                b = f[(i+1)%len(f)]
                edges[tuple(sorted((a,b)))] += 1
                directed[(a,b)] += 1
        self.assertEqual(set(edges.values()), {2})
        self.assertTrue(all(directed[(b,a)] == n for (a,b),n in directed.items()))
        self.assertEqual(len(mesh['vertices'])-len(edges)+len(mesh['faces']), 2)
        self.assertLess(len(mesh['vertices']), 10000)
        self.assertEqual(set(mesh['regions']), {'sclera','limbus','cornea'})
        self.assertTrue(all(0 <= w <= 1 for w in mesh['transmission']))
        volume6 = 0
        for face in mesh['faces']:
            a = mesh['vertices'][face[0]]
            for i in range(1,len(face)-1):
                b,c = (mesh['vertices'][face[j]] for j in (i,i+1))
                cross = (b[1]*c[2]-b[2]*c[1], b[2]*c[0]-b[0]*c[2],
                         b[0]*c[1]-b[1]*c[0])
                volume6 += sum(a[j]*cross[j] for j in range(3))
        self.assertGreater(volume6,0, 'Outer normals must face outwards')

    def test_cap_continuity_and_clearance(self):
        model = construct_eye()
        p = model['parameters']
        r = p['cap_radius_m']
        self.assertAlmostEqual(r-math.sqrt(r*r-p['aperture_m']**2),p['sag_m'])
        y0,y1,s0,s1,width = p['limbus_hermite']
        self.assertEqual(hermite_profile(0,y0,y1,s0,s1,width),(y0,s0))
        y,s = hermite_profile(1,y0,y1,s0,s1,width)
        self.assertAlmostEqual(y,y1)
        self.assertAlmostEqual(s,s1)
        self.assertTrue(all(hermite_profile(k/64,y0,y1,s0,s1,width)[1]>0 for k in range(65)))
        # A spherical clear aperture has positive meridional curvature;
        # the retired quartic failed this near its edge despite passing C1.
        for k in range(101):
            x = p['aperture_m']*k/100
            self.assertGreater(r*r/(r*r-x*x)**1.5,0)
        cap = [model['outer']['vertices'][0]] + [
            model['outer']['vertices'][1+k*p['segments']] for k in range(12)]
        slopes = [(b[1]-a[1])/(b[0]-a[0]) for a,b in zip(cap,cap[1:])]
        self.assertTrue(all(b>a>0 for a,b in zip(slopes,slopes[1:])),
                        'Actual clear-cap mesh must not reverse curvature')
        self.assertGreaterEqual(model['minimum_axial_iris_clearance_m'], .0001)
        for part in ('outer','iris','pupil'):
            self.assertTrue(all(math.isfinite(v) for p in model[part]['vertices'] for v in p))

    def test_deterministic(self):
        self.assertEqual(construct_eye(), construct_eye())

    def test_reject_bad_parameters(self):
        for args in ({'radius':float('nan')}, {'aperture':.03}, {'sag':-.1},
                     {'segments':10000}, {'segments':True}, {'iris_depth':0}):
            with self.subTest(args=args), self.assertRaises(ValueError):
                construct_eye(**args)


if __name__ == '__main__':
    unittest.main()
