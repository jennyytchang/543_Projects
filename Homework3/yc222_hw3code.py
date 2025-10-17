import numpy as np
import math

def f(x, y):
    return math.sin (x + y) + (x - y) ** 2 - 1.5 * x + 2.5 * y + 1

def df_dxy(x, y):
    dx = math.cos(x+y) + 2*(x-y) - 1.5
    dy = math.cos(x+y) - 2*(x-y) + 2.5
    return np.array([dx, dy]) 

def gd_optimize(a, lr=1.0, thr=1e-20, max_iters=10000):
    x, y = a
    lossPrev = f(x, y)
    for _ in range(max_iters):
        dx, dy = df_dxy(x, y)
        new_x = x - lr * dx
        new_y = y - lr * dy
        lossCur = f(new_x, new_y)

        if abs(lossCur - lossPrev) < thr:
            print(new_x, new_y)
            return

        if lossCur < lossPrev:
            lr *= 1.1
            x, y = new_x, new_y
            lossPrev = lossCur
        else:
            lr *= 0.5

        print(lossCur)

def hess_f(x, y):
    d2f_dx2 = -math.sin(x + y) + 2
    d2f_dy2 = -math.sin(x + y) + 2
    d2f_dxdy = -math.sin(x + y) - 2
    return np.array([[d2f_dx2, d2f_dxdy],
                     [d2f_dxdy, d2f_dy2]])

def nm_optimize(a, thr=1e-20, max_iters=10000):
    x, y = a
    lossPrev = f(x, y)

    for _ in range(max_iters):

        grad = df_dxy(x, y)
        hess = hess_f(x, y)

        hess_inv = np.linalg.inv(hess)
        step = hess_inv.dot(grad)

        new_x = x - step[0]
        new_y = y - step[1]
        lossCur = f(new_x, new_y)
    
        if abs(lossCur - lossPrev) < thr:
            print(new_x, new_y)
            return

        x, y = new_x, new_y
        lossPrev = lossCur

        print(lossCur)

a = [-0.5, -1.5]
print("==== Q1 gd_optimize ====")
q1Result = gd_optimize(a)

print("==== Q2 nm_optimize ====")
q2Result = nm_optimize(a)
