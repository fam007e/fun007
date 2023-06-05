import random
import math
import time
from multiprocessing import Pool

def M_PI(N):
    count = 0
    seed = int(time.time())
    random.seed(seed)
    
    for i in range(1, N+1):
        x = random.random()
        y = random.random()
        
        if math.sqrt(x*x + y*y) <= 1:
            count += 1
    
    return 4 * count / N

if __name__ == '__main__':
    num_cores = int(input("Number of cores for simulations: "))  # Number of CPU cores to use
    num_iterations = int(float(input("Number of iterations: ")))  # Total number of iterations
    
    # Divide the workload among the available cores
    workload = num_iterations // num_cores
    
    start_time = time.time()  # Start time
    
    with Pool(processes=num_cores) as pool:
        results = pool.map(M_PI, [workload] * num_cores)
    
    # Combine the results from different cores
    pi_estimate = sum(results) / num_cores
    
    end_time = time.time()  # End time
    elapsed_time = end_time - start_time  # Time taken in seconds
    
    print("Estimated Pi:", pi_estimate)
    print("Time taken:", elapsed_time, "seconds")
