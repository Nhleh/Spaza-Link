# Play Store Deployment Guide

## 1. Google Play Console Setup
1. Create a [Google Play Console](https://play.google.com/console) account ($25 one-time fee).
2. Click **Create App** and fill in basic info.

## 2. Store Listing Requirements
- **App Name**: Spaza Shop (Max 30 chars)
- **Short Description**: Premium Spaza grocery delivery.
- **Full Description**: The best way to order groceries for your Spaza shop with reliable delivery.
- **Icon**: 512x512px PNG (Transparent).
- **Feature Graphic**: 1024x500px JPEG.
- **Screenshots**: At least 2 for phone, 7-inch tablet, and 10-inch tablet.

## 3. Uploading the App
1. Go to **Production > Create New Release**.
2. Upload the `.aab` (App Bundle) file generated from Android Studio.
3. Write your release notes.

## 4. App Content & Rating
Complete the following in the Sidebar:
- Privacy Policy (See `LEGAL_AND_ASSETS.md`)
- Content Rating Questionnaire
- Target Audience (e.g., 18+)
- Data Safety section (Declare that you use Firebase for Auth).

## 5. Review & Launch
1. Check for any warnings in the **Pre-launch report**.
2. Click **Start Rollout to Production**.
