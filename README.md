# Final_Project
## Final project for 2025 Principles and Techniques of Reproducible Science

Four different viral isolates underwent seven serial passages in two distinct substrates: chicken embryonated eggs and Vero cells. After each passage, viral load was determined by quantifying the relative amount of viral RNA per sample. Whole genome sequencing was conducted using the Illumina platform. To identify specific genomic positions exhibiting evolutionary changes during passaging, allele frequencies were analyzed using a trend test. Viral loads were analyzed using linear mixed model.

## Documents included in this repository:

- Data_Frame_Allele_Frequency.xlsx --> Data frame used for the analysis
- Final_Project.Rmd --> R scrypt used for the analysis
- Final_Project_files --> Folder containing the figures

## Details and specifics of the pipeline:

### Trend test

Since I have proportions of alternative alleles ("%AF"), I can apply the Cochran-Armitage trend test for each position and substrate (Eggs/Cells) combination to check if there's a significant trend over time.

Create success and total columns based on %AF. Since %AF is a proportion, total will always be 1. In here, I am preparing the data for the Cochran-Armitage Trend Test by creating two new columns, success and total.
The trend test typically works with counts, so setting total to 1 allows the proportion data (%AF) to be interpreted as a “count” relative to a single trial, avoiding the need for integer values.
  
### Trend test for each position and substrate 

This code applies the Cochran-Armitage Trend Test to analyze allele frequency trends over passages, grouped by Position_Genome and Passage_Substrate. I am not considering viral Isolates here.

The trend test will determine if there is a statistically significant trend in allele frequencies across passages for each position and substrate. The results are stored in results_trend_test, where each row contains a unique combination of Position_Genome and Passage_Substrate along with the associated trend test result stored in test_result.

Extract p-values and test statistics from the 'results_trend_test' data frame and create 2 new columns with that information so I can filter after. Results are stored in results_trend_test_summary.

Filter positions where the p-value is less than or equal to 0.05 and store the results in results_trend_test_significant.

### Interpretation p_value column

In the context of the Cochran-Armitage Trend Test, the p_value column represents the probability that the observed trend in allele frequency over time (across passage numbers) could occur by random chance. The p_value indicates whether this trend is statistically significant. A low p-value suggests that the trend is unlikely due to random variation and may instead reflect a genuine pattern of change over time:

- Small p-value (e.g., ≤ 0.05): Suggests a statistically significant trend in allele frequency over time (either increasing or decreasing). For these positions, we can infer that changes in allele frequency are unlikely to be random.
- Large p-value (e.g., > 0.05): Implies that any observed trend might just be due to random variation, and thus there’s no strong evidence of a consistent change in allele frequency over time.

### Interpretation statistic column

The statistic column provides the test statistic for each position tested in the Cochran-Armitage Trend Test. The statistic indicates the strength and direction of the trend observed in allele frequency across the passage numbers (time points). It’s a numeric value calculated as part of the trend test to assess whether there’s a statistically significant increase or decrease in allele frequency over time:

- A larger absolute value of the statistic (positive or negative) suggests a stronger trend in allele frequency over the time points.
- A positive statistic usually indicates an upward trend, meaning the allele frequency is increasing over time.
- A negative statistic suggests a downward trend, meaning the allele frequency is decreasing over time.

### Creating a table to visualize the data

Add a column for significance that indicates "Yes" if the p-value is less than 0.05 and "No" if it is higher than 0.05.

Remove the test_result column because it is a mess to look at it. I don't need it.

Sort the data frame by Position in ascending order.

Create the table with distinct row colors based on Passage Substrate.

### Creating a plot to visualize the data

Summarize Data for Trend Plot.

Create the Trend Plot.

### Trend test by isolate

Apply Cochran-Armitage Trend Test for each Position, Substrate, and Isolate
In here, I am doing the same as before but I am including the Isolates separately to analyze them one by one.

Trend Test Grouped by Isolate, Position, and Substrate.

Extract key results from trend test.

Filter significant results.

Summarize data for trend plot.

Create the trend plot.

## Logistic regression model 

### Logistic regression model by substrate

Since I want to model the percentage of the alternative allele ("%AF") as a function of the "Passage Number" (time) and potentially "Passage Substrate" (to account for differences between Eggs and Cells). Since "%AF" represents proportions, I need to convert it into a form suitable for logistic regression. 

Logistic regression models binary outcomes or proportions, so I can model the percentage of the alternative allele as the proportion of success (presence of the alternative allele) and failure (absence)

First, I need to create a "success" column (the number of alternative alleles) and a "failure" column (the remaining proportion). The success column was already created in the trend test, but I am doing it again here.

Convert Passage Substrate to a factor for logistic regression.

Fitting a logistic regression model using the glm() function, where I model the alternative allele frequency as a function of "Passage Number" and "Passage Substrate." Since my data represents proportions (not true counts), I can fit the model with a quasibinomial family instead of binomial. The quasibinomial family accounts for over-dispersion and works with proportions.

### Extract and format coefficients

Extract and tidy the model coefficients.

Add significance stars for interpretation.

Add an interpretation column with detailed explanations.

Display the coefficients table with interpretation.

### Model Summary

- Dependent Variable: success (proportion of alternative alleles, %AF).
- Independent Variables:
  - Passage_Number (continuous): Represents time or passage count.
  - Passage_Substrate (categorical: "Cells" vs. "Eggs").
  - Interaction term (Passage_Number:Passage_Substrate): Examines whether the effect of Passage_Number on success differs by substrate.

### Interpretations

- (Intercept): Baseline log-odds of observing the alternative allele (success) in cells at passage 0.
- Passage_Number: Passage number significantly increases the odds of success by ~43% per passage.
- Passage_SubstrateEggs: Switching from Cells to Eggs increases odds by ~62.8%.
- Passage_Number: In Eggs, the increase in success across passages is weaker than in Cells.

### Get predicted probabilities for alternative allele frequency

To visualize the predicted allele frequencies over time for each substrate, I can use the predict() function and plot the results.

Plot observed vs predicted allele frequencies over time for each Passage Substrate.

### Define a function to run logistic regression 

This function is designed to fit a logistic regression model to examine how Passage Number (time or passage) affects the probability of observing a "success" (e.g., an alternative allele) out of the total possible outcomes in each passage.

Filter for Cells and Eggs. This code splits the original data frame into two separate data frames based on the type of passage substrate (Cells or Eggs). Now I can analyze each subset individually.

### Perform logistic regression for cells and eggs separately 

The purpose of this code is to generate separate logistic regression models for each substrate type—"Cells" and "Eggs." This allows me to examine the relationship between Passage Number (or another predictor) and the success rate (in this case, the %AF or alternative allele frequency) independently for each type of passage substrate.

I can then use summary(of the logistic results) to see details such as the coefficients and significance of Passage Number. This can be useful for comparing how Passage Number affects allele frequency differently in Cells versus Eggs and for assessing the strength of the logistic models’ fit. These summaries provide insights into:

- The significance of predictors (e.g., whether Passage Number significantly influences the allele frequency),
- The fit of each model for Cells and Eggs,
- How well each model explains variation in allele frequency over time.

The exp() function calculates the exponential (or antilogarithm) of a number.  In logistic regression, exponentiation the estimated coefficients converts them from log-odds to odds ratios, which are more intuitive for interpretation. Using odds ratios makes it easier to interpret the effect size of each predictor directly in terms of the change in odds:

- exp(0.05750) # exp(0.05750) ≈ 1.0592: This indicates that a one-unit increase in the predictor (e.g., Passage Number) increases the odds of observing the alternative allele by about 5.9%.
- exp(0.86863) # exp(0.86863) ≈ 2.3835: Here, a one-unit increase in the predictor increases the odds by about 138.4%, suggesting a stronger relationship.

### Logistic regression model by isolate

Scale success and failure to integer counts.

Fit a GLMM model with Isolate_ID as a random effect.

Get predicted probabilities for alternative allele frequency.

Plot observed vs predicted allele frequencies over time for each Passage Substrate.

## Viral load analysis 

### Mixed effects linear model for viral load

Using mixed effects to examine the relationship between specific genome positions with mutations and the viral load over passages. This approach will allow us to assess the impact of specific mutations (via allele frequencies) on viral load while accounting for repeated measures across passages. 

Use lme4 to fit a mixed model where viral load (Viral_Load_SQ) is the outcome variable. Include fixed effects for allele frequency (mutation presence as %AF), passage number, and substrate, with passage number modeled as a random effect to account for repeated measurements.

Fit the linear mixed model.

### Interpretation 

Look for significant fixed effects related to allele frequency, which would suggest that specific mutations are associated with changes in viral load.

Results: 

a. Passage number and allele frequency both tend to reduce viral load overall.
b. Eggs have higher viral load compared to cells, and this effect varies with passage number and allele frequency.
c. The significant interaction terms reveal that the relationship between passage, allele frequency, and viral load is nuanced, with adaptation differences between eggs and cells.
d. These results suggest that mutations in viral alleles and adaptation over passages influence viral load differently depending on the substrate, with eggs potentially supporting more stable or adaptable viral replication over time.

Next step should be examine significant predictors. The interaction between passage number, substrate, and allele frequency. Also, a Post hoc testing to explore how viral load changes with specific mutations

Perform post hoc analysis. The summary output will show the estimated marginal means of viral load at each passage number, along with confidence intervals and p_values. These values allow us to interpret which passage numbers significantly differ in viral load within each combination of allele frequency and substrate.

### Results

- Higher Viral Load in Eggs: 
  - For %AF = 0.793 at passage number 4.76, eggs show a higher viral load (mean 9.66) compared to cells (mean 7.40). 
  - The confidence intervals do not overlap significantly, suggesting that viral replication may be more successful in eggs than in cells at this passage number and allele frequency.
    
- Significance of Passage Substrate: 
  - This difference aligns with previous findings showing that the passage substrate significantly impacts viral load, with eggs generally supporting a higher load. 
  - This could indicate that eggs are a more favorable environment for viral replication under these conditions.

### Other plots for viral load

These visualizations will support interpreting trends and interactions from the linear mixed-effects model. Leverages the full range of %AF for more nuanced visualization.

Plot continuous %AF with lines for substrate. Each row shows Cells and Eggs with distinct trends. A clear color gradient legend for %AF explains line and point colors.

Plot for Viral Load and Allele Frequency. Prepare data with a 'Variable' column for color mapping.

Plot with no title in the legend.

<<<<<<< HEAD
Plot continuous %AF for each substrate.
=======
Plot continuous %AF for each substrate.
>>>>>>> 34d05aca7b2ed56dc454a986b019be8dc264efc1
