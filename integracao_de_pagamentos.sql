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