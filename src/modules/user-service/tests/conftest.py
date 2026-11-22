import os

os.environ["JWT_SECRET_KEY"] = "unit-test-secret-key-value"
os.environ["DATABASE_URL"] = "sqlite://"

pytest_plugins = [
    "tests.requirements.service_scope",
    "tests.requirements.session_steps",
    "tests.requirements.account_settings_steps",
    "tests.requirements.key_steps",
]
