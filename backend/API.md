# Contrato da API — Jardim Fácil V2

Dois serviços web (Python + FastAPI), cada um no seu container, mais um
PostgreSQL em container próprio. Tudo sobe com `docker compose up --build`
na raiz do repositório.

| Serviço            | Porta (host) | Responsabilidade                    |
|--------------------|--------------|-------------------------------------|
| `plantas-service`  | 8001         | Catálogo de plantas (paginado)      |
| `usuarios-service` | 8002         | Login (JWT) e favoritos do usuário  |
| `db` (PostgreSQL)  | 5432         | Tabelas `plantas`, `usuarios`, `favoritos` |

Campos JSON em camelCase, iguais ao `Planta.toJson()` do app:
`id, nome, nomeCientifico, emoji, descricao, luminosidade, rega, dificuldade, dica`.
`dificuldade` ∈ {`Fácil`, `Média`, `Difícil`}.

## plantas-service (:8001)

### `GET /saude`
`200 {"status": "ok"}`

### `GET /plantas`
Query (todas opcionais):
- `pagina` (int, padrão 1, mínimo 1)
- `tamanho` (int, padrão 10, 1..50)
- `busca` (texto; filtra `nome` sem diferenciar maiúsculas, via `ILIKE '%busca%'`)
- `dificuldade` (`Fácil` | `Média` | `Difícil`; ausente = todas)
- `ids` (lista separada por vírgula; quando presente retorna só essas plantas)

Ordenação: por `nome` ascendente.

Resposta `200`:
```json
{
  "itens": [ { "id": "samambaia", "nome": "Samambaia", "...": "..." } ],
  "pagina": 1,
  "tamanho": 10,
  "total": 40,
  "temMais": true
}
```

### `GET /plantas/{id}`
`200` com a planta, ou `404 {"detail": "Planta não encontrada"}`.

## usuarios-service (:8002)

### `GET /saude`
`200 {"status": "ok"}`

### `POST /auth/login`
Corpo: `{"email": "maria@jardim.com", "senha": "123456"}` (e-mail sem diferenciar maiúsculas, com trim).

`200`:
```json
{
  "token": "<JWT HS256, expira em 24h, claim sub = id do usuário>",
  "usuario": { "id": "1", "nome": "Maria Silva", "email": "maria@jardim.com" }
}
```
`401 {"detail": "E-mail ou senha inválidos"}`

Senhas guardadas com hash bcrypt.

### Rotas autenticadas
Header `Authorization: Bearer <token>`; sem token ou token inválido → `401`.

- `GET /favoritos` → `200 {"ids": ["manjericao", "samambaia"]}`
- `PUT /favoritos/{plantaId}` → `204` (idempotente)
- `DELETE /favoritos/{plantaId}` → `204` (idempotente)

## Dados iniciais (seed)
- 40 plantas (as 12 atuais de `assets/data/plantas.json` + 28 novas comuns em casa/apartamento).
- Usuários: `1` Maria Silva `maria@jardim.com` / `123456`; `2` João Souza `joao@jardim.com` / `123456`.
- Favoritos: Maria → `samambaia`, `manjericao`; João → `cacto`.

## App
URL base de cada serviço configurável por `--dart-define`:
`PLANTAS_API` (padrão `http://localhost:8001`) e `USUARIOS_API` (padrão `http://localhost:8002`).
No celular via USB: `adb reverse tcp:8001 tcp:8001 && adb reverse tcp:8002 tcp:8002`.
