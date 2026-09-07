"""Bounded analytic eye study, metres, front at -Y. No captured anatomy claim.

One continuous outer mesh carries sclera/limbus/cornea labels. Iris and pupil
are separate internal surfaces. The caller supplies fitted placement and UVs.
"""
import math


def construct_eye(radius=0.015, aperture=0.0058, sag=0.0023,
                  iris_depth=0.0003, segments=96):
    values = (radius, aperture, sag, iris_depth)
    if not all(math.isfinite(v) for v in values):
        raise ValueError('Nonfinite eye dimensions')
    if not (0.009 <= radius <= 0.020 and 0.25*radius < aperture < 0.55*radius
            and 0.001 <= sag <= 0.004 and 0.0001 <= iris_depth <= 0.001):
        raise ValueError('Eye dimensions outside reviewed study envelope')
    if type(segments) is not int or not 32 <= segments <= 192:
        raise ValueError('Eye tessellation outside bounded study envelope')
    depth = radius * 0.9
    theta0 = math.asin(aperture/radius)
    # Quartic cap: apex slope=0, boundary position and slope match ellipsoid.
    slope = depth*aperture/(radius*radius*math.cos(theta0))
    a = 2*sag - slope*aperture/2
    b = slope*aperture/2 - sag
    if a <= 0 or 2*a+4*b <= 0:
        raise ValueError('Corneal cap would fold')
    center_y = sag + depth*math.cos(theta0)
    verts, weights = [(0., 0., 0.)], [1.]
    rings = []
    for k in range(1, 13):
        t = k/12
        rings.append((aperture*t, a*t*t+b*t**4,
                      1 if t <= 0.85 else 1-((t-.85)/.15)**2*(3-2*(t-.85)/.15)))
    for k in range(1, 36):
        angle = theta0+(math.pi-theta0)*k/36
        rings.append((radius*math.sin(angle), center_y-depth*math.cos(angle), 0.))
    for r, y, weight in rings:
        for j in range(segments):
            phi = 2*math.pi*j/segments
            verts.append((r*math.cos(phi), y, r*math.sin(phi)))
            weights.append(weight)
    faces = [(0, 1+j, 1+(j+1)%segments) for j in range(segments)]
    for k in range(len(rings)-1):
        lo, hi = 1+k*segments, 1+(k+1)*segments
        faces.extend((lo+j, hi+j, hi+(j+1)%segments, lo+(j+1)%segments)
                     for j in range(segments))
    back = len(verts)
    verts.append((0., center_y+depth, 0.))
    weights.append(0.)
    lo = 1+(len(rings)-1)*segments
    faces.extend((lo+j, back, lo+(j+1)%segments) for j in range(segments))
    labels = ['cornea' if max(weights[v] for v in f) == 1 else
              'limbus' if max(weights[v] for v in f) > 0 else 'sclera' for f in faces]

    pupil_radius = aperture*.32
    iris = []
    for k in range(17):
        t = k/16
        r = pupil_radius+(aperture*.99-pupil_radius)*t
        for j in range(segments):
            phi = 2*math.pi*j/segments
            # Small relief, zero at borders; not a synthetic anatomy dataset.
            relief = .000025*math.sin(phi*47+2*t)*math.sin(math.pi*t)
            iris.append((r*math.cos(phi), sag+iris_depth+.00015*(1-t)+relief,
                         r*math.sin(phi)))
    iris_faces = [(k*segments+j, (k+1)*segments+j,
                   (k+1)*segments+(j+1)%segments, k*segments+(j+1)%segments)
                  for k in range(16) for j in range(segments)]
    # Backing is behind the opening; it does not cap the iris at its plane.
    pupil = [(0., sag+iris_depth+.001, 0.)]
    pupil.extend((pupil_radius*1.1*math.cos(2*math.pi*j/segments),
                  sag+iris_depth+.001,
                  pupil_radius*1.1*math.sin(2*math.pi*j/segments)) for j in range(segments))
    return {'outer': {'vertices':verts, 'faces':faces, 'transmission':weights,
                      'regions':labels},
            'iris': {'vertices':iris, 'faces':iris_faces},
            'pupil': {'vertices':pupil, 'faces':[(0, 1+j, 1+(j+1)%segments)
                                               for j in range(segments)]},
            'parameters': {'radius_m':radius,'aperture_m':aperture,'sag_m':sag,
                'iris_depth_m':iris_depth,'segments':segments,
                'cap_coefficients_m':[a,b], 'boundary_slope':slope},
            'minimum_axial_iris_clearance_m':min(v[1]-sag for v in iris)}
