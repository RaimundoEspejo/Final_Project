# Libraries and Data Frame ----

#Load necessary libraries
library(readxl)
library(ggplot2)
library(gridExtra)
library(dplyr)
library(tidyr)
library(kableExtra)
library(broom)
library(brms)
library(lme4)
library(emmeans)
library(purrr)

# Get the data frame to work with using relative path
Data_Frame_Allele_Frequency <- read_excel("Data_Frame_Allele_Frequency.xlsx", sheet = "Table")

# Cochran-Armitage Trend test by Substrate ----
  # Since I have proportions of alternative alleles ("%AF"), I can apply the Cochran-Armitage trend test for each position and substrate (Eggs/Cells) combination to check if there's a significant trend over time.

# Create success and total columns based on %AF. Since %AF is a proportion, total will always be 1.
  # In here, I am preparing the data for the Cochran-Armitage Trend Test by creating two new columns, success and total.
  # The trend test typically works with counts, so setting total to 1 allows the proportion data (%AF) to be interpreted as a “count” relative to a single trial, avoiding the need for integer values.
Data_Frame_Allele_Frequency$success <- Data_Frame_Allele_Frequency$`%AF` # This assigns the values from the %AF column (which represents the proportion of the alternative allele) to a new column called success.Since %AF represents proportions, each entry in success is also a proportion (a decimal between 0 and 1) rather than an integer count.
Data_Frame_Allele_Frequency$total <- 1  # Total column creation. Since %AF is a proportion, total is set to 1 to represent it as a proportion out of 1.

# Apply Cochran-Armitage Trend Test for each Position and Substrate (I am not considering Isolates here)
  # This code applies the Cochran-Armitage Trend Test to analyze allele frequency trends over passages, grouped by Position_Genome and Passage_Substrate.
  # The trend test will determine if there is a statistically significant trend in allele frequencies across passages for each position and substrate.
  # The results are stored in results_trend_test, where each row contains a unique combination of Position_Genome and Passage_Substrate along with the associated trend test result stored in test_result.
results_trend_test <- Data_Frame_Allele_Frequency %>%
  group_by(Position_Genome, `Passage_Substrate`, `Isolate_ID`) %>% # This groups the data by Position_Genome, Passage_Substrate, and Isolate_ID. Each unique combination is treated as an individual group for analysis.
  summarise( # Creates a summary for each group considering what is below
    test_result = list(
      prop.trend.test(success * 100, rep(100, length(success)), score = `Passage_Number`)
    )
  )

# View the trend test results
results_trend_test # This table is huge. I need to obtain the important information out of it.

# Extract p-values and test statistics from the 'results_trend_test' data frame and create 2 new columns with that information so I can filter after. 
  # Results are stored in results_trend_test_summary.
results_trend_test_summary <- results_trend_test %>%
  mutate(
    p_value = sapply(test_result, function(x) x$p.value),
    statistic = sapply(test_result, function(x) x$statistic)
  )

# View the trend results summary with p-values and statistics
results_trend_test_summary # Now the 2 new columns are included. Still a huge table but now I can filter the important results.

# Filter positions where the p-value is less than or equal to 0.05 and store the results in results_trend_test_significant.
results_trend_test_significant <- results_trend_test_summary %>%
  filter(p_value <= 0.05)

# View the trend results significant positions
  # This final table is showing positions with a significant change in allele frequency over time.
results_trend_test_significant # Now I have just the 25 significant positions where a trend is present. 

# Interpretation p_value column:
  # In the context of the Cochran-Armitage Trend Test, the p_value column represents the probability that the observed trend in allele frequency over time (across passage numbers) could occur by random chance.
  # The p_value indicates whether this trend is statistically significant. A low p-value suggests that the trend is unlikely due to random variation and may instead reflect a genuine pattern of change over time.
  # Small p-value (e.g., ≤ 0.05): Suggests a statistically significant trend in allele frequency over time (either increasing or decreasing). For these positions, we can infer that changes in allele frequency are unlikely to be random.
  # Large p-value (e.g., > 0.05): Implies that any observed trend might just be due to random variation, and thus there’s no strong evidence of a consistent change in allele frequency over time.

# Interpretation Statistic column:
  # The statistic column provides the test statistic for each position tested in the Cochran-Armitage Trend Test.
  # The statistic indicates the strength and direction of the trend observed in allele frequency across the passage numbers (time points). 
  # It’s a numeric value calculated as part of the trend test to assess whether there’s a statistically significant increase or decrease in allele frequency over time.
  # A larger absolute value of the statistic (positive or negative) suggests a stronger trend in allele frequency over the time points.
  # A positive statistic usually indicates an upward trend, meaning the allele frequency is increasing over time.
  # A negative statistic suggests a downward trend, meaning the allele frequency is decreasing over time.

# From now on I am creating a table to visualize the data in a nicer way:
  # Add a column for significance that indicates "Yes" if the p-value is less than 0.05 and "No" if it is higher than 0.05.
results_trend_test_significant$Significant_Trend <- ifelse(results_trend_test_significant$p_value <= 0.05, "Yes", "No")

# Remove the test_result column because it is a mess to look at it. I don't need it.
results_trend_test_significant_clean <- results_trend_test_significant %>%
  select(-test_result)

# Sort the data frame by Position in ascending order 
results_trend_test_significant_clean <- results_trend_test_significant_clean %>%
  arrange(Position_Genome)

# Create the table with distinct row colors based on Passage Substrate
results_trend_test_significant_clean %>%
  kable("html", caption = "Trend Test Results for Significant Positions", align = "c") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"), full_width = F) %>%
  row_spec(
    which(results_trend_test_significant_clean$`Passage_Substrate` == "Cells"), 
    background = "#D9EAD3"  # Light green for Cells
  ) %>%
  row_spec(
    which(results_trend_test_significant_clean$`Passage_Substrate` == "Eggs"), 
    background = "#F9CB9C"  # Light orange for Eggs
  )

# Summarize Data for Trend Plot
trend_plot_data <- Data_Frame_Allele_Frequency %>%
  group_by(Passage_Substrate, Passage_Number) %>%
  summarise(
    mean_AF = mean(`%AF`, na.rm = TRUE),
    sd_AF = sd(`%AF`, na.rm = TRUE),
    .groups = "drop"
  )

# Create the Trend Plot
ggplot(trend_plot_data, aes(x = Passage_Number, y = mean_AF, color = Passage_Substrate, group = Passage_Substrate)) +
  geom_line(linewidth = 4) +
  labs(
    title = "Allele Frequency Trends by Passage Substrate",
    x = "Passage Number",
    y = "Mean Allele Frequency",
    color = "Passage Substrate"
  ) +
  scale_x_continuous(breaks = 1:7) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14),
    legend.position = "top"
  )

# Cochran-Armitage Trend test by Isolate ----
  # Apply Cochran-Armitage Trend Test for each Position, Substrate, and Isolate
  # In here, I am doing the same as before but I am including the Isolates separately to analyze them one by one.

# Trend Test Grouped by Isolate, Position, and Substrate
results_trend_test_by_Isolate <- Data_Frame_Allele_Frequency %>%
  group_by(Position_Genome, Passage_Substrate, Isolate_ID) %>%
  summarise(
    test_result = list(
      prop.trend.test(success * 100, rep(100, length(success)), score = Passage_Number)
    ),
    .groups = "drop"
  )

# Extract key results from trend test
results_summary_by_Isolate <- results_trend_test_by_Isolate %>%
  mutate(
    p_value = map_dbl(test_result, ~ .x$p.value),
    statistic = map_dbl(test_result, ~ .x$statistic)
  )

# Filter significant results
results_trend_test_significant_by_Isolate <- results_summary_by_Isolate %>%
  filter(p_value <= 0.05)

# Summarize data for trend plot
trend_plot_data_by_Isolate <- Data_Frame_Allele_Frequency %>%
  group_by(Isolate_ID, Passage_Substrate, Passage_Number) %>%
  summarise(
    mean_AF = mean(`%AF`, na.rm = TRUE),
    sd_AF = sd(`%AF`, na.rm = TRUE),
    .groups = "drop"
  )

# Create the trend plot
ggplot(trend_plot_data_by_Isolate, aes(x = Passage_Number, y = mean_AF, color = Passage_Substrate, group = Passage_Substrate)) +
  geom_line(size = 3) +
  facet_wrap(~Isolate_ID) +
  labs(
    title = "Allele Frequency Trends by Isolate and Passage Substrate",
    x = "Passage Number",
    y = "Mean Allele Frequency",
    color = "Passage Substrate"
  ) +
  scale_x_continuous(breaks = 1:7) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14),
    legend.position = "top"
  )

# Logistic Regression Model by Substrate ----
  # Since I want to model the percentage of the alternative allele ("%AF") as a function of the "Passage Number" (time) and potentially "Passage Substrate" (to account for differences between Eggs and Cells)
  
# Since "%AF" represents proportions, I need to convert it into a form suitable for logistic regression. 
  # Logistic regression models binary outcomes or proportions, so I can model the percentage of the alternative allele as the proportion of success (presence of the alternative allele) and failure (absence)
  # First, I need to create a "success" column (the number of alternative alleles) and a "failure" column (the remaining proportion).
  # The success column was already created in the trend test, but I am doing it again here.
Data_Frame_Allele_Frequency$success <- Data_Frame_Allele_Frequency$`%AF`  # Proportion of alternative allele
Data_Frame_Allele_Frequency$failure <- 1 - Data_Frame_Allele_Frequency$success  # Proportion of reference allele

# Convert Passage Substrate to a factor for logistic regression
Data_Frame_Allele_Frequency$`Passage_Substrate` <- as.factor(Data_Frame_Allele_Frequency$`Passage_Substrate`)

#  Fitting a logistic regression model using the glm() function, where I model the alternative allele frequency as a function of "Passage Number" and "Passage Substrate."
  # Since my data represents proportions (not true counts), I can fit the model with a quasibinomial family instead of binomial. The quasibinomial family accounts for over-dispersion and works with proportions.
logistic_model <- glm(cbind(success, failure) ~ `Passage_Number` * `Passage_Substrate`, 
                      data = Data_Frame_Allele_Frequency, 
                      family = quasibinomial)

# View summary of the quasibinomial model
  # The summary(logistic_model) output will show me the coefficients for "Passage Number" and "Passage Substrate" as well as their interaction.
summary(logistic_model) 


# Extract and format coefficients
# Extract and tidy the model coefficients
tidy_logistic_model <- broom::tidy(logistic_model)

# Add significance stars for interpretation
tidy_logistic_model <- tidy_logistic_model %>%
  mutate(Significance = case_when(
    p.value < 0.001 ~ "***",
    p.value < 0.01 ~ "**",
    p.value < 0.05 ~ "*",
    TRUE ~ ""
  ))

# Add an interpretation column with detailed explanations
tidy_logistic_model <- tidy_logistic_model %>%
  mutate(Interpretation = case_when(
    term == "(Intercept)" ~ "Baseline log-odds of success (%AF) in cells at passage 0. Significant at p<0.05",
    term == "Passage_Number" ~ "Passage number has a significant positive effect. For each additional passage, the odds of success (alternative allele presence) increase by about 43%.",
    term == "Passage_SubstrateEggs" ~ "Switching from Cells to Eggs significantly increases the odds of success by approximately 62.8% (exp(0.48751)).",
    term == "Passage_Number:Passage_SubstrateEggs" ~ "The interaction term is significant. The positive effect of passage number on success is weaker in eggs compared to cells.",
    TRUE ~ "N/A"
  ))

# Display the coefficients table with interpretation
tidy_logistic_model %>%
  select(term, estimate, std.error, statistic, p.value, Significance, Interpretation) %>%
  kable("html", caption = "Logistic Regression Model Coefficients with Interpretation", align = "c") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"), full_width = F)

# Model Summary
  # Dependent Variable: success (proportion of alternative alleles, %AF).
  #Independent Variables:
    # Passage_Number (continuous): Represents time or passage count.
    # Passage_Substrate (categorical: "Cells" vs. "Eggs").
    # Interaction term (Passage_Number:Passage_Substrate): Examines whether the effect of Passage_Number on success differs by substrate.

# Interpretations:
  # (Intercept): Baseline log-odds of observing the alternative allele (success) in cells at passage 0.
  # Passage_Number: Passage number significantly increases the odds of success by ~43% per passage.
  # Passage_SubstrateEggs: Switching from Cells to Eggs increases odds by ~62.8%.
  # Passage_Number: In Eggs, the increase in success across passages is weaker than in Cells.

# Get predicted probabilities for alternative allele frequency:
  # To visualize the predicted allele frequencies over time for each substrate, I can use the predict() function and plot the results
Data_Frame_Allele_Frequency$predicted_AF <- predict(logistic_model, type = "response")
Data_Frame_Allele_Frequency$successAF <- as.integer(round(100*Data_Frame_Allele_Frequency$Allele_Frequency, 0))
Data_Frame_Allele_Frequency$trialsAF <- 100

# Plot observed vs predicted allele frequencies over time for each Passage Substrate
ggplot(Data_Frame_Allele_Frequency, aes(x = `Passage_Number`, y = success, color = `Passage_Substrate`)) +
  geom_line(aes(y = predicted_AF), size = 3) +  # Increased line thickness
  scale_x_continuous(breaks = seq(min(Data_Frame_Allele_Frequency$Passage_Number), 
                                  max(Data_Frame_Allele_Frequency$Passage_Number), by = 1)) +  # X-axis with steps of 1
  labs(title = "Observed vs Predicted Alternative Allele Frequency Over Passages",  # Add a title
       y = "Alternative Allele Frequency", 
       x = "Passage Number") +
  theme_minimal()

# Define a function to run logistic regression. 
  # This function is designed to fit a logistic regression model to examine how Passage Number (time or passage) affects the probability of observing a "success" (e.g., an alternative allele) out of the total possible outcomes in each passage.
get_logistic_results <- function(data) {
  glm(cbind(success, total - success) ~ `Passage_Number`, data = data, family = quasibinomial)
}

# Filter for Cells and Eggs. 
  # This code splits the original data frame into two separate data frames based on the type of passage substrate (Cells or Eggs). Now I can analyze each subset individually:
cells_data <- Data_Frame_Allele_Frequency %>%
  filter(`Passage_Substrate` == "Cells")
eggs_data <- Data_Frame_Allele_Frequency %>%
  filter(`Passage_Substrate` == "Eggs")

# Perform logistic regression for Cells and Eggs separately 
  # The purpose of this code is to generate separate logistic regression models for each substrate type—"Cells" and "Eggs." 
  # This allows me to examine the relationship between Passage Number (or another predictor) and the success rate (in this case, the %AF or alternative allele frequency) independently for each type of passage substrate.
cells_results <- get_logistic_results(cells_data)
eggs_results <- get_logistic_results(eggs_data)

# I can then use summary(of the logistic results) to see details such as the coefficients and significance of Passage Number.
  # This can be useful for comparing how Passage Number affects allele frequency differently in Cells versus Eggs and for assessing the strength of the logistic models’ fit.  
  # These summaries provide insights into:
    # The significance of predictors (e.g., whether Passage Number significantly influences the allele frequency),
    # The fit of each model for Cells and Eggs,
    # How well each model explains variation in allele frequency over time.
summary(cells_results)
summary(eggs_results)

# The exp() function calculates the exponential (or antilogarithm) of a number. 
  # In logistic regression, exponentiation the estimated coefficients converts them from log-odds to odds ratios, which are more intuitive for interpretation.
  # Using odds ratios makes it easier to interpret the effect size of each predictor directly in terms of the change in odds.
exp(0.05750) # exp(0.05750) ≈ 1.0592: This indicates that a one-unit increase in the predictor (e.g., Passage Number) increases the odds of observing the alternative allele by about 5.9%.
exp(0.86863) # exp(0.86863) ≈ 2.3835: Here, a one-unit increase in the predictor increases the odds by about 138.4%, suggesting a stronger relationship.

# Logistic Regression Model by Isolate ----

# Scale success and failure to integer counts
Data_Frame_Allele_Frequency <- Data_Frame_Allele_Frequency %>%
  mutate(success_counts = round(success * 100),  # Convert success to integer counts
         failure_counts = round(failure * 100))  # Convert failure to integer counts

# Fit a GLMM model with Isolate_ID as a random effect
glmm_model_by_Isolate <- glmer(
  cbind(success_counts, failure_counts) ~ `Passage_Number` * `Passage_Substrate` + (1 | Isolate_ID),
  data = Data_Frame_Allele_Frequency,
  family = binomial(link = "logit")
)

# View the summary of the GLMM model
summary(glmm_model_by_Isolate)

# Get predicted probabilities for alternative allele frequency
Data_Frame_Allele_Frequency$predicted_AF_by_Isolate <- predict(glmm_model_by_Isolate, type = "response")

# Plot observed vs predicted allele frequencies over time for each Passage Substrate
ggplot(Data_Frame_Allele_Frequency, aes(x = `Passage_Number`, y = success, color = `Passage_Substrate`)) +
  geom_line(aes(y = predicted_AF_by_Isolate), size = 1.5) +  # Predicted trends
  facet_wrap(~Isolate_ID) +  # Create separate panels for each isolate
  scale_x_continuous(breaks = seq(min(Data_Frame_Allele_Frequency$Passage_Number), 
                                  max(Data_Frame_Allele_Frequency$Passage_Number), by = 1)) +  # X-axis for all passages
  labs(title = "Observed vs Predicted Alternative Allele Frequency Over Passages by Isolate",
       y = "Alternative Allele Frequency",
       x = "Passage Number") +
  theme_minimal()

# Bayesian Logistic Regression Model by Substrate ----
# Using the brms package to fit a Bayesian logistic regression model.
  # This function allows to run the same logistic regression setup on different subsets of data, automating the process of generating Bayesian regression results for each subset. 
  # The Bayesian framework provides additional flexibility and interpretive insights over traditional logistic regression by providing credible intervals and posterior distributions for each parameter.
get_brms_results <- function(data) {
  brm(
    successAF | trials(trialsAF) ~ Viral_Load_SQ * Passage_Number, 
    data = data, 
    family = binomial())
}

# Applying the function get_brms_results() to cells_data and eggs_data, and gets a Bayesian model for each. 
  # These models are stored in cells_results_bayesian and eggs_results_bayesian.
cells_results_bayesian <- get_brms_results(cells_data)
eggs_results_bayesian <- get_brms_results(eggs_data)

# Interpretation: 
  # Each of these results contains a fitted Bayesian logistic regression model for the "Cells" and "Eggs" subsets, respectively.
  # Posterior Distributions: 
    # Since brms performs Bayesian inference, it returns posterior distributions for model parameters instead of just point estimates.
    # I can summarize, plot, or examine the posterior distributions to understand the estimated effects of Passage on success for both "Cells" and "Eggs".
    # Advantages: 
      # Uncertainty Quantification: brms provides full posterior distributions, allowing a deeper understanding of the uncertainty around parameter estimates.
      # Flexibility: brms can handle complex models with additional hierarchical structures, non-standard distributions, and more.

# Summarize to interpret the results. These summaries will provide the posterior mean, standard error, credible intervals, and other details on each predictor.
summary(cells_results_bayesian)
summary(eggs_results_bayesian)

# Interpretation for cells:
  # Baseline (Intercept): The low intercept indicates that the probability of observing the alternative allele is very low when viral load and passage number are at their baseline values.
  # Viral Load (Viral_Load_SQ): Viral load has a positive impact on the odds of success. Higher viral load is associated with an increased probability of observing the alternative allele, likely reflecting greater viral replication success in the substrate.
  # Passage Number: Passage number has a strong positive effect, showing that the likelihood of observing the alternative allele increases significantly over time.
  # Interaction (Viral Load × Passage Number): The negative interaction indicates that while both predictors independently increase success, the combined effect is slightly less than the sum of their individual contributions. This suggests diminishing returns: as viral load and passage number increase, their synergistic effect weakens.

# Interpretation for eggs:
  # Baseline (Intercept): The baseline log-odds of observing the alternative allele are very low when both viral load and passage number are at their minimum values.
  # Viral Load (Viral_Load_SQ): Viral load has a strong positive effect on the probability of observing the alternative allele. Higher viral load significantly increases the odds of success.
  # Passage Number: Passage number also has a positive effect but with a smaller magnitude compared to viral load. Over time, the likelihood of observing the alternative allele increases moderately.
  # Interaction (Viral Load × Passage Number): The negative interaction term indicates that as both viral load and passage number increase, their combined effect diminishes slightly. This suggests diminishing returns where high viral load reduces the additional impact of more passages on success.

# Plot to interpret the results. The plots generates diagnostic plots for the Bayesian model.
plot(cells_results_bayesian)
plot(eggs_results_bayesian)

# Interpreting Each Plot
  # Trace and Density Plots Together: These can help you assess the reliability of your parameter estimates by showing you the stability and spread of each parameter.
  # R-hat and Autocorrelation: These diagnostics provide information on model convergence and the independence of the samples.

# Extract posterior samples as a data frame:
  # This code is using Bayesian analysis diagnostics to interpret the posterior distributions of the slope parameter (b_Passage_Number) from two separate Bayesian logistic regression models, one for "Cells" and one for "Eggs". 
  # The posterior_samples function extracts the samples for each parameter from the posterior distribution, allowing for a direct comparison between models.
post_cells <- as_draws_df(cells_results_bayesian)
post_eggs <- as_draws_df(eggs_results_bayesian)

# Plot the posterior distribution for cells 
ggplot(post_cells, aes(x = b_Passage_Number)) +
  geom_density(fill = "blue", alpha = 0.5) +
  labs(title = "Posterior Distribution of Passage Number Effect",
       x = "Estimate",
       y = "Density") +
  theme_minimal()

# Plot the posterior distribution for eggs
ggplot(post_eggs, aes(x = b_Passage_Number)) +
  geom_density(fill = "blue", alpha = 0.5) +
  labs(title = "Posterior Distribution of Passage Number Effect",
       x = "Estimate",
       y = "Density") +
  theme_minimal()

# Calculate the Difference in Slopes:
  # Here, diff is calculated as the difference between the posterior distributions of the slope (or coefficient) for "Passage Number" in cells versus eggs. This difference represents how much the slope varies between the two substrates.
diff <- post_cells$b_Passage_Number - post_eggs$b_Passage_Number
hist(diff)

# Calculate the p-value:
  # The p_val represents the proportion of the posterior samples in which the difference is less than 0. 
  # This can be interpreted as the posterior probability that the slope for "Cells" is less than that for "Eggs".
p_val <- mean(diff < 0)

# Prepare Data for Plotting:
  # This creates a combined data frame with both b_Passage_Number posterior samples, labeling each sample as either from "Cells" or "Eggs".
df.bay <- data.frame(y = c(post_cells$`b_Viral_Load_SQ:Passage_Number`, post_eggs$`b_Viral_Load_SQ:Passage_Number`),
                     Slope = c(rep("Cells", length(post_cells$b_Passage_Number)),
                            rep("Eggs", length(post_eggs$b_Passage_Number)) ))

# Plot the Distribution of Slopes:
  # This plot shows the distributions of the b_Passage_Number slopes for each substrate, allowing you to visually compare how the passage number’s effect on the log-odds differs between cells and eggs.
ggplot(data = df.bay, aes(x = y, color = Slope)) +
  geom_histogram() + labs(x = "Distribution of log-odds of change") +
  theme_bw()

# Bayesian Logistic Regression Model by Isolate ----

# Define a function to fit a Bayesian logistic regression model for each isolate
get_brms_results_by_isolate <- function(data) {
  brm(
    successAF | trials(trialsAF) ~ Viral_Load_SQ * Passage_Number,
    data = data,
    family = binomial(),
    seed = 347,
    iter = 10000
  )
}

# Fit models separately for each isolate and substrate
bayesian_models_by_isolate <- Data_Frame_Allele_Frequency %>%
  group_by(Isolate_ID, Passage_Substrate) %>%
  group_map(~ get_brms_results_by_isolate(.x), .keep = TRUE)

# Naming models for better reference
names(bayesian_models_by_isolate) <- Data_Frame_Allele_Frequency %>%
  distinct(Isolate_ID) %>%
  mutate(model_name = paste(Isolate_ID, sep = "_")) %>%
  pull(model_name)

# Extract posterior samples for Passage_Number coefficient from each model
posterior_samples_list <- lapply(bayesian_models_by_isolate, function(model) {
  as_draws_df(model, pars = "b_Passage_Number")
})

# Combine samples into a single data frame for plotting
df_posteriors <- bind_rows(
  lapply(names(posterior_samples_list), function(name) {
    if ("b_Passage_Number" %in% colnames(posterior_samples_list[[name]])) {
      data.frame(
        Isolate_ID = name,
        Slope = posterior_samples_list[[name]]$b_Passage_Number
      )
    } else {
      NULL  # Skip models without b_Passage_Number
    }
  }),
  .id = "Model"
)


# Plot Posterior Distributions for Each Isolate
ggplot(df_posteriors, aes(x = Slope, fill = Passage_Substrate)) +
  geom_density(alpha = 0.6) +
  facet_wrap(~Isolate_ID, scales = "free") +  # Separate panels for each isolate-substrate combination
  labs(
    title = "Posterior Distributions of Passage Number Slopes by Isolate and Substrate",
    x = "Slope (Passage Number Effect)",
    y = "Density"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14))

# Viral Load analysis - Mixed Effects Linear Model ----
# Using mixed effects to examine the relationship between specific genome positions with mutations and the viral load over passages.
  # This approach will allow us to assess the impact of specific mutations (via allele frequencies) on viral load while accounting for repeated measures across passages.
  # Use lme4 to fit a mixed model where viral load (Viral_Load_SQ) is the outcome variable.
  # Include fixed effects for allele frequency (mutation presence as %AF), passage number, and substrate, with passage number modeled as a random effect to account for repeated measurements.

# Fit the linear mixed model
viral_linear_mixed_model <- lmer(Viral_Load_SQ ~ `Passage_Number` * `%AF` * `Passage_Substrate` + 
                      (1 | Isolate_ID), data = Data_Frame_Allele_Frequency)

# Summary of the linear mixed model
summary(viral_linear_mixed_model)

# Interpretation: 
  # Look for significant fixed effects related to allele frequency, which would suggest that specific mutations are associated with changes in viral load.
  # Results: 
    # a. Passage number and allele frequency both tend to reduce viral load overall.
    # b. Eggs have higher viral load compared to cells, and this effect varies with passage number and allele frequency.
    # c. The significant interaction terms reveal that the relationship between passage, allele frequency, and viral load is nuanced, with adaptation differences between eggs and cells.
    # d. These results suggest that mutations in viral alleles and adaptation over passages influence viral load differently depending on the substrate, with eggs potentially supporting more stable or adaptable viral replication over time.

# Next step should be examine significant predictors: 
  # The interaction between passage number, substrate, and allele frequency.
  # Also, a Post hoc testing to explore how viral load changes with specific mutations

# Perform post hoc analysis
posthoc_results <- emmeans(viral_linear_mixed_model, ~ Passage_Number | `%AF` * `Passage_Substrate`)

# Summary of the post hoc analysis
  # The summary output will show the estimated marginal means of viral load at each passage number, along with confidence intervals and p_values. 
  # These values allow us to interpret which passage numbers significantly differ in viral load within each combination of allele frequency and substrate.
summary(posthoc_results)

# Results:
  # Higher Viral Load in Eggs: 
    # For %AF = 0.793 at passage number 4.76, eggs show a higher viral load (mean 9.66) compared to cells (mean 7.40). 
    # The confidence intervals do not overlap significantly, suggesting that viral replication may be more successful in eggs than in cells at this passage number and allele frequency.
  # Significance of Passage Substrate: 
    # This difference aligns with previous findings showing that the passage substrate significantly impacts viral load, with eggs generally supporting a higher load. 
    # This could indicate that eggs are a more favorable environment for viral replication under these conditions.

# Plots for Viral Load ----
  # These visualizations will support interpreting trends and interactions from the linear mixed-effects model.
  # Leverages the full range of %AF for more nuanced visualization.

# Plot continuous %AF with lines for substrate
  # Each row shows Cells and Eggs with distinct trends.
  # A clear color gradient legend for %AF explains line and point colors.

ggplot(Data_Frame_Allele_Frequency, aes(x = `Passage_Number`, y = Viral_Load_SQ, color = `%AF`)) +
  geom_line(size = 1.2) +  # Line varies by color
  geom_point(size = 2) +   # Points with color gradient
  facet_grid(Passage_Substrate ~ Isolate_ID) +  # Separate panels for Substrate and Isolate
  scale_color_gradient(low = "blue", high = "red") +  # Gradient color for %AF
  labs(
    title = "Viral Load over Passages by Allele Frequency and Substrate",
    x = "Passage Number",
    y = "Viral Load (Log Scale)",
    color = "Allele Frequency (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    legend.position = "top"
  )

# Plot for Viral Load and Allele Frequency
# Prepare data with a 'Variable' column for color mapping
Data_Frame_Allele_Frequency_long <- Data_Frame_Allele_Frequency %>%
  pivot_longer(
    cols = c(Viral_Load_SQ, Allele_Frequency),
    names_to = "Variable",
    values_to = "Value"
  ) %>%
  mutate(
    Value = ifelse(Variable == "Allele_Frequency", Value * 12, Value),
    Variable = recode(Variable, "Viral_Load_SQ" = "Viral Load", "Allele_Frequency" = "Allele Frequency")
  )

# Plot with no title in the legend
ggplot(Data_Frame_Allele_Frequency_long, aes(x = `Passage_Number`, y = Value, color = Variable)) +
  geom_smooth(aes(group = Variable), size = 2, method = "lm", formula = y ~ splines::bs(x, 3), se = F) +
  scale_y_continuous(
    name = "Viral Load",
    sec.axis = sec_axis(~ . * (1 / 12), name = "Allele Frequency (%)")
  ) +
  facet_grid(Passage_Substrate ~ Isolate_ID) +
  labs(
    title = "Trends in Viral Load and Allele Frequency Across Passages",
    x = "Passage Number"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14),
    legend.title = element_blank(),  # Removes the legend title
    legend.position = "top"
  )

  # Plot continuous %AF for each substrate
ggplot(Data_Frame_Allele_Frequency, aes(x = `Passage_Number`, y = Viral_Load_SQ, color = `%AF`)) +
  geom_line(size = 1.2) +
  geom_point(size = 2) +
  facet_wrap(~Passage_Substrate) +  # Panel per substrate
  scale_color_gradient(low = "blue", high = "red") +
  labs(title = "Viral Load over Passages by Continuous Allele Frequency (by Substrate)",
       x = "Passage Number",
       y = "Viral Load (Log Scale)",
       color = "Allele Frequency (%)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

