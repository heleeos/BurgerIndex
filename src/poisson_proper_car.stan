// poisson_proper_car.stan
data {
  int<lower = 1> n; // the number of obs.
  int<lower = 1> p; // dim of obs.
  matrix[n, p] X; // design matrix
  int<lower = 0> y[n]; // BMK_i
  vector[n] log_expected; // E_i
  matrix<lower = 0, upper = 1>[n, n] W; // adjacency matrix
}
transformed data{
  vector[n] zeros;
  matrix<lower = 0>[n, n] M; // M
  {
    vector[n] W_rowsums;
    for (i in 1:n) {
      W_rowsums[i] = sum(W[i, ]);
    }
    M = diag_matrix(W_rowsums);
  }
  zeros = rep_vector(0, n);
}
parameters {
  vector[p] beta;
  vector[n] epsilon;
  real<lower = 0> tau; // precision: sigma^2
  real<lower = 0, upper = 1> gamma;
}
transformed parameters {
  vector[n] log_theta; // log relative risk
  log_theta = X * beta + epsilon;
}
model {
  epsilon ~ multi_normal_prec(zeros, tau * (M - gamma * W));
  beta ~ normal(0, 0.1); // flat prior
  tau ~ gamma(0.1, 0.1); // flat prior
  gamma ~ uniform(0, 1); // uniform prior
  y ~ poisson_log(log_theta + log_expected); // y_i ~ pois()
}
generated quantities {
  vector[n] y_rep;
  for (i in 1:n) {
    y_rep[i] = poisson_log_rng(log_theta[i] + log_expected[i]);
    // recall: obs n is predicting obs n+1
  }
}
