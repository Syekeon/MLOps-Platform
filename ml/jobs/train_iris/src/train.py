import json
import os
import argparse

import joblib
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_output", type=str, required=True)
    return parser.parse_args()


def main():
    args = parse_args()

    iris = load_iris()
    X_train, X_test, y_train, y_test = train_test_split(
        iris.data, iris.target, test_size=0.2, random_state=42
    )

    clf = RandomForestClassifier(n_estimators=100, random_state=42)
    clf.fit(X_train, y_train)

    y_pred = clf.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    print(f"Modelo entrenado con exito. Accuracy: {acc}")

    os.makedirs(args.model_output, exist_ok=True)
    os.makedirs("outputs", exist_ok=True)

    model_path = os.path.join(args.model_output, "model.pkl")
    metrics_path = "outputs/metrics.json"

    joblib.dump(clf, model_path)

    with open(metrics_path, "w", encoding="utf-8") as f:
        json.dump({"accuracy": acc}, f)

    print(f"Modelo guardado en: {model_path}")
    print(f"Metricas guardadas en: {metrics_path}")


if __name__ == "__main__":
    main()
