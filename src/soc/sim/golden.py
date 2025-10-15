from dataclasses import dataclass

@dataclass
class DC

    @dataclass
    class Sweep:
        "Linear sweep from v_start to v_end"
        v_start: float
        v_end: float
        num_points: int
        dt_ns: int

        def __post_init__(self):
            if self.dt_ns < 2000 or self.dt_ns % 4 != 0:
                raise ValueError("dt_ns must be >= 2000 and divisible by 4")
            if self.num_points < 1:
                raise ValueError("num_points must be >= 1")
            if self.v_start < -10 or self.v_start > 10 or
               self.v_end < -10 or self.v_end > 10:
                raise ValueError("v_start and v_end must be within -10 and 10")

    @dataclass
    class Level:
        "Hold a single DC level setting"
        v: float
        t_ns: int

        def __post_init__(self):
            if self.t_ns < 2000 or self.t_ns % 4 != 0:
                raise ValueError("t_ns must be >= 2000 and divisible by 4")
            if v < -10 or v > 10:
                raise ValueError("v must be within -10 and 10")

