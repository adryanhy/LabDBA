
CREATE TABLE funcionario (
    codigo INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(255) NOT NULL
);

CREATE TABLE projeto (
    codigo INT PRIMARY KEY AUTO_INCREMENT,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    valor_orcamento DECIMAL(10,2) NOT NULL,
    nome VARCHAR(255) NOT NULL
);

CREATE TABLE maquina (
    codigo INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(255) NOT NULL
);

CREATE TABLE alocacao (
    codigo_funcionario INT NOT NULL,
    codigo_projeto INT NOT NULL,
    data_inicio_alocacao DATE NOT NULL,
    data_fim_alocacao DATE,
    PRIMARY KEY (codigo_funcionario, codigo_projeto),
    FOREIGN KEY (codigo_funcionario) REFERENCES funcionario(codigo),
    FOREIGN KEY (codigo_projeto) REFERENCES projeto(codigo)
);

CREATE TABLE utilizacao (
    codigo_alocacao INT NOT NULL,
    codigo_maquina INT NOT NULL,
    FOREIGN KEY (codigo_alocacao) REFERENCES alocacao(codigo_funcionario, codigo_projeto),
    FOREIGN KEY (codigo_maquina) REFERENCES maquina(codigo)
);


-- Inserts

INSERT INTO funcionario (nome)
VALUES ('João Silva'), ('Maria Oliveira'), ('Pedro Souza'), ('Ana Costa'), ('Carlos Santos');


INSERT INTO projeto (data_inicio, data_fim, valor_orcamento, nome)
VALUES ('2024-03-01', '2024-05-31', 10000.00, 'Projeto X'),
       ('2024-04-01', '2024-06-30', 15000.00, 'Projeto Y'),
       ('2024-05-01', '2024-07-31', 20000.00, 'Projeto Z');


INSERT INTO maquina (nome)
VALUES ('Computador 1'), ('Computador 2'), ('Servidor 1'), ('Servidor 2');


INSERT INTO alocacao (codigo_funcionario, codigo_projeto, data_inicio_alocacao, data_fim_alocacao)
VALUES (1, 1, '2024-03-01', '2024-05-31'),
       (2, 2, '2024-04-01', '2024-06-30'),
       (3, 3, '2024-05-01', '2024-07-31'),
       (4, 1, '2024-06-01', '2024-08-31'),
       (5, 2, '2024-07-01', '2024-09-30');


INSERT INTO utilizacao (codigo_alocacao, codigo_maquina)
SELECT a.codigo_funcionario, a.codigo_projeto, m.codigo
FROM alocacao a
INNER JOIN maquina m ON 1 = 1;


-- Comandos pra consultas
-- Qual projeto um determinado funcionário está trabalhando no momento
SELECT projeto.nome
FROM funcionario
INNER JOIN alocacao ON funcionario.codigo = alocacao.codigo_funcionario
INNER JOIN projeto ON alocacao.codigo_projeto = projeto.codigo
WHERE funcionario.nome = 'Ronaldo'
AND (alocacao.data_fim_alocacao IS NULL OR alocacao.data_fim_alocacao >= CURRENT_DATE());

-- Funcionários sem projetos em uma data específica
SELECT funcionario.nome
FROM funcionario
LEFT JOIN alocacao ON funcionario.codigo = alocacao.codigo_funcionario
WHERE alocacao.codigo_projeto IS NULL
OR (alocacao.data_fim_alocacao IS NOT NULL AND alocacao.data_fim_alocacao < 'Data Especifica');

-- Verificação da disponibilidade do funcionário
CREATE FUNCTION funcionario_disponivel(id_funcionario INT) RETURNS DATE
BEGIN
    DECLARE data_disponivel DATE;

    SELECT MAX(data_fim_alocacao) INTO data_disponivel
    FROM alocacao
    WHERE codigo_funcionario = id_funcionario;

    IF data_disponivel IS NULL THEN
        RETURN CURRENT_DATE();
    ELSE
        RETURN data_disponivel + INTERVAL 1 DAY;
    END IF;
END;

SELECT funcionario_disponivel(123); 
-- Retorna a data a partir da qual o funcionario123 vai estar disponivel


-- Prevenção de alocações simultaneas
CREATE TRIGGER before_insert_alocacao
BEFORE INSERT ON alocacao
FOR EACH ROW
BEGIN
    DECLARE data_inicio_nova_alocacao DATE;
    DECLARE data_fim_nova_alocacao DATE;
    DECLARE data_inicio_alocacao_existente DATE;
    DECLARE data_fim_alocacao_existente DATE;

    SET data_inicio_nova_alocacao = NEW.data_inicio_alocacao;
    SET data_fim_nova_alocacao = NEW.data_fim_alocacao;

    SELECT data_inicio_alocacao, data_fim_alocacao
    INTO data_inicio_alocacao_existente, data_fim_alocacao_existente
    FROM alocacao
    WHERE codigo_funcionario = NEW.codigo_funcionario
    AND (
        (data_inicio_alocacao_existente BETWEEN data_inicio_nova_alocacao AND data_fim_nova_alocacao)
        OR (data_fim_alocacao_existente BETWEEN data_inicio_nova_alocacao AND data_fim_nova_alocacao)
        OR (data_inicio_nova_alocacao BETWEEN data_inicio_alocacao_existente AND data_fim_alocacao_existente)
    );

    IF data_inicio_alocacao_existente IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT 'Funcionario ja está alocado em outro projeto durante este periodo.';
    END IF;
END;



