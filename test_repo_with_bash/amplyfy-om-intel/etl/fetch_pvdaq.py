import os
import boto3
from botocore import UNSIGNED
from botocore.config import Config

ROOT = "data/raw/pvdaq"
BUCKET = "oedi-data-lake"
PREFIX = "pvdaq/csv/"


def main():
    os.makedirs(ROOT, exist_ok=True)
    s3 = boto3.client("s3", config=Config(signature_version=UNSIGNED))
    resp = s3.list_objects_v2(Bucket=BUCKET, Prefix=PREFIX, MaxKeys=100)
    items = [c["Key"] for c in resp.get("Contents", []) if c["Key"].endswith(".csv")]
    if not items:
        print("No PVDAQ CSV objects found")
        return
    key = items[0]
    out = os.path.join(ROOT, "sample_timeseries.csv")
    s3.download_file(BUCKET, key, out)
    print(f"Downloaded {key} -> {out}")


if __name__ == "__main__":
    main()
