import numpy as np
from gif import write_gif
import matplotlib.pyplot as plt

#  0
# 2 3
#  1 

klotski = np.array([[4, 6, 13, 3],
                    [11, 2, 15, 12],
                    [9, 7, 1, 10],
                    [5, 14, 8, 0]])

matrices = []

def find_number(klotski, number):
    for i in range(4):
        for j in range(4):
            if klotski[i][j] == number:
                return (i, j)
            
def check_move(mask, pos, direction):
    if direction == 0:
        if pos[0] - 1 >= 0 and mask[pos[0] - 1][pos[1]] == 0:
            return True
    elif direction == 1:
        if pos[0] + 1 < 4 and mask[pos[0] + 1][pos[1]] == 0:
            return True
    elif direction == 2:
        if pos[1] - 1 >= 0 and mask[pos[0]][pos[1] - 1] == 0:
            return True
    elif direction == 3:
        if pos[1] + 1 < 4 and mask[pos[0]][pos[1] + 1] == 0:
            return True
    return False

def move(klotski, pos, direction):
    if direction == 0:
        klotski[pos[0]][pos[1]] = klotski[pos[0] - 1][pos[1]]
        klotski[pos[0] - 1][pos[1]] = 0
    elif direction == 1:
        klotski[pos[0]][pos[1]] = klotski[pos[0] + 1][pos[1]]
        klotski[pos[0] + 1][pos[1]] = 0
    elif direction == 2:
        klotski[pos[0]][pos[1]] = klotski[pos[0]][pos[1] - 1]
        klotski[pos[0]][pos[1] - 1] = 0
    elif direction == 3:
        klotski[pos[0]][pos[1]] = klotski[pos[0]][pos[1] + 1]
        klotski[pos[0]][pos[1] + 1] = 0

def move_zero_to_target(klotski, mask, target, flag = False):
    zero_pos = find_number(klotski, 0)
    if zero_pos[0] == target[0]:
        if zero_pos[1] == target[1]:
            return
        elif zero_pos[1] < target[1]:
            if check_move(mask, zero_pos, 3):
                move(klotski, zero_pos, 3)
            elif check_move(mask, zero_pos, 0):
                move(klotski, zero_pos, 0)
            else:
                move(klotski, zero_pos, 1)
        else:
            if check_move(mask, zero_pos, 2):
                move(klotski, zero_pos, 2)
            elif check_move(mask, zero_pos, 0):
                move(klotski, zero_pos, 0)
            else:
                move(klotski, zero_pos, 1)
    elif zero_pos[0] < target[0]:
        if zero_pos[1] == target[1]:
            if check_move(mask, zero_pos, 1):
                move(klotski, zero_pos, 1)
            elif check_move(mask, zero_pos, 2):
                move(klotski, zero_pos, 2)
            else:
                move(klotski, zero_pos, 3)
        elif zero_pos[1] < target[1]:
            if check_move(mask, zero_pos, 3):
                move(klotski, zero_pos, 3)
            else:
                move(klotski, zero_pos, 1)
        else:
            if (flag):
                if check_move(mask, zero_pos, 1):
                    move(klotski, zero_pos, 1)
                else:
                    move(klotski, zero_pos, 2)
            else:
                if check_move(mask, zero_pos, 2):
                    move(klotski, zero_pos, 2)
                else:
                    move(klotski, zero_pos, 1)
    else:
        if zero_pos[1] == target[1]:
            if check_move(mask, zero_pos, 0):
                move(klotski, zero_pos, 0)
            elif check_move(mask, zero_pos, 3):
                move(klotski, zero_pos, 3)
            else:
                move(klotski, zero_pos, 2)
        elif zero_pos[1] < target[1]:
            if check_move(mask, zero_pos, 3):
                move(klotski, zero_pos, 3)
            else:
                move(klotski, zero_pos, 0)
        else:
            if check_move(mask, zero_pos, 2):
                move(klotski, zero_pos, 2)
            else:
                move(klotski, zero_pos, 0)
    matrices.append(klotski.copy())
    # write_gif(matrices)
    move_zero_to_target(klotski, mask, target, flag)

def shift_start_to_finish(klotski, mask, start, finish):
    start_pos = find_number(klotski, start)
    zero_target = None
    if start_pos[0] == start // 4:
        zero_target = (start_pos[0], start_pos[1] - 1)
    elif start_pos[1] == 3:
        zero_target = (start_pos[0] - 1, start_pos[1])
    elif start_pos[0] == 3:
        zero_target = (start_pos[0], start_pos[1] + 1)
    elif start_pos[1] == 0:
        zero_target = (start_pos[0] + 1, start_pos[1])
    move_zero_to_target(klotski, mask, zero_target)
    mask = np.zeros((4, 4))
    zero_pos = zero_target
    for _ in range(start, finish + 1):
        if (zero_pos[1] == 0):
            if (zero_pos[0] == start // 4):
                move(klotski, zero_pos, 3)
                mask[zero_pos[0]][zero_pos[1]] = 1
                zero_pos = (zero_pos[0], zero_pos[1] + 1)
            else:
                move(klotski, zero_pos, 0)
                mask[zero_pos[0]][zero_pos[1]] = 1
                zero_pos = (zero_pos[0] - 1, zero_pos[1])
        elif (zero_pos[0] == 3):
            move(klotski, zero_pos, 2)
            mask[zero_pos[0]][zero_pos[1]] = 1
            zero_pos = (zero_pos[0], zero_pos[1] - 1)
        elif (zero_pos[1] == 3):
            move(klotski, zero_pos, 1)
            mask[zero_pos[0]][zero_pos[1]] = 1
            zero_pos = (zero_pos[0] + 1, zero_pos[1])
        elif (zero_pos[0] == start // 4):
            move(klotski, zero_pos, 3)
            mask[zero_pos[0]][zero_pos[1]] = 1
            zero_pos = (zero_pos[0], zero_pos[1] + 1)
        matrices.append(klotski.copy())
    return mask

def rotate_13_14_15(klotski):
    move(klotski, (3, 1), 0)
    while klotski[3][1] != 15:
        move(klotski, (2, 1), 2)
        move(klotski, (2, 0), 1)
        move(klotski, (3, 0), 3)
        move(klotski, (3, 1), 0)


def solve(klotski):
    mask = np.zeros((4, 4))
    matrices.append(klotski.copy())
    for cnt in range(1, 11):
        target = (2, 0)
        while True:
            number_pos = find_number(klotski, cnt+1)
            if (target == number_pos):
                break
            mask[number_pos[0]][number_pos[1]] = 1
            move_zero_to_target(klotski, mask, target, (number_pos[1] == 0))
            mask[number_pos[0]][number_pos[1]] = 0
            move_zero_to_target(klotski, mask, number_pos)
        while True:
            number_pos = find_number(klotski, cnt)
            if (target == number_pos):
                break
            mask[number_pos[0]][number_pos[1]] = 1
            move_zero_to_target(klotski, mask, target, (number_pos[1] == 0))
            mask[number_pos[0]][number_pos[1]] = 0
            move_zero_to_target(klotski, mask, number_pos)
        mask[target[0]][target[1]] = 1
        mask = shift_start_to_finish(klotski, mask, 1, cnt)
    for cnt in range(11, 13):
        target = (2, 0)
        while True:
            number_pos = find_number(klotski, cnt)
            if (target == number_pos):
                break
            mask[number_pos[0]][number_pos[1]] = 1
            move_zero_to_target(klotski, mask, target, (number_pos[1] == 0))
            mask[number_pos[0]][number_pos[1]] = 0
            move_zero_to_target(klotski, mask, number_pos)
        mask[target[0]][target[1]] = 1
        mask = shift_start_to_finish(klotski, mask, 5, cnt)
    mask = shift_start_to_finish(klotski, mask, 5, 12)
    mask = shift_start_to_finish(klotski, mask, 9, 12)
    rotate_13_14_15(klotski)
    mask = shift_start_to_finish(klotski, mask, 9, 12)
    mask = shift_start_to_finish(klotski, mask, 9, 12)
            

def main():
    solve(klotski)
    write_gif(matrices)

if __name__ == "__main__":
    main()
    

