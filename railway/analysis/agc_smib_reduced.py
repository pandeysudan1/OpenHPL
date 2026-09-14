import numpy as np
from scipy.integrate import solve_ivp

PBASE = 2.5e6
F0 = 50.0
H = 3.0
D = 1.0
R = 0.05
TG = 0.30
TT = 0.50
KI = 1.50
STEP_TIME = 5.0
DPL = 0.10


def rhs(t, x):
    df, dg, dpm, xi = x
    dload = 0.0 if t < STEP_TIME else DPL
    ef = -df
    dgate_cmd = ef / R + KI * xi
    return [
        (dpm - dload - D * df) / (2 * H),
        (dgate_cmd - dg) / TG,
        (dg - dpm) / TT,
        ef,
    ]


def run():
    sol = solve_ivp(rhs, (0, 65), [0, 0, 0, 0], max_step=0.01, rtol=1e-9, atol=1e-11, dense_output=True)
    t = np.linspace(0, 65, 6501)
    x = sol.sol(t)
    df, dg, dpm, xi = x
    f = F0 * (1 + df)
    pm_mw = (0.5 + dpm) * PBASE / 1e6
    return t, f, pm_mw, dg, xi


if __name__ == "__main__":
    t, f, pm, gate, xi = run()
    post = t >= STEP_TIME
    i = np.where(post)[0][np.argmin(f[post])]
    print(f"nadir_hz={f[i]:.9f}")
    print(f"nadir_time_s={t[i]:.6f}")
    print(f"f_65_hz={f[-1]:.9f}")
    print(f"pm_65_mw={pm[-1]:.9f}")
    print(f"initial_rocof_hz_per_s={-DPL*F0/(2*H):.9f}")
