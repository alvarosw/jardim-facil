#!/usr/bin/env bash
# Smoke test end-to-end dos dois serviços, cobrindo o contrato de backend/API.md.
# Pré-requisito: stack no ar (docker compose up -d a partir da raiz do repositório).
# Uso: ./backend/smoke_test.sh
set -uo pipefail

PLANTAS="${PLANTAS_API:-http://localhost:8001}"
USUARIOS="${USUARIOS_API:-http://localhost:8002}"

PASSOU=0
FALHAS=0
STATUS=""
CORPO=""

# Faz a requisição e guarda o status HTTP e o corpo em STATUS e CORPO.
# Uso: req METODO URL [opções do curl...]
req() {
  local metodo="$1" url="$2"
  shift 2
  local arquivo
  arquivo=$(mktemp)
  STATUS=$(curl -s -o "$arquivo" -w '%{http_code}' -X "$metodo" "$@" "$url")
  CORPO=$(cat "$arquivo")
  rm -f "$arquivo"
}

# Codifica um valor para uso em query string
enc() { jq -rn --arg v "$1" '$v | @uri'; }

ok() {
  PASSOU=$((PASSOU + 1))
  echo "  [OK]    $1"
}

falha() {
  FALHAS=$((FALHAS + 1))
  echo "  [FALHA] $1 (status=$STATUS, corpo=${CORPO:0:200})"
}

# Confere o status HTTP
esperar_status() {
  local esperado="$1" nome="$2"
  if [ "$STATUS" = "$esperado" ]; then ok "$nome"; else falha "$nome (esperado $esperado)"; fi
}

# Confere um valor extraído do corpo com jq (comparação em JSON compacto)
esperar_json() {
  local nome="$1" filtro="$2" esperado="$3" obtido
  obtido=$(echo "$CORPO" | jq -c "$filtro" 2>/dev/null)
  if [ "$obtido" = "$esperado" ]; then
    ok "$nome"
  else
    falha "$nome (esperado $esperado, obtido $obtido)"
  fi
}

login() {
  req POST "$USUARIOS/auth/login" -H 'Content-Type: application/json' -d "$1"
}

echo "== plantas-service ($PLANTAS) =="

req GET "$PLANTAS/saude"
esperar_status 200 "GET /saude"
esperar_json "saude retorna status ok" '.status' '"ok"'

req GET "$PLANTAS/plantas"
esperar_status 200 "GET /plantas (padrao)"
esperar_json "paginacao tem as chaves do contrato" '.|keys|sort' '["itens","pagina","tamanho","temMais","total"]'
esperar_json "padrao: pagina 1" '.pagina' '1'
esperar_json "padrao: tamanho 10" '.tamanho' '10'
esperar_json "padrao: total 40" '.total' '40'
esperar_json "padrao: 10 itens" '.itens|length' '10'
esperar_json "padrao: temMais true" '.temMais' 'true'
esperar_json "itens usam camelCase (nomeCientifico)" '.itens[0]|keys|sort' '["descricao","dica","dificuldade","emoji","id","luminosidade","nome","nomeCientifico","rega"]'
esperar_json "itens ordenados por nome" '[.itens[].nome] == ([.itens[].nome] | sort)' 'true'

req GET "$PLANTAS/plantas?pagina=4&tamanho=10"
esperar_status 200 "GET /plantas?pagina=4&tamanho=10"
esperar_json "ultima pagina: 10 itens" '.itens|length' '10'
esperar_json "ultima pagina: temMais false" '.temMais' 'false'

req GET "$PLANTAS/plantas?pagina=5&tamanho=10"
esperar_status 200 "GET /plantas pagina alem do fim"
esperar_json "pagina vazia: 0 itens" '.itens|length' '0'
esperar_json "pagina vazia: temMais false" '.temMais' 'false'

req GET "$PLANTAS/plantas?tamanho=50"
esperar_json "tamanho 50 traz todas (40) e temMais false" '[(.itens|length), .temMais]' '[40,false]'

req GET "$PLANTAS/plantas?tamanho=51"
esperar_status 422 "tamanho acima de 50 e rejeitado"

req GET "$PLANTAS/plantas?pagina=0"
esperar_status 422 "pagina 0 e rejeitada"

req GET "$PLANTAS/plantas?busca=jiboia"
esperar_status 200 "GET /plantas?busca=jiboia"
esperar_json "busca ignora maiusculas (1 resultado)" '[.total, .itens[0].id]' '[1,"jiboia"]'

req GET "$PLANTAS/plantas?busca=$(enc 'SAMAMBAIA')"
esperar_json "busca case-insensitive (SAMAMBAIA)" '[.total, .itens[0].id]' '[1,"samambaia"]'

req GET "$PLANTAS/plantas?dificuldade=$(enc 'Difícil')"
esperar_status 200 "GET /plantas?dificuldade=Difícil"
esperar_json "dificuldade Difícil: 5 resultados" '.total' '5'
esperar_json "dificuldade Difícil: todas sao Difícil" '[.itens[].dificuldade] | unique' '["Difícil"]'

req GET "$PLANTAS/plantas?dificuldade=$(enc 'Média')&tamanho=50"
esperar_json "dificuldade Média: todas sao Média" '[.itens[].dificuldade] | unique' '["Média"]'

req GET "$PLANTAS/plantas?ids=suculenta,cacto,inexistente"
esperar_status 200 "GET /plantas?ids=..."
esperar_json "ids retorna so as plantas existentes" '[.total, [.itens[].id]]' '[2,["cacto","suculenta"]]'

req GET "$PLANTAS/plantas/samambaia"
esperar_status 200 "GET /plantas/samambaia"
esperar_json "planta traz o id e o nome cientifico" '[.id, .nomeCientifico]' '["samambaia","Nephrolepis exaltata"]'

req GET "$PLANTAS/plantas/nao-existe"
esperar_status 404 "GET /plantas/nao-existe retorna 404"
esperar_json "404 com detail do contrato" '.detail' '"Planta não encontrada"'

echo
echo "== usuarios-service ($USUARIOS) =="

req GET "$USUARIOS/saude"
esperar_status 200 "GET /saude"
esperar_json "saude retorna status ok" '.status' '"ok"'

login '{"email":"maria@jardim.com","senha":"123456"}'
esperar_status 200 "POST /auth/login (Maria) ok"
esperar_json "login retorna usuario da Maria" '.usuario' '{"id":"1","nome":"Maria Silva","email":"maria@jardim.com"}'
TOKEN_MARIA=$(echo "$CORPO" | jq -r '.token // empty')
if [ -n "$TOKEN_MARIA" ]; then ok "login retorna token JWT"; else falha "login retorna token JWT"; fi

login '{"email":"  MARIA@jardim.com ","senha":"123456"}'
esperar_status 200 "login com e-mail em maiusculas e espacos"

login '{"email":"joao@jardim.com","senha":"123456"}'
esperar_status 200 "POST /auth/login (Joao) ok"
TOKEN_JOAO=$(echo "$CORPO" | jq -r '.token // empty')

login '{"email":"maria@jardim.com","senha":"errada"}'
esperar_status 401 "login com senha errada retorna 401"
esperar_json "401 com detail do contrato" '.detail' '"E-mail ou senha inválidos"'

login '{"email":"ninguem@jardim.com","senha":"123456"}'
esperar_status 401 "login com e-mail inexistente retorna 401"

req GET "$USUARIOS/favoritos"
esperar_status 401 "GET /favoritos sem token retorna 401"

req GET "$USUARIOS/favoritos" -H "Authorization: Bearer token.invalido.aqui"
esperar_status 401 "GET /favoritos com token invalido retorna 401"

req GET "$USUARIOS/favoritos" -H "Authorization: Bearer $TOKEN_MARIA"
esperar_status 200 "GET /favoritos (Maria)"
esperar_json "favoritos da Maria (seed)" '.ids' '["manjericao","samambaia"]'

req PUT "$USUARIOS/favoritos/lavanda" -H "Authorization: Bearer $TOKEN_MARIA"
esperar_status 204 "PUT /favoritos/lavanda"

req PUT "$USUARIOS/favoritos/lavanda" -H "Authorization: Bearer $TOKEN_MARIA"
esperar_status 204 "PUT /favoritos/lavanda again (idempotente)"

req GET "$USUARIOS/favoritos" -H "Authorization: Bearer $TOKEN_MARIA"
esperar_json "lavanda aparece nos favoritos sem duplicar" '.ids' '["lavanda","manjericao","samambaia"]'

req PUT "$USUARIOS/favoritos/nao-existe" -H "Authorization: Bearer $TOKEN_MARIA"
esperar_status 404 "PUT de planta inexistente retorna 404"

req PUT "$USUARIOS/favoritos/lavanda"
esperar_status 401 "PUT /favoritos sem token retorna 401"

req DELETE "$USUARIOS/favoritos/lavanda" -H "Authorization: Bearer $TOKEN_MARIA"
esperar_status 204 "DELETE /favoritos/lavanda"

req DELETE "$USUARIOS/favoritos/lavanda" -H "Authorization: Bearer $TOKEN_MARIA"
esperar_status 204 "DELETE /favoritos/lavanda again (idempotente)"

req GET "$USUARIOS/favoritos" -H "Authorization: Bearer $TOKEN_MARIA"
esperar_json "lavanda removida dos favoritos" '.ids' '["manjericao","samambaia"]'

req DELETE "$USUARIOS/favoritos/cacto"
esperar_status 401 "DELETE /favoritos sem token retorna 401"

req GET "$USUARIOS/favoritos" -H "Authorization: Bearer $TOKEN_JOAO"
esperar_json "favoritos isolados por usuario (Joao)" '.ids' '["cacto"]'

echo
echo "Resultado: $PASSOU ok, $FALHAS falha(s)"
[ "$FALHAS" -eq 0 ]
