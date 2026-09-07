"""Bounded image structure-tensor line field; not full hair reconstruction."""
import numpy as np


def direction_field(gray):
    gray = np.asarray(gray,dtype=np.float64)
    if gray.ndim != 2 or min(gray.shape)<8 or max(gray.shape)>2048 or not np.isfinite(gray).all():
        raise ValueError('Expected finite grayscale image, 8..2048 pixels per dimension')
    def blur(a):
        for axis in (0,1):
            pad = [(0,0),(0,0)]
            pad[axis] = (2,2)
            p = np.pad(a,pad,mode='reflect')
            a = sum(w*np.take(p,range(i,i+a.shape[axis]),axis=axis)
                    for i,w in enumerate((1,4,6,4,1)))/16
        return a
    gy,gx = np.gradient(blur(gray))
    a,b,c = blur(gx*gx),blur(gx*gy),blur(gy*gy)
    delta = np.sqrt((a-c)**2+4*b*b)
    angle = .5*np.arctan2(2*b,a-c)+np.pi/2
    confidence = delta/(a+c+1e-12)
    confidence[(a+c)<1e-8] = 0
    return np.stack((np.cos(angle),np.sin(angle)),axis=-1),confidence


def trace_line(field,confidence,seed,steps=40,step=1.5):
    if type(steps) is not int or not 1<=steps<=128 or not .25<=step<=3:
        raise ValueError('Unbounded tracing request')
    def half(sign):
        p = np.asarray(seed,dtype=float)
        previous = None
        result = []
        for _ in range(steps):
            x,y = np.rint(p).astype(int)
            if x<2 or y<2 or x>=confidence.shape[1]-2 or y>=confidence.shape[0]-2:
                break
            if confidence[y,x]<.6:
                break
            direction = field[y,x].copy()
            if previous is None:
                direction *= sign
            elif np.dot(direction,previous)<0:
                direction *= -1
            if previous is not None and np.dot(direction,previous)<.90:
                break
            result.append(tuple(p))
            previous = direction
            p = p+step*direction
        return result
    left,right = half(-1),half(1)
    return left[:0:-1]+right
