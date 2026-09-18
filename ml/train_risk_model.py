"""
train_risk_model.py
Muc dich: Huan luyen baseline model du doan xac suat phat sinh boi thuong (Claim Propensity / Risk Scoring)
          dua tren dac trung khach hang tu bo du lieu Porto Seguro Safe Driver va lich su hop dong DWH.
Output: File model artifact (models/risk_model.pkl) va thong so danh gia (ROC-AUC, Precision, Recall).
"""

import os
import sys
import pickle
from datetime import datetime


def extract_training_features(data_path: str = None):
    """
    TODO: Trich xuat tap dac trung tu DWH_Insurance hoac file staging da lam sach.
    Cac dac trung bao gom:
      - Nhom dac trung ca nhan: ps_ind_* (tuoi, gioi tinh, vung mien)
      - Nhom dac trung xe: ps_car_* (loai xe, tuoi tho xe, gia tri bao hiem)
      - Nhom chi so tinh toan rui ro: ps_calc_*
      - Target: target (0: Khong phat sinh claim, 1: Co phat sinh claim)
    """
    print("Extracting features for risk scoring model...")
    # Vi du stub doc du lieu:
    # import pandas as pd
    # df = pd.read_csv(data_path or 'data/raw/train.csv')
    # return df
    return None


def train_baseline_model(features_df=None):
    """
    TODO: Huan luyen mo hinh phan loai (Logistic Regression, LightGBM hoac XGBoost).
    """
    print("Training baseline risk scoring model (LightGBM / LogisticRegression)...")
    # Vi du stub huan luyen:
    # from sklearn.model_selection import train_test_split
    # from sklearn.linear_model import LogisticRegression
    # from sklearn.metrics import roc_auc_score
    # X_train, X_test, y_train, y_test = train_test_split(...)
    # model = LogisticRegression(class_weight='balanced', max_iter=1000)
    # model.fit(X_train, y_train)
    # print(f"Validation ROC-AUC: {roc_auc_score(y_test, model.predict_proba(X_test)[:, 1]):.4f}")
    # return model
    return {"model_name": "porto_seguro_risk_v1", "trained_at": datetime.utcnow().isoformat()}


def save_model_artifact(model_obj, output_path: str = "ml/risk_model.pkl"):
    """
    Luu mo hinh da huan luyen vao file artifact de phuc vu batch inference.
    """
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "wb") as f:
        pickle.dump(model_obj, f)
    print(f"Model artifact saved successfully to {output_path}")


def main():
    print("Starting ML Model Training Pipeline...")
    features = extract_training_features()
    model = train_baseline_model(features)
    save_model_artifact(model)
    print("Model Training Pipeline completed.")


if __name__ == "__main__":
    main()
