import pandas as pd
import mysql.connector
import time

CSV_PATH = r"C:\Users\yasht\Downloads\Airbnb revenue analytics\Datasets\processed\reviews_clean.csv"

BATCH_SIZE = 5000

print("Reading reviews CSV...")

df = pd.read_csv(CSV_PATH)

print(f"Rows loaded: {len(df)}")

df = df.where(pd.notnull(df), None)


df["date"] = pd.to_datetime(
    df["date"],
    format="%Y-%m-%d",
    errors="coerce"
)

df["date"] = df["date"].apply(
    lambda x: x.date() if pd.notnull(x) else None
)

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="yashtheranger",
    database="airbnb_analytics",
    connection_timeout=60
)

cursor = conn.cursor()

sql = """
INSERT INTO reviews (
    listing_id,
    id,
    date,
    reviewer_id,
    reviewer_name,
    comments
)
VALUES (%s, %s, %s, %s, %s, %s)
"""

total = len(df)

for start in range(0, total, BATCH_SIZE):

    end = min(start + BATCH_SIZE, total)

    batch = [
        tuple(row)
        for row in df.iloc[start:end].itertuples(
            index=False,
            name=None
        )
    ]

    cursor.executemany(sql, batch)
    conn.commit()

    print(f"Imported {end:,} / {total:,}")

cursor.close()
conn.close()

print("Reviews import completed successfully.")