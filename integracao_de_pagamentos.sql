USE projeto_dock;

CREATE TABLE Usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    saldo DECIMAL(10, 2) DEFAULT 0.00
);

CREATE TABLE Transacoes (
    id_transacao INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    tipo ENUM('transferencia', 'deposito') NOT NULL,
    valor DECIMAL(10, 2) NOT NULL,
    data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario)
);

CREATE TABLE Boletos (
    id_boleto INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    valor DECIMAL(10, 2) NOT NULL,
    data_emissao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_vencimento DATE NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario)
);

-- Inserindo dados de teste na tabela Usuarios
INSERT INTO Usuarios (nome, email, senha, saldo) 
VALUES 
('Alice Silva', 'alice.silva@email.com', 'senha123', 1000.00),
('Bruno Santos', 'bruno.santos@email.com', 'senha456', 2500.00),
('Carla Nunes', 'carla.nunes@email.com', 'senha789', 500.00),
('Diego Costa', 'diego.costa@email.com', 'senha321', 3000.00);

SELECT * FROM Usuarios;

SELECT nome, saldo FROM Usuarios WHERE id_usuario = 1;

-- TRANSAÇÃO DE TRANSFERENCIA
START TRANSACTION;

-- Inserir uma nova transação
INSERT INTO Transacoes (id_usuario, tipo, valor)
VALUES (1, 'transferencia', -200.00);

-- Atualizar o saldo do usuário
UPDATE Usuarios
SET saldo = saldo - 200.00
WHERE id_usuario = 1;

COMMIT;


-- TRANSAÇÃO DE DEPÓSITO
START TRANSACTION;

-- Inserir uma nova transação
INSERT INTO Transacoes (id_usuario, tipo, valor)
VALUES (2, 'deposito', 300.00);

-- Atualizar o saldo do usuário
UPDATE Usuarios
SET saldo = saldo + 300.00
WHERE id_usuario = 2;

COMMIT;


-- TRANSAÇÕES POR USUÁRIOS
SELECT tipo, valor, data_hora
FROM Transacoes
WHERE id_usuario = 1
ORDER BY data_hora DESC;


-- RELATÓRIO FINANCEIRO MENSAL PARA UM USUÁRIO ESPECIFICO
SELECT 
    DATE_FORMAT(data_hora, '%Y-%m') AS mes_ano,
    SUM(CASE WHEN tipo = 'deposito' THEN valor ELSE 0 END) AS total_depositos,
    SUM(CASE WHEN tipo = 'transferencia' THEN valor ELSE 0 END) AS total_transferencias,
    SUM(valor) AS saldo_mensal
FROM Transacoes
WHERE id_usuario = 1
GROUP BY DATE_FORMAT(data_hora, '%Y-%m')
ORDER BY mes_ano DESC;


-- INSERINDO UM NOVO BOLETO PARA UM USUÁRIO
INSERT INTO Boletos (id_usuario, valor, data_emissao, data_vencimento)
VALUES (1, 600.00, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY));

-- EXIBINDO O VALOR TOTAL DOS BOLETOS POR USUARIO
SELECT
	u.nome as Usuário,
	SUM(valor) AS valor_total_de_boletos
FROM Boletos b INNER JOIN Usuarios u
WHERE b.id_usuario = u.id_usuario
GROUP BY u.nome;


-- ADICIONANDO A COLUNA STATUS NA TABELA BOLETOS
ALTER TABLE Boletos
ADD COLUMN status ENUM('pendente', 'pago') DEFAULT 'pendente';


-- Consulta para visualizar boletos pendentes de um usuário específico
SELECT id_boleto, valor, data_emissao, data_vencimento, status
FROM Boletos
WHERE id_usuario = 1
  AND data_vencimento >= CURDATE()
  AND status != 'pago'
ORDER BY data_vencimento;


DELIMITER //

CREATE PROCEDURE MostrarBoletosPendentes (IN usuario_id INT)
BEGIN
    SELECT id_boleto, valor, data_emissao, data_vencimento, status
    FROM Boletos
    WHERE id_usuario = usuario_id
      AND data_vencimento >= CURDATE()
      AND status != 'pago'
	GROUP BY id_boleto;
END //

DELIMITER ;

CALL MostrarBoletosPendentes(1);



-- REALIZAR O PAGAMENTO DO BOLETO PELO ID
DELIMITER //

CREATE PROCEDURE PagarBoleto (IN boleto_id INT)
BEGIN
    DECLARE boleto_valor DECIMAL(10, 2);
    DECLARE usuario_id INT;

    -- Verificar se o boleto existe e está pendente
    SELECT id_usuario, valor INTO usuario_id, boleto_valor
    FROM Boletos
    WHERE id_boleto = boleto_id AND status = 'pendente';

    -- Caso o boleto não seja encontrado ou já esteja pago, finaliza a procedure
    IF usuario_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Boleto não encontrado ou já está pago';
    ELSE
        -- Iniciar transação para garantir atomicidade
        START TRANSACTION;

        -- Inserir a transação de pagamento
        INSERT INTO Transacoes (id_usuario, tipo, valor)
        VALUES (usuario_id, 'transferencia', -boleto_valor);

        -- Atualizar o saldo do usuário
        UPDATE Usuarios
        SET saldo = saldo - boleto_valor
        WHERE id_usuario = usuario_id;

        -- Atualizar o status do boleto para pago
        UPDATE Boletos
        SET status = 'pago'
        WHERE id_boleto = boleto_id;

        -- Confirmar as alterações
        COMMIT;
    END IF;
END //

DELIMITER ;

CALL PagarBoleto(1);


