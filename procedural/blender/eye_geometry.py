"""Bounded analytic eye study, metres, front at -Y. No captured anatomy claim.

One continuous outer mesh carries sclera/limbus/cornea labels. Iris and pupil
are separate internal surfaces. The caller supplies fitted placement and UVs.
"""
import math


def hermite_profile(t, y0, y1, slope0, slope1, width):
    """Position and radial slope of a finite transition band."""
    y = (2*t**3-3*t*t+1)*y0 + (t**3-2*t*t+t)*width*slope0
    y += (-2*t**3+3*t*t)*y1 + (t**3-t*t)*width*slope1
    slope = ((6*t*t-6*t)*y0 + (3*t*t-4*t+1)*width*slope0
             + (-6*t*t+6*t)*y1 + (3*t*t-2*t)*width*slope1)/width
    return y, slope


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
    if sag >= aperture:
        raise ValueError('Corneal cap must remain below a hemisphere')
    # Preserve apex/aperture/sag, but remove the old quartic's central
    # curvature reversal. Blend to sclera OUTSIDE the clear aperture.
    cap_radius = (aperture*aperture+sag*sag)/(2*sag)
    cap_slope = aperture/(cap_radius-sag)
    blend_radius = aperture*1.15
    theta0 = math.asin(blend_radius/radius)
    center_y = sag + depth*math.sqrt(1-(aperture/radius)**2)
    end_y = center_y-depth*math.cos(theta0)
    end_slope = depth*blend_radius/(radius*radius*math.cos(theta0))
    width = blend_radius-aperture
    blend_args = (sag,end_y,cap_slope,end_slope,width)
    if min(hermite_profile(k/64,*blend_args)[1] for k in range(65)) < 0:
        raise ValueError('Limbus transition would reverse its axial slope')
    verts, weights = [(0., 0., 0.)], [1.]
    rings = []
    for k in range(1, 13):
        t = k/12
        r = aperture*t
        rings.append((r,cap_radius-math.sqrt(cap_radius*cap_radius-r*r),1.))
    for k in range(1,9):
        t = k/8
        rings.append((aperture+t*width,hermite_profile(t,*blend_args)[0],
                      1-t*t*(3-2*t)))
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
                'profile':'spherical clear cap with external Hermite limbus',
                'cap_radius_m':cap_radius,'limbus_radius_m':blend_radius,
                'limbus_hermite':[sag,end_y,cap_slope,end_slope,width]},
            'minimum_axial_iris_clearance_m':min(v[1]-sag for v in iris)}
