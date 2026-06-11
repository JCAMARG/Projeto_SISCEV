/* =========================================================
   SCRIPT DE DEMONSTRAÇÃO – SISCEV
   Sistema de Gestão de Compras, Estoque e Vendas

   Objetivo:
   Demonstrar o funcionamento integrado do banco:
   - Consulta inicial
   - Criação de pedido por procedure
   - Inserção de itens por procedure
   - Atualização automática por triggers
   - Geração de financeiro
   - Consulta por views
   ========================================================= */


/* =========================================================
   1) CONSULTA INICIAL DO ESTOQUE
   O que fazer:
   Mostrar a situação inicial dos produtos antes da operação.

   O que deve acontecer:
   A base deve exibir estoque disponível e reserva zerada.
   ========================================================= */

SELECT 
    EST_ID_Produto,
    EST_Quantidade,
    EST_Reserva,
    (NVL(EST_Quantidade,0) - NVL(EST_Reserva,0)) AS EST_Disponivel
FROM EST_Produto
WHERE EST_ID_Produto IN ('PR001','PR002')
ORDER BY EST_ID_Produto;



/* =========================================================
   2) CRIAR PEDIDO DE COMPRA
   Procedure: PKG_COMPRAS.PR_Criar_Pedido_Compra

   O que fazer:
   Criar o cabeçalho do pedido de compra.

   O que deve acontecer:
   O pedido PC900 será criado com valor 0.
   O valor será atualizado automaticamente depois da inclusão dos itens.
   ========================================================= */

BEGIN
    PKG_COMPRAS.PR_Criar_Pedido_Compra(
        p_id_pedido     => 'PC900',
        p_id_fornecedor => 'F001',
        p_emissao       => TO_DATE('20260601','YYYYMMDD'),
        p_valor         => 0,
        p_pagamento     => 'BOLETO',
        p_parcelas      => 2
    );
END;
/

SELECT *
FROM COM_Pedido
WHERE ID_P_Compra = 'PC900';



/* =========================================================
   3) INSERIR ITENS NO PEDIDO DE COMPRA
   Procedure: PKG_COMPRAS.PR_Inserir_Item_Compra
   Trigger acionada: TRG_RECALC_TOTAL_PEDIDO_COMPRA

   O que fazer:
   Inserir dois itens no pedido PC900.

   O que deve acontecer:
   A trigger recalcula automaticamente o valor total do pedido.

   Cálculo esperado:
   PR001: 10 x 50 = 500
   PR002:  5 x 30 = 150
   Total esperado do pedido = 650
   ========================================================= */

BEGIN
    PKG_COMPRAS.PR_Inserir_Item_Compra(
        p_id_item    => 'IC901',
        p_id_pedido  => 'PC900',
        p_id_produto => 'PR001',
        p_qtde       => 10,
        p_valor_unit => 50,
        p_entrega    => TO_DATE('20260603','YYYYMMDD')
    );

    PKG_COMPRAS.PR_Inserir_Item_Compra(
        p_id_item    => 'IC902',
        p_id_pedido  => 'PC900',
        p_id_produto => 'PR002',
        p_qtde       => 5,
        p_valor_unit => 30,
        p_entrega    => TO_DATE('20260603','YYYYMMDD')
    );
END;
/

SELECT *
FROM COM_Item_Pedido
WHERE PCI_ID_P_Compra = 'PC900';

SELECT 
    ID_P_Compra,
    PCO_Valor
FROM COM_Pedido
WHERE ID_P_Compra = 'PC900';



/* =========================================================
   4) EMITIR NOTA FISCAL DE ENTRADA
   Inserts diretos em NFE_Cabecalho e NFE_Item

   Triggers acionadas:
   - TRG_ESTOQUE_ENTRADA
   - TRG_RECALC_TOTAL_NFE

   O que fazer:
   Criar uma NFE vinculada aos itens do pedido de compra.

   O que deve acontecer:
   - O total da NFE será recalculado automaticamente.
   - O estoque dos produtos será aumentado automaticamente.

   Total esperado da NFE = 650
   Estoque:
   PR001 aumenta +10
   PR002 aumenta +5
   ========================================================= */

INSERT INTO NFE_Cabecalho (
    ID_NFE,
    NFE_Numero,
    NFE_Serie,
    NFE_Emissao,
    NFE_Vencimento,
    NFE_Valor_Total,
    NFE_Chave
) VALUES (
    'NFE90',
    9001,
    '1',
    TO_DATE('20260604','YYYYMMDD'),
    TO_DATE('20260704','YYYYMMDD'),
    0,
    'NFE90000000000000000000000000000000000000000'
);

INSERT INTO NFE_Item
VALUES ('NE901','NFE90','IC901','PR001',10,500);

INSERT INTO NFE_Item
VALUES ('NE902','NFE90','IC902','PR002',5,150);

SELECT 
    ID_NFE,
    NFE_Numero,
    NFE_Valor_Total
FROM NFE_Cabecalho
WHERE ID_NFE = 'NFE90';

SELECT 
    EST_ID_Produto,
    EST_Quantidade,
    EST_Reserva,
    (NVL(EST_Quantidade,0) - NVL(EST_Reserva,0)) AS EST_Disponivel
FROM EST_Produto
WHERE EST_ID_Produto IN ('PR001','PR002')
ORDER BY EST_ID_Produto;



/* =========================================================
   5) GERAR TÍTULOS A PAGAR
   Procedure: PKG_FINANCEIRO.PR_Gerar_Titulos_Pagar

   O que fazer:
   Gerar financeiro a pagar com base na NFE.

   O que deve acontecer:
   A procedure busca:
   - Valor total da NFE
   - Número de parcelas do pedido vinculado
   - Data base da NFE

   Como o pedido PC900 possui 2 parcelas:
   Total 650 / 2 = 325 por parcela

   IDs esperados:
   TPNFE9001
   TPNFE9002
   ========================================================= */

BEGIN
    PKG_FINANCEIRO.PR_Gerar_Titulos_Pagar(
        p_id_nfe => 'NFE90'
    );
END;
/

SELECT *
FROM FIN_Titulo_Pg
WHERE FTP_ID_NFE = 'NFE90'
ORDER BY FTP_Parcela;



/* =========================================================
   6) CRIAR PEDIDO DE VENDA
   Procedure: PKG_VENDAS.PR_Criar_Pedido_Venda

   O que fazer:
   Criar o cabeçalho do pedido de venda.

   O que deve acontecer:
   O pedido PV900 será criado com valor 0.
   O valor será atualizado automaticamente depois da inclusão dos itens.
   ========================================================= */

BEGIN
    PKG_VENDAS.PR_Criar_Pedido_Venda(
        p_id_venda    => 'PV900',
        p_id_cliente  => 'C001',
        p_id_vendedor => 'V001',
        p_emissao     => TO_DATE('20260605','YYYYMMDD'),
        p_valor       => 0,
        p_pagamento   => 'CRED',
        p_parcelas    => 2
    );
END;
/

SELECT *
FROM VEN_Pedido
WHERE ID_P_Venda = 'PV900';



/* =========================================================
   7) INSERIR ITEM NO PEDIDO DE VENDA
   Procedure: PKG_VENDAS.PR_Inserir_Item_Venda

   Triggers acionadas:
   - TRG_VALIDA_ESTOQUE_PEDIDO
   - TRG_RESERVA_ESTOQUE_PEDIDO
   - TRG_RECALC_TOTAL_PEDIDO_VENDA

   O que fazer:
   Inserir item no pedido de venda.

   O que deve acontecer:
   - O estoque disponível será validado.
   - A reserva do produto será aumentada.
   - O valor total do pedido será recalculado.

   Cálculo esperado:
   PR001: 2 x 90 = 180
   Total do pedido = 180
   Reserva PR001 aumenta +2
   ========================================================= */

BEGIN
    PKG_VENDAS.PR_Inserir_Item_Venda(
        p_id_item    => 'IV901',
        p_id_venda   => 'PV900',
        p_id_produto => 'PR001',
        p_qtde       => 2,
        p_valor_unit => 90
    );
END;
/

SELECT *
FROM VEN_Item_Pedido
WHERE PVI_ID_P_Venda = 'PV900';

SELECT 
    ID_P_Venda,
    PVE_Valor
FROM VEN_Pedido
WHERE ID_P_Venda = 'PV900';

SELECT 
    EST_ID_Produto,
    EST_Quantidade,
    EST_Reserva,
    (NVL(EST_Quantidade,0) - NVL(EST_Reserva,0)) AS EST_Disponivel
FROM EST_Produto
WHERE EST_ID_Produto = 'PR001';



/* =========================================================
   8) TESTE DE REGRA DE NEGÓCIO – ESTOQUE INSUFICIENTE
   Trigger acionada: TRG_VALIDA_ESTOQUE_PEDIDO

   O que fazer:
   Tentar inserir uma venda com quantidade muito acima do estoque.

   O que deve acontecer:
   O banco deve bloquear a operação com erro de estoque insuficiente.

   IMPORTANTE:
   Esse erro é esperado na demonstração.
   ========================================================= */

-- Este comando deve gerar erro proposital:
-- ORA-20001: Estoque insuficiente considerando reservas existentes.
INSERT INTO VEN_Item_Pedido
VALUES ('IV999','PV900','PR001',9999,90);



/* =========================================================
   9) EMITIR NOTA FISCAL DE SAÍDA
   Inserts diretos em NFS_Cabecalho e NFS_Item

   Triggers acionadas:
   - TRG_VALIDA_ESTOQUE_NFS
   - TRG_ESTOQUE_SAIDA
   - TRG_RECALC_TOTAL_NFS

   O que fazer:
   Criar uma NFS vinculada ao item do pedido de venda.

   O que deve acontecer:
   - O total da NFS será recalculado automaticamente.
   - O estoque físico será reduzido.
   - A reserva será reduzida.

   Total esperado da NFS = 180
   Estoque PR001 reduz -2
   Reserva PR001 reduz -2
   ========================================================= */

INSERT INTO NFS_Cabecalho (
    ID_NFS,
    NFS_Numero,
    NFS_Serie,
    NFS_Emissao,
    NFS_Vencimento,
    NFS_Valor_Total,
    NFS_Chave
) VALUES (
    'NFS90',
    9901,
    '1',
    TO_DATE('20260606','YYYYMMDD'),
    TO_DATE('20260706','YYYYMMDD'),
    0,
    'NFS90000000000000000000000000000000000000000'
);

INSERT INTO NFS_Item
VALUES ('NS901','NFS90','IV901','PR001',2,180);

SELECT 
    ID_NFS,
    NFS_Numero,
    NFS_Valor_Total
FROM NFS_Cabecalho
WHERE ID_NFS = 'NFS90';

SELECT 
    EST_ID_Produto,
    EST_Quantidade,
    EST_Reserva,
    (NVL(EST_Quantidade,0) - NVL(EST_Reserva,0)) AS EST_Disponivel
FROM EST_Produto
WHERE EST_ID_Produto = 'PR001';



/* =========================================================
   10) GERAR TÍTULOS A RECEBER
   Procedure: PKG_FINANCEIRO.PR_Gerar_Titulos_Receber

   O que fazer:
   Gerar financeiro a receber com base na NFS.

   O que deve acontecer:
   A procedure busca:
   - Valor total da NFS
   - Número de parcelas do pedido vinculado
   - Vencimento da NFS

   Como o pedido PV900 possui 2 parcelas:
   Total 180 / 2 = 90 por parcela

   IDs esperados:
   TRS9001
   TRS9002
   ========================================================= */

BEGIN
    PKG_FINANCEIRO.PR_Gerar_Titulos_Receber(
        p_id_nfs => 'NFS90'
    );
END;
/

SELECT *
FROM FIN_Titulo_Rec
WHERE FTR_ID_NFS = 'NFS90'
ORDER BY FTR_Parcela;



/* =========================================================
   11) BAIXA FINANCEIRA PARCIAL
   Trigger acionada: TRG_BAIXA_RECEBER

   O que fazer:
   Inserir uma baixa parcial no primeiro título a receber.

   O que deve acontecer:
   O saldo do título será reduzido automaticamente.

   Valor inicial do título: 90
   Baixa: 50
   Saldo esperado: 40
   ========================================================= */

INSERT INTO FIN_Baixa (
    ID_Baixa,
    FBX_ID_PG,
    FBX_ID_RC,
    FBX_Data,
    FBX_Valor,
    FBX_Tipo_Baixa,
    FBX_Historico
) VALUES (
    'BX900',
    NULL,
    'TRS9001',
    TO_DATE('20260610','YYYYMMDD'),
    50,
    'RC',
    'Baixa parcial demonstrativa'
);

SELECT *
FROM FIN_Titulo_Rec
WHERE ID_Titulo_Rec = 'TRS9001';



/* =========================================================
   12) CONSULTAR VIEWS GERENCIAIS
   O que fazer:
   Finalizar mostrando as informações consolidadas.

   O que deve acontecer:
   As views devem apresentar dados integrados sem precisar consultar
   manualmente várias tabelas.
   ========================================================= */

SELECT *
FROM VW_Estoque_Atual
WHERE PRO_Descricao = 'Teclado';

SELECT *
FROM VW_Compra_Completa
WHERE ID_P_Compra = 'PC900';

SELECT *
FROM VW_Venda_Completa
WHERE ID_P_Venda = 'PV900';

SELECT *
FROM VW_NFE_Completa
WHERE ID_NFE = 'NFE90';

SELECT *
FROM VW_NFS_Completa
WHERE ID_NFS = 'NFS90';

SELECT *
FROM VW_Resultado_Financeiro;

SELECT *
FROM VW_Fluxo_Caixa_Mensal;



/* =========================================================
   13) COMMIT FINAL
   O que fazer:
   Confirmar os dados gerados na demonstração.

   Caso queira repetir a demonstração, execute novamente o script
   de limpeza/carga inicial.
   ========================================================= */

COMMIT;