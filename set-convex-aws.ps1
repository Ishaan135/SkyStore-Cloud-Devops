# Copies the AWS Learner Lab credentials (profile "personal") into your Convex deployment.
# Run this again each time you restart the lab (credentials expire every ~4 hours).
param([string]$Bucket = "skystore-files-baf29a07", [string]$Profile = "personal")
Set-Location $PSScriptRoot
$c = aws configure export-credentials --profile $Profile --format process | ConvertFrom-Json
npx convex env set CONVEX_AWS_REGION us-east-1
npx convex env set CONVEX_AWS_S3_BUCKET $Bucket
npx convex env set CONVEX_AWS_ACCESS_KEY_ID $c.AccessKeyId
npx convex env set CONVEX_AWS_SECRET_ACCESS_KEY $c.SecretAccessKey
npx convex env set CONVEX_AWS_SESSION_TOKEN $c.SessionToken
Write-Host "Convex now uses your S3 bucket $Bucket" -ForegroundColor Green
