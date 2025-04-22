import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import glob
import os

# Setup directories
base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../"))
data_dir = os.path.join(base_dir, "processed")
output_dir = os.path.join(base_dir, "insight_outputs")
os.makedirs(output_dir, exist_ok=True)

# Load all processed CSVs
all_files = sorted(glob.glob(os.path.join(data_dir, "*.csv")))
df_list = []

for file in all_files:
    try:
        df = pd.read_csv(file, dtype=str, usecols=[
            "CALENDAR_DATE", "ROUTE", "DIRECTION", "TRIP_POINT", "TIMETABLE_HOUR_BAND",
            "TIMETABLE_TIME", "ACTUAL_TIME", "SUBURB", "LATITUDE", "LONGITUDE",
            "CAPACITY_BUCKET_ENCODED"
        ])
        df_list.append(df)
    except Exception as e:
        print(f"Error reading {file}: {e}")

if not df_list:
    raise ValueError("No CSV files found in processed folder.")

df = pd.concat(df_list, ignore_index=True)
df["CAPACITY_BUCKET_ENCODED"] = pd.to_numeric(df["CAPACITY_BUCKET_ENCODED"], errors="coerce")

# ---------------------------------------
# 1. Average Crowd Level by Route
# ---------------------------------------
route_crowd = df.groupby("ROUTE")["CAPACITY_BUCKET_ENCODED"].mean().sort_values(ascending=False).head(20)
plt.figure(figsize=(12, 6))
route_crowd.plot(kind="bar", color="skyblue")
plt.title("Top 20 Routes by Average Crowd Level")
plt.ylabel("Average Crowd Level")
plt.xlabel("Route")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "route_vs_crowd.png"))
plt.close()

# ---------------------------------------
# 2. Trip Point Influence on Crowd
# ---------------------------------------
trip_point_dist = df.groupby("TRIP_POINT")["CAPACITY_BUCKET_ENCODED"].value_counts().unstack().fillna(0)
trip_point_dist.plot(kind="bar", stacked=True, figsize=(12, 6))
plt.title("Crowd Level Distribution by Trip Point")
plt.ylabel("Number of Entries")
plt.xlabel("Trip Point")
plt.legend(title="Crowd Level")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "trip_point_crowd.png"))
plt.close()

# ---------------------------------------
# 3. Delay Distribution
# ---------------------------------------
df["TIMETABLE_TIME"] = pd.to_datetime(df["TIMETABLE_TIME"], errors="coerce")
df["ACTUAL_TIME"] = pd.to_datetime(df["ACTUAL_TIME"], errors="coerce")
df["DELAY_MIN"] = (df["ACTUAL_TIME"] - df["TIMETABLE_TIME"]).dt.total_seconds() / 60
df["DELAY_MIN"].dropna().hist(bins=40, figsize=(12, 6), color="salmon")
plt.title("Distribution of Bus Delays (Minutes)")
plt.xlabel("Delay (Minutes)")
plt.ylabel("Frequency")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "delay_distribution.png"))
plt.close()

# ---------------------------------------
# 4. Weekly Crowd Trend
# ---------------------------------------
df["CALENDAR_DATE"] = pd.to_datetime(df["CALENDAR_DATE"], errors="coerce")
df["DAY"] = df["CALENDAR_DATE"].dt.day_name()
day_order = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
day_trend = df.groupby("DAY")["CAPACITY_BUCKET_ENCODED"].mean().reindex(day_order)
day_trend.plot(kind="bar", color="lightgreen", figsize=(12, 6))
plt.title("Average Crowd Level by Day of the Week")
plt.ylabel("Average Crowd Level")
plt.xlabel("Day")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "crowd_by_day.png"))
plt.close()

# ---------------------------------------
# 5. Directional Influence
# ---------------------------------------
directional = df.groupby("DIRECTION")["CAPACITY_BUCKET_ENCODED"].value_counts().unstack().fillna(0)
directional.plot(kind="bar", stacked=True, figsize=(12, 6), colormap="Pastel1")
plt.title("Crowd Levels by Travel Direction")
plt.ylabel("Number of Entries")
plt.xlabel("Direction")
plt.legend(title="Crowd Level")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "directional_crowd.png"))
plt.close()

# ---------------------------------------
# 6. Suburb-Level Crowd Insight
# ---------------------------------------
suburb_top = df["SUBURB"].value_counts().head(20).index.tolist()
suburb_crowd = df[df["SUBURB"].isin(suburb_top)].groupby("SUBURB")["CAPACITY_BUCKET_ENCODED"].mean()
suburb_crowd.sort_values(ascending=False).plot(kind="bar", figsize=(12, 6), color="orchid")
plt.title("Top 20 Suburbs by Average Crowd Level")
plt.ylabel("Average Crowd Level")
plt.xlabel("Suburb")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "suburb_crowd.png"))
plt.close()

# ---------------------------------------
# 7. Feature Correlation Heatmap
# ---------------------------------------
encoded_df = df.copy()
encoded_df["ROUTE"] = pd.factorize(encoded_df["ROUTE"])[0]
encoded_df["TRIP_POINT"] = pd.factorize(encoded_df["TRIP_POINT"])[0]
encoded_df["TIMETABLE_HOUR_BAND"] = pd.factorize(encoded_df["TIMETABLE_HOUR_BAND"])[0]
encoded_df["DIRECTION"] = pd.factorize(encoded_df["DIRECTION"])[0]
encoded_df["SUBURB"] = pd.factorize(encoded_df["SUBURB"])[0]
corr = encoded_df[["ROUTE", "TRIP_POINT", "TIMETABLE_HOUR_BAND", "DIRECTION", "SUBURB", "DELAY_MIN", "CAPACITY_BUCKET_ENCODED"]].corr()
plt.figure(figsize=(10, 8))
sns.heatmap(corr, annot=True, cmap="coolwarm", fmt=".2f")
plt.title("Feature Correlation with Crowd Level")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "feature_correlation_heatmap.png"))
plt.close()

# ---------------------------------------
# 8. Rush Hour Analysis by Time Band
# ---------------------------------------
rush_df = df.dropna(subset=["TIMETABLE_HOUR_BAND", "CAPACITY_BUCKET_ENCODED"])
grouped = rush_df.groupby(["TIMETABLE_HOUR_BAND", "CAPACITY_BUCKET_ENCODED"]).size().unstack().fillna(0)

def extract_hour(s):
    try:
        return int(s.split(":")[0])
    except:
        return 0

grouped = grouped.loc[sorted(grouped.index, key=extract_hour)]
grouped.plot(kind="line", marker="o", figsize=(12, 6))
plt.title("Crowd Levels by Timetable Hour Band (Line Chart)")
plt.xlabel("Hour Band")
plt.ylabel("Trip Count")
plt.legend(title="Crowd Level (0 = Low → 3 = High)")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "crowd_by_hourband.png"))
plt.close()
