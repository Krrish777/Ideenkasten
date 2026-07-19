---
term: Data Version Control (DVC)
---

# Data Version Control (DVC)

DVC is a command line tool that sits alongside Git and versions datasets and model files. Git tracks small pointer files, while the actual data lives in S3, GCS or any other remote storage.

**Why it matters:** Without it you cannot reproduce a model, because you know the code that produced it but not the exact data. DVC makes a training run pinnable to a commit.

**Where it came up:** [[01 Six Architecture Decisions - Sachin Garg]]

**Source:** [dvc.org](https://dvc.org/)
