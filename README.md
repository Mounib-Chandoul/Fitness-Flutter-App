# 🏋️ Fitness Flutter App

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-009485?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Grade](https://img.shields.io/badge/Grade-17.05%2F20-9ECE6A?style=for-the-badge)](https://github.com/Mounib-Chandoul/Fitness-Flutter-App)
[![License: MIT](https://img.shields.io/badge/License-MIT-9ECE6A?style=for-the-badge)](LICENSE)

</div>

A full-stack mobile application that bridges the gap between fitness coaches
and athletes. Built during a **second-year internship at IT HOUSE** as an ISD
student at ISET Radès, and graded **17.05/20**.

---

## Features

- **Role-based auth** — JWT login for Athletes, Coaches and Administrators.
- **Plan management** — coaches create and distribute structured JSON plans.
- **Follow system** — athletes subscribe to their coach's programs.
- **Community chat** — synchronized messaging to keep users motivated.
- **REST sync** — Flutter client talks to the FastAPI backend over HTTP.
- **Modern UI** — responsive Flutter screens for iOS and Android.

---

## Stack

| Layer | Technology |
|---|---|
| Backend | FastAPI, SQLAlchemy, Pydantic |
| Auth | `passlib` hashing + PyJWT tokens |
| Database | SQLite (dev) / PostgreSQL (prod) |
| Frontend | Flutter + Dart, Provider/Riverpod state |
| HTTP | `dio` / `http` packages |
| Docs | PDF reports and PlantUML diagrams in `docs/` |

---

## Layout

```text
Fitness-Flutter-App/
├── app-files/
│   ├── fitness_backend/        # FastAPI app, models, schemas, routes
│   │   ├── app/main.py
│   │   ├── app/models.py
│   │   ├── app/dependencies.py
│   │   └── app/routes/         # auth, users, plans
│   └── fitness_frontend/       # Flutter application
│       ├── lib/
│       ├── android/
│       └── pubspec.yaml
├── docs/                       # reports, PlantUML sources, diagrams, UIUX
└── Project Report
```

---

## Run

Backend:

```bash
cd app-files/fitness_backend
python -m venv .venv
source .venv/bin/activate       # Windows: .venv\Scripts\activate
pip install fastapi uvicorn sqlalchemy passlib pyjwt pydantic
uvicorn app.main:api --reload --port 8000
```

Frontend:

```bash
cd app-files/fitness_frontend
flutter pub get
flutter run
```

Point the app's API base URL at your machine (`http://<pc-ip>:8000`) for device
testing.

---

## Documentation

The `docs/` folder contains the internship deliverables:

- `docs/CHECKME/` — PRD and architecture PDFs
- `docs/DiagramCode/` — PlantUML sources (use case, sequence, activity, class)
- `docs/Diagrams/` — rendered diagrams and UI mockups
- `docs/UIUX/` — interface notes

## License

[MIT](LICENSE).
