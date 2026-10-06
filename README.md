# AskDocs Flutter Client

Flutter client for the protected FastAPI service in
`/home/sumeet/Desktop/document-intelligence-ai`.

Internal native application identifier:

```text
com.legendsumeet.documentintelligence
```

The Dart package name remains `documentintelligence` as an internal package
identifier.

## Run Locally

Start FastAPI:

```bash
cd /home/sumeet/Desktop/document-intelligence-ai
uv run python -m uvicorn document_intelligence.api:app \
	--host 0.0.0.0 \
	--port 8000
```

Run on Android emulator:

```bash
flutter run --dart-define=API_TOKEN=local-document-app-dev-key
```

Run on a physical device:

```bash
flutter run \
	--dart-define=API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:8000 \
	--dart-define=API_TOKEN=local-document-app-dev-key
```

The client supports authenticated document listing, PDF upload, multi-document
selection, process-local chat sessions, SSE token streaming, retrieval stages,
and verified-answer state.

The development bearer token is not sufficient for production because native
application secrets can be extracted. Production requires HTTPS, user
authentication, and platform app attestation.
