"""
predict_risk_batch.py
Muc dich: Chay du doan rui ro theo lo (Batch Inference) cho cac khach hang / hop dong moi nap vao DWH.
          Duoc dieu phoi tu dong boi task 'predict_customer_risk' trong Airflow DAG.
Output: Tap ket qua du doan (CustomerKey, DateKey, PredictedClaimProbability, RiskCategory, ModelVersion)
        chuan bi nap vao Fact_Customer_Risk_Prediction trong DWH.
"""

import os
import sys
import pickle
from datetime import datetime


def load_model_artifact(model_path: str = "ml/risk_model.pkl"):
    """
    Nap pre-trained model artifact tu dia de thuc hien du doan.
    """
    if not os.path.exists(model_path):
        print(f"Warning: Model artifact not found at {model_path}. Using fallback default rules.")
        return None
    with open(model_path, "rb") as f:
        model = pickle.load(f)
    print(f"Loaded model artifact from {model_path}")
    return model


def fetch_batch_features_for_inference(batch_id: str = None):
    """
    TODO: Doc tap dac trung cua cac khach hang chua duoc danh gia rui ro tu DWH.
    Vi du:
        SELECT c.CustomerKey, c.CustomerId, c.Age, c.VehicleAge, ...
        FROM DWH_Insurance.dbo.Dim_Customer c
        LEFT JOIN DWH_Insurance.dbo.Fact_Customer_Risk_Prediction p
            ON c.CustomerKey = p.CustomerKey
        WHERE p.CustomerKey IS NULL AND c.Is_Current = 1
    """
    print(f"Fetching unscored customer features for batch {batch_id}...")
    return []


def run_batch_scoring(model, customer_data):
    """
    TODO: Thuc hien du doan xac suat rui ro va gan nhan phan loai.
    Quy tac phan nhom rui ro (RiskCategory):
      - Probability < 0.10: 'LOW'
      - 0.10 <= Probability < 0.30: 'MEDIUM'
      - 0.30 <= Probability < 0.60: 'HIGH'
      - Probability >= 0.60: 'CRITICAL'
    """
    print("Running batch risk scoring on customer records...")
    predictions = []
    # Vi du stub ket qua du doan:
    # probs = model.predict_proba(features)[:, 1]
    return predictions


def export_predictions_for_dwh_load(predictions, output_path: str = "data/raw/stg_risk_predictions.csv"):
    """
    Xuat ket qua ra file CSV trung gian hoac bang staging de procedure sql/08_sp_load_risk_predictions.sql
    nap vao bang Fact_Customer_Risk_Prediction.
    """
    print(f"Exporting predictions to staging location: {output_path}")
    # TODO: Luu file CSV dinh dang chuan de SQL Server BULK INSERT / MERGE


def main():
    batch_id = sys.argv[1] if len(sys.argv) > 1 else datetime.utcnow().strftime("%Y%m%d%H%M%S")
    print(f"Starting Batch Risk Prediction Job for Batch: {batch_id}")
    model = load_model_artifact()
    features = fetch_batch_features_for_inference(batch_id)
    predictions = run_batch_scoring(model, features)
    export_predictions_for_dwh_load(predictions)
    print("Batch Risk Prediction Job completed successfully.")


if __name__ == "__main__":
    main()
