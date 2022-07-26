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

 # Infrastructure
 Infrastructure is currently been managed with terraform (IAC), it also use's a terraform workspace undernite.
 
