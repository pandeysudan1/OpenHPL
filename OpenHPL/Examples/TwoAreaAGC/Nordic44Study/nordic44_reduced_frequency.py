"""Reduced Nordic-44 multi-area frequency study.

Frozen network source:
ALSETLab/Nordic44-Nordpool, N44_BC.raw, 2015-08-12.

This is a transparent 10-region explanatory model, not a replacement for the
full PSS/E DYR dynamic model.
"""
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp

AREA = ["NO1","NO2","NO3","NO4","NO5","SE1","SE2","SE3","SE4","FI1"]
S = np.array([6960,12280,4000,4200,6450,5000,10690,16803,7098,13203.], float)
H = np.array([5.0,5.2,4.5,4.8,5.5,7.0,8.0,5.0,4.8,6.0])
F0 = 50.0
R = 0.05
TG = 0.30
TT = 1.00
D = 50.0
M = 2*H*S/F0
KP = S/(R*F0)

# Cross-area AC branch X values extracted from N44_BC.raw.
EDGE_X = {
("SE3","SE1"):[0.9],
("SE1","SE2"):[0.5,0.2],
("SE1","NO4"):[0.4],
("SE1","FI1"):[0.13],
("SE2","NO3"):[0.2],
("SE2","NO4"):[2.0],
("SE2","FI1"):[0.075],
("SE3","SE2"):[0.12,0.2,0.24,0.24,0.24,0.5,0.23],
("SE3","SE4"):[0.17,0.23,0.27,0.27,0.32],
("SE3","NO1"):[0.26,0.22],
("NO1","NO3"):[0.9],
("NO1","NO5"):[0.1,0.07],
("NO1","NO2"):[0.36,0.255,0.6],
("NO2","NO5"):[0.22],
("NO3","NO4"):[1.8,1.3],
}
AGGREGATION_SCALE = 0.01
K = np.zeros((len(AREA),len(AREA)))
for (a,b), xs in EDGE_X.items():
    kab = AGGREGATION_SCALE*sum(1000.0/x for x in xs)
    i,j = AREA.index(a), AREA.index(b)
    K[i,j] = K[j,i] = kab

def rhs(t, y):
    n=len(AREA)
    theta=y[:n]
    df=y[n:2*n]
    gov=y[2*n:3*n]
    pm=y[3*n:4*n]
    pnet=np.array([sum(K[i,j]*(theta[i]-theta[j]) for j in range(n))
                   for i in range(n)])
    disturbance=np.zeros(n)
    if t >= 5.0:
        disturbance[AREA.index("NO2")] = 1000.0
    return np.r_[
        2*np.pi*df,
        (pm-disturbance-pnet-D*df)/M,
        (-KP*df-gov)/TG,
        (gov-pm)/TT,
    ]

sol=solve_ivp(rhs,(0,60),np.zeros(4*len(AREA)),method="Radau",
              rtol=1e-8,atol=1e-10,max_step=0.05,dense_output=True)
t=np.arange(0,60.0001,0.05)
Y=sol.sol(t)
theta=Y[:len(AREA)]
freq=F0+Y[len(AREA):2*len(AREA)]

pd.DataFrame({"time_s":t, **{a:freq[i] for i,a in enumerate(AREA)}}).to_csv(
    "nordic44_area_frequency_timeseries.csv", index=False)
