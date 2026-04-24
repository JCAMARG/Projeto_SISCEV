/* --- TESTES --- */ 


/* =========================================================
   1) TESTES DE ESTOQUE (CONSULTA INICIAL)
   ========================================================= */
SELECT EST_ID_Produto, EST_Quantidade, EST_Reserva
FROM EST_Produto
ORDER BY EST_ID_Produto;


/* =========================================================
   2) TESTE OK - INSERÇÃO DE ITEM DE VENDA (RESERVA ESTOQUE)
   Esperado: SUCESSO + aumento da reserva
   Trigger: TRG_RESERVA_ESTOQUE_PEDIDO
   ========================================================= */
INSERT INTO VEN_Item_Pedido
VALUES ('IVT01','PV001','PR001',2,50);

SELECT EST_Quantidade, EST_Reserva
FROM EST_Produto
WHERE EST_ID_Produto = 'PR001';


/* =========================================================
   3) TESTE ERRO - ESTOQUE INSUFICIENTE
   Esperado: ERRO -20001
   Trigger: TRG_VALIDA_ESTOQUE_REAL
   ========================================================= */
INSERT INTO VEN_Item_Pedido
VALUES ('IVT02','PV001','PR001',999,50);


/* =========================================================
   4) TESTE OK - EXCLUSÃO DE ITEM (DEVOLVE RESERVA)
   Esperado: SUCESSO + redução da reserva
   ========================================================= */
DELETE FROM VEN_Item_Pedido
WHERE ID_V_Item = 'IVT01';

SELECT EST_Quantidade, EST_Reserva
FROM EST_Produto
WHERE EST_ID_Produto = 'PR001';


/* =========================================================
   5) TESTE ERRO - EXCLUSÃO DE PEDIDO DE VENDA COM NF
   Esperado: ERRO -20003
   Trigger: TRG_BLOQ_DEL_PEDIDO_VENDA
   ========================================================= */
DELETE FROM VEN_Pedido
WHERE ID_P_Venda = 'PV001';


/* =========================================================
   6) TESTE ERRO - EXCLUSÃO DE PEDIDO DE COMPRA COM NF
   Esperado: ERRO -20002
   Trigger: TRG_BLOQ_DEL_PEDIDO_COMPRA
   ========================================================= */
DELETE FROM COM_Pedido
WHERE ID_P_Compra = 'PC001';


/* =========================================================
   7) TESTE OK - CRIAÇÃO DE PEDIDO DE COMPRA (PROCEDURE)
   Procedure: PR_Criar_Pedido_Compra
   ========================================================= */
BEGIN
    PKG_COMPRAS.Criar_Pedido_Compra(
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


/* =========================================================
   8) TESTE OK - INSERÇÃO DE ITEM DE COMPRA (PROCEDURE)
   Procedure: PR_Inserir_Item_Compra
   ========================================================= */
BEGIN
    PR_Inserir_Item_Compra(
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


/* =========================================================
   9) TESTE OK - CRIAÇÃO DE PEDIDO DE VENDA (PROCEDURE)
   Procedure: PR_Criar_Pedido_Venda
   ========================================================= */
BEGIN
    PR_Criar_Pedido_Venda(
        p_id_venda    => 'PV999',
        p_id_cliente  => 'C001',
        p_id_vendedor => 'V001',
        p_emissao     => TO_DATE('20260402','YYYYMMDD'),
        p_valor       => 800,
        p_pagamento   => 'CREDITO',
        p_parcelas    => 2
    );
END;
/

SELECT * FROM VEN_Pedido WHERE ID_P_Venda = 'PV999';


/* =========================================================
   10) TESTE OK - INSERÇÃO DE ITEM DE VENDA (PROCEDURE)
   Procedure: PR_Inserir_Item_Venda
   ========================================================= */
BEGIN
    PR_Inserir_Item_Venda(
        p_id_item    => 'IV999',
        p_id_venda   => 'PV999',
        p_id_produto => 'PR003',
        p_qtde       => 1,
        p_valor_unit => 500
    );
END;
/

SELECT * FROM VEN_Item_Pedido WHERE PVI_ID_P_Venda = 'PV999';


/* =========================================================
   11) TESTE OK - GERAR TÍTULOS A PAGAR
   Procedure: PR_Gerar_Titulos_Pagar
   ========================================================= */
BEGIN
    PR_Gerar_Titulos_Pagar(
        p_id_nfe      => 'NFE001',
        p_parcelas    => 3,
        p_valor_total => 1500,
        p_data_base   => TO_DATE('20260405','YYYYMMDD')
    );
END;
/

SELECT * FROM FIN_Titulo_Pg WHERE FTP_ID_NFE = 'NFE001';


/* =========================================================
   12) TESTE OK - GERAR TÍTULOS A RECEBER
   Procedure: PR_Gerar_Titulos_Receber
   ========================================================= */
BEGIN
    PR_Gerar_Titulos_Receber(
        p_id_nfs      => 'NFS001',
        p_parcelas    => 2,
        p_valor_total => 800,
        p_data_base   => TO_DATE('20260406','YYYYMMDD')
    );
END;
/

SELECT * FROM FIN_Titulo_Rec WHERE FTR_ID_NFS = 'NFS001';


/* =========================================================
   13) TESTE ERRO - BAIXA MAIOR QUE SALDO
   Esperado: ERRO -20004
   Trigger: TRG_VALIDA_BAIXA
   ========================================================= */
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


/* =========================================================
   FIM DOS TESTES
   ========================================================= */
