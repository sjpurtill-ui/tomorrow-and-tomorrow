"""Geometric acceptance checks for the court pinna deformation field."""
import unittest
import numpy as np
from court_ear_anatomy import EAR_HEIGHT, ear_displacement


class EarAnatomyTest(unittest.TestCase):
    def test_head_and_body_outside_ear_are_exactly_unchanged(self):
        points = np.array([[0., .13, .10], [.068, .125, -.014], [.085, .20, -.014],
                           [.09, EAR_HEIGHT, .035], [.13, EAR_HEIGHT, -.014],
                           [.25, -.4, .01], [0., -.8, 0.]])
        np.testing.assert_array_equal(ear_displacement(points), np.zeros_like(points))

    def test_mirrored_ears_have_mirrored_displacement(self):
        rng = np.random.default_rng(391)
        points = rng.uniform([.075, .085, -.047], [.11, .167, .019], (3000, 3))
        reflection = np.array([-1., 1., 1.])
        np.testing.assert_allclose(ear_displacement(points * reflection),
                                   ear_displacement(points) * reflection, atol=1e-14)

    def test_cavity_is_recessed_below_outer_rim_and_tragus(self):
        # Samples on a constant lateral plane isolate the sculpted relief.
        points = np.array([[.095, EAR_HEIGHT - .002, -.014],
                           [.095, EAR_HEIGHT + .022, -.014],
                           [.095, EAR_HEIGHT - .005, -.0022]])
        moved = points + ear_displacement(points)
        self.assertGreater(moved[1, 0] - moved[0, 0], .005)
        self.assertGreater(moved[2, 0] - moved[0, 0], .004)
        self.assertLess(ear_displacement(points)[0, 0], -.004)

    def test_inner_ridge_lobe_and_silhouette_have_physical_relief(self):
        points = np.array([[.095, EAR_HEIGHT, -.014 + .019 * -.30],
                           [.095, EAR_HEIGHT, -.014 + .019 * .10],
                           [.093, EAR_HEIGHT - .028 * .77, -.014],
                           [.093, EAR_HEIGHT + .028 * .78, -.014]])
        delta = ear_displacement(points)
        self.assertGreater(delta[0, 0] - delta[1, 0], .001)
        self.assertLess(delta[2, 1], -.001)
        self.assertGreater(delta[3, 0], .001)

    def test_field_is_bounded_finite_and_does_not_mutate_source(self):
        rng = np.random.default_rng(239)
        points = rng.uniform([-.13, .08, -.05], [.13, .17, .025], (30000, 3))
        original = points.copy()
        delta = ear_displacement(points)
        np.testing.assert_array_equal(points, original)
        self.assertTrue(np.isfinite(delta).all())
        self.assertLess(np.max(np.linalg.norm(delta, axis=1)), .011)

    def test_compact_support_has_no_boundary_step(self):
        epsilon = 1e-7
        boundaries = [[.075, EAR_HEIGHT, -.014], [.126, EAR_HEIGHT, -.014],
                      [.095, EAR_HEIGHT + .043, -.014], [.095, EAR_HEIGHT, .020]]
        for point in boundaries:
            samples = np.asarray(point) + np.array([[epsilon, 0., 0.], [-epsilon, 0., 0.],
                                                   [0., epsilon, 0.], [0., -epsilon, 0.],
                                                   [0., 0., epsilon], [0., 0., -epsilon]])
            self.assertLess(np.max(np.abs(ear_displacement(samples))), 1e-9)

    def test_deformation_does_not_fold_the_ear_volume(self):
        # A negative Jacobian determinant would turn local triangles inside
        # out, including between source vertices after subdivision.  Sample
        # the whole support volume, not only the few original ear vertices.
        rng = np.random.default_rng(493)
        points = rng.uniform([.075, .085, -.047], [.126, .168, .020], (12000, 3))
        epsilon = 1e-6
        jacobian = np.broadcast_to(np.eye(3), (len(points), 3, 3)).copy()
        for axis in range(3):
            offset = np.eye(3)[axis] * epsilon
            jacobian[:, :, axis] += (ear_displacement(points + offset) -
                                     ear_displacement(points - offset)) / (2. * epsilon)
        self.assertGreater(np.min(np.linalg.det(jacobian)), .1)

    def test_empty_and_invalid_inputs(self):
        self.assertEqual(ear_displacement(np.empty((0, 3))).shape, (0, 3))
        for points in [np.ones(3), np.ones((2, 4)), [[np.nan, 0., 0.]]]:
            with self.assertRaises(ValueError):
                ear_displacement(points)


if __name__ == "__main__":
    unittest.main()
