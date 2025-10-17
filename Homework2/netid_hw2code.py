import math
import numpy as np
from scipy.stats import invgamma

# Load the data and put it in a dictionary.
all_data = {}
with open('data.txt', 'r') as data:
    for line in data:
        vals = [float(x) for x in line.split()]
        all_data[int(vals[0])] = (vals[1], vals[2])

# Parameters on the prior for m.
mu_zero_m = 5.0
sigma_zero_m = 10.0

# Parameters on the prior for c.
mu_zero_c = 50.0
sigma_zero_c = 100.0

# Parameters on the prior for sigma^2.
alpha = 10.0
beta = 1.0

# Initial estimates for the three model parameters.
m = 20.0
c = 50.0
sigma = 200.0


# Write this for 1a).
def sample_sigma():
    """Placeholder for sampling sigma."""
    # Prior: sigma^2 ~ InvGamma(alpha, beta)
    # Posterior:  InvGamma(alpha + n/2, beta + 0.5 * SSE)

    # wiki: https://en.wikipedia.org/wiki/Conjugate_prior
    # Likelihood: Normal with known mean μ
    # Conjugate prior (and posterior) distribution: InvGamma
    # Prior hyperparameters Θ: a, b

    global m, c, alpha, beta

    # x for weight, y for hedight
    x = np.array([tmp[0] for tmp in all_data.values()])
    y = np.array([tmp[1] for tmp in all_data.values()])
    n = x.size

    # Residual sum of squares under current m, c
    residuals = y - (m * x + c)
    SSE = np.dot(residuals, residuals)

    # Posterior hyperparameters
    alpha_post = alpha + n / 2.0
    beta_post  = beta  + 0.5 * SSE

    # Draw one sample of sigma^2 from the posterior
    sigma_sq = invgamma.rvs(a=alpha_post, scale=beta_post)

    # Return sigma (std dev) to match the assignment’s expected numbers
    return np.sqrt(sigma_sq)

# Write this for 1b).
def sample_c():
    """Placeholder for sampling c."""
    # Prior: c ~ Normal(mu_zero_c, sigma_zero_c^2)
    # Likelihood: y_i - m*x_i ~ Normal(c, sigma^2)
    # Posterior: c | data ~ Normal(mu_post, sigma_post^2)

    # wiki
    # Likelihood: Normal with known variance σ2
    # Conjugate prior (and posterior) distribution: Normal
    # Prior hyperparameters m, sigma2

    global m, sigma, mu_zero_c, sigma_zero_c

    # Convert data to NumPy arrays
    x = np.array([tmp[0] for tmp in all_data.values()])
    y = np.array([tmp[1] for tmp in all_data.values()])
    n = x.size

    # Compute observed weight differences
    y_minus_mx = y - m * x

    # Compute posterior variance
    sigma_sq = sigma ** 2
    sigma_post_sq = 1 / (1 / sigma_zero_c**2 + n / sigma_sq)

    # Compute posterior mean
    mu_post = sigma_post_sq * (mu_zero_c / sigma_zero_c**2 + np.sum(y_minus_mx) / sigma_sq)

    # Sample one value from the posterior Normal distribution
    c_sample = np.random.normal(mu_post, np.sqrt(sigma_post_sq))

    return c_sample

# Write this for 1c).
def sample_m():
    """Placeholder for sampling m."""
    # Prior: m ~ Normal(mu_zero_m, sigma_zero_m^2)
    # Likelihood: y_i ~ Normal(m*x_i + c, sigma^2)
    # Posterior: m | data ~ Normal(mu_post, sigma_post^2)

    global c, sigma, mu_zero_m, sigma_zero_m

    # Convert data dictionary to NumPy arrays
    x = np.array([tmp[0] for tmp in all_data.values()])
    y = np.array([tmp[1] for tmp in all_data.values()])
    n = x.size

    sigma_sq = sigma ** 2

    # Posterior variance
    sigma_post_sq = 1 / (1 / sigma_zero_m**2 + np.sum(x**2) / sigma_sq)

    # Posterior mean
    mu_post = sigma_post_sq * (mu_zero_m / sigma_zero_m**2 + np.sum(x * (y - c)) / sigma_sq)

    # Sample one value from the posterior Normal
    m_sample = np.random.normal(mu_post, np.sqrt(sigma_post_sq))

    return m_sample

def get_error():
    """This computes the error of the current model."""
    error = 0.0
    count = 0
    for x in all_data:
        y = all_data[x]
        residual = c + y[0] * m - y[1]
        error += residual ** 2
        count += 1
    return error / count

def main():
    
    
    print("==== 1a) Sample sigma ====")
    for _ in range(10):
        print(sample_sigma())

    print("==== 1b) Sample c ====")
    for _ in range(10):
        print(sample_c())

    print("==== 1c) Sample m ====")
    for _ in range(10):
        print(sample_m())


    # For part 2, you run 1000 iterations of a Gibbs sampler.
    # global sigma, m, c
    # for _ in range(1000):
    #     print(get_error())
    #     sigma = sample_sigma()
    #     m = sample_m()
    #     c = sample_c()

    # print("Final model: m = {}, c = {}, sigma = {}".format(m, c, sigma))

        
if __name__ == "__main__":
    main()