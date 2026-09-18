"""
insurance_dwh_pipeline.py
Giai doan: Giai doan 6 — Orchestration voi Airflow
Muc dich: Dieu phoi toan bo pipeline Data Warehouse & Machine Learning:
          Load Staging -> Load Dim (song song) -> Load Fact -> Data Quality Check
          -> Batch Risk Prediction (ML) -> Load Risk Predictions -> Notify
Tham chieu: docs/specs/implementation-guide.md

Thu tu phu thuoc (Dependency):
  load_staging >> [load_dim_customer, load_dim_policy, load_dim_date, load_dim_region]
  [load_dim_customer, load_dim_policy, load_dim_date, load_dim_region] >> [load_fact_premium, load_fact_claims]
  [load_fact_premium, load_fact_claims] >> run_data_quality_checks >> predict_customer_risk >> load_risk_predictions >> notify
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator


def failure_alert(context):
    """
    on_failure_callback: Canh bao khi co bat ky task nao that bai trong DAG.
    """
    task_instance = context.get('task_instance')
    dag_id = context.get('dag').dag_id
    execution_date = context.get('execution_date')
    log_url = task_instance.log_url
    print(f"[ALERT] Task failed in DAG: {dag_id}")
    print(f"Task ID: {task_instance.task_id}")
    print(f"Execution Date: {execution_date}")
    print(f"Log URL: {log_url}")
    # TODO: Gui thong bao qua Webhook Slack/Teams hoac email alert neu co SMTP


def run_stored_procedure_stub(procedure_name: str, **kwargs):
    """
    TODO: Thuc thi Stored Procedure tren SQL Server qua MsSqlHook / pyodbc.
    Vi du:
        hook = MsSqlHook(mssql_conn_id='mssql_default')
        hook.run(f"EXEC {procedure_name} @BatchId = '{kwargs.get('run_id')}';")
    """
    print(f"Executing Stored Procedure stub: {procedure_name}")
    print(f"Run ID: {kwargs.get('run_id')}")


def run_ml_batch_prediction_stub(**kwargs):
    """
    TODO: Thuc thi script ML batch scoring (ml/predict_risk_batch.py).
    Doc cac record khach hang moi, tinh toan PredictedClaimProbability va RiskCategory.
    """
    print("Executing ML Batch Risk Scoring job...")
    print(f"Batch Run ID: {kwargs.get('run_id')}")


default_args = {
    'owner': 'data_engineering_team',
    'depends_on_past': False,
    'start_date': datetime(2026, 1, 1),
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'on_failure_callback': failure_alert,
}

with DAG(
    dag_id='insurance_dwh_pipeline',
    default_args=default_args,
    description='Pipeline ETL, Data Quality va Batch ML Scoring DWH Bao hiem (SQL Server + CDC + LightGBM)',
    schedule_interval='@daily',
    catchup=False,
    tags=['insurance', 'dwh', 'cdc', 'sqlserver', 'machine-learning'],
) as dag:

    # -------------------------------------------------------------------------
    # Task: load_staging
    # -------------------------------------------------------------------------
    # TODO: Goi script/procedure BULK INSERT nap du lieu tho vao Staging_InsuranceRaw
    load_staging = PythonOperator(
        task_id='load_staging',
        python_callable=run_stored_procedure_stub,
        op_kwargs={'procedure_name': 'dbo.sp_Load_Staging'},
    )

    # -------------------------------------------------------------------------
    # Dimension Tasks (Chay song song sau load_staging)
    # -------------------------------------------------------------------------
    # TODO: Goi Stored Procedure sp_Load_DimCustomer (SCD Type 2 tu Porto Seguro)
    load_dim_customer = PythonOperator(
        task_id='load_dim_customer',
        python_callable=run_stored_procedure_stub,
        op_kwargs={'procedure_name': 'dbo.sp_Load_DimCustomer'},
    )

    # TODO: Goi Stored Procedure sp_Load_DimPolicy
    load_dim_policy = PythonOperator(
        task_id='load_dim_policy',
        python_callable=run_stored_procedure_stub,
        op_kwargs={'procedure_name': 'dbo.sp_Load_DimPolicy'},
    )

    # TODO: Goi Stored Procedure sp_Load_DimDate
    load_dim_date = PythonOperator(
        task_id='load_dim_date',
        python_callable=run_stored_procedure_stub,
        op_kwargs={'procedure_name': 'dbo.sp_Load_DimDate'},
    )

    # TODO: Goi Stored Procedure sp_Load_DimRegion
    load_dim_region = PythonOperator(
        task_id='load_dim_region',
        python_callable=run_stored_procedure_stub,
        op_kwargs={'procedure_name': 'dbo.sp_Load_DimRegion'},
    )

    # -------------------------------------------------------------------------
    # Fact Tasks (Phu thuoc tat ca cac Dimension)
    # -------------------------------------------------------------------------
    # TODO: Goi Stored Procedure sp_Load_FactPremium
    load_fact_premium = PythonOperator(
        task_id='load_fact_premium',
        python_callable=run_stored_procedure_stub,
        op_kwargs={'procedure_name': 'dbo.sp_Load_FactPremium'},
    )

    # TODO: Goi Stored Procedure sp_Load_FactClaims
    load_fact_claims = PythonOperator(
        task_id='load_fact_claims',
        python_callable=run_stored_procedure_stub,
        op_kwargs={'procedure_name': 'dbo.sp_Load_FactClaims'},
    )

    # -------------------------------------------------------------------------
    # Task: run_data_quality_checks (Phu thuoc Fact tables)
    # -------------------------------------------------------------------------
    # TODO: Goi Stored Procedure sp_Run_DataQualityChecks
    run_data_quality_checks = PythonOperator(
        task_id='run_data_quality_checks',
        python_callable=run_stored_procedure_stub,
        op_kwargs={'procedure_name': 'dbo.sp_Run_DataQualityChecks'},
    )

    # -------------------------------------------------------------------------
    # Machine Learning Batch Prediction Tasks
    # -------------------------------------------------------------------------
    # Task 1: Chay batch scoring bang Python ML Model
    predict_customer_risk = PythonOperator(
        task_id='predict_customer_risk',
        python_callable=run_ml_batch_prediction_stub,
    )

    # Task 2: Nap ket qua du doan ML vao Fact_Customer_Risk_Prediction trong DWH
    load_risk_predictions = PythonOperator(
        task_id='load_risk_predictions',
        python_callable=run_stored_procedure_stub,
        op_kwargs={'procedure_name': 'dbo.sp_Load_CustomerRiskPredictions'},
    )

    # -------------------------------------------------------------------------
    # Task: notify (Gui thong bao sau khi pipeline hoan thanh thanh cong)
    # -------------------------------------------------------------------------
    # TODO: Thong bao hoan thanh pipeline qua webhook hoac log
    notify = EmptyOperator(
        task_id='notify',
    )

    # -------------------------------------------------------------------------
    # Pipeline Dependencies
    # -------------------------------------------------------------------------
    dim_tasks = [load_dim_customer, load_dim_policy, load_dim_date, load_dim_region]
    fact_tasks = [load_fact_premium, load_fact_claims]

    load_staging >> dim_tasks
    dim_tasks >> fact_tasks
    fact_tasks >> run_data_quality_checks >> predict_customer_risk >> load_risk_predictions >> notify
