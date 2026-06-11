/* =========================================================
   APRESENTAÇÃO - SCRIPT 1 - PRÉ-DEMONSTRAÇÃO
   SISCEV - Sistema de Gestão de Compras, Estoque e Vendas

   Objetivo:
   Preparar a base com cadastros e estoque inicial para a
   demonstração ao vivo.

   Ordem recomendada antes deste script:
   1) DDL
   2) Procedures / Packages
   3) Triggers
   4) Views

   Este script limpa apenas os IDs utilizados na demonstração
   e recria a carga inicial.
   ========================================================= */

--> 0) LIMPEZA PREVENTIVA DOS IDs DA DEMONSTRAÇÃO

DELETE FROM FIN_Baixa
 WHERE ID_Baixa = 'BX900';

DELETE FROM FIN_Titulo_Rec
 WHERE FTR_ID_NFS = 'NFS90';

DELETE FROM FIN_Titulo_Pg
 WHERE FTP_ID_NFE = 'NFE90';

DELETE FROM NFS_Item
 WHERE NSI_ID_NFS = 'NFS90';

DELETE FROM NFS_Cabecalho
 WHERE ID_NFS = 'NFS90';

DELETE FROM NFE_Item
 WHERE NEI_ID_NFE = 'NFE90';

DELETE FROM NFE_Cabecalho
 WHERE ID_NFE = 'NFE90';

DELETE FROM VEN_Item_Pedido
 WHERE PVI_ID_P_Venda = 'PV900'
    OR ID_V_Item IN ('IV901','IV999');

DELETE FROM VEN_Pedido
 WHERE ID_P_Venda = 'PV900';

DELETE FROM COM_Item_Pedido
 WHERE PCI_ID_P_Compra = 'PC900';

DELETE FROM COM_Pedido
 WHERE ID_P_Compra = 'PC900';

DELETE FROM EST_Produto
 WHERE ID_Estoque IN ('E001','E002','E003','E004','E005');

DELETE FROM EST_Local
 WHERE ID_EST_Local = 'L001';

DELETE FROM CAD_Fornecedor
 WHERE ID_Fornecedor IN ('F001','F002');

DELETE FROM CAD_Cliente
 WHERE ID_Cliente IN ('C001','C002');

DELETE FROM CAD_Vendedor
 WHERE ID_Vendedor = 'V001';

DELETE FROM CAD_Produto
 WHERE ID_Produto IN ('PR001','PR002','PR003','PR004','PR005');

DELETE FROM CAD_Pessoa
 WHERE ID_Pessoa IN ('P001','P002','P003','P004','P005');

COMMIT;


/* =========================================================
   1) CADASTROS BÁSICOS
   ========================================================= */

INSERT INTO CAD_Pessoa VALUES ('P001','J','11111111000101','Fornecedor Alpha','alpha@forn.com','11999990001','Rua A');
INSERT INTO CAD_Pessoa VALUES ('P002','J','22222222000102','Fornecedor Beta','beta@forn.com','11999990002','Rua B');

INSERT INTO CAD_Pessoa VALUES ('P003','F','33333333333','Cliente João','joao@cli.com','11999990003','Rua C');
INSERT INTO CAD_Pessoa VALUES ('P004','F','44444444444','Cliente Maria','maria@cli.com','11999990004','Rua D');

INSERT INTO CAD_Pessoa VALUES ('P005','F','55555555555','Vendedor Carlos','carlos@vend.com','11999990005','Rua E');


/* =========================================================
   2) FORNECEDORES, CLIENTES E VENDEDOR
   ========================================================= */

INSERT INTO CAD_Fornecedor VALUES ('F001','P001',0);
INSERT INTO CAD_Fornecedor VALUES ('F002','P002',0);

INSERT INTO CAD_Cliente VALUES ('C001','P003',0);
INSERT INTO CAD_Cliente VALUES ('C002','P004',0);

INSERT INTO CAD_Vendedor VALUES ('V001','P005',0);


/* =========================================================
   3) PRODUTOS
   ========================================================= */

INSERT INTO CAD_Produto VALUES ('PR001','Teclado',50,90);
INSERT INTO CAD_Produto VALUES ('PR002','Mouse',30,60);
INSERT INTO CAD_Produto VALUES ('PR003','Monitor',400,650);
INSERT INTO CAD_Produto VALUES ('PR004','Notebook',2500,3200);
INSERT INTO CAD_Produto VALUES ('PR005','Headset',80,150);


/* =========================================================
   4) LOCAL DE ESTOQUE
   ========================================================= */

INSERT INTO EST_Local VALUES ('L001','Depósito Central');


/* =========================================================
   5) ESTOQUE INICIAL
   Observação:
   A quantidade inicial é propositalmente positiva para permitir
   a demonstração de reserva, venda e baixa de estoque.
   ========================================================= */

INSERT INTO EST_Produto VALUES ('E001','L001','PR001',20,0);
INSERT INTO EST_Produto VALUES ('E002','L001','PR002',15,0);
INSERT INTO EST_Produto VALUES ('E003','L001','PR003',10,0);
INSERT INTO EST_Produto VALUES ('E004','L001','PR004',5,0);
INSERT INTO EST_Produto VALUES ('E005','L001','PR005',12,0);

COMMIT;


/* =========================================================
   6) CONFERÊNCIA DA CARGA INICIAL
   Esperado:
   - Pessoas, clientes, fornecedores, vendedor e produtos criados
   - Estoque com quantidade inicial
   - Reserva zerada
   ========================================================= */

SELECT * FROM CAD_Pessoa ORDER BY ID_Pessoa;

SELECT * FROM CAD_Fornecedor ORDER BY ID_Fornecedor;

SELECT * FROM CAD_Cliente ORDER BY ID_Cliente;

SELECT * FROM CAD_Vendedor ORDER BY ID_Vendedor;

SELECT * FROM CAD_Produto ORDER BY ID_Produto;

SELECT
    EST_ID_Produto,
    EST_Quantidade,
    EST_Reserva,
    (NVL(EST_Quantidade,0) - NVL(EST_Reserva,0)) AS EST_Disponivel
FROM EST_Produto
ORDER BY EST_ID_Produto;


/* =========================================================
   7) CONFERÊNCIA DE BASE LIMPA PARA DEMONSTRAÇÃO
   Esperado:
   Todas as consultas abaixo devem retornar zero registros.
   ========================================================= */

SELECT * FROM COM_Pedido WHERE ID_P_Compra = 'PC900';

SELECT * FROM VEN_Pedido WHERE ID_P_Venda = 'PV900';

SELECT * FROM NFE_Cabecalho WHERE ID_NFE = 'NFE90';

SELECT * FROM NFS_Cabecalho WHERE ID_NFS = 'NFS90';

SELECT * FROM FIN_Titulo_Pg WHERE FTP_ID_NFE = 'NFE90';

SELECT * FROM FIN_Titulo_Rec WHERE FTR_ID_NFS = 'NFS90';

SELECT * FROM FIN_Baixa WHERE ID_Baixa = 'BX900';
