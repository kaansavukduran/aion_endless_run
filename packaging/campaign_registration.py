"""Local patch registration: image data stays unchanged, only anchors are recorded."""
import numpy as np
from scipy.signal import fftconvolve

def match_patch(image,patch,expected,radius):
    q=image.astype(float)/255.;t=patch.astype(float)/255.
    squared=fftconvolve((q*q).sum(2),np.ones(t.shape[:2]),mode='valid')
    cross=sum(fftconvolve(q[:,:,c],t[::-1,::-1,c],mode='valid') for c in range(4))
    error=np.maximum(0.,squared+(t*t).sum()-2.*cross)
    yy,xx=np.indices(error.shape)
    error[(abs(xx-expected[0])>radius[0])|(abs(yy-expected[1])>radius[1])]=np.inf
    y,x=np.unravel_index(np.argmin(error),error.shape)
    return int(x),int(y),float(error[y,x]/t.size)
