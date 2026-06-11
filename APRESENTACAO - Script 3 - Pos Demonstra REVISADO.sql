/* =========================================================
   LIMPEZA PÓS-DEMONSTRAÇÃO – SISCEV
   Objetivo:
   Remover apenas os dados criados durante a demonstração,
   mantendo os cadastros e estoque inicial.

   Use depois de testar a demo, antes da apresentação oficial.
   ========================================================= */


--> 1) REMOVER BAIXAS FINANCEIRAS DA DEMO
DELETE FROM FIN_Baixa
WHERE ID_Baixa = 'BX900';


--> 2) REMOVER TÍTULOS FINANCEIROS DA DEMO
DELETE FROM FIN_Titulo_Rec
WHERE FTR_ID_NFS = 'NFS90';

DELETE FROM FIN_Titulo_Pg
WHERE FTP_ID_NFE = 'NFE90';


--> 3) REMOVER NOTA FISCAL DE SAÍDA
-- Ao deletar NFS_Item, atenção:
-- se suas triggers tratam apenas INSERT, o estoque não será devolvido automaticamente.
DELETE FROM NFS_Item
WHERE NSI_ID_NFS = 'NFS90';

DELETE FROM NFS_Cabecalho
WHERE ID_NFS = 'NFS90';


--> 4) REMOVER NOTA FISCAL DE ENTRADA
-- Ao deletar NFE_Item, atenção:
-- se suas triggers tratam apenas INSERT, o estoque não será reduzido automaticamente.
DELETE FROM NFE_Item
WHERE NEI_ID_NFE = 'NFE90';

DELETE FROM NFE_Cabecalho
WHERE ID_NFE = 'NFE90';


--> 5) REMOVER ITENS E PEDIDO DE VENDA
-- A exclusão do item de venda deve devolver a reserva,
-- caso a trigger TRG_RESERVA_ESTOQUE_PEDIDO esteja ativa para DELETE.
DELETE FROM VEN_Item_Pedido
WHERE PVI_ID_P_Venda = 'PV900'
   OR ID_V_Item IN ('IV901','IV999');

DELETE FROM VEN_Pedido
WHERE ID_P_Venda = 'PV900';


--> 6) REMOVER ITENS E PEDIDO DE COMPRA
DELETE FROM COM_Item_Pedido
WHERE PCI_ID_P_Compra = 'PC900';

DELETE FROM COM_Pedido
WHERE ID_P_Compra = 'PC900';


--> 7) RESTAURAR ESTOQUE INICIAL DA CARGA PRÉ-DEMONSTRAÇÃO
-- Importante porque as triggers de NFE/NFS podem não desfazer estoque no DELETE.
UPDATE EST_Produto
   SET EST_Quantidade = 20,
       EST_Reserva    = 0
 WHERE EST_ID_Produto = 'PR001';

UPDATE EST_Produto
   SET EST_Quantidade = 15,
       EST_Reserva    = 0
 WHERE EST_ID_Produto = 'PR002';

UPDATE EST_Produto
   SET EST_Quantidade = 10,
       EST_Reserva    = 0
 WHERE EST_ID_Produto = 'PR003';

UPDATE EST_Produto
   SET EST_Quantidade = 5,
       EST_Reserva    = 0
 WHERE EST_ID_Produto = 'PR004';

UPDATE EST_Produto
   SET EST_Quantidade = 12,
       EST_Reserva    = 0
 WHERE EST_ID_Produto = 'PR005';


--> 8) RESTAURAR SALDOS CADASTRAIS IMPACTADOS NA DEMO
UPDATE CAD_Fornecedor
   SET FOR_Saldo_Fin = 0
 WHERE ID_Fornecedor IN ('F001','F002');

UPDATE CAD_Cliente
   SET CLI_Saldo_Fin = 0
 WHERE ID_Cliente IN ('C001','C002');

-- Se o pedido de venda da demo atualizou vendas do vendedor,
-- este comando volta ao estado inicial da carga.
UPDATE CAD_Vendedor
   SET VEN_Vendas = 0
 WHERE ID_Vendedor = 'V001';


COMMIT;


/* =========================================================
   CONFERÊNCIA FINAL
   Esperado:
   - Nenhum registro da demo
   - Estoque igual à carga inicial
   - Saldos zerados
   ========================================================= */

SELECT * FROM COM_Pedido WHERE ID_P_Compra = 'PC900';
SELECT * FROM VEN_Pedido WHERE ID_P_Venda = 'PV900';

SELECT * FROM NFE_Cabecalho WHERE ID_NFE = 'NFE90';
SELECT * FROM NFS_Cabecalho WHERE ID_NFS = 'NFS90';

SELECT * FROM FIN_Titulo_Pg WHERE FTP_ID_NFE = 'NFE90';
SELECT * FROM FIN_Titulo_Rec WHERE FTR_ID_NFS = 'NFS90';
SELECT * FROM FIN_Baixa WHERE ID_Baixa = 'BX900';

SELECT 
    EST_ID_Produto,
    EST_Quantidade,
    EST_Reserva,
    (NVL(EST_Quantidade,0) - NVL(EST_Reserva,0)) AS EST_Disponivel
FROM EST_Produto
ORDER BY EST_ID_Produto;

SELECT * FROM CAD_Vendedor WHERE ID_Vendedor = 'V001';