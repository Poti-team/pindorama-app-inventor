-- Area do mapa
CREATE TABLE public.categoria (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  nome character varying NOT NULL UNIQUE,
  descricao text,
  icone_url character varying(500),
  cor_tema character varying(7),
  ativa boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  deleted_at timestamp with time zone NULL,
  total_vezes_acessada integer NOT NULL DEFAULT 0,
  CONSTRAINT categoria_pkey PRIMARY KEY (id)
);

CREATE TABLE public.conteudo (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_categoria bigint NOT NULL,
  titulo character varying(200) NOT NULL,
  descricao text NOT NULL,
  imagem_capa_url character varying(500),
  ordem smallint NOT NULL DEFAULT 1,
  ativo boolean NOT NULL DEFAULT true,
  total_paginas smallint NOT NULL DEFAULT 0,
  tempo_leitura_estimado smallint NOT NULL DEFAULT 0, 
  num_visualizacoes integer NOT NULL DEFAULT 0,
  num_conclusoes integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone DEFAULT timezone('utc':: text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  deleted_at timestamp with time zone NULL,
  CONSTRAINT conteudo_pkey PRIMARY KEY (id),
  CONSTRAINT conteudo_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categoria(id) ON DELETE RESTRICT,
  CONSTRAINT conteudo_duracao_check CHECK (duracao_estimada_minutos > 0),
  CONSTRAINT conteudo_total_paginas_check CHECK (total_paginas >= 0),
  CONSTRAINT uq_conteudo_categoria_ordem UNIQUE (id_categoria, ordem)
);
CREATE TABLE public.pagina (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_conteudo bigint NOT NULL,
  ordem smallint NOT NULL DEFAULT 1,
  corpo text NOT NULL, -- string HTML sem estilização, mas com indicações como negrito, italico, paragrafo etc.
  titulo_pagina character varying(200),
  caracteres_maximo integer DEFAULT 800,
  notas text NULL, -- (observações) string HTML sem estilização, mas com indicações como negrito, italico, paragrafo etc.
  total_visualizacoes integer NOT NULL DEFAULT 0,
  tempo_medio_leitura interval,
  created_at timestamp with time zone DEFAULT timezone('utc':: text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT pagina_pkey PRIMARY KEY (id),
  CONSTRAINT pagina_id_conteudo_fkey FOREIGN KEY (id_conteudo) REFERENCES public.conteudo(id) ON DELETE RESTRICT,
  CONSTRAINT pagina_caracteres_check CHECK (caracteres_maximo > 0 AND caracteres_maximo <= 1500),
  CONSTRAINT uq_pagina_conteudo_ordem UNIQUE (id_conteudo, ordem)
);

CREATE TABLE public.pagina_imagem (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_pagina bigint NOT NULL,
  url character varying(500) NOT NULL,
  alt_text text NOT NULL,
  descricao text,  
  posicao character varying(20) DEFAULT 'corpo',
  ordem smallint DEFAULT 1,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT pagina_imagem_pkey PRIMARY KEY (id),
  CONSTRAINT pagina_imagem_id_pagina_fkey FOREIGN KEY (id_pagina) REFERENCES public.pagina(id) ON DELETE CASCADE,--OK
  CONSTRAINT pagina_imagem_posicao_check CHECK (posicao IN ('topo', 'meio', 'rodape', 'corpo')),
  CONSTRAINT uq_pagina_imagem_ordem UNIQUE (id_pagina, ordem)
);

CREATE TABLE public.quiz (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_categoria bigint NOT NULL,
  titulo character varying(200) NOT NULL,
  descricao text,
  num_perguntas smallint NOT NULL DEFAULT 0,
  pontos_base integer NOT NULL DEFAULT 100,
  tempo_limite_segundos integer NULL,
  percentual_min_conclusao smallint DEFAULT 70 NULL,
  dificuldade character varying(1) NULL DEFAULT 'f',
  ativo boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc':: text, now()) NOT NULL,
  deleted_at timestamp with time zone NULL,
  num_vezes_iniciado integer NOT NULL DEFAULT 0,
  num_vezes_concluido integer NOT NULL DEFAULT 0,
  CONSTRAINT quiz_pkey PRIMARY KEY (id),
  CONSTRAINT quiz_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categoria(id) ON DELETE RESTRICT,
  CONSTRAINT quiz_pontos_check CHECK (pontos_base >= 0),
  CONSTRAINT quiz_tempo_limite_check CHECK (tempo_limite_segundos > 0),
  CONSTRAINT quiz_dificuldade_check CHECK (dificuldade IN ('f', 'm', 'd')),
  CONSTRAINT quiz_percentual_check CHECK (percentual_min_conclusao BETWEEN 0 AND 100)
);

CREATE TABLE public.conteudo_quiz (
  id_conteudo bigint NOT NULL,
  id_quiz bigint NOT NULL,
  ordem smallint NOT NULL DEFAULT 1,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT conteudo_quiz_pkey PRIMARY KEY (id_conteudo, id_quiz),
  CONSTRAINT conteudo_quiz_id_conteudo_fkey FOREIGN KEY (id_conteudo) REFERENCES public.conteudo(id) ON DELETE RESTRICT,
  CONSTRAINT conteudo_quiz_id_quiz_fkey FOREIGN KEY (id_quiz) REFERENCES public.quiz(id) ON DELETE RESTRICT,
  CONSTRAINT uq_conteudo_quiz_ordem UNIQUE (id_conteudo, ordem)
);

CREATE TABLE public.pergunta (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_quiz bigint NOT NULL,
  ordem smallint NOT NULL DEFAULT '1'::smallint,
  enunciado text NOT NULL,
  explicacao text NULL,
  tipo character varying(3) DEFAULT 'm_e',
  pontos integer NOT NULL DEFAULT 10,  
  total_tentativas_corretas integer NOT NULL DEFAULT 0,
  total_tentativas_erradas integer NOT NULL DEFAULT 0,
  total_dicas_usadas integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone DEFAULT timezone('utc':: text, now()) NOT NULL,
  CONSTRAINT pergunta_pkey PRIMARY KEY (id),
  CONSTRAINT pergunta_id_quiz_fkey FOREIGN KEY (id_quiz) REFERENCES public.quiz(id) ON DELETE RESTRICT,
  CONSTRAINT pergunta_tipo_check CHECK (tipo IN ('m_e', 'v_f')),
  CONSTRAINT pergunta_pontos_check CHECK (pontos >= 0),
  CONSTRAINT uq_pergunta_quiz_ordem UNIQUE (id_quiz, ordem)
);

CREATE TABLE public.dica (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_pergunta bigint NOT NULL,
  texto text NOT NULL,
  custo_pontos smallint NOT NULL DEFAULT 5; -- penalização na pontuação para o quiz específico
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT dica_pkey PRIMARY KEY (id),
  CONSTRAINT dica_id_pergunta_fkey FOREIGN KEY (id_pergunta) REFERENCES public.pergunta(id) ON DELETE RESTRICT,
  CONSTRAINT custo_pontos_check CHECK (custo_pontos > 0);
  CONSTRAINT uq_dica_pergunta UNIQUE (id_pergunta);  
);

CREATE TABLE public.alternativa (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_pergunta bigint NOT NULL,
  ordem smallint NOT NULL DEFAULT 1,  
  texto text NOT NULL,
  correta boolean NOT NULL DEFAULT false,  
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT alternativa_pkey PRIMARY KEY (id),
  CONSTRAINT alternativa_id_pergunta_fkey FOREIGN KEY (id_pergunta) REFERENCES public.pergunta(id) ON DELETE RESTRICT,
  CONSTRAINT uq_alternativa_pergunta_ordem UNIQUE (id_pergunta, ordem)
);

CREATE TABLE public.usuario_progresso_conteudo (
  id_usuario uuid NOT NULL,
  id_conteudo bigint NOT NULL,
  pagina_atual smallint NOT NULL DEFAULT 1,
  ultima_pagina_lida smallint NOT NULL DEFAULT 1,
  leitura_concluida boolean NOT NULL DEFAULT false,
  tamanho_fonte_preferido smallint NULL DEFAULT 16,
  tempo_total_leitura interval DEFAULT '0 seconds'::interval,
  num_acessos integer NOT NULL DEFAULT 1,
  iniciado_em timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  ultima_visualizacao timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  concluido_em timestamp with time zone,
  deleted_at timestamp with time zone NULL,
  CONSTRAINT usuario_progresso_conteudo_pkey PRIMARY KEY (id_usuario, id_conteudo),
  CONSTRAINT usuario_progresso_conteudo_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id) ON DELETE RESTRICT,
  CONSTRAINT usuario_progresso_conteudo_id_conteudo_fkey FOREIGN KEY (id_conteudo) REFERENCES public.conteudo(id) ON DELETE RESTRICT,
  CONSTRAINT usuario_progresso_conteudo_fonte_check CHECK (tamanho_fonte_preferido BETWEEN 14 AND 32), -- revisar aq os valores
  CONSTRAINT usuario_progresso_conteudo_pagina_check CHECK (ultima_pagina_lida >= pagina_atual)
);

CREATE TABLE public.usuario (
  id uuid NOT NULL,
  username character varying NOT NULL UNIQUE,
  nome_exibicao character varying(100),
  pontos_totais integer NOT NULL DEFAULT 0,
  nivel smallint NOT NULL DEFAULT 1,
  xp_atual integer NOT NULL DEFAULT 0,
  xp_proximo_nivel integer NOT NULL DEFAULT 100,
  num_quizes_concluidos integer NOT NULL DEFAULT 0,
  streak_dias integer NOT NULL DEFAULT 0,
  melhor_streak integer NOT NULL DEFAULT 0,
  ultimo_acesso_dia date DEFAULT CURRENT_DATE,
  tempo_total_app interval DEFAULT '0 seconds'::interval,
  preferencias jsonb DEFAULT '{}'::jsonb, -- configurações do usuário
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  deleted_at timestamp with time zone NULL, -- soft delete
  CONSTRAINT usuario_pkey PRIMARY KEY (id)
  CONSTRAINT usuario_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);

CREATE TABLE public.sessao_leitura_pagina (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_usuario uuid NOT NULL,
  id_pagina bigint NOT NULL,
  id_conteudo bigint NOT NULL,  
  inicio timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  fim timestamp with time zone,
  duracao interval,  
  tamanho_fonte_usado smallint,
  deleted_at timestamp with time zone NULL,
  CONSTRAINT sessao_leitura_pagina_pkey PRIMARY KEY (id),
  CONSTRAINT sessao_leitura_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id) ON DELETE RESTRICT,
  CONSTRAINT sessao_leitura_id_pagina_fkey FOREIGN KEY (id_pagina) REFERENCES public.pagina(id) ON DELETE RESTRICT,
  CONSTRAINT sessao_leitura_id_conteudo_fkey FOREIGN KEY (id_conteudo) REFERENCES public.conteudo(id) ON DELETE RESTRICT
);

CREATE TABLE public.usuario_tentativa_quiz (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_usuario uuid NOT NULL,
  id_quiz bigint NOT NULL,  
  numero_tentativa smallint NOT NULL DEFAULT 1,  
  concluido boolean NOT NULL DEFAULT false,
  aprovado boolean NOT NULL DEFAULT false,
  pontuacao smallint NOT NULL DEFAULT 0,
  pontos_ganhos smallint NOT NULL DEFAULT 0,
  percentual_acerto smallint DEFAULT 0,
  tempo_gasto interval, 
  iniciado_em timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  concluido_em timestamp with time zone,
  deleted_at timestamp with time zone NULL,  
  CONSTRAINT usuario_tentativa_quiz_pkey PRIMARY KEY (id),
  CONSTRAINT usuario_tentativa_quiz_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id) ON DELETE RESTRICT,
  CONSTRAINT usuario_tentativa_quiz_id_quiz_fkey FOREIGN KEY (id_quiz) REFERENCES public.quiz(id) ON DELETE RESTRICT,
  CONSTRAINT usuario_tentativa_quiz_pontuacao_check CHECK (pontuacao >= 0),
  CONSTRAINT usuario_tentativa_quiz_percentual_check CHECK (percentual_acerto BETWEEN 0 AND 100),
  CONSTRAINT uq_usuario_quiz_tentativa UNIQUE (id_usuario, id_quiz, numero_tentativa)
);

CREATE TABLE public.usuario_quiz (
  id_usuario uuid NOT NULL,
  id_quiz bigint NOT NULL,
  melhor_pontuacao integer NOT NULL DEFAULT 0,
  melhor_percentual smallint NOT NULL DEFAULT 0,
  melhor_tempo interval,
  total_tentativas integer NOT NULL DEFAULT 0,
  total_aprovacoes integer NOT NULL DEFAULT 0,
  concluido boolean NOT NULL DEFAULT false, -- pelo menos 1 aprovação
  primeira_tentativa timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  ultima_tentativa timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  deleted_at timestamp with time zone NULL,
  CONSTRAINT usuario_quiz_pkey PRIMARY KEY (id_usuario, id_quiz),
  CONSTRAINT usuario_quiz_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id) ON DELETE RESTRICT,
  CONSTRAINT usuario_quiz_id_quiz_fkey FOREIGN KEY (id_quiz) REFERENCES public.quiz(id) ON DELETE RESTRICT
);

CREATE TABLE public.usuario_resposta_pergunta (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_tentativa_quiz bigint NOT NULL,
  id_dica bigint NULL,
  id_usuario uuid NOT NULL,
  id_pergunta bigint NOT NULL,
  id_alternativa bigint NOT NULL,
  acertou boolean NOT NULL,
  usou_dica boolean NOT NULL DEFAULT false,
  tempo_resposta interval,
  respondido_em timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  deleted_at timestamp with time zone NULL,
  CONSTRAINT usuario_resposta_pergunta_pkey PRIMARY KEY (id),
  CONSTRAINT usuario_resposta_pergunta_id_tentativa_fkey FOREIGN KEY (id_tentativa_quiz) REFERENCES public.usuario_tentativa_quiz(id) ON DELETE RESTRICT,
  CONSTRAINT usuario_resposta_pergunta_id_dica_fkey FOREIGN KEY (id_dica) REFERENCES public.dica(id) ON DELETE RESTRICT,
  CONSTRAINT usuario_resposta_pergunta_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id) ON DELETE RESTRICT,
  CONSTRAINT usuario_resposta_pergunta_id_pergunta_fkey FOREIGN KEY (id_pergunta) REFERENCES public.pergunta(id) ON DELETE RESTRICT,
  CONSTRAINT usuario_resposta_pergunta_id_alternativa_fkey FOREIGN KEY (id_alternativa) REFERENCES public.alternativa(id) ON DELETE RESTRICT,
  CONSTRAINT uq_usuario_tentativa_pergunta UNIQUE (id_tentativa_quiz, id_pergunta)
);

CREATE TABLE public.ranking_global_usuario (
  id_usuario uuid NOT NULL,
  posicao integer NOT NULL,
  pontos_totais integer NOT NULL,
  nivel smallint NOT NULL, 
  quizes_concluidos integer NOT NULL,
  atualizado_em timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  deleted_at timestamp with time zone NULL,
  CONSTRAINT ranking_global_usuario_pkey PRIMARY KEY (id_usuario),
  CONSTRAINT ranking_global_usuario_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id) ON DELETE RESTRICT,
  CONSTRAINT ranking_global_usuario_posicao_check CHECK (posicao > 0)
);

CREATE TABLE public.conquista (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_categoria bigint UNIQUE NULL, -- em qual mapa ocorreu a conquista (opcional)
  nome character varying NOT NULL UNIQUE,
  descricao character varying NOT NULL,
  tipo character varying NOT NULL, --categoria, quiz ou acerto (c, f, a)
  ativa boolean NOT NULL DEFAULT true,
  icone_url character varying NULL,
  meta_numerica integer NULL,
  CONSTRAINT conquista_pkey PRIMARY KEY (id),
  CONSTRAINT conquista_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categoria(id) ON DELETE SET NULL,
  CONSTRAINT conquista_tipo_check CHECK (tipo IN ('c', 'f', 'a')),
  CONSTRAINT conquista_meta_numerica_check CHECK (meta_numerica > 0)
);

CREATE TABLE public.usuario_conquista (
  id_conquista bigint NOT NULL,
  id_usuario uuid NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()), --N precisa de updated_at pq nao vai perde a conquista
  CONSTRAINT usuario_conquista_pkey PRIMARY KEY (id_conquista, id_usuario),
  CONSTRAINT usuario_conquista_id_conquista_fkey FOREIGN KEY (id_conquista) REFERENCES public.conquista(id) ON DELETE RESTRICT,
  CONSTRAINT usuario_conquista_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id) ON DELETE RESTRICT
);

CREATE TABLE public.item (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_quiz bigint NULL, --opcional, caso seja um item desbloqueável ao concluir uma quiz específica
  nome text NOT NULL unique, 
  descricao text NOT NULL,
  tipo character varying NOT NULL, --(cor da pele), silhueta, expressão (rosto), roupa, cabelo, pintura facial, brinco, óculos 
  url character varying NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT item_pkey PRIMARY KEY (id),
  CONSTRAINT item_id_quiz_fkey FOREIGN KEY (id_quiz) REFERENCES public.quiz(id) ON DELETE SET NULL,-- relação opcional
  CONSTRAINT item_tipo_check CHECK (tipo IN ('cor_pele', 'silhueta', 'expressao', 'roupa', 'cabelo', 'pintura_facial', 'brinco', 'oculos'))
);

CREATE TABLE public.usuario_item (
  id_item bigint NOT NULL,
  id_usuario uuid NOT NULL,
  usando boolean NOT NULL DEFAULT false,
  obtido_em timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT usuario_item_pkey PRIMARY KEY (id_item, id_usuario),
  CONSTRAINT usuario_item_id_item_fkey FOREIGN KEY (id_item) REFERENCES public.item(id) ON DELETE RESTRICT,
  CONSTRAINT usuario_item_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id) ON DELETE RESTRICT
);

CREATE TABLE public.usuario_categoria (
  id_categoria bigint NOT NULL,
  id_usuario uuid NOT NULL,
  primeiro_acesso timestamp with time zone DEFAULT timezone('utc'::text, now())
  num_vezes_acessada integer NOT NULL DEFAULT 0,
  tempo_total_gasto interval DEFAULT '0 seconds'::interval,
  created_at timestamp with time zone DEFAULT timezone('utc':: text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT usuario_categoria_pkey PRIMARY KEY (id_categoria, id_usuario),
  CONSTRAINT usuario_categoria_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categoria(id) ON DELETE RESTRICT,
  CONSTRAINT usuario_categoria_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id) ON DELETE RESTRICT
);

CREATE TABLE public.sessao_usuario (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_usuario uuid NOT NULL,
  inicio timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  fim timestamp with time zone,
  duracao interval,
  dispositivo character varying(100),
  sistema_operacional character varying(50),
  versao_app character varying(20),
  CONSTRAINT sessao_usuario_pkey PRIMARY KEY (id),
  CONSTRAINT sessao_usuario_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id) ON DELETE RESTRICT
);

CREATE TABLE public.denuncia (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_usuario_denunciante uuid NOT NULL,
  tipo character varying(50) NOT NULL, -- 'usuario', 'conteudo', 'pagina', 'quiz', 'pergunta', 'item', 'conquista', 'outro'
  status character varying(20) NOT NULL DEFAULT 'pendente', -- 'pendente', 'em_analise', 'resolvida', 'rejeitada'
  prioridade character varying(20) DEFAULT 'normal', -- 'baixa', 'normal', 'alta', 'critica'
  id_usuario_denunciado uuid NULL,
  id_conteudo bigint NULL,
  id_pagina bigint NULL,
  id_quiz bigint NULL,
  id_pergunta bigint NULL,
  id_item bigint NULL,
  id_conquista bigint NULL,
  titulo character varying(200) NOT NULL,
  descricao text NOT NULL,
  resposta_admin text NULL,
  respondido_por uuid NULL, -- ID do admin que respondeu
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  resolvido_em timestamp with time zone NULL,  
  CONSTRAINT denuncia_pkey PRIMARY KEY (id),
  CONSTRAINT denuncia_id_usuario_denunciante_fkey FOREIGN KEY (id_usuario_denunciante) REFERENCES public.usuario(id) ON DELETE RESTRICT,
  CONSTRAINT denuncia_id_usuario_denunciado_fkey FOREIGN KEY (id_usuario_denunciado) REFERENCES public.usuario(id) ON DELETE SET NULL,
  CONSTRAINT denuncia_id_conteudo_fkey FOREIGN KEY (id_conteudo) REFERENCES public.conteudo(id) ON DELETE SET NULL,
  CONSTRAINT denuncia_id_pagina_fkey FOREIGN KEY (id_pagina) REFERENCES public.pagina(id) ON DELETE SET NULL,
  CONSTRAINT denuncia_id_quiz_fkey FOREIGN KEY (id_quiz) REFERENCES public.quiz(id) ON DELETE SET NULL,
  CONSTRAINT denuncia_id_pergunta_fkey FOREIGN KEY (id_pergunta) REFERENCES public.pergunta(id) ON DELETE SET NULL,
  CONSTRAINT denuncia_id_item_fkey FOREIGN KEY (id_item) REFERENCES public.item(id) ON DELETE SET NULL,
  CONSTRAINT denuncia_id_conquista_fkey FOREIGN KEY (id_conquista) REFERENCES public.conquista(id) ON DELETE SET NULL,
  CONSTRAINT denuncia_tipo_check CHECK (tipo IN ('usuario', 'conteudo', 'pagina', 'quiz', 'pergunta', 'item', 'conquista', 'outro')),
  CONSTRAINT denuncia_status_check CHECK (status IN ('pendente', 'em_analise', 'resolvida', 'rejeitada')),
  CONSTRAINT denuncia_prioridade_check CHECK (prioridade IN ('baixa', 'normal', 'alta', 'critica'))
);

CREATE TABLE public.denuncia_anexo (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_denuncia bigint NOT NULL,
  url character varying(500) NOT NULL,
  tipo character varying(50), -- 'imagem', 'video', 'outro'
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT denuncia_anexo_pkey PRIMARY KEY (id),
  CONSTRAINT denuncia_anexo_id_denuncia_fkey FOREIGN KEY (id_denuncia) REFERENCES public.denuncia(id) ON DELETE CASCADE
);
