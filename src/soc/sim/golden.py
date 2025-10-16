from dataclasses import dataclass
from scipy.signal import chirp
import numpy as np
import subprocess
import matplotlib.pyplot as plt

@dataclass
class DC:

    @dataclass
    class Sweep:
        v_start: float
        v_end: float
        num_points: int
        dt_ns: int

        def __post_init__(self):
            if self.dt_ns < 2000 or self.dt_ns % 4 != 0:
                raise ValueError("dt_ns must be >= 2000 and divisible by 4")
            if self.num_points < 1:
                raise ValueError("num_points must be >= 1")
            if self.v_start < -10 or self.v_start > 10 or \
               self.v_end < -10 or self.v_end > 10:
                raise ValueError("v_start and v_end must be within -10 and 10")

    @dataclass
    class Level:
        v: float
        t_ns: int

        def __post_init__(self):
            if self.t_ns < 2000 or self.t_ns % 4 != 0:
                raise ValueError("t_ns must be >= 2000 and divisible by 4")
            if self.v < -10 or self.v > 10:
                raise ValueError("v must be within -10 and 10")

@dataclass
class RF:

    @dataclass
    class Chirp:
        f_span_hz: int
        f_nco_hz: int
        t_ns: int

    @dataclass
    class Drive:
        phase_deg: float
        iters: int
        t_drive_ns: int
        dt_drive_ns: int
        t_idle_ns: int
        dt_idle_ns: int


def chirp_test(channel: int, chp: RF.Chirp, samplerate=2):

    subprocess.run(
        ["../sw/chirp", str(channel), str(chp.f_span_hz), str(chp.f_nco_hz), str(chp.t_ns)], 
        cwd="../sw", check=True
    )
    subprocess.run(
        ["../rtl/swashispin_tb"], 
        cwd="../rtl", check=True
    )

    vrf = np.loadtxt(f"traces/rf{channel}.txt", dtype=float)

    t = np.arange(0, chp.t_ns, 1 / samplerate)
    f_span_ghz = chp.f_span_hz / 1e9
    golden = chirp(t, t1=chp.t_ns, f0=-f_span_ghz / 2, f1=f_span_ghz / 2, method='linear', phi=0)

    plt.figure("vrf")
    plt.plot(vrf)
    plt.xlabel("Index"); plt.ylabel("[V]"); plt.title("vrf"); plt.grid(True)

    plt.figure("golden")
    plt.plot(golden)
    plt.xlabel("Index"); plt.ylabel("[V]"); plt.title("golden"); plt.grid(True)

    plt.show()  # displays all open figures at once


if __name__ == "__main__":
    chirp_test(0, RF.Chirp(
        f_span_hz = 10000000,
        f_nco_hz = 10000000,
        t_ns = 100000
    ))
