"""Reduced 5+3 hydro reference model for tuning the full OpenHPL two-area benchmark.

States are area frequency deviations, tie-line angle, distributed governor/turbine
increments, and one secondary ACE state per area. The script reproduces the
metrics quoted in README.md and writes CSV/SVG outputs when run with SciPy,
NumPy, pandas and matplotlib available.
"""
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp

N1, N2 = 5, 3
S1, S2 = 750.0, 450.0       # MW
F0 = 50.0                    # Hz
H1 = H2 = 4.0                # s
M1, M2 = 2*H1*S1/F0, 2*H2*S2/F0
D1, D2 = 15.0, 9.0           # MW/Hz
R = 0.05                     # 5% droop
KP1, KP2 = S1/(R*F0), S2/(R*F0)
B1, B2 = KP1 + D1, KP2 + D2 # MW/Hz
TG, TT = 0.30, 1.20          # governor/turbine time constants [s]
KI = 0.03                    # ACE integral gain [1/s]
K_TIE = 5.0                  # MW/rad
DP_LOAD = 30.0               # MW at t=5 s in Area 1


def simulate(ki=KI):
    n = 3 + 2*N1 + 1 + 2*N2 + 1
    x0 = np.zeros(n)

    def f(t, x):
        i = 0
        df1, df2, delta = x[i:i+3]; i += 3
        g1 = x[i:i+N1]; i += N1
        pm1 = x[i:i+N1]; i += N1
        sec1 = x[i]; i += 1
        g2 = x[i:i+N2]; i += N2
        pm2 = x[i:i+N2]; i += N2
        sec2 = x[i]

        ptie = K_TIE*delta
        load1 = DP_LOAD if t >= 5.0 else 0.0
        ace1 = B1*df1 + ptie
        ace2 = B2*df2 - ptie

        cmd1 = (-KP1*df1 + sec1)/N1
        cmd2 = (-KP2*df2 + sec2)/N2
        dg1 = (cmd1-g1)/TG
        dg2 = (cmd2-g2)/TG
        dpm1 = (g1-pm1)/TT
        dpm2 = (g2-pm2)/TT

        ddf1 = (pm1.sum()-load1-ptie-D1*df1)/M1
        ddf2 = (pm2.sum()+ptie-D2*df2)/M2
        ddelta = 2*np.pi*(df1-df2)
        dsec1 = -ki*ace1
        dsec2 = -ki*ace2
        return np.r_[ddf1, ddf2, ddelta, dg1, dpm1, dsec1, dg2, dpm2, dsec2]

    sol = solve_ivp(f, (0, 80), x0, rtol=1e-9, atol=1e-11,
                    max_step=0.02, dense_output=True)
    t = np.linspace(0, 80, 4001)
    X = sol.sol(t)
    df1, df2, delta = X[0], X[1], X[2]
    ptie = K_TIE*delta
    return t, X, F0+df1, F0+df2, ptie


def main():
    t, X, f1, f2, ptie = simulate(KI)
    _, _, f1_noagc, f2_noagc, ptie_noagc = simulate(0.0)
    post = t >= 5.0

    print(f"Area-1 nadir: {f1[post].min():.6f} Hz")
    print(f"Area-2 nadir: {f2[post].min():.6f} Hz")
    print(f"Peak |tie-line|: {np.abs(ptie[post]).max():.6f} MW")
    print(f"Final f1/f2: {f1[-1]:.6f}, {f2[-1]:.6f} Hz")
    print(f"Final tie-line: {ptie[-1]:.6f} MW")
    print(f"Droop-only final f1/f2: {f1_noagc[-1]:.6f}, {f2_noagc[-1]:.6f} Hz")
    print(f"Droop-only final tie-line: {ptie_noagc[-1]:.6f} MW")

    pd.DataFrame({"time_s":t, "frequency1_Hz":f1,
                  "frequency2_Hz":f2, "tie_line_MW":ptie}).to_csv(
        "two_area_reference_results.csv", index=False)

    plt.figure(figsize=(8,4.5))
    plt.plot(t, f1, label="Area 1: 5 hydros")
    plt.plot(t, f2, label="Area 2: 3 hydros")
    plt.axhline(50, ls=":"); plt.axvline(5, ls="--")
    plt.xlabel("Time [s]"); plt.ylabel("Frequency [Hz]")
    plt.grid(alpha=.3); plt.legend(); plt.tight_layout()
    plt.savefig("frequency_response.svg"); plt.close()

    plt.figure(figsize=(8,4.5))
    plt.plot(t, ptie, label="Area 1 -> Area 2")
    plt.axhline(0, ls=":"); plt.axvline(5, ls="--")
    plt.xlabel("Time [s]"); plt.ylabel("Tie-line power [MW]")
    plt.grid(alpha=.3); plt.legend(); plt.tight_layout()
    plt.savefig("tie_line_power.svg"); plt.close()

    plt.figure(figsize=(8,4.5))
    plt.plot(t, f1, label="ACE control")
    plt.plot(t, f1_noagc, label="Droop only")
    plt.axhline(50, ls=":"); plt.axvline(5, ls="--")
    plt.xlabel("Time [s]"); plt.ylabel("Area-1 frequency [Hz]")
    plt.grid(alpha=.3); plt.legend(); plt.tight_layout()
    plt.savefig("ace_vs_droop.svg"); plt.close()

if __name__ == "__main__":
    main()
