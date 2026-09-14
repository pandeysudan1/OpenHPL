"""Heterogeneous 5+3 hydro two-area reference model.

Purpose
-------
Study two distinct layers of electromechanical dynamics:
1. common/COI area-frequency and tie-line modes;
2. inter-machine oscillations inside each hydro area.

Each Trollheim-like unit has different rating, inertia, permanent droop,
transient-droop compensation, governor/turbine time constant, and gate-rate
limit. Integration uses max_step = 0.1 s.
"""
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp

F0 = 50.0
N = 8
AREA = np.array([0,0,0,0,0,1,1,1])

S = np.array([180,150,130,110,90, 170,130,100.], dtype=float)
H = np.array([4.8,4.2,3.8,3.4,3.0, 4.5,3.7,3.1])
R = np.array([0.040,0.045,0.050,0.055,0.060, 0.045,0.052,0.060])
TG = np.array([0.22,0.28,0.35,0.42,0.50, 0.25,0.36,0.48])
TT = np.array([0.8,1.0,1.2,1.4,1.6, 0.9,1.25,1.55])
TR = np.array([4.0,5.0,6.0,7.5,9.0, 4.5,6.5,8.0])
KTD = np.array([1.0,1.2,1.4,1.6,1.8, 1.1,1.45,1.8])
RATE = np.array([0.14,0.12,0.10,0.09,0.08, 0.13,0.10,0.08])
D = 0.2*S
KSYNC = np.array([150,135,120,105,95, 145,120,100.])
KI_AREA = np.array([0.018,0.015])
B_AREA = np.array([20.0,20.0])
K_TIE = 5.0
DP_LOAD = 30.0
T_END = 120.0
MAX_STEP = 0.1

SAREA = np.array([S[AREA==a].sum() for a in (0,1)])
ALPHA = S/np.array([SAREA[a] for a in AREA])
W = H*S
P0 = 0.5*S

def coi(x, a):
    idx = AREA == a
    return np.sum(W[idx]*x[idx])/np.sum(W[idx])

def rhs(t, y):
    k = 0
    theta = y[k:k+N]; k += N
    df = y[k:k+N]; k += N
    gate = y[k:k+N]; k += N
    pm = y[k:k+N]; k += N
    ztr = y[k:k+N]; k += N
    xi = y[k:k+2]

    theta_coi = np.array([coi(theta,0), coi(theta,1)])
    df_coi = np.array([coi(df,0), coi(df,1)])
    ptie = K_TIE*(theta_coi[0]-theta_coi[1])

    dload = np.zeros(N)
    if t >= 5.0:
        dload[AREA==0] = DP_LOAD*ALPHA[AREA==0]

    pe = P0 + dload + KSYNC*(theta-theta_coi[AREA])
    pe[AREA==0] += ALPHA[AREA==0]*ptie
    pe[AREA==1] -= ALPHA[AREA==1]*ptie

    ef = df/F0
    ace = np.array([
        B_AREA[0]*(df_coi[0]/F0) + ptie/SAREA[0],
        B_AREA[1]*(df_coi[1]/F0) - ptie/SAREA[1]
    ])

    ucmd = 0.5 - ef/R - KTD*(ef-ztr) - KI_AREA[AREA]*xi[AREA]
    dgate = np.clip((ucmd-gate)/TG, -RATE, RATE)

    dpm = (S*gate-pm)/TT
    dztr = (ef-ztr)/TR
    ddf = F0/(2*H*S)*(pm-pe-D*df)
    dtheta = 2*np.pi*df
    dxi = ace

    return np.r_[dtheta, ddf, dgate, dpm, dztr, dxi]

def simulate():
    y0 = np.r_[np.zeros(N), np.zeros(N), np.full(N,0.5), P0,
               np.zeros(N), np.zeros(2)]
    sol = solve_ivp(rhs, (0,T_END), y0, rtol=1e-7, atol=1e-9,
                    max_step=MAX_STEP, dense_output=True)
    t = np.arange(0,T_END+MAX_STEP/2,MAX_STEP)
    Y = sol.sol(t)

    theta = Y[0:N]
    df = Y[N:2*N]
    gate = Y[2*N:3*N]
    pm = Y[3*N:4*N]
    df_coi = np.vstack([
        np.sum(W[AREA==a,None]*df[AREA==a],axis=0)/np.sum(W[AREA==a])
        for a in (0,1)
    ])
    theta_coi = np.vstack([
        np.sum(W[AREA==a,None]*theta[AREA==a],axis=0)/np.sum(W[AREA==a])
        for a in (0,1)
    ])
    ptie = K_TIE*(theta_coi[0]-theta_coi[1])
    return t, df, df_coi, ptie, gate, pm

def main():
    t, df, df_coi, ptie, gate, pm = simulate()
    post = t >= 5.0
    inter = np.zeros_like(df)
    inter[:5] = df[:5]-df_coi[0]
    inter[5:] = df[5:]-df_coi[1]

    metrics = {
        "area1_COI_nadir_Hz": float(F0+df_coi[0,post].min()),
        "area2_COI_nadir_Hz": float(F0+df_coi[1,post].min()),
        "peak_abs_tie_line_MW": float(np.abs(ptie[post]).max()),
        "final_area1_COI_Hz": float(F0+df_coi[0,-1]),
        "final_area2_COI_Hz": float(F0+df_coi[1,-1]),
        "final_tie_line_MW": float(ptie[-1]),
        "max_area1_inter_machine_mHz": float(1000*np.abs(inter[:5,post]).max()),
        "max_area2_inter_machine_mHz": float(1000*np.abs(inter[5:,post]).max()),
    }
    for k,v in metrics.items():
        print(f"{k}: {v:.6f}")

    data = {"time_s":t, "fCOI_area1_Hz":F0+df_coi[0],
            "fCOI_area2_Hz":F0+df_coi[1], "tie_line_MW":ptie}
    for i in range(N):
        data[f"f_G{i+1}_Hz"] = F0+df[i]
        data[f"df_inter_G{i+1}_mHz"] = 1000*inter[i]
        data[f"gate_G{i+1}_pu"] = gate[i]
        data[f"Pm_G{i+1}_MW"] = pm[i]
    pd.DataFrame(data).to_csv("heterogeneous_two_area_results.csv",index=False)

    pd.DataFrame({
        "unit":[f"G{i+1}" for i in range(N)],
        "area":[1 if a==0 else 2 for a in AREA],
        "rating_MW":S, "H_s":H, "R_pu":R, "Tg_s":TG, "Tt_s":TT,
        "transient_T_s":TR, "transient_gain":KTD,
        "gate_rate_pu_s":RATE, "Ksync_MW_rad":KSYNC
    }).to_csv("heterogeneous_unit_parameters.csv",index=False)

    plt.figure(figsize=(9,5))
    for i in range(5):
        plt.plot(t,F0+df[i],label=f"G{i+1} ({S[i]:.0f} MW)")
    plt.plot(t,F0+df_coi[0],lw=2.5,label="Area 1 COI")
    plt.axvline(5,ls="--",lw=1); plt.xlabel("Time [s]"); plt.ylabel("Frequency [Hz]")
    plt.grid(alpha=.3); plt.legend(ncol=2); plt.tight_layout()
    plt.savefig("area1_individual_frequencies.svg"); plt.close()

    plt.figure(figsize=(9,5))
    for i in range(5,8):
        plt.plot(t,F0+df[i],label=f"G{i+1} ({S[i]:.0f} MW)")
    plt.plot(t,F0+df_coi[1],lw=2.5,label="Area 2 COI")
    plt.axvline(5,ls="--",lw=1); plt.xlabel("Time [s]"); plt.ylabel("Frequency [Hz]")
    plt.grid(alpha=.3); plt.legend(); plt.tight_layout()
    plt.savefig("area2_individual_frequencies.svg"); plt.close()

    plt.figure(figsize=(9,5))
    for i in range(N):
        plt.plot(t,1000*inter[i],label=f"G{i+1}")
    plt.axhline(0,ls=":",lw=1); plt.axvline(5,ls="--",lw=1)
    plt.xlabel("Time [s]"); plt.ylabel(r"$f_i-f_{COI}$ [mHz]")
    plt.grid(alpha=.3); plt.legend(ncol=2); plt.tight_layout()
    plt.savefig("intermachine_frequency_deviation.svg"); plt.close()

    plt.figure(figsize=(9,5))
    plt.plot(t,F0+df_coi[0],label="Area 1 COI")
    plt.plot(t,F0+df_coi[1],label="Area 2 COI")
    plt.axhline(F0,ls=":",lw=1); plt.axvline(5,ls="--",lw=1)
    plt.xlabel("Time [s]"); plt.ylabel("COI frequency [Hz]")
    plt.grid(alpha=.3); plt.legend(); plt.tight_layout()
    plt.savefig("heterogeneous_coi_frequency.svg"); plt.close()

    plt.figure(figsize=(9,5))
    plt.plot(t,ptie,label="Tie-line Area 1 -> Area 2")
    plt.axhline(0,ls=":",lw=1); plt.axvline(5,ls="--",lw=1)
    plt.xlabel("Time [s]"); plt.ylabel("Tie-line power [MW]")
    plt.grid(alpha=.3); plt.legend(); plt.tight_layout()
    plt.savefig("heterogeneous_tie_line.svg"); plt.close()

if __name__=="__main__":
    main()
