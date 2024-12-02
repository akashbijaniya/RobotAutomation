environments = {
    "qac1": {
        "url": "https://portal.bgcls1.com",
        "environmentSuffix": "qac1"
    },
    "dev4": {
        "url": "https://portal.dev4.fp1.dev",
        "environmentSuffix": "dev4"
    }
}

api_headers = {
    "kinesis_shard_key": {
        "qac1": {
            "X-Bitglass-Machine-GUID": "08D5720C-7FBE-40F4-AE6C-2644A5F6A03B",
            "cid": "0_Ce7G3tM6v0P2DOJVNqqg6pbk7AC_1mmg8A==",
            "Content-Type": "application/json"
        },
        "dev4": {
            "X-Bitglass-Machine-GUID": "8384ACD4-E326-4D6B-9650-36454B1F2ED6",
            "cid": "0_TxbPtvZGUnzAkFHv27-_oVAs4Z9aI7nPVQ==",
            "Content-Type": "application/json"
        }
    },
    "signed_kinesis_post": {
        "qac1": {
            "X-Bitglass-Machine-GUID": "3CCF0BA8-057E-4FEC-8987-C46E1489DC3B",
            "cid": "0_nZnYKcWRQ6EERS-Y9grTrSVLgScvN8A7zg==",
            "Content-Type": "application/json"
        },
        "dev4": {
            "X-Bitglass-Machine-GUID": "8384ACD4-E326-4D6B-9650-36454B1F2ED6",
            "cid": "0_TxbPtvZGUnzAkFHv27-_oVAs4Z9aI7nPVQ==",
            "Content-Type": "application/json"
        }
    },
    "kinesis_file_upload": {
        "qac1": {
            "X-Bitglass-Machine-GUID": "08D5720C-7FBE-40F4-AE6C-2644A5F6A03B",
            "cid": "0_Ce7G3tM6v0P2DOJVNqqg6pbk7AC_1mmg8A==",
            "Content-Type": "application/json"
        },
        "dev4": {
            "X-Bitglass-Machine-GUID": "08D5720C-7FBE-40F4-AE6C-2644A5F6A03B",
            "cid": "0_Ce7G3tM6v0P2DOJVNqqg6pbk7AC_1mmg8A==",
            "Content-Type": "application/json"
        }
    }
}

api_payloads = {
    "kinesis_shard_key": {
        "qac1": {
            "company_id": 314663
        },
        "dev4": {
            "company_id": 315420
        }
    }
}
