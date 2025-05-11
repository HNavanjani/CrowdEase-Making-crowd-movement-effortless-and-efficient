import os
import glob
import pandas as pd
import numpy as np
import joblib
import datetime
import matplotlib.pyplot as plt
import time

from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from xgboost import XGBClassifier
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix, ConfusionMatrixDisplay
from sklearn.preprocessing import LabelEncoder
from app.utils.setup_data import download_and_unzip_force

if os.getenv("RENDER") == "true":
    download_and_unzip_force()

model_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "models"))
data_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "processed"))
feedback_file = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "feedback.csv"))
report_dir = os.path.abspath(os.path.join(model_dir, "..", "model_metrics"))
route_encoder_path = os.path.join(model_dir, "route_label_encoder.pkl")

os.makedirs(model_dir, exist_ok=True)
os.makedirs(report_dir, exist_ok=True)

def load_all_data():
    all_files = sorted(glob.glob(os.path.join(data_dir, "*.csv")))
    df_list = []
    for file in all_files:
        try:
            df = pd.read_csv(file, dtype=str, usecols=[
                "ROUTE", "TIMETABLE_HOUR_BAND", "TRIP_POINT", "TIMETABLE_TIME",
                "ACTUAL_TIME", "CAPACITY_BUCKET", "CAPACITY_BUCKET_ENCODED"
            ], low_memory=False)
            df_list.append(df)
        except Exception as e:
            print(f"Failed to read {file}: {e}")
    if os.path.exists(feedback_file):
        try:
            df = pd.read_csv(feedback_file, dtype=str, usecols=[
                "ROUTE", "TIMETABLE_HOUR_BAND", "TRIP_POINT", "TIMETABLE_TIME",
                "ACTUAL_TIME", "CAPACITY_BUCKET", "CAPACITY_BUCKET_ENCODED"
            ], low_memory=False)
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
    joblib.dump(le_route, route_encoder_path)
    df = pd.get_dummies(df, columns=["TRIP_POINT", "TIMETABLE_HOUR_BAND"])
    X = df.drop(columns=["CAPACITY_BUCKET", "CAPACITY_BUCKET_ENCODED", "ROUTE", "TIMETABLE_TIME", "ACTUAL_TIME"])
    y = df["CAPACITY_BUCKET_ENCODED"].astype(int)
    return X, y

def train_models():
    df = load_all_data()
    print(f"Training on full dataset: {len(df):,} rows")
    X, y = prepare_features(df)
    print("Class distribution:\n", y.value_counts())

    X_temp, X_test, y_temp, y_test = train_test_split(X, y, test_size=0.15, stratify=y, random_state=42)
    X_train, X_val, y_train, y_val = train_test_split(X_temp, y_temp, test_size=0.1765, stratify=y_temp, random_state=42)

    models = {
        "LogisticRegression": LogisticRegression(max_iter=200),
        "RandomForest": RandomForestClassifier(n_estimators=50, max_depth=10, n_jobs=-1),
        "XGBoost": XGBClassifier(n_estimators=50, max_depth=6, use_label_encoder=False, eval_metric="mlogloss")
    }

    best_model = None
    best_score = -1
    best_name = ""
    best_preds = None
    metrics = {}
    train_times = {}

    for name, model in models.items():
        start_time = time.time()
        model.fit(X_train, y_train)
        y_pred = model.predict(X_val)
        elapsed_time = time.time() - start_time
        acc = accuracy_score(y_val, y_pred)
        prec = precision_score(y_val, y_pred, average="weighted", zero_division=0)
        rec = recall_score(y_val, y_pred, average="weighted", zero_division=0)
        f1 = f1_score(y_val, y_pred, average="weighted", zero_division=0)
        metrics[name] = {"accuracy": acc, "precision": prec, "recall": rec, "f1": f1}
        train_times[name] = elapsed_time
        if f1 > best_score:
            best_model = model
            best_score = f1
            best_name = name
            best_preds = y_pred

    all_metrics_path = os.path.join(report_dir, "all_models_metrics.txt")
    with open(all_metrics_path, "w") as f:
        f.write(f"Model Comparison Report ({datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')})\n")
        f.write("="*60 + "\n\n")
        for model_name in metrics.keys():
            line = (f"Model: {model_name}\n"
                    f"  Accuracy: {metrics[model_name]['accuracy']:.4f}\n"
                    f"  Precision: {metrics[model_name]['precision']:.4f}\n"
                    f"  Recall: {metrics[model_name]['recall']:.4f}\n"
                    f"  F1 Score: {metrics[model_name]['f1']:.4f}\n"
                    f"  Training Time: {train_times[model_name]:.2f} seconds\n"
                    f"{'-'*60}\n")
            print(line)
            f.write(line)

    joblib.dump(best_model, os.path.join(model_dir, "best_model.pkl"))
    joblib.dump(X_train.columns.tolist(), os.path.join(model_dir, "feature_columns.pkl"))
    with open("new_model_flag.txt", "w") as f:
        f.write("new model ready")

    version = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(os.path.join(model_dir, "model_version.txt"), "w") as f:
        f.write(f"Last retrained: {version}")

    with open(os.path.join(model_dir, "model_metrics.txt"), "w") as f:
        f.write(f"Last trained: {version}\n")
        f.write(f"Best Model: {best_name}\n")
        f.write(f"Accuracy: {metrics[best_name]['accuracy']:.4f}\n")
        f.write(f"Precision: {metrics[best_name]['precision']:.4f}\n")
        f.write(f"Recall: {metrics[best_name]['recall']:.4f}\n")
        f.write(f"F1 Score: {metrics[best_name]['f1']:.4f}\n")

    for metric in ["accuracy", "precision", "recall", "f1"]:
        labels = list(metrics.keys())
        values = [metrics[m][metric] for m in labels]
        plt.figure()
        plt.bar(labels, values)
        plt.title(f"{metric.capitalize()} Comparison")
        plt.ylabel(metric.capitalize())
        plt.savefig(os.path.join(report_dir, f"{metric}_comparison.png"))
        plt.close()

    cm = confusion_matrix(y_val, best_preds)
    disp = ConfusionMatrixDisplay(confusion_matrix=cm)
    disp.plot()
    plt.title(f"Confusion Matrix - {best_name}")
    plt.savefig(os.path.join(report_dir, "confusion_matrix.png"))
    plt.close()

def predict(input_dict):
    model_path = os.path.join(model_dir, "best_model.pkl")
    feature_path = os.path.join(model_dir, "feature_columns.pkl")
    if not os.path.exists(model_path):
        raise FileNotFoundError("No trained model found. Please train the model first.")
    if not os.path.exists(feature_path):
        raise FileNotFoundError("Feature columns file not found.")
    if not os.path.exists(route_encoder_path):
        raise FileNotFoundError("Route label encoder not found.")

    model = joblib.load(model_path)
    feature_columns = joblib.load(feature_path)
    le_route = joblib.load(route_encoder_path)

    input_df = pd.DataFrame([input_dict])
    input_df.fillna("Unknown", inplace=True)
    route = input_df["ROUTE"].iloc[0]
    if route not in le_route.classes_:
        print(f"[WARNING] Unseen route: {route}. Mapping to 'Unknown'.")
        le_route.classes_ = np.append(le_route.classes_, "Unknown")
        input_df["ROUTE"] = "Unknown"

    input_df["ROUTE_ENCODED"] = le_route.transform(input_df["ROUTE"])
    input_df = pd.get_dummies(input_df)
    input_df = input_df.reindex(columns=feature_columns, fill_value=0)
    prediction = model.predict(input_df)[0]
    return int(prediction)

def append_feedback(feedback_row):
    columns = ["ROUTE", "TIMETABLE_HOUR_BAND", "TRIP_POINT", "TIMETABLE_TIME", "ACTUAL_TIME", "CAPACITY_BUCKET", "CAPACITY_BUCKET_ENCODED"]
    row_df = pd.DataFrame([feedback_row], columns=columns)
    if not os.path.exists(feedback_file):
        row_df.to_csv(feedback_file, index=False)
    else:
        row_df.to_csv(feedback_file, mode="a", index=False, header=False)
    df = pd.read_csv(feedback_file)
    if len(df) >= 100 and len(df) % 100 == 0:
        if os.getenv("RUN_RETRAINING") == "true":
            print("Threshold reached. Retraining model with feedback included.")
            train_models()
