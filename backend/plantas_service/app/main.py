import os
from typing import Literal

import psycopg
from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from psycopg.rows import dict_row
from pydantic import BaseModel, ConfigDict, Field

DATABASE_URL = os.environ["DATABASE_URL"]

app = FastAPI(title="Plantas Service")

# CORS liberado para o Flutter web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

Dificuldade = Literal["Fácil", "Média", "Difícil"]


class Planta(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: str
    nome: str
    nome_cientifico: str = Field(alias="nomeCientifico")
    emoji: str
    descricao: str
    luminosidade: str
    rega: str
    dificuldade: str
    dica: str


class PaginaPlantas(BaseModel):
    itens: list[Planta]
    pagina: int
    tamanho: int
    total: int
    tem_mais: bool = Field(alias="temMais")

    model_config = ConfigDict(populate_by_name=True)


def get_conn():
    with psycopg.connect(DATABASE_URL, row_factory=dict_row, autocommit=True) as conn:
        yield conn


@app.get("/saude")
def saude():
    return {"status": "ok"}


@app.get("/plantas", response_model=PaginaPlantas)
def listar_plantas(
    pagina: int = Query(1, ge=1),
    tamanho: int = Query(10, ge=1, le=50),
    busca: str | None = None,
    dificuldade: Dificuldade | None = None,
    ids: str | None = None,
    conn: psycopg.Connection = Depends(get_conn),
):
    # Monta o filtro dinamicamente, sempre com parâmetros (sem concatenar SQL)
    condicoes = []
    params: list = []

    if busca:
        condicoes.append("nome ILIKE %s")
        params.append(f"%{busca}%")
    if dificuldade:
        condicoes.append("dificuldade = %s")
        params.append(dificuldade)
    if ids:
        lista_ids = [i.strip() for i in ids.split(",") if i.strip()]
        condicoes.append("id = ANY(%s)")
        params.append(lista_ids)

    where = f"WHERE {' AND '.join(condicoes)}" if condicoes else ""

    total = conn.execute(f"SELECT COUNT(*) AS total FROM plantas {where}", params).fetchone()["total"]

    offset = (pagina - 1) * tamanho
    linhas = conn.execute(
        f"SELECT * FROM plantas {where} ORDER BY nome ASC LIMIT %s OFFSET %s",
        [*params, tamanho, offset],
    ).fetchall()

    return PaginaPlantas(
        itens=[Planta(**linha) for linha in linhas],
        pagina=pagina,
        tamanho=tamanho,
        total=total,
        temMais=offset + tamanho < total,
    )


@app.get("/plantas/{planta_id}", response_model=Planta)
def buscar_planta(planta_id: str, conn: psycopg.Connection = Depends(get_conn)):
    linha = conn.execute("SELECT * FROM plantas WHERE id = %s", (planta_id,)).fetchone()
    if linha is None:
        raise HTTPException(status_code=404, detail="Planta não encontrada")
    return Planta(**linha)
