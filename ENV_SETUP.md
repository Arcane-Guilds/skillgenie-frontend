# Environment Variables Setup

This document explains how to set up and use environment variables in the SkillGenie application.

## Overview

We use environment variables to securely store sensitive information such as API keys, credentials, and other configuration values that should not be hardcoded in the source code.

## Setup Instructions

1. Create a `.env` file in the root directory of the project (if it doesn't exist already).
2. Add your environment variables to the `.env` file in the format `KEY=VALUE`.
3. Make sure the `.env` file is included in the `.gitignore` file to prevent it from being committed to version control.

## Required Environment Variables

The following environment variables are required for the application to function properly:

```
# API Base URL
API_BASE_URL=your_api_base_url

# Cloudinary Credentials
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_cloudinary_upload_preset
CLOUDINARY_API_KEY=your_cloudinary_api_key

# Gemini AI API Key
GEMINI_API_KEY=your_gemini_api_key
```

## Usage in Code

The environment variables are loaded using the `flutter_dotenv` package. To access an environment variable in your code, use:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Access an environment variable
String apiKey = dotenv.env['API_KEY'] ?? 'default_value';
```

## Adding New Environment Variables

When adding new environment variables:

1. Add the variable to your local `.env` file.
2. Update the `ENV_SETUP.md` file to document the new variable.
3. Add a fallback value in the code for development and testing purposes.
4. Update the constants file to use the environment variable.

## Security Considerations

- Never commit the `.env` file to version control.
- When deploying the application, ensure that the environment variables are properly set in the deployment environment.
- Regularly rotate API keys and other sensitive credentials.
- Use different credentials for development, testing, and production environments. 