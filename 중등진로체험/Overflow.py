import numpy as np # type: ignore

# 나는 현재 255 레벨(만렙)이다!
current_level = np.uint8(255) # 8비트의 최댓값
print(f"current_level: {current_level}")

# 여기서 1 레벨업을 하면?
next_level = current_level + 1
print(f"1 레벨업 후: {next_level}")
