
CREATE DATABASE IF NOT EXISTS db_simulado_prova;
USE db_simulado_prova;


DROP TABLE IF EXISTS tb_base_de_dados_beneficios_cidadoes;

CREATE TABLE tb_base_de_dados_beneficios_cidadoes (
    ano_competencia INT,
    mes_competencia INT,
    ano_referencia INT,
    mes_referencia INT,
    id_municipio VARCHAR(20),
    sigla_uf VARCHAR(2),
    cpf_favorecido VARCHAR(20),
    nis_favorecido VARCHAR(20),
    nome_favorecido VARCHAR(100),
    valor_parcela DECIMAL(10,2)
);


INSERT INTO tb_base_de_dados_beneficios_cidadoes 
(ano_competencia, mes_competencia, ano_referencia, mes_referencia, id_municipio, sigla_uf, cpf_favorecido, nis_favorecido, nome_favorecido, valor_parcela) 
VALUES
(2024, 1, 2024, 1, '1200401', 'AC', '***.669.902-**', '12345678901', 'MARIA SILVA', 230.00),
(2024, 1, 2024, 1, '1200401', 'AC', '***.669.902-**', '12345678901', 'MARIA SILVA', 230.00),
(2024, 1, 2024, 1, '1200401', 'AC', '***.001.292-**', '12345678902', 'JOAO SOUZA', 230.00),
(2024, 1, 2024, 1, '1200401', 'AC', '***.111.222-**', '12345678903', 'ANA SANTOS', 115725.00),
(2024, 1, 2024, 1, '1200203', 'AC', '***.333.444-**', '12345678904', 'PEDRO ALVES', 213.33),
(2024, 1, 2024, 1, '1200203', 'AC', '***.333.444-**', '12345678904', 'PEDRO ALVES', 213.33),
(2024, 1, 2024, 1, '1200203', 'AC', '***.333.444-**', '12345678904', 'PEDRO ALVES', 213.34),
(2024, 1, 2024, 1, '1200104', 'AC', '***.555.666-**', '12345678905', 'CARLOS OLIVEIRA', 205.00),
(2024, 1, 2024, 1, '1200104', 'AC', '***.555.666-**', '12345678905', 'CARLOS OLIVEIRA', 205.00),
(2024, 1, 2024, 1, '1200500', 'AC', '***.777.888-**', '12345678906', 'LUCIA FERREIRA', 205.00),
(2024, 1, 2024, 1, '1200500', 'AC', '***.777.888-**', '12345678906', 'LUCIA FERREIRA', 205.00),
(2024, 1, 2024, 1, '1200302', 'AC', '***.999.000-**', '12345678907', 'FERNANDO GOMES', 5947.00),
(2024, 1, 2024, 1, '1200138', 'AC', '***.222.333-**', '12345678908', 'PAULA COSTA', 4840.00),
(2024, 1, 2024, 1, '1200401', 'AC', '***.349.952-**', '99900000001', 'TESTE DUPLICADO 1', 200.00),
(2024, 1, 2024, 1, '1200401', 'AC', '***.349.952-**', '99900000002', 'TESTE DUPLICADO 1', 200.00),
(2024, 1, 2024, 1, '1200401', 'AC', '***.715.912-**', '88800000001', 'TESTE DUPLICADO 2', 200.00),
(2024, 1, 2024, 1, '1200401', 'AC', '***.888.999-**', '88800000001', 'TESTE DUPLICADO 3', 200.00);

-- Verificação da tabela criada
SELECT * FROM tb_base_de_dados_beneficios_cidadoes;

# 1 - Painel Municipal Mensal -------------------------------------------------------------
WITH agregacao_municipal AS (
    SELECT 
        ano_competencia,
        mes_competencia,
        id_municipio,
        SUM(valor_parcela) AS valor_total,
        AVG(valor_parcela) AS ticket_medio,
        MAX(valor_parcela) AS valor_max,
        COUNT(DISTINCT cpf_favorecido) AS qtd_beneficiarios
    FROM tb_base_de_dados_beneficios_cidadoes
    WHERE valor_parcela IS NOT NULL
    GROUP BY 
        ano_competencia,
        mes_competencia,
        id_municipio
)
SELECT 
    ano_competencia,
    mes_competencia,
    id_municipio,
    valor_total,
    ticket_medio,
    valor_max,
    qtd_beneficiarios
FROM agregacao_municipal
ORDER BY ano_competencia, mes_competencia, id_municipio;

# 2 - Qualidade de Dados ------------------------------------------------------------------
WITH cpf_com_multiplos_nis AS (
    SELECT 
        'CPF->NIS' AS tipo,
        cpf_favorecido AS chave,
        COUNT(DISTINCT nis_favorecido) AS qtd
    FROM tb_base_de_dados_beneficios_cidadoes
    WHERE cpf_favorecido IS NOT NULL AND nis_favorecido IS NOT NULL
    GROUP BY cpf_favorecido
    HAVING COUNT(DISTINCT nis_favorecido) > 1
),
nis_com_multiplos_cpf AS (
    SELECT 
        'NIS->CPF' AS tipo,
        nis_favorecido AS chave,
        COUNT(DISTINCT cpf_favorecido) AS qtd
    FROM tb_base_de_dados_beneficios_cidadoes
    WHERE cpf_favorecido IS NOT NULL AND nis_favorecido IS NOT NULL
    GROUP BY nis_favorecido
    HAVING COUNT(DISTINCT cpf_favorecido) > 1
)
SELECT * FROM cpf_com_multiplos_nis
UNION ALL
SELECT * FROM nis_com_multiplos_cpf;

# 3 - Ranking por Município dentro da UF --------------------------------------------------
WITH total_por_municipio AS (
    SELECT 
        sigla_uf,
        ano_competencia,
        mes_competencia,
        id_municipio,
        SUM(valor_parcela) AS valor_total_mes
    FROM tb_base_de_dados_beneficios_cidadoes
    WHERE valor_parcela IS NOT NULL
    GROUP BY 
        sigla_uf,
        ano_competencia,
        mes_competencia,
        id_municipio
)
SELECT 
    sigla_uf,
    ano_competencia,
    mes_competencia,
    id_municipio,
    valor_total_mes,
    DENSE_RANK() OVER (
        PARTITION BY sigla_uf, ano_competencia, mes_competencia 
        ORDER BY valor_total_mes DESC
    ) AS pos_uf
FROM total_por_municipio
ORDER BY sigla_uf, ano_competencia, mes_competencia, pos_uf;

# 4 - Participação do Município no Total da UF ------------------------------------------
WITH total_municipio AS (
    SELECT 
        sigla_uf,
        ano_competencia,
        mes_competencia,
        id_municipio,
        SUM(valor_parcela) AS valor_mun
    FROM tb_base_de_dados_beneficios_cidadoes
    WHERE valor_parcela IS NOT NULL
    GROUP BY 
        sigla_uf,
        ano_competencia,
        mes_competencia,
        id_municipio
),
total_uf AS (
    SELECT 
        sigla_uf,
        ano_competencia,
        mes_competencia,
        SUM(valor_mun) AS valor_uf
    FROM total_municipio
    GROUP BY 
        sigla_uf,
        ano_competencia,
        mes_competencia
)
SELECT 
    m.sigla_uf,
    m.ano_competencia,
    m.mes_competencia,
    m.id_municipio,
    m.valor_mun,
    u.valor_uf,
    ROUND((m.valor_mun / u.valor_uf) * 100, 2) AS share_pct
FROM total_municipio m
JOIN total_uf u 
    ON m.sigla_uf = u.sigla_uf 
   AND m.ano_competencia = u.ano_competencia 
   AND m.mes_competencia = u.mes_competencia
ORDER BY m.sigla_uf, m.ano_competencia, m.mes_competencia, m.valor_mun DESC;

# 5 - Perfil do Beneficiário -------------------------------------------------------------
WITH total_municipio AS (
    SELECT 
        sigla_uf,
        id_municipio,
        ano_competencia,
        mes_competencia,
        SUM(valor_parcela) AS total_mun_mes
    FROM tb_base_de_dados_beneficios_cidadoes
    WHERE valor_parcela IS NOT NULL
    GROUP BY sigla_uf, id_municipio, ano_competencia, mes_competencia
),
detalhe_cpf AS (
    SELECT 
        sigla_uf,
        id_municipio,
        ano_competencia,
        mes_competencia,
        cpf_favorecido,
        SUM(valor_parcela) AS total_cpf_mes,
        AVG(valor_parcela) AS media_cpf_mes,
        COUNT(*) AS qtd_linhas_mes
    FROM tb_base_de_dados_beneficios_cidadoes
    WHERE valor_parcela IS NOT NULL
    GROUP BY sigla_uf, id_municipio, ano_competencia, mes_competencia, cpf_favorecido
)
SELECT 
    c.sigla_uf,
    c.id_municipio,
    c.ano_competencia,
    c.mes_competencia,
    c.cpf_favorecido,
    c.total_cpf_mes,
    c.media_cpf_mes,
    c.qtd_linhas_mes,
    m.total_mun_mes,
    ROUND((c.total_cpf_mes / m.total_mun_mes) * 100, 2) AS part_cpf_no_mun_pct
FROM detalhe_cpf c
JOIN total_municipio m 
    ON c.sigla_uf = m.sigla_uf 
   AND c.id_municipio = m.id_municipio 
   AND c.ano_competencia = m.ano_competencia 
   AND c.mes_competencia = m.mes_competencia
ORDER BY c.sigla_uf, c.id_municipio, c.ano_competencia, c.mes_competencia, c.total_cpf_mes DESC;