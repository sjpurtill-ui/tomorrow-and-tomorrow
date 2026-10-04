import unittest
import numpy as np
from diagnose_court_legacy_motion import edges, nearest_hits


class LegacyDiagnosticTests(unittest.TestCase):
    def test_ray_distinguishes_cover_in_front_from_cloth_behind_skin(self):
        camera=np.array([0.,0.,3.]); skin=np.array([[0.,0.,0.]])
        front=np.array([[[-1.,-1.,.1],[1.,-1.,.1],[0.,1.,.1]]])
        back=front.copy();back[:,:,2]=-.1
        self.assertAlmostEqual(nearest_hits(camera,skin,front)[0],2.9)
        self.assertAlmostEqual(nearest_hits(camera,skin,back)[0],3.1)

    def test_open_vent_is_not_covered_by_nearby_cloth(self):
        camera=np.array([0.,0.,3.]);skin=np.array([[0.,0.,0.],[.7,0.,0.]])
        side=np.array([[[.4,-1.,.1],[1.2,-1.,.1],[1.2,1.,.1]],[[.4,-1.,.1],[1.2,1.,.1],[.4,1.,.1]]])
        distances=nearest_hits(camera,skin,side)
        self.assertTrue(np.isinf(distances[0]))
        self.assertLess(distances[1],np.linalg.norm(skin[1]-camera))

    def test_edge_set_keeps_shared_edge_only_once(self):
        actual=edges(np.array([[0,1,2],[2,1,3]]))
        self.assertEqual(len(actual),5)
        self.assertEqual(sum(np.all(actual==[1,2],axis=1)),1)

    def test_projection_bounds_match_full_triangle_scan(self):
        rng=np.random.default_rng(37)
        triangles=rng.uniform(-2.,2.,size=(300,3,3))
        targets=rng.uniform(-1.,1.,size=(64,3))
        for camera in (np.array([0.,0.,4.]),np.array([0.,.1,0.]),np.array([1.,4.,.3])):
            fast=nearest_hits(camera,targets,triangles)
            reference=nearest_hits(camera,targets,triangles,projected_bounds=False)
            np.testing.assert_allclose(fast,reference,atol=1e-12)


if __name__=="__main__":unittest.main()
