import pandas as pd
import mysql.connector

CSV_PATH = r"C:\Users\yasht\Downloads\Airbnb revenue analytics\Datasets\processed\listings_featured.csv"

# Read CSV
df = pd.read_csv(CSV_PATH)

# Convert missing values to None
df = df.where(pd.notnull(df), None)

# Convert dates
df["last_review"] = pd.to_datetime(
    df["last_review"],
    format="%d-%m-%Y",
    errors="coerce"
)

df["last_review"] = df["last_review"].apply(
    lambda x: x.date() if pd.notnull(x) else None
)

# Connect to MySQL
conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="yoursqlpasswword",
    database="airbnb_analytics"
)

cursor = conn.cursor()

sql = """
INSERT INTO listings (
    id,
    name,
    host_id,
    host_profile_id,
    host_name,
    neighbourhood_group,
    neighbourhood,
    latitude,
    longitude,
    room_type,
    price,
    minimum_nights,
    number_of_reviews,
    last_review,
    reviews_per_month,
    calculated_host_listings_count,
    availability_365,
    number_of_reviews_ltm,
    stay_type,
    price_category,
    host_type,
    has_reviews,
    price_log,
    availability_category
)
VALUES (
    %s, %s, %s, %s, %s, %s, %s, %s,
    %s, %s, %s, %s, %s, %s, %s, %s,
    %s, %s, %s, %s, %s, %s, %s, %s
)
"""

rows = [
    tuple(row)
    for row in df.itertuples(index=False, name=None)
]

cursor.executemany(sql, rows)

conn.commit()

print(f"Imported {cursor.rowcount} records successfully.")

cursor.close()
conn.close()
