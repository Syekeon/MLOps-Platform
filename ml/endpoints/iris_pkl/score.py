import json
import os
from pathlib import Path

import joblib
import numpy as np


model = None


def init():
    global model

    model_root = Path(os.environ["AZUREML_MODEL_DIR"])
    candidates = list(model_root.rglob("model.pkl"))

    if not candidates:
        raise FileNotFoundError(f"No se encontro model.pkl bajo {model_root}")

    model_path = candidates[0]
    print(f"Buscando modelo en: {model_path}")

    model = joblib.load(model_path)
    print("Modelo cargado con exito.")


def run(raw_data):
    try:
        data = json.loads(raw_data)["data"]
        input_data = np.array(data)
        predictions = model.predict(input_data)

        response = {"result": predictions.tolist()}

        if hasattr(model, "predict_proba"):
            response["probabilities"] = model.predict_proba(input_data).tolist()

        return response
    except Exception as e:
        return {"error": str(e)}
