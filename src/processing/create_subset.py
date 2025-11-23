import findspark
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# --- Configuration ---
SPARK_MASTER = "spark://spark-master:7077"
APP_NAME = "FlightDelay_Subset_Creator"
INPUT_PATH = "flight-delay-forecasting/data/raw/2008_airline.csv"
OUTPUT_DIR = "flight-delay-forecasting/data/raw/2_months_subset_fast.csv" 

if __name__ == "__main__":
    try:
        # 1. Start a temporary Spark Session
        findspark.init()
        spark = (
            SparkSession.builder
            .appName(APP_NAME)
            .master(SPARK_MASTER)
            .config("spark.driver.memory", "4g")
            .config("spark.sql.shuffle.partitions", "20")
            .getOrCreate()
        )
        
        print(f"Loading data from: {INPUT_PATH}")

        # 2. Load and filter the data (Month <= 2)
        df_full = spark.read.format("csv").option("header", "true").option("inferSchema", "true").load(INPUT_PATH)
        df_filtered = df_full.filter(col("Month").cast("integer") <= 2)
        
        # 3. Save the result without counting first (reduces initial resource request)
        (
            df_filtered.coalesce(1)
            .write
            .mode("overwrite")
            .option("header", "true")
            .csv(OUTPUT_DIR)
        )
        
        # Count only AFTER the save to confirm the result
        final_count = spark.read.csv(OUTPUT_DIR, header=True).count()
        print(f"Subset created with {final_count} rows in directory: {OUTPUT_DIR}")
        
    except Exception as e:
        print(f"An error occurred during subset creation: {e}")
    finally:
        if 'spark' in locals() and spark:
            spark.stop()