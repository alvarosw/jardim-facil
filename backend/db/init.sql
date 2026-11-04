-- Esquema e dados iniciais do Jardim Fácil.
-- Executado automaticamente pelo container db apenas na primeira criação do volume.

CREATE TABLE plantas (
    id              TEXT PRIMARY KEY,
    nome            TEXT NOT NULL,
    nome_cientifico TEXT NOT NULL,
    emoji           TEXT NOT NULL,
    descricao       TEXT NOT NULL,
    luminosidade    TEXT NOT NULL,
    rega            TEXT NOT NULL,
    dificuldade     TEXT NOT NULL CHECK (dificuldade IN ('Fácil', 'Média', 'Difícil')),
    dica            TEXT NOT NULL
);

CREATE TABLE usuarios (
    id         TEXT PRIMARY KEY,
    nome       TEXT NOT NULL,
    email      TEXT NOT NULL UNIQUE,
    senha_hash TEXT NOT NULL
);

CREATE TABLE favoritos (
    usuario_id TEXT NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    planta_id  TEXT NOT NULL REFERENCES plantas (id) ON DELETE CASCADE,
    PRIMARY KEY (usuario_id, planta_id)
);

-- Plantas originais (assets/data/plantas.json)
INSERT INTO plantas (id, nome, nome_cientifico, emoji, descricao, luminosidade, rega, dificuldade, dica) VALUES
('suculenta', 'Suculenta', 'Echeveria spp.', '🪴', 'Planta compacta que armazena água nas folhas carnudas. Ideal para quem tem pouco tempo para cuidar.', 'Sol pleno ou luz indireta intensa', 'A cada 7 a 10 dias', 'Fácil', 'Regue somente quando o substrato estiver completamente seco e evite molhar o centro da roseta.'),
('samambaia', 'Samambaia', 'Nephrolepis exaltata', '🌿', 'Folhagem exuberante e caída, ótima para ambientes úmidos e com bastante charme.', 'Meia-sombra ou luz indireta', '2 a 3 vezes por semana', 'Média', 'Mantenha o substrato sempre úmido e borrife água nas folhas em dias secos.'),
('espada-de-sao-jorge', 'Espada-de-São-Jorge', 'Dracaena trifasciata', '🗡️', 'Planta resistente de folhas rígidas e eretas, que tolera bem o esquecimento.', 'Meia-sombra ou sol pleno', 'A cada 10 a 15 dias', 'Fácil', 'O excesso de água apodrece as raízes; na dúvida, espere o solo secar antes de regar.'),
('manjericao', 'Manjericão', 'Ocimum basilicum', '🌱', 'Erva aromática muito usada na culinária, que cresce bem em vasos na janela.', 'Sol pleno (mínimo de 4 a 6 horas por dia)', 'A cada 2 ou 3 dias', 'Média', 'Pode as pontas e retire as flores para estimular novas folhas.'),
('zamioculca', 'Zamioculca', 'Zamioculcas zamiifolia', '🍃', 'Folhas brilhantes e muito resistentes, ótima para interiores e iniciantes.', 'Luz indireta ou sombra clara', 'A cada 15 dias', 'Fácil', 'Armazena água nos rizomas, então regue pouco, principalmente no inverno.'),
('jiboia', 'Jiboia', 'Epipremnum aureum', '☘️', 'Trepadeira de crescimento rápido, pode ficar pendurada ou apoiada em tutores.', 'Luz indireta ou meia-sombra', '1 a 2 vezes por semana', 'Fácil', 'É tóxica para pets; mantenha fora do alcance de cães e gatos.'),
('lirio-da-paz', 'Lírio-da-paz', 'Spathiphyllum wallisii', '🌸', 'Folhas verde-escuras e flores brancas elegantes, comuns em salas e escritórios.', 'Meia-sombra, sem sol direto', '2 vezes por semana', 'Média', 'As folhas murchas indicam sede; regue e elas se recuperam rapidamente.'),
('costela-de-adao', 'Costela-de-adão', 'Monstera deliciosa', '🌴', 'Folhas grandes e recortadas que dão um ar tropical ao ambiente.', 'Luz indireta intensa', '1 a 2 vezes por semana', 'Fácil', 'Limpe as folhas com pano úmido e ofereça um tutor para ela crescer.'),
('babosa', 'Babosa', 'Aloe vera', '🌾', 'Suculenta conhecida pelo gel das folhas, usado em cuidados com a pele.', 'Sol pleno ou luz indireta intensa', 'A cada 10 a 14 dias', 'Fácil', 'Use vaso com boa drenagem e nunca deixe água acumulada no prato.'),
('hortela', 'Hortelã', 'Mentha spp.', '🥬', 'Erva aromática de crescimento vigoroso, usada em chás e sucos.', 'Sol pleno ou meia-sombra', 'A cada 2 dias', 'Fácil', 'Cultive em vaso separado, pois suas raízes se espalham e dominam outras plantas.'),
('cacto', 'Cacto', 'Cereus spp.', '🌵', 'Planta de origem desértica, armazena água no caule e dispensa cuidados frequentes.', 'Sol pleno', 'A cada 15 a 20 dias', 'Fácil', 'Use substrato bem arenoso e reduza a rega no inverno.'),
('orquidea', 'Orquídea', 'Phalaenopsis spp.', '💮', 'Flores duradouras e delicadas, uma das plantas decorativas mais populares.', 'Luz indireta intensa, sem sol direto', '1 vez por semana', 'Difícil', 'Regue sem molhar o miolo da planta e deixe as raízes secarem entre as regas.');

-- Novas plantas comuns em casas e apartamentos
INSERT INTO plantas (id, nome, nome_cientifico, emoji, descricao, luminosidade, rega, dificuldade, dica) VALUES
('peperomia', 'Peperômia', 'Peperomia obtusifolia', '🍀', 'Folhas carnudas e brilhantes em tons de verde, pequena e fácil de manter em qualquer canto da casa.', 'Meia-sombra ou luz indireta', 'A cada 7 a 10 dias', 'Fácil', 'Espere o substrato secar entre as regas, pois o excesso de água causa podridão.'),
('anturio', 'Antúrio', 'Anthurium andraeanum', '🌺', 'Flores vermelhas em formato de coração que duram meses e enfeitam varandas e salas.', 'Meia-sombra, com luz indireta', '2 vezes por semana', 'Média', 'Mantenha o substrato levemente úmido e adube a cada duas ou três semanas na primavera.'),
('violeta-africana', 'Violeta-africana', 'Saintpaulia ionantha', '💜', 'Plantinha de folhas aveludadas que floresce quase o ano todo em vasos pequenos.', 'Luz indireta intensa', '2 vezes por semana', 'Média', 'Regue pela borda do vaso, pois gotas nas folhas e nas flores manchem a planta.'),
('bromelia', 'Bromélia', 'Aechmea fasciata', '🍍', 'Roseta de folhas rígidas com uma inflorescência rosa que dura bastante tempo.', 'Meia-sombra ou luz indireta', '1 vez por semana', 'Fácil', 'Mantenha um pouco de água no centro da roseta e troque essa água a cada duas semanas.'),
('comigo-ninguem-pode', 'Comigo-ninguém-pode', 'Dieffenbachia seguine', '🌿', 'Folhagem grande e variegada que purifica o ar e tolera bem ambientes internos com pouca luz.', 'Meia-sombra ou luz indireta', '1 vez por semana', 'Fácil', 'É tóxica se ingerida e causa irritação na pele; use luvas ao podar e mantenha longe de crianças e pets.'),
('lavanda', 'Lavanda', 'Lavandula angustifolia', '💐', 'Arbusto aromático de flores lilás, muito apreciado por seu perfume e pelas abelhas.', 'Sol pleno, no mínimo 6 horas por dia', 'A cada 5 a 7 dias', 'Difícil', 'Não tolera umidade excessiva; use vaso com drenagem e substrato bem arejado.'),
('alecrim', 'Alecrim', 'Salvia rosmarinus', '🌿', 'Erva aromática de folhas finas e perenes, ótima para temperos e chás.', 'Sol pleno', 'A cada 3 a 4 dias', 'Média', 'Poda leve depois da floração estimula a planta a crescer mais cheia.'),
('salsinha', 'Salsinha', 'Petroselinum crispum', '🥬', 'Erva de folhas crespas muito usada em receitas, fácil de cultivar em vasos.', 'Sol pleno ou meia-sombra', 'A cada 2 dias', 'Média', 'Colha as folhas externas primeiro e mantenha o solo uniformemente úmido.'),
('cebolinha', 'Cebolinha', 'Allium fistulosum', '🌱', 'Erva de folhas tubulares e sabor suave, cresce rápido e rende várias colheitas.', 'Sol pleno ou meia-sombra', 'A cada 2 dias', 'Fácil', 'Corte as folhas rente à base e deixe pelo menos alguns centímetros para rebrotar.'),
('hortensia', 'Hortênsia', 'Hydrangea macrophylla', '💠', 'Arbusto de flores grandes em bolas azuis, rosas ou brancas, que mudam de cor conforme o solo.', 'Meia-sombra, com sol da manhã', 'Diariamente no verão', 'Difícil', 'Precisa de rega constante, pois murcha rapidamente quando o solo seca.'),
('azaleia', 'Azaleia', 'Rhododendron simsii', '🌺', 'Arbusto floral de flores vibrantes que cobrem a planta na primavera.', 'Meia-sombra e luz indireta', '3 vezes por semana', 'Difícil', 'Use água sem cal ou com pH levemente ácido e evite deixar o substrato encharcado.'),
('begonia', 'Begônia', 'Begonia spp.', '🌸', 'Planta de folhas decorativas e flores delicadas, muito versátil em vasos e jardineiras.', 'Meia-sombra ou luz indireta', '2 vezes por semana', 'Média', 'Regue a terra e não molhe as folhas, para evitar fungos.'),
('maranta', 'Maranta', 'Maranta leuconeura', '🍃', 'Folhas com desenhos que se fecham à noite, uma planta decorativa e cheia de graça.', 'Meia-sombra, sem sol direto', '2 vezes por semana', 'Média', 'Use água filtrada ou da chuva, pois ela é sensível ao cloro e ao sal.'),
('calathea', 'Calathea', 'Calathea orbifolia', '🍃', 'Folhas grandes e listradas que se movem ao longo do dia, exigente com umidade.', 'Meia-sombra, sem sol direto', '2 vezes por semana', 'Difícil', 'Mantenha o ar úmido e evite água da torneira com muito cloro ou cal.'),
('ficus-lira', 'Ficus-lira', 'Ficus lyrata', '🌳', 'Árvore de folhas grandes em formato de violino, muito popular em salas de estar.', 'Luz indireta intensa', '1 vez por semana', 'Média', 'Não mude a planta de lugar com frequência, pois ela pode deixar cair as folhas.'),
('ficus-benjamina', 'Ficus-benjamina', 'Ficus benjamina', '🌳', 'Árvore de folhas pequenas e brilhantes, ótima para compor ambientes internos.', 'Luz indireta ou sol da manhã', '1 a 2 vezes por semana', 'Média', 'Evite correntes de ar e mudanças bruscas de lugar, que fazem as folhas cair.'),
('yucca', 'Iúca', 'Yucca elephantipes', '🌵', 'Planta de caule firme e folhas em espada, resistente e de visual marcante.', 'Sol pleno ou luz indireta intensa', 'A cada 10 a 14 dias', 'Fácil', 'Regue apenas quando a terra estiver seca e nunca deixe água no prato.'),
('agave', 'Agave', 'Agave americana', '🌵', 'Suculenta de roseta grande e folhas espinhosas, que dispensa cuidados frequentes.', 'Sol pleno', 'A cada 15 a 20 dias', 'Fácil', 'Use substrato arenoso e manuseie com cuidado por causa dos espinhos nas pontas.'),
('pleomele', 'Pleomele', 'Dracaena reflexa', '🌿', 'Arbusto de folhas em espiral com faixas claras, bom para ambientes internos claros.', 'Meia-sombra ou luz indireta', '1 vez por semana', 'Fácil', 'Regue quando o substrato secar na superfície e evite o encharcamento.'),
('dinheiro-em-penca', 'Dinheiro-em-penca', 'Pilea peperomioides', '🪙', 'Folhas redondas em forma de moeda que crescem em hastes finas e muito bonitas.', 'Luz indireta intensa', '1 vez por semana', 'Fácil', 'Gire o vaso de vez em quando para as folhas crescerem retas e equilibradas.'),
('tillandsia', 'Tilândsia', 'Tillandsia spp.', '✨', 'Planta aérea que não precisa de substrato e absorve água e nutrientes pelas folhas.', 'Luz indireta intensa', 'Borrifar 2 a 3 vezes por semana', 'Fácil', 'Mergulhe a planta em água por 20 minutos uma vez por semana e deixe secar de cabeça para baixo.'),
('guzmania', 'Guzmânia', 'Guzmania lingulata', '🌺', 'Bromélia de roseta colorida e brácteas vistosas que duram vários meses.', 'Meia-sombra ou luz indireta', '1 vez por semana', 'Fácil', 'Mantenha a roseta com água limpa e troque a água a cada duas semanas.'),
('kalanchoe', 'Kalanchoe', 'Kalanchoe blossfeldiana', '🌼', 'Suculenta de flores pequenas e coloridas que florescem durante muitas semanas.', 'Sol pleno ou luz indireta intensa', 'A cada 7 a 10 dias', 'Fácil', 'Retire as flores secas para estimular novas floradas.'),
('coroa-de-cristo', 'Coroa-de-cristo', 'Euphorbia milii', '🌵', 'Arbusto espinhoso com flores vermelhas pequenas que aparecem quase o ano todo.', 'Sol pleno', 'A cada 10 a 15 dias', 'Fácil', 'É tóxica por causa do látex; use luvas para manusear e mantenha longe de crianças e pets.'),
('pimenta-dedo-de-moca', 'Pimenta-dedo-de-moça', 'Capsicum baccatum', '🌶️', 'Pimenteira de frutos alongados e ardidos, ótima para cultivar em vasos na varanda.', 'Sol pleno, no mínimo 6 horas por dia', 'A cada 2 ou 3 dias', 'Média', 'Mantenha o solo úmido, mas sem encharcar, e adube com frequência durante a frutificação.'),
('tomate-cereja', 'Tomate-cereja', 'Solanum lycopersicum var. cerasiforme', '🍅', 'Tomateiro compacto que produz frutos pequenos e doces em vasos grandes.', 'Sol pleno, no mínimo 6 horas por dia', 'Diariamente no verão', 'Média', 'Use vaso grande, tutore a planta e retire os brotos laterais para ganhar mais frutos.'),
('morango', 'Morango', 'Fragaria × ananassa', '🍓', 'Planta rasteira que produz frutos vermelhos e doces, ideal para vasos suspensos ou jardineiras.', 'Sol pleno', 'A cada 2 dias', 'Média', 'Retire as folhas secas e mantenha o solo úmido; proteja os frutos do contato direto com a terra.'),
('alface', 'Alface', 'Lactuca sativa', '🥬', 'Folhas tenras e crocantes que crescem rápido em vasos rasos e canteiros pequenos.', 'Sol pleno ou meia-sombra', 'A cada 2 dias', 'Fácil', 'Colha as folhas externas e replante a cada dois meses para ter colheita constante.');

INSERT INTO usuarios (id, nome, email, senha_hash) VALUES
('1', 'Maria Silva', 'maria@jardim.com', '$2b$12$QzCYUiCeFPibEnYIbmne5uay1/DiABcf3YBTvBznkiRchj.my432G'),
('2', 'João Souza', 'joao@jardim.com', '$2b$12$yBc/RTFdVAp6m3dUxNR5ouC7m5sA0C/8MuVlHKd6N8YVlY9/X1Unq');

INSERT INTO favoritos (usuario_id, planta_id) VALUES
('1', 'samambaia'),
('1', 'manjericao'),
('2', 'cacto');
