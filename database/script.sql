CREATE DATABASE IF NOT EXISTS API2
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE API2;

DROP VIEW IF EXISTS vw_os_detalhadas;
DROP VIEW IF EXISTS vw_resumo_times;
DROP VIEW IF EXISTS vw_projetos_detalhados;

DROP PROCEDURE IF EXISTS prc_os_por_status;
DROP PROCEDURE IF EXISTS prc_os_por_time;
DROP PROCEDURE IF EXISTS prc_atualizar_status_os;
DROP PROCEDURE IF EXISTS prc_transferir_os;
DROP PROCEDURE IF EXISTS buscar_os_por_periodo;
DROP PROCEDURE IF EXISTS consultar_historico_os;
DROP PROCEDURE IF EXISTS prc_relatorio_cursor;

DROP FUNCTION IF EXISTS dias_para_prazo;
DROP FUNCTION IF EXISTS percentual_conclusao;
DROP FUNCTION IF EXISTS contar_os_usuario;
DROP FUNCTION IF EXISTS quantidade_os_equipe;
DROP FUNCTION IF EXISTS quantidade_alteracoes;
DROP FUNCTION IF EXISTS taxa_conclusao;

DROP TRIGGER IF EXISTS trg_insert_os;
DROP TRIGGER IF EXISTS trg_update_os;
DROP TRIGGER IF EXISTS trg_delete_os;
DROP TRIGGER IF EXISTS trg_insert_projeto;
DROP TRIGGER IF EXISTS trg_update_projeto;
DROP TRIGGER IF EXISTS trg_delete_projeto;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS item_equipamento_manutencao;
DROP TABLE IF EXISTS item_equipamento_projeto;
DROP TABLE IF EXISTS item_equipamento_os;
DROP TABLE IF EXISTS anexo;
DROP TABLE IF EXISTS manutencoes;
DROP TABLE IF EXISTS projetos;
DROP TABLE IF EXISTS os;
DROP TABLE IF EXISTS time;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS equipamentos;
DROP TABLE IF EXISTS notificacao_leituras;
DROP TABLE IF EXISTS notificacoes;
DROP TABLE IF EXISTS historico_registros;
DROP TABLE IF EXISTS historico_os;
SET FOREIGN_KEY_CHECKS = 1;

-- USUÁRIOS

CREATE TABLE usuarios (
    id_usuario INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    cargo ENUM(
        'superusuario',
        'gestor',
        'comercial',
        'suporte',
        'producao',
        'software',
        'implantacao',
        'monitoramento'
    ) NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    time_id INT NULL,
    data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_usuarios_time (time_id)
) ENGINE=InnoDB;

-- TIMES

CREATE TABLE time (
    id_time INT PRIMARY KEY AUTO_INCREMENT,
    nome_time VARCHAR(100) NOT NULL UNIQUE,
    email_time VARCHAR(150) NULL UNIQUE,
    departamento VARCHAR(100) NOT NULL,
    responsavel_id INT NULL,
    INDEX idx_time_responsavel (responsavel_id)
) ENGINE=InnoDB;

ALTER TABLE usuarios
    ADD CONSTRAINT fk_usuario_time
    FOREIGN KEY (time_id) REFERENCES time(id_time)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

ALTER TABLE time
    ADD CONSTRAINT fk_time_responsavel
    FOREIGN KEY (responsavel_id) REFERENCES usuarios(id_usuario)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

-- EQUIPAMENTOS

CREATE TABLE equipamentos (
    equipamento_id INT PRIMARY KEY AUTO_INCREMENT,
    nome_equipamento VARCHAR(150) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ORDENS DE SERVIÇO

CREATE TABLE os (
    os_id INT PRIMARY KEY AUTO_INCREMENT,
    os_titulo VARCHAR(150) NOT NULL,
    os_descricao TEXT NOT NULL,
    os_status ENUM(
        'aberta',
        'em andamento',
        'concluida',
        'teste',
        'bloqueado',
        'review'
    ) NOT NULL DEFAULT 'aberta',
    prioridade ENUM('baixa', 'media', 'alta', 'critica') NOT NULL DEFAULT 'media',
    data_limite DATE NOT NULL,
    id_criador INT NOT NULL,
    id_time_responsavel INT NULL,
    projeto_id INT NULL,
    manutencao_id INT NULL,
    data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_os_criador (id_criador),
    INDEX idx_os_time (id_time_responsavel),
    INDEX idx_os_projeto (projeto_id),
    INDEX idx_os_manutencao (manutencao_id),
    INDEX idx_os_status (os_status),
    CONSTRAINT fk_criador_os
        FOREIGN KEY (id_criador) REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_os_time
        FOREIGN KEY (id_time_responsavel) REFERENCES time(id_time)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- PROJETOS

CREATE TABLE projetos (
    projeto_id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(150) NOT NULL,
    data_assinatura_contrato DATE NULL,
    data_implantacao DATE NULL,
    data_vencimento_contrato DATE NULL,
    data_limite DATE NULL,
    responsavel_id INT NULL,
    vendedor_id INT NULL,
    tipo_sistema VARCHAR(100) NOT NULL,
    prioridade ENUM('baixa', 'media', 'alta', 'critica') NOT NULL DEFAULT 'media',
    status ENUM('aberto', 'em_andamento', 'finalizado') NOT NULL DEFAULT 'aberto',
    descricao TEXT NULL,
    data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_projeto_responsavel (responsavel_id),
    INDEX idx_projeto_vendedor (vendedor_id),
    CONSTRAINT fk_projeto_responsavel
        FOREIGN KEY (responsavel_id) REFERENCES usuarios(id_usuario)
        ON DELETE SET NULL,
    CONSTRAINT fk_projeto_vendedor
        FOREIGN KEY (vendedor_id) REFERENCES usuarios(id_usuario)
        ON DELETE SET NULL
) ENGINE=InnoDB;

-- MANUTENÇÕES

CREATE TABLE manutencoes (
    manutencao_id INT PRIMARY KEY AUTO_INCREMENT,
    data_inicio_problema DATE NOT NULL,
    tipo_manutencao ENUM('corretiva', 'preventiva', 'evolutiva', 'adaptativa') NOT NULL,
    descricao_situacao TEXT NOT NULL,
    status ENUM('aberta', 'em andamento', 'concluida', 'cancelada') NOT NULL DEFAULT 'aberta',
    data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    projeto_id INT NULL,
    resumo VARCHAR(255) NULL,
    responsavel_id INT NULL,
    data_limite DATE NULL,
    prioridade ENUM('baixa', 'media', 'alta', 'critica') NOT NULL DEFAULT 'media',
    INDEX idx_manutencao_projeto (projeto_id),
    INDEX idx_manutencao_responsavel (responsavel_id),
    CONSTRAINT fk_manutencao_projeto
        FOREIGN KEY (projeto_id) REFERENCES projetos(projeto_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_manutencao_responsavel
        FOREIGN KEY (responsavel_id) REFERENCES usuarios(id_usuario)
        ON DELETE SET NULL
) ENGINE=InnoDB;

-- O.S. vinculadas a projeto/manutenção (criadas após as duas tabelas existirem)
ALTER TABLE os
    ADD CONSTRAINT fk_os_projeto
        FOREIGN KEY (projeto_id) REFERENCES projetos(projeto_id)
        ON DELETE CASCADE,
    ADD CONSTRAINT fk_os_manutencao
        FOREIGN KEY (manutencao_id) REFERENCES manutencoes(manutencao_id)
        ON DELETE CASCADE;

-- ANEXOS

CREATE TABLE anexo (
    anexo_id INT PRIMARY KEY AUTO_INCREMENT,
    os_id INT NULL,
    nome_anexo VARCHAR(255) NOT NULL,
    anexo_tipo VARCHAR(150) NOT NULL,
    anexo_tamanho BIGINT UNSIGNED NULL,
    data_anexo DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    manutencao_id INT NULL,
    projeto_id INT NULL,
    conteudo_arquivo LONGBLOB NOT NULL,
    INDEX idx_anexo_os (os_id),
    INDEX idx_anexo_manutencao (manutencao_id),
    INDEX idx_anexo_projeto (projeto_id),
    CONSTRAINT fk_anexos_os
        FOREIGN KEY (os_id) REFERENCES os(os_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_anexo_manutencao
        FOREIGN KEY (manutencao_id) REFERENCES manutencoes(manutencao_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_anexo_projeto
        FOREIGN KEY (projeto_id) REFERENCES projetos(projeto_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_anexo_um_vinculo CHECK (
        (os_id IS NOT NULL) +
        (manutencao_id IS NOT NULL) +
        (projeto_id IS NOT NULL) = 1
    )
) ENGINE=InnoDB;

-- RELACIONAMENTOS DE EQUIPAMENTOS

CREATE TABLE item_equipamento_os (
    os_id INT NOT NULL,
    equipamento_id INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1,
    PRIMARY KEY (os_id, equipamento_id),
    CONSTRAINT chk_item_os_quantidade CHECK (quantidade > 0),
    CONSTRAINT fk_item_os
        FOREIGN KEY (os_id) REFERENCES os(os_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_item_os_equipamento
        FOREIGN KEY (equipamento_id) REFERENCES equipamentos(equipamento_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE item_equipamento_projeto (
    projeto_id INT NOT NULL,
    equipamento_id INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1,
    PRIMARY KEY (projeto_id, equipamento_id),
    CONSTRAINT chk_item_projeto_quantidade CHECK (quantidade > 0),
    CONSTRAINT fk_item_projeto
        FOREIGN KEY (projeto_id) REFERENCES projetos(projeto_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_item_projeto_equipamento
        FOREIGN KEY (equipamento_id) REFERENCES equipamentos(equipamento_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE item_equipamento_manutencao (
    manutencao_id INT NOT NULL,
    equipamento_id INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1,
    PRIMARY KEY (manutencao_id, equipamento_id),
    CONSTRAINT chk_item_manutencao_quantidade CHECK (quantidade > 0),
    CONSTRAINT fk_item_manutencao
        FOREIGN KEY (manutencao_id) REFERENCES manutencoes(manutencao_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_item_manutencao_equipamento
        FOREIGN KEY (equipamento_id) REFERENCES equipamentos(equipamento_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE notificacoes (
    notificacao_id INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(150) NOT NULL,
    mensagem VARCHAR(200) NOT NULL,
    time_id INT NOT NULL,
    os_id INT NULL,
    usuario_origem_id INT NULL,
    data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_notificacoes_time (time_id),
    INDEX idx_notificacoes_os (os_id),
    INDEX idx_notificacoes_data (data_criacao),

    CONSTRAINT fk_notificacao_time
        FOREIGN KEY (time_id)
        REFERENCES time(id_time)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_notificacao_os
        FOREIGN KEY (os_id)
        REFERENCES os(os_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT fk_notificacao_usuario
        FOREIGN KEY (usuario_origem_id)
        REFERENCES usuarios(id_usuario)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ;

CREATE TABLE notificacao_leituras (
    notificacao_id INT NOT NULL,
    usuario_id INT NOT NULL,
    data_leitura DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (notificacao_id, usuario_id),

    CONSTRAINT fk_leitura_notificacao
        FOREIGN KEY (notificacao_id)
        REFERENCES notificacoes(notificacao_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_leitura_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuarios(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ;

CREATE TABLE historico_registros (
    historico_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    tabela VARCHAR(64) NOT NULL,
    registro_id VARCHAR(100) NOT NULL,
    tipo_acao ENUM('criado', 'atualizado', 'deletado') NOT NULL,
    dados JSON NOT NULL,
    usuario_id INT NULL,
    usuario_email VARCHAR(150) NULL,
    data_historico DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_historico_tabela_registro (tabela, registro_id),
    INDEX idx_historico_data (data_historico)
) ENGINE=InnoDB;

CREATE TABLE historico_os (
    historico_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    usuario_id INT NULL,
    usuario_email VARCHAR(150) NULL,
    data_historico DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tipo_acao ENUM(
        'criado',
        'atualizado',
        'deletado'
    ) NOT NULL,
    os_id INT NOT NULL,
    id_time_responsavel INT NULL,
    os_titulo VARCHAR(150) NOT NULL,
    os_status ENUM(
        'aberta',
        'em andamento',
        'concluida',
        'teste',
        'bloqueado',
        'review'
    ) NOT NULL DEFAULT 'aberta',
    data_limite DATE NOT NULL,

    FOREIGN KEY (id_time_responsavel) REFERENCES time(id_time)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- VIEWS

CREATE VIEW vw_os_detalhadas AS
SELECT
    o.os_id,
    o.os_titulo,
    o.os_descricao,
    o.os_status,
    o.prioridade,
    o.data_limite,
    o.data_criacao,
    u.nome AS nome_criador,
    u.email AS email_criador,
    t.nome_time,
    p.nome AS nome_projeto,
    m.resumo AS resumo_manutencao
FROM os o
INNER JOIN usuarios u
    ON o.id_criador = u.id_usuario
LEFT JOIN time t
    ON o.id_time_responsavel = t.id_time
LEFT JOIN projetos p
    ON o.projeto_id = p.projeto_id
LEFT JOIN manutencoes m
    ON o.manutencao_id = m.manutencao_id;

CREATE VIEW vw_resumo_times AS
SELECT
    t.id_time,
    t.nome_time,
    COUNT(o.os_id) AS total_os,
    SUM(CASE WHEN o.os_status = 'concluida' THEN 1 ELSE 0 END) AS os_concluidas,
    SUM(CASE WHEN o.os_status = 'aberta' THEN 1 ELSE 0 END) AS os_abertas
FROM time t
LEFT JOIN os o
    ON t.id_time = o.id_time_responsavel
GROUP BY t.id_time, t.nome_time;

CREATE VIEW vw_projetos_detalhados AS
SELECT
    p.projeto_id,
    p.nome,
    p.status,
    p.prioridade,
    p.tipo_sistema,
    u.nome AS nome_responsavel,
    COUNT(o.os_id) AS total_os
FROM projetos p
LEFT JOIN usuarios u
    ON p.responsavel_id = u.id_usuario
LEFT JOIN os o
    ON p.projeto_id = o.projeto_id
GROUP BY
    p.projeto_id, p.nome, p.status, p.prioridade,
    p.tipo_sistema, u.nome;

-- TRIGGERS DE HISTÓRICO

DELIMITER //

CREATE TRIGGER trg_insert_os
AFTER INSERT ON os
FOR EACH ROW
BEGIN
    INSERT INTO historico_os (
        os_id, id_time_responsavel, os_titulo, os_status,
        data_limite, tipo_acao, usuario_id, usuario_email
    )
    VALUES (
        NEW.os_id, NEW.id_time_responsavel, NEW.os_titulo, NEW.os_status,
        NEW.data_limite, 'criado', @app_actor_id, @app_actor_email
    );
END //

CREATE TRIGGER trg_update_os
AFTER UPDATE ON os
FOR EACH ROW
BEGIN
    INSERT INTO historico_os (
        os_id, id_time_responsavel, os_titulo, os_status,
        data_limite, tipo_acao, usuario_id, usuario_email
    )
    VALUES (
        NEW.os_id, NEW.id_time_responsavel, NEW.os_titulo, NEW.os_status,
        NEW.data_limite, 'atualizado', @app_actor_id, @app_actor_email
    );
END //

CREATE TRIGGER trg_delete_os
AFTER DELETE ON os
FOR EACH ROW
BEGIN
    INSERT INTO historico_os (
        os_id, id_time_responsavel, os_titulo, os_status,
        data_limite, tipo_acao, usuario_id, usuario_email
    )
    VALUES (
        OLD.os_id, OLD.id_time_responsavel, OLD.os_titulo, OLD.os_status,
        OLD.data_limite, 'deletado', @app_actor_id, @app_actor_email
    );
END //

CREATE TRIGGER trg_insert_projeto
AFTER INSERT ON projetos
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (
        tabela, registro_id, tipo_acao, dados, usuario_id, usuario_email
    )
    VALUES (
        'projetos',
        CAST(NEW.projeto_id AS CHAR),
        'criado',
        JSON_OBJECT(
            'nome', NEW.nome,
            'status', NEW.status,
            'prioridade', NEW.prioridade,
            'tipo_sistema', NEW.tipo_sistema,
            'descricao', NEW.descricao
        ),
        @app_actor_id,
        @app_actor_email
    );
END //

CREATE TRIGGER trg_update_projeto
AFTER UPDATE ON projetos
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (
        tabela, registro_id, tipo_acao, dados, usuario_id, usuario_email
    )
    VALUES (
        'projetos',
        CAST(NEW.projeto_id AS CHAR),
        'atualizado',
        JSON_OBJECT(
            'nome', NEW.nome,
            'status', NEW.status,
            'prioridade', NEW.prioridade,
            'tipo_sistema', NEW.tipo_sistema,
            'descricao', NEW.descricao
        ),
        @app_actor_id,
        @app_actor_email
    );
END //

CREATE TRIGGER trg_delete_projeto
AFTER DELETE ON projetos
FOR EACH ROW
BEGIN
    INSERT INTO historico_registros (
        tabela, registro_id, tipo_acao, dados, usuario_id, usuario_email
    )
    VALUES (
        'projetos',
        CAST(OLD.projeto_id AS CHAR),
        'deletado',
        JSON_OBJECT(
            'nome', OLD.nome,
            'status', OLD.status,
            'prioridade', OLD.prioridade,
            'tipo_sistema', OLD.tipo_sistema,
            'descricao', OLD.descricao
        ),
        @app_actor_id,
        @app_actor_email
    );
END //

-- PROCEDURES

CREATE PROCEDURE prc_os_por_status(
    IN p_status VARCHAR(30)
)
BEGIN
    SELECT
        os_id, os_titulo, os_status, prioridade,
        data_limite, id_time_responsavel
    FROM os
    WHERE os_status = p_status
    ORDER BY data_limite ASC;
END //

CREATE PROCEDURE prc_os_por_time(
    IN p_id_time INT
)
BEGIN
    SELECT
        os_id, os_titulo, os_status, prioridade, data_limite
    FROM os
    WHERE id_time_responsavel = p_id_time
    ORDER BY data_limite ASC;
END //

CREATE PROCEDURE prc_atualizar_status_os(
    IN p_os_id INT,
    IN p_novo_status VARCHAR(30)
)
BEGIN
    UPDATE os
    SET os_status = p_novo_status
    WHERE os_id = p_os_id;
END //

CREATE PROCEDURE prc_transferir_os(
    IN p_os_id INT,
    IN p_novo_time INT
)
BEGIN
    UPDATE os
    SET id_time_responsavel = p_novo_time
    WHERE os_id = p_os_id;
END //

CREATE PROCEDURE buscar_os_por_periodo(
    IN p_data_inicio DATE,
    IN p_data_fim DATE
)
BEGIN
    SELECT
        os_id, os_titulo, os_status, prioridade, data_limite
    FROM os
    WHERE data_limite BETWEEN p_data_inicio AND p_data_fim
    ORDER BY data_limite;
END //

CREATE PROCEDURE consultar_historico_os(
    IN p_os_id INT
)
BEGIN
    SELECT
        os_id, os_titulo, os_status, tipo_acao,
        id_time_responsavel, data_limite, usuario_id,
        usuario_email, data_historico
    FROM historico_os
    WHERE os_id = p_os_id
    ORDER BY data_historico DESC;
END //

-- Cursor
CREATE PROCEDURE prc_relatorio_cursor()
BEGIN
    DECLARE v_id_time INT;
    DECLARE v_nome_time VARCHAR(100);
    DECLARE v_total_os INT DEFAULT 0;
    DECLARE v_fim BOOLEAN DEFAULT FALSE;

    DECLARE cur_times CURSOR FOR
        SELECT id_time, nome_time
        FROM time
        ORDER BY nome_time;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_fim = TRUE;

    DROP TEMPORARY TABLE IF EXISTS tmp_relatorio_times;

    CREATE TEMPORARY TABLE tmp_relatorio_times (
        id_time INT,
        nome_time VARCHAR(100),
        total_os INT
    );

    OPEN cur_times;

    leitura: LOOP
        FETCH cur_times INTO v_id_time, v_nome_time;

        IF v_fim THEN
            LEAVE leitura;
        END IF;

        SELECT COUNT(*)
        INTO v_total_os
        FROM os
        WHERE id_time_responsavel = v_id_time;

        INSERT INTO tmp_relatorio_times (id_time, nome_time, total_os)
        VALUES (v_id_time, v_nome_time, v_total_os);
    END LOOP;

    CLOSE cur_times;

    SELECT id_time, nome_time, total_os
    FROM tmp_relatorio_times
    ORDER BY nome_time;
END //

-- FUNCTIONS

CREATE FUNCTION dias_para_prazo(p_data DATE)
RETURNS INT
NOT DETERMINISTIC
NO SQL
BEGIN
    RETURN DATEDIFF(p_data, CURDATE());
END //

CREATE FUNCTION percentual_conclusao(
    p_concluidas INT,
    p_total INT
)
RETURNS DECIMAL(5,2)
DETERMINISTIC
NO SQL
BEGIN
    IF p_total IS NULL OR p_total = 0 THEN
        RETURN 0;
    END IF;

    RETURN (p_concluidas / p_total) * 100;
END //

CREATE FUNCTION contar_os_usuario(p_id_usuario INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_quantidade INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_quantidade
    FROM os
    WHERE id_criador = p_id_usuario;

    RETURN v_quantidade;
END //

CREATE FUNCTION quantidade_os_equipe(p_id_time INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_total
    FROM os
    WHERE id_time_responsavel = p_id_time;

    RETURN v_total;
END //

CREATE FUNCTION quantidade_alteracoes(p_os_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_total
    FROM historico_os
    WHERE os_id = p_os_id;

    RETURN v_total;
END //

CREATE FUNCTION taxa_conclusao(p_id_time INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_concluidas INT DEFAULT 0;

    SELECT
        COUNT(*),
        COALESCE(SUM(CASE WHEN os_status = 'concluida' THEN 1 ELSE 0 END), 0)
    INTO v_total, v_concluidas
    FROM os
    WHERE id_time_responsavel = p_id_time;

    IF v_total = 0 THEN
        RETURN 0;
    END IF;

    RETURN (v_concluidas / v_total) * 100;
END //

DELIMITER ;

-- CONSULTAS

-- INNER JOIN: OS com seu usuário criador.
SELECT o.os_id, o.os_titulo, u.nome AS criador
FROM os o
INNER JOIN usuarios u
    ON o.id_criador = u.id_usuario;

-- LEFT JOIN: todos os times, inclusive os que não possuem OS.
SELECT t.nome_time, o.os_titulo, o.os_status
FROM time t
LEFT JOIN os o
    ON t.id_time = o.id_time_responsavel;

-- RIGHT JOIN: todas as OS, inclusive as que não possuem time.
SELECT o.os_id, o.os_titulo, t.nome_time
FROM time t
RIGHT JOIN os o
    ON t.id_time = o.id_time_responsavel;

-- GROUP BY + funções de grupo: quantidade e média por time.
SELECT
    t.nome_time,
    COUNT(o.os_id) AS total_os,
    SUM(CASE WHEN o.os_status = 'concluida' THEN 1 ELSE 0 END) AS concluidas,
    AVG(DATEDIFF(o.data_limite, DATE(o.data_criacao))) AS media_dias_ate_prazo,
    MIN(o.data_limite) AS prazo_mais_proximo,
    MAX(o.data_limite) AS prazo_mais_distante
FROM time t
LEFT JOIN os o
    ON t.id_time = o.id_time_responsavel
GROUP BY t.id_time, t.nome_time
HAVING COUNT(o.os_id) >= 0;

-- Subconsulta: OS cujo prazo é posterior à média de prazo das OS.
SELECT os_id, os_titulo, data_limite
FROM os
WHERE DATEDIFF(data_limite, DATE(data_criacao)) > (
    SELECT AVG(DATEDIFF(data_limite, DATE(data_criacao)))
    FROM os
);

-- Subconsulta correlacionada: projetos que possuem ao menos uma OS.
SELECT p.projeto_id, p.nome
FROM projetos p
WHERE EXISTS (
    SELECT 1
    FROM os o
    WHERE o.projeto_id = p.projeto_id
);

-- Chamadas
CALL prc_os_por_status('em andamento');
CALL prc_os_por_time(1);
CALL prc_atualizar_status_os(1, 'em andamento');
CALL prc_transferir_os(1, 1);
CALL buscar_os_por_periodo('2026-11-01', '2026-11-30');
CALL consultar_historico_os(1);
CALL prc_relatorio_cursor();
SELECT dias_para_prazo('2026-12-01');
SELECT percentual_conclusao(25, 100);
SELECT contar_os_usuario(1);
SELECT quantidade_os_equipe(1);
SELECT quantidade_alteracoes(1);
SELECT taxa_conclusao(1);

-- DADOS INICIAIS PARA DESENVOLVIMENTO/TESTE 

INSERT INTO usuarios (nome, email, cargo, senha_hash, ativo, time_id) VALUES
('Administrador do Sistema', 'admin@empresa.com', 'superusuario', 'scrypt:f423adce56b0c68ef13f54a9a6dab911:d753c6bbe0ca0c1e217477833b09319af62e801615f6d0ae19df3f13deedf61c1b28a892d61d04cfad09b23357fa150bd3718c88b17ebc2ee240495119661c73', TRUE, NULL),
('Gestor', 'gestor@empresa.com', 'gestor', 'scrypt:e6bc28adde569978437137eb4249a2b2:338ff8c098c765e2f5bd5ea44ca91d1c94e99efba278b4196b1cbe8aa346bb8f8c9c41ee8cff0513aeeb59c2ad11557e9ec1b3b7553d599438edb6d3c908cea8', TRUE, NULL),
('Comercial', 'comercial@empresa.com', 'comercial', 'scrypt:8a78c314b6510531d0cba3fac701d8ac:8aeeb8710808b31ef709b5a8b1e43e5f1cc18b49b2ae5db34485d638ddd590f6e91239d9adc2a02b663669c500ff2005d8102612c3503583d02e5e0fca580521', TRUE, NULL),
('Suporte', 'suporte@empresa.com', 'suporte', 'scrypt:24c3fea94bc378d0c3ce81162201e610:161b1c9ea0ffb3d9b6fc4ac7fe22c1ef9cb0d2399840a61347a30cbe51b04fb1c44c1c46677fa43b52fe4e56ae1756fa6e0a2331dfdc5182abc2b6f7c8139622', TRUE, NULL),
('Produção', 'producao@empresa.com', 'producao', 'scrypt:3e15643b6efea99e9c5e8337224ce6da:43e47af515c456c9d3b79e35b4fdc214145daafddf9db3433785dad3ac8574ee1711a04a1f71e882413e0d2a4e95d52bfbf0a0f22cd1ecfc4f717f8737821134', TRUE, NULL),
('Software', 'software@empresa.com', 'software', 'scrypt:e0fbf81ea30fb0310350d12fc6e0858b:7dc391979d9f6500ee85685b7ba3229a1928bdbb6bd4cb03ff158a2949b695755918dd4c58a8e132809010cb44a660bd50c31e6b0f2ab8d40c2c7d5ad7296805', TRUE, NULL),
('Implantação', 'implantacao@empresa.com', 'implantacao', 'scrypt:f79381f899e0a9b58754f1b02fd5b8aa:83f75865934992466e1b8292036a9b77d26823541a59a686ea54d6d32d8a89bc891af6059d32989c4f315befc8981ac0ea57ba7778da739690b1520aaa959366', TRUE, NULL),
('Monitoramento', 'monitoramento@empresa.com', 'monitoramento', 'scrypt:10e30fc14d0eab11e4582007171557a0:15d1449e09830e09fb99910527f8250ce63ef1f3d9a1ad2f4202c010249610a9de8ef7ecb377846da9a0826e3e866a954b0d855962505044d3e699b9827550a8', TRUE, NULL);

-- Times: apenas produção, software, implantação e monitoramento são alocados em times.
-- Usuários de comercial e suporte não pertencem a times.
INSERT INTO time (nome_time, email_time, departamento) VALUES
('Software', NULL, 'software'),
('Produção', NULL, 'producao'),
('Implantação', NULL, 'implantacao'),
('Monitoramento', NULL, 'monitoramento');

UPDATE usuarios SET time_id = 1 WHERE id_usuario = 6;
UPDATE usuarios SET time_id = 2 WHERE id_usuario = 5;
UPDATE usuarios SET time_id = 3 WHERE id_usuario = 7;
UPDATE usuarios SET time_id = 4 WHERE id_usuario = 8;

INSERT INTO equipamentos (nome_equipamento) VALUES
('aeróstato'),
('torre'),
('câmera óptica'),
('câmera térmica'),
('switch'),
('roteador'),
('cabo de rede'),
('conector rj45'),
('patch cord'),
('sensor de movimento');