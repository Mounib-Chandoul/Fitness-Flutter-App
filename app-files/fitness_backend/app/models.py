import os
from sqlalchemy import JSON, create_engine, Column, Integer, String, ForeignKey, Float, Table
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship

# --- configuration --------------------------------------------------------
# allow the database URL to be overridden by an environment variable so
# production deployments can switch to PostgreSQL, MySQL, etc.  the default
# remains a local SQLite file for development convenience.
DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./fitness_tracker.db")
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

purchases = Table(
    "purchases",
    Base.metadata,
    Column("user_id", Integer, ForeignKey("users.id"), primary_key=True),
    Column("plan_id", Integer, ForeignKey("plans.id"), primary_key=True)
)

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    password = Column(String)
    name = Column(String, index=True, nullable=False)
    role = Column(String, default="client")
    bio = Column(String, nullable=True, default="")
    specialization = Column(String, nullable=True, default="")
    emoji = Column(String, nullable=True, default="⚡")

    plans_created = relationship("Plan", back_populates="coach", cascade="all, delete-orphan")
    purchased_plans = relationship("Plan", secondary=purchases, back_populates="buyers")

class Plan(Base):
    __tablename__ = "plans"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    category = Column(String)
    description = Column(String, nullable=True)
    duration = Column(Integer)
    workouts_per_week = Column(Integer)
    level = Column(String)
    exercises = Column(JSON, default=[]) 
    diet = Column(String, nullable=True)
    price = Column(Float, default=0.0)
    
    # --- COACH INFO ---
    coach_id = Column(Integer, ForeignKey("users.id"))
    coach_name = Column(String) # This stores the name directly

    coach = relationship("User", back_populates="plans_created")
    buyers = relationship("User", secondary=purchases, back_populates="purchased_plans")

Base.metadata.create_all(bind=engine)