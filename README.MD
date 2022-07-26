This repository is for production promo dedicated to **elitesolutionsIT cloud computing BootCamp**.

# Table of Contents
* [App](#App)
* [Pipeline](#Pipeline)
* [Infrastructure](#Infrastructure)

# App
 A simple Word press frame work application that was developed for the sole purpose of promoting this bootcamp.
 - Future Improvement would be to move this to a more production stable environment.
 - Current development testing are done on it to solidify things.
 - It's open for community development.


 # Pipeline
 GitHub Actions work was used for the CICD process.
 # Features
 - Use's AWS Creds set on the Repo level to Authenticate AWS.
 - Copies App folder structure from local Dir to AWS S3 Bucket.
 - App is curentlt been delivered through CloudFront and spread across edge locations.

 ```
 name: Upload website

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v1

    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: change directory & Deploy static site to S3 bucket
      run: cd /home/runner/work/elitesolutionsit-official-website/elitesolutionsit-official-website/app && aws s3 sync . s3://${{ secrets.S3_BUCKET_NAME }}
```

 # Infrastructure
 Infrastructure is currently been managed with terraform (IAC), it also use's a terraform workspace undernite.

