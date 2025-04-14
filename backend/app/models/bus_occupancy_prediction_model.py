import os
import glob
import pandas as pd
import joblib

from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from xgboost import XGBClassifier
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
from sklearn.preprocessing import LabelEncoder

model_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "models"))
data_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "processed"))
feedback_file = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "feedback.csv"))
os.makedirs(model_dir, exist_ok=True)

def load_all_data():
    print("DEBUG: load_all_data() started")
    print(f"Looking for CSVs in: {data_dir}")
    all_files = sorted(glob.glob(os.path.join(data_dir, "*.csv")))
    print(f"Found files: {all_files}")
    df_list = []

    for file in all_files:
        print(f"Trying to read: {file}")
        try:
            df = pd.read_csv(file, dtype=str, usecols=[
                "ROUTE", "TIMETABLE_HOUR_BAND", "TRIP_POINT", "TIMETABLE_TIME", "ACTUAL_TIME", "CAPACITY_BUCKET", "CAPACITY_BUCKET_ENCODED"
            ], low_memory=False)
            print(f"Loaded: {file}, rows: {len(df)}")
            df_list.append(df)
        except Exception as e:
            print(f"Failed to read {file}: {e}")

    if os.path.exists(feedback_file):
        print(f"Trying to read feedback file: {feedback_file}")
        try:
            df = pd.read_csv(feedback_file, dtype=str, usecols=[
                "ROUTE", "TIMETABLE_HOUR_BAND", "TRIP_POINT", "TIMETABLE_TIME", "ACTUAL_TIME", "CAPACITY_BUCKET", "CAPACITY_BUCKET_ENCODED"
            ], low_memory=False)
            print(f"Loaded feedback rows: {len(df)}")
            df_list.append(df)
        except Exception as e:
            print(f"Failed to read feedback file: {e}")

    if not df_list:
        raise ValueError("No valid data files found to concatenate.")

    return pd.concat(df_list, ignore_index=True)

def prepare_features(df):
    df = df.copy()
    df.fillna("Unknown", inplace=True)
    df["CAPACITY_BUCKET_ENCODED"] = pd.to_numeric(df["CAPACITY_BUCKET_ENCODED"], errors="coerce")
    df.dropna(subset=["CAPACITY_BUCKET_ENCODED"], inplace=True)

    le_route = LabelEncoder()
    df["ROUTE_ENCODED"] = le_route.fit_transform(df["ROUTE"])

    df = pd.get_dummies(df, columns=["TRIP_POINT", "TIMETABLE_HOUR_BAND"])

    X = df.drop(columns=[
        "CAPACITY_BUCKET",
        "CAPACITY_BUCKET_ENCODED",
        "ROUTE",
        "TIMETABLE_TIME",
        "ACTUAL_TIME"
    ])

    y = df["CAPACITY_BUCKET_ENCODED"].astype(int)
    return X, y

def train_models():
    df = load_all_data()
    if len(df) > 10_000_000:
        df = df.sample(n=10_000_000, random_state=42)

    X, y = prepare_features(df)
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    models = {
        "LogisticRegression": LogisticRegression(max_iter=200),
        "RandomForest": RandomForestClassifier(n_estimators=50, max_depth=10, n_jobs=-1),
        "XGBoost": XGBClassifier(n_estimators=50, max_depth=6, use_label_encoder=False, eval_metric="mlogloss")
    }

    best_model = None
    best_score = -1
    best_name = ""

    for name, model in models.items():
        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)
        score = f1_score(y_test, y_pred, average="weighted")
        acc = accuracy_score(y_test, y_pred)
        print(f"{name}: Accuracy={acc:.2f}, F1={score:.2f}")
        if score > best_score:
            best_model = model
            best_score = score
            best_name = name

    joblib.dump(best_model, os.path.join(model_dir, "best_model.pkl"))
    print(f"Best model saved: {best_name} with F1={best_score:.2f}")

def predict(input_dict):
    model_path = os.path.join(model_dir, "best_model.pkl")
    if not os.path.exists(model_path):
        raise FileNotFoundError("No trained model found. Please train the model first.")
    model = joblib.load(model_path)
    input_df = pd.DataFrame([input_dict])
    input_df.fillna("Unknown", inplace=True)

    all_data = load_all_data()
    le_route = LabelEncoder()
    le_route.fit(all_data["ROUTE"])
    input_df["ROUTE_ENCODED"] = le_route.transform(input_df["ROUTE"])

    input_df = pd.get_dummies(input_df)
    X_all, _ = prepare_features(all_data)
    input_df = input_df.reindex(columns=X_all.columns, fill_value=0)

    prediction = model.predict(input_df)[0]
    return int(prediction)

def append_feedback(feedback_row):
    columns = ["ROUTE", "TIMETABLE_HOUR_BAND", "TRIP_POINT", "TIMETABLE_TIME", "ACTUAL_TIME", "CAPACITY_BUCKET", "CAPACITY_BUCKET_ENCODED"]
    row_df = pd.DataFrame([feedback_row], columns=columns)
    if not os.path.exists(feedback_file):
        row_df.to_csv(feedback_file, index=False)
    else:
        row_df.to_csv(feedback_file, mode="a", index=False, header=False)
