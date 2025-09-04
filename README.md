# Telepatía AI Tech Test Frontend

Pequeña aplicación web en Flutter para interactuar con el pipeline de Telepatía AI.

## Requisitos

- [Flutter](https://flutter.dev) 3.7 o superior
- Navegador Chrome

## Variables de entorno

1. Copia el archivo de ejemplo y renómbralo:
   ```bash
   cp telepatia_ai_techtest_frontend/.env.example telepatia_ai_techtest_frontend/.env
   ```
2. Edita `telepatia_ai_techtest_frontend/.env` y completa los valores necesarios:
   ```bash
   API_BASE_URL=http://127.0.0.1:5005/telepatia-ai-techtest-hfunes/us-central1
   PROJECT_ID=<tu-project-id>
   ```
3. Carga las variables antes de ejecutar la app:
   ```bash
   cd telepatia_ai_techtest_frontend
   source .env
   ```

## Ejecución local

Dentro de la carpeta `telepatia_ai_techtest_frontend` ejecuta:
```bash
./run-local.sh
```
El script instalará dependencias y levantará la aplicación en Chrome.

