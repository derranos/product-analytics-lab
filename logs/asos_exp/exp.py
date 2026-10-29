from pathlib import Path
from scipy.stats import norm
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
df = pd.read_parquet(
	Path(__file__).resolve().parents[2]
    / "data"
	/ "raw"
	/ "asos"
	/ "asos_digital_experiments_dataset.parquet"
)
mask = (df['variant_id'] == 2) & (df['experiment_id'] == '036afc') & (df['metric_id'] == 1)
df = df[mask]
print(df.head())
print(df.shape)
print(df.describe())

last_row = df.iloc[[-1], :]
print(f"count diff {last_row['count_c'] - last_row['count_t']}")
print(f"mean diff {last_row['mean_c'] - last_row['mean_t']}")
print(f"variance diff {last_row['variance_c'] - last_row['variance_t']}")

z_value = (last_row['mean_t'] - last_row['mean_c']) / ((last_row['variance_c'] / last_row['count_c']) + (last_row['variance_t'] / last_row['count_t'])) ** 0.5
print(f"z value {z_value}")
print(f"p value {norm.sf(abs(z_value)) * 2}")  

z_values = (df['mean_t'] - df['mean_c']) / ((df['variance_c'] / df['count_c']) + (df['variance_t'] / df['count_t'])) ** 0.5
p_values = norm.sf(abs(z_values)) * 2
sns.lineplot(data=df, x='time_since_start', y=p_values, label='P-value')
sns.lineplot(data=df, x='time_since_start', y=[0.05] * len(df), color='red', label='Significance level (0.05)')
sns.set(rc={'figure.figsize':(12, 6)})
plt.title('P-values over time for experiment 036afc, variant 2, metric 1')
plt.legend()
plt.show()

# доверительные интервалы
se_diff = (df['variance_t'] / df['count_t'] + df['variance_c'] / df['count_c']) ** 0.5
diff = df['mean_t'] - df['mean_c']
lower, upper = norm.interval(0.95, loc=diff, scale=se_diff)
sns.lineplot(data=df, x='time_since_start', y=lower, color='green', label='Lower CI')
sns.lineplot(data=df, x='time_since_start', y=upper, color='blue', label='Upper CI')
sns.set(rc={'figure.figsize':(12, 6)})
sns.lineplot(data=df, x='time_since_start', y=diff, color='black', label='Difference')
plt.title('95% Confidence Intervals for the difference in means over time')
plt.legend()
plt.show()