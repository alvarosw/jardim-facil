# Jardim Fácil

Aplicativo Flutter com um catálogo de plantas comuns de casa e apartamento.
Cada planta tem uma tela de detalhes com luminosidade, frequência de rega,
nível de dificuldade e uma dica de cuidado. Projeto da disciplina de
Programação para Dispositivos Móveis (IFBA), Avaliação II.

## Versão 2: back-end real

Os dados não ficam mais em JSON dentro do app. O app consome dois serviços web:

- **plantas-service** (porta 8001): catálogo paginado, busca e filtro por dificuldade.
- **usuarios-service** (porta 8002): login (JWT) e favoritos do usuário.
- **PostgreSQL**: banco dos dois serviços, em container próprio.

Os três sobem com Docker Compose. O contrato da API está em `backend/API.md`.

A lista de plantas é **carregada sob demanda** (lazy-loading): são 10 plantas
por página, e a próxima página é buscada quando o usuário rola perto do fim.
Busca e filtro reiniciam a paginação na página 1, e puxar a lista para baixo
também.

## Funcionalidades

**Usuário anônimo**
- Ver a lista de plantas, buscar pelo nome e filtrar por dificuldade.
- Abrir os detalhes de qualquer planta.

**Usuário logado**
- Tudo o que o anônimo faz.
- Favoritar e desfavoritar plantas (coração na lista ou botão nos detalhes).
- Acessar a tela "Meu jardim" com as plantas escolhidas.
- Sair da conta (logoff) com confirmação.

## Credenciais de teste

| Nome | E-mail | Senha |
|------|--------|-------|
| Maria Silva | maria@jardim.com | 123456 |
| João Souza | joao@jardim.com | 123456 |

## Como executar

### 1. Back-end

Na raiz do repositório:

```bash
docker compose up --build
```

Sobem `plantas-service` (8001), `usuarios-service` (8002) e o PostgreSQL (5432).
Para testar: `curl http://localhost:8001/saude` deve responder `{"status": "ok"}`.

### 2. App

Com um celular Android conectado por USB, redirecione as portas para o PC:

```bash
adb reverse tcp:8001 tcp:8001 && adb reverse tcp:8002 tcp:8002
flutter run
```

Em outros casos (emulador, celular na mesma rede Wi-Fi), informe o endereço
do PC com `--dart-define`. No emulador Android, o PC é `10.0.2.2`:

```bash
flutter run --dart-define=PLANTAS_API=http://<ip-do-pc>:8001 --dart-define=USUARIOS_API=http://<ip-do-pc>:8002
```

Os endereços padrão ficam em `lib/services/api_config.dart`
(`http://localhost:8001` e `http://localhost:8002`).

### Testes e análise estática

```bash
flutter analyze
flutter test
```

Os testes não precisam do back-end: usam um servidor falso em memória
(`test/fake_api.dart`) com `MockClient` do pacote `http`.

## Estrutura de pastas

```
backend/
  API.md                    # contrato da API (rotas, campos, códigos de resposta)
  plantas_service/          # FastAPI: catálogo de plantas (porta 8001)
  usuarios_service/         # FastAPI: login e favoritos (porta 8002)
  db/                       # script SQL inicial (tabelas e dados de exemplo)
  smoke_test.sh             # teste rápido dos serviços em execução
docker-compose.yml          # sobe os dois serviços e o PostgreSQL
lib/
  main.dart                 # ponto de entrada, providers, tema e troca de telas
  models/                   # Planta e Usuario
  services/                 # api_config, plantas, autenticação, favoritos e estado da tela
  screens/                  # lista (paginada), detalhes, login e Meu jardim
  widgets/                  # PlantaCard, DificuldadeChip, InfoCard
test/
  fake_api.dart             # servidor falso para os testes
  data_layer_test.dart      # repositórios e serviços
  widget_test.dart          # telas e fluxos (inclui paginação ao rolar)
```
