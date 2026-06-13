import os
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi import Body
from sqlalchemy.orm import Session

from .routes import auth, users, plans
from .dependencies import get_db, get_current_user
from . import models
from passlib.context import CryptContext
from passlib.exc import UnknownHashError

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return pwd_context.verify(plain_password, hashed_password)
    except (UnknownHashError, ValueError):
        return plain_password == hashed_password


# create the FastAPI application
api = FastAPI(title="Fitness Tracker API (Full CRUD)")

# --- CORS ------------------------------------------------------------------
# by default we allow everything (development) but in production the
# CORS_ORIGINS environment variable can be set to a comma-separated list of
# allowed origins.  a value of "*" keeps the permissive behaviour.
origins_env = os.environ.get("CORS_ORIGINS", "*")
if origins_env.strip() == "*":
    allowed_origins = ["*"]
else:
    allowed_origins = [o.strip() for o in origins_env.split(",") if o.strip()]

api.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- SQLAdmin views (optional admin interface) -----
from sqladmin import Admin, ModelView
from sqladmin.authentication import AuthenticationBackend
from fastapi import Request

class AdminAuth(AuthenticationBackend):
    async def login(self, request: Request) -> bool:
        form = await request.form()
        email = form.get("username")
        password = form.get("password")
        db = models.SessionLocal()
        try:
            user = db.query(models.User).filter(models.User.email == email).first()
            if user and verify_password(password, user.password) and user.role == "admin":
                request.session["user"] = email
                return True
        finally:
            db.close()
        return False

    async def authenticate(self, request: Request) -> bool:
        return "user" in request.session

admin = Admin(
    api,
    models.engine,
    authentication_backend=AdminAuth(secret_key=os.environ.get("SECRET_KEY", "2f14729969ac6768e4477786dc720686481afbfc32faedd2ab6defce9c16b5ee")),
)

class UserAdmin(ModelView, model=models.User):
    name = "User"
    identity = "user"
    column_list = [models.User.id, models.User.email, models.User.name, models.User.role]

class PlanAdmin(ModelView, model=models.Plan):
    name = "Plan"
    identity = "plan"
    column_list = [models.Plan.id, models.Plan.title, models.Plan.category, models.Plan.coach_name, models.Plan.price]

admin.add_view(UserAdmin)
admin.add_view(PlanAdmin)

# include routers defined in separate modules
api.include_router(auth.router)
api.include_router(users.router)
api.include_router(plans.router)


# convenience alias so older clients that hit `/purchase-plan` directly
# (the original Flutter code) continue to work.  it simply forwards the
# request to the same logic used by the router above.
@api.post("/purchase-plan")
def purchase_plan_alias(
    payload: dict = Body(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    plan_id = payload.get("plan_id")
    if plan_id is None:
        raise HTTPException(status_code=400, detail="plan_id is required")

    plan = db.query(models.Plan).get(plan_id)
    if not plan:
        return {"error": "Plan not found"}

    db_user = db.query(models.User).get(current_user.id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    if plan not in db_user.purchased_plans:
        db_user.purchased_plans.append(plan)
        db.commit()
        return {"message": "Purchase successful"}

    return {"message": "Already owned"}
