# Telepatía AI Tech Test Frontend

Small Flutter web application to interact with the Telepatía AI pipeline.

## Requirements

- [Flutter](https://flutter.dev) 3.7 or higher
- Chrome browser

## Environment variables

1. Copy the example file and rename it:
   ```bash
   cp telepatia_ai_techtest_frontend/.env.example telepatia_ai_techtest_frontend/.env
   ```
2. Edit `telepatia_ai_techtest_frontend/.env` and fill in the required values:
   ```bash
   API_BASE_URL=http://127.0.0.1:5005/telepatia-ai-techtest-hfunes/us-central1
   PROJECT_ID=<your-project-id>
   ```
3. Load the variables before running the app:
   ```bash
   cd telepatia_ai_techtest_frontend
   source .env
   ```

## Local run

Inside the `telepatia_ai_techtest_frontend` folder run:
```bash
./run-local.sh
```
The script will install dependencies and launch the application in Chrome.

