/* --- SCRIPTS DE TESTES --- */

--> 1) CONSULTA INICIAL DE ESTOQUE
SELECT EST_ID_Produto, EST_Quantidade, EST_Reserva
FROM EST_Produto
ORDER BY EST_ID_Produto;



--> 2) TESTE OK – INSERÇÃO DE ITEM DE VENDA
-- Esperado: SUCESSO - Reserva de estoque aumentada
-- Triggers: TRG_VALIDA_ESTOQUE_PEDIDO / TRG_RESERVA_ESTOQUE_PEDIDO
INSERT INTO VEN_Item_Pedido
VALUES ('IVT01','PV001','PR001',2,50);

SELECT EST_Quantidade, EST_Reserva
FROM EST_Produto
WHERE EST_ID_Produto = 'PR001';



--> 3) TESTE ERRO – ESTOQUE INSUFICIENTE (CONSIDERANDO RESERVA)
-- Esperado: ERRO -20001
-- Trigger: TRG_VALIDA_ESTOQUE_PEDIDO
INSERT INTO VEN_Item_Pedido
VALUES ('IVT02','PV001','PR001',999,50);



--> 4) TESTE OK – EXCLUSÃO DE ITEM DE VENDA
-- Esperado: SUCESSO - Reserva devolvida ao estoque
-- Trigger: TRG_RESERVA_ESTOQUE_PEDIDO
DELETE FROM VEN_Item_Pedido
WHERE ID_V_Item = 'IVT01';

SELECT EST_Quantidade, EST_Reserva
FROM EST_Produto
WHERE EST_ID_Produto = 'PR001';



--> 5) TESTE ERRO – EXCLUSÃO DE PEDIDO DE VENDA COM NF
-- Esperado: ERRO -20002
-- Trigger: TRG_BLOQ_DEL_PEDIDO_VENDA
DELETE FROM VEN_Pedido
WHERE ID_P_Venda = 'PV001';



--> 6) TESTE ERRO – EXCLUSÃO DE PEDIDO DE COMPRA COM NF
-- Esperado: ERRO -20003
-- Trigger: TRG_BLOQ_DEL_PEDIDO_COMPRA
DELETE FROM COM_Pedido
WHERE ID_P_Compra = 'PC001';



--> 7) TESTE OK – CRIAÇÃO DE PEDIDO DE COMPRA
-- Procedure: PKG_COMPRAS.PR_Criar_Pedido_Compra
BEGIN
    PKG_COMPRAS.PR_Criar_Pedido_Compra(
        p_id_pedido     => 'PC999',
        p_id_fornecedor => 'F001',
        p_emissao       => TO_DATE('20260401','YYYYMMDD'),
        p_valor         => 1500,
        p_pagamento     => 'BOLETO',
        p_parcelas      => 3
    );
END;
/

SELECT * FROM COM_Pedido WHERE ID_P_Compra = 'PC999';



--> 8) TESTE OK – INSERÇÃO DE ITEM DE COMPRA
-- Procedure: PKG_COMPRAS.PR_Inserir_Item_Compra
BEGIN
    PKG_COMPRAS.PR_Inserir_Item_Compra(
        p_id_item    => 'IC999',
        p_id_pedido  => 'PC999',
        p_id_produto => 'PR002',
        p_qtde       => 10,
        p_valor_unit => 30,
        p_entrega    => TO_DATE('20260410','YYYYMMDD')
    );
END;
/

SELECT * FROM COM_Item_Pedido WHERE PCI_ID_P_Compra = 'PC999';



--> 9) TESTE OK – CRIAÇÃO DE PEDIDO DE VENDA
-- Procedure: PKG_VENDAS.PR_Criar_Pedido_Venda
BEGIN
    PKG_VENDAS.PR_Criar_Pedido_Venda(
        p_id_venda    => 'PV999',
        p_id_cliente  => 'C001',
        p_id_vendedor => 'V001',
        p_emissao     => TO_DATE('20260402','YYYYMMDD'),
        p_valor       => 800,
        p_pagamento   => 'CREDIT',
        p_parcelas    => 2
    );
END;
/

SELECT * FROM VEN_Pedido WHERE ID_P_Venda = 'PV999';



--> 10) TESTE OK – INSERÇÃO DE ITEM DE VENDA
-- Procedure: PKG_VENDAS.PR_Inserir_Item_Venda
BEGIN
    PKG_VENDAS.PR_Inserir_Item_Venda(
        p_id_item    => 'IV999',
        p_id_venda   => 'PV999',
        p_id_produto => 'PR003',
        p_qtde       => 1,
        p_valor_unit => 500
    );
END;
/

SELECT * FROM VEN_Item_Pedido WHERE PVI_ID_P_Venda = 'PV999';



--> 11) TESTE OK – GERAR TÍTULOS A PAGAR
-- Procedure: PKG_FINANCEIRO.PR_Gerar_Titulos_Pagar
BEGIN
    PKG_FINANCEIRO.PR_Gerar_Titulos_Pagar(
        p_id_nfe => 'NFE001'
    );
END;
/

SELECT *
FROM FIN_Titulo_Pg
WHERE FTP_ID_NFE = 'NFE001'
ORDER BY FTP_Parcela;



--> 12) TESTE OK – GERAR TÍTULOS A RECEBER
-- Procedure: PKG_FINANCEIRO.PR_Gerar_Titulos_Receber
BEGIN
    PKG_FINANCEIRO.PR_Gerar_Titulos_Receber(
        p_id_nfs => 'NFS001'
    );
END;
/

SELECT *
FROM FIN_Titulo_Rec
WHERE FTR_ID_NFS = 'NFS001'
ORDER BY FTR_Parcela;



--> 13) TESTE ERRO – BAIXA MAIOR QUE SALDO (PAGAR)
-- Esperado: ERRO -20005
-- Trigger: TRG_VALIDA_BAIXA_PAGAR
INSERT INTO FIN_Baixa
VALUES (
    'BX999',
    'TPNFE00101',
    NULL,
    TO_DATE('20260410','YYYYMMDD'),
    99999,
    'PG',
    'Teste de erro'
);



/* TESTE EXTRA 1 – ATUALIZAÇÃO DE ITEM DE VENDA */
INSERT INTO VEN_Item_Pedido
VALUES ('IVT10','PV001','PR001',2,50);

-- Atualiza quantidade
UPDATE VEN_Item_Pedido
SET PVI_Qtde = 4
WHERE ID_V_Item = 'IVT10';

SELECT EST_Quantidade, EST_Reserva
FROM EST_Produto
WHERE EST_ID_Produto = 'PR001';

-- Limpeza
DELETE FROM VEN_Item_Pedido WHERE ID_V_Item = 'IVT10';


/* TESTE EXTRA 2 – BLOQUEIO DE DUPLICIDADE (PAGAR) */
BEGIN
    PKG_FINANCEIRO.PR_Gerar_Titulos_Pagar(
        p_id_nfe => 'NFE001'
    );
END;
/


/* TESTE EXTRA 3 – BLOQUEIO DE DUPLICIDADE (RECEBER) */
BEGIN
    PKG_FINANCEIRO.PR_Gerar_Titulos_Receber(
        p_id_nfs => 'NFS001'
    );
END;
/


/* TESTE EXTRA 4 – ERRO EM NF DE SAÍDA SEM ESTOQUE */
INSERT INTO NFS_Item
VALUES (
    'NFSI999',
    'NFS001',
    'IV999',
    'PR001',
    999,
    50
);


/* TESTE EXTRA 5 – BAIXA PARCIAL */
INSERT INTO FIN_Baixa
VALUES (
    'BX010',
    'TPNFE00101',
    NULL,
    SYSDATE,
    200,
    'PG',
    'Baixa parcial'
);

SELECT ID_Titulo_Pg, FTP_Saldo
FROM FIN_Titulo_Pg
WHERE ID_Titulo_Pg = 'TPNFE00101';


/* TESTE EXTRA 6 – QUITAÇÃO TOTAL */
INSERT INTO FIN_Baixa
VALUES (
    'BX011',
    'TPNFE00101',
    NULL,
    SYSDATE,
    FTP_Saldo,
    'PG',
    'Quitação total'
);
