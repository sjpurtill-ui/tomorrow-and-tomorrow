"""Small independent geometric controls for the exhaustive walking audit."""
import tempfile
import unittest
from pathlib import Path
import numpy as np
from validate_court_walking_cloth import intersections, check


class CrossingTest(unittest.TestCase):
    def test_real_surface_crossing_is_detected(self):
        triangle=np.array([[[0.,0.,0.],[1.,0.,0.],[0.,1.,0.]]])
        segment=np.array([[[.2,.2,-1.],[.2,.2,1.]]])
        self.assertTrue(np.allclose(intersections(segment,triangle),[[.2,.2,0.]]))

    def test_nearby_and_tangent_edges_are_not_penetration(self):
        triangle=np.array([[[0.,0.,0.],[1.,0.,0.],[0.,1.,0.]]])
        for segment in [[[-.1,.2,-1.],[-.1,.2,1.]],[[.2,.2,0.],[.2,.2,1.]],[[.2,.2,0.],[.3,.2,0.]]]:
            self.assertEqual(intersections(np.array([segment]),triangle),[])

    def test_no_geometry_cannot_pass(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/"empty.jsonl";path.write_text("")
            with self.assertRaisesRegex(AssertionError,"Empty"):check(path)


if __name__=="__main__":unittest.main()
