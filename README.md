

This project is a full-stack mobile application designed to bridge the gap between fitness coaches and athletes. Developed during a professional internship at **IT HOUSE**, the application aims to centralize training programs, facilitate performance tracking, and foster a community environment.

## 🚀 Key Features
* **Role-Based Authentication:** Secure access control using JWT, distinguishing between Athletes, Coaches, and Administrators.
* **Dynamic Plan Management:** Coaches can create, manage, and distribute structured fitness plans (JSON-based) to their followers.
* **Real-time Interaction:** Synchronized data exchange between the mobile client and the backend API.
* **Community Engagement:** Integrated follow system and chat functionality to keep users motivated.
* **Modern UI/UX:** A responsive and intuitive interface built with Flutter, optimized for both iOS and Android.

## 🛠️ Technical Stack

### Backend
* **Framework:** [FastAPI](https://fastapi.tiangolo.com/) (High-performance, asynchronous Python framework).
* **Database:** SQLite (development) / PostgreSQL (production) with SQLAlchemy ORM.
* **Security:** Password hashing with `passlib` and token-based authentication via `PyJWT`.

### Frontend
* **Framework:** [Flutter](https://flutter.dev/) (Cross-platform mobile development).
* **State Management:** Provider/Riverpod (for clean, scalable state).
* **Communication:** RESTful API integration using `dio` or `http` packages.

## 📂 Project Structure
```text
/fitness-tracker
├── /backend          # FastAPI application, database models, and routes
├── /frontend         # Flutter mobile application codebase
├── /docs             # Technical reports and diagrams
└── README.md
