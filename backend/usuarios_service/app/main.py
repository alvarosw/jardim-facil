import os
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
import psycopg
from fastapi import Depends, FastAPI, Header, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from psycopg.errors import ForeignKeyViolation
from psycopg.rows import dict_row
from pydantic import BaseModel

DATABASE_URL = os.environ["DATABASE_URL"]
JWT_SECRET = os.environ["JWT_SECRET"]
JWT_ALGORITMO = "HS256"
JWT_EXPIRA_HORAS = 24

app = FastAPI(title="Usuarios Service")

# CORS liberado para o Flutter web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class LoginEntrada(BaseModel):
    email: str
    senha: str


def get_conn():
    with psycopg.connect(DATABASE_URL, row_factory=dict_row, autocommit=True) as conn:
        yield conn


def usuario_autenticado(authorization: str | None = Header(default=None)) -> str:
    """Valida o Bearer token e devolve o id do usuário (claim sub)."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Não autenticado")
    token = authorization.removeprefix("Bearer ").strip()
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITMO])
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Token inválido")
    return payload["sub"]


@app.get("/saude")
def saude():
    return {"status": "ok"}


@app.post("/auth/login")
def login(entrada: LoginEntrada, conn: psycopg.Connection = Depends(get_conn)):
    email = entrada.email.strip().lower()
    usuario = conn.execute(
        "SELECT id, nome, email, senha_hash FROM usuarios WHERE lower(trim(email)) = %s",
        (email,),
    ).fetchone()

    if usuario is None or not bcrypt.checkpw(
        entrada.senha.encode("utf-8"), usuario["senha_hash"].encode("utf-8")
    ):
        raise HTTPException(status_code=401, detail="E-mail ou senha inválidos")

    agora = datetime.now(timezone.utc)
    token = jwt.encode(
        {
            "sub": usuario["id"],
            "iat": agora,
            "exp": agora + timedelta(hours=JWT_EXPIRA_HORAS),
        },
        JWT_SECRET,
        algorithm=JWT_ALGORITMO,
    )

    return {
        "token": token,
        "usuario": {
            "id": usuario["id"],
            "nome": usuario["nome"],
            "email": usuario["email"],
        },
    }


@app.get("/favoritos")
def listar_favoritos(
    usuario_id: str = Depends(usuario_autenticado),
    conn: psycopg.Connection = Depends(get_conn),
):
    linhas = conn.execute(
        "SELECT planta_id FROM favoritos WHERE usuario_id = %s ORDER BY planta_id",
        (usuario_id,),
    ).fetchall()
    return {"ids": [linha["planta_id"] for linha in linhas]}


@app.put("/favoritos/{planta_id}", status_code=204)
def adicionar_favorito(
    planta_id: str,
    usuario_id: str = Depends(usuario_autenticado),
    conn: psycopg.Connection = Depends(get_conn),
):
    try:
        # ON CONFLICT torna a operação idempotente
        conn.execute(
            "INSERT INTO favoritos (usuario_id, planta_id) VALUES (%s, %s) "
            "ON CONFLICT (usuario_id, planta_id) DO NOTHING",
            (usuario_id, planta_id),
        )
    except ForeignKeyViolation:
        raise HTTPException(status_code=404, detail="Planta não encontrada")
    return Response(status_code=204)


@app.delete("/favoritos/{planta_id}", status_code=204)
def remover_favorito(
    planta_id: str,
    usuario_id: str = Depends(usuario_autenticado),
    conn: psycopg.Connection = Depends(get_conn),
):
    conn.execute(
        "DELETE FROM favoritos WHERE usuario_id = %s AND planta_id = %s",
        (usuario_id, planta_id),
    )
    return Response(status_code=204)
