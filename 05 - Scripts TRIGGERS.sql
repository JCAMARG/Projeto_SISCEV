/* --- Triggers --- */


--> 01 – Atualiza saldo do título A PAGAR
CREATE OR REPLACE TRIGGER TRG_BAIXA_PAGAR
AFTER INSERT ON FIN_Baixa
FOR EACH ROW
WHEN (NEW.FBX_ID_PG IS NOT NULL)
BEGIN
    UPDATE FIN_Titulo_Pg
       SET FTP_Saldo = NVL(FTP_Saldo,0) - :NEW.FBX_Valor
     WHERE ID_Titulo_Pg = :NEW.FBX_ID_PG;
END;
/



--> 02 – Atualiza saldo do título A RECEBER
CREATE OR REPLACE TRIGGER TRG_BAIXA_RECEBER
AFTER INSERT ON FIN_Baixa
FOR EACH ROW
WHEN (NEW.FBX_ID_RC IS NOT NULL)
BEGIN
    UPDATE FIN_Titulo_Rec
       SET FTR_Saldo = NVL(FTR_Saldo,0) - :NEW.FBX_Valor
     WHERE ID_Titulo_Rec = :NEW.FBX_ID_RC;
END;
/



--> 03 – Atualiza total de vendas do vendedor
CREATE OR REPLACE TRIGGER TRG_ATUALIZA_VENDAS_VENDEDOR
AFTER INSERT ON VEN_Pedido
FOR EACH ROW
BEGIN
    UPDATE CAD_Vendedor
       SET VEN_Vendas = NVL(VEN_Vendas,0) + :NEW.PVE_Valor
     WHERE ID_Vendedor = :NEW.PVE_ID_Vendedor;
END;
/



--> 04 – Valida estoque antes de vender
CREATE OR REPLACE TRIGGER TRG_VALIDA_ESTOQUE_VENDA
BEFORE INSERT ON NFS_Item
FOR EACH ROW
DECLARE
    v_qtde_estoque NUMBER;
BEGIN
    SELECT NVL(EST_Quantidade,0)
      INTO v_qtde_estoque
      FROM EST_Produto
     WHERE EST_ID_Produto = :NEW.NSI_ID_Prod;

    IF v_qtde_estoque < :NEW.NSI_Qtde THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Estoque insuficiente para o produto informado.'
        );
    END IF;
END;
/



--> TRIGGER 05 – Atualizar estoque após NF de Entrada (Compra)
CREATE OR REPLACE TRIGGER TRG_ESTOQUE_ENTRADA
AFTER INSERT ON NFE_Item
FOR EACH ROW
BEGIN
    UPDATE EST_Produto
       SET EST_Quantidade = NVL(EST_Quantidade,0) + :NEW.NEI_Qtde
     WHERE EST_ID_Produto = :NEW.NEI_ID_Prod;
END;
/



--> TRIGGER 06 – Atualizar estoque após NF de Saída (Venda)
CREATE OR REPLACE TRIGGER TRG_ESTOQUE_SAIDA
AFTER INSERT ON NFS_Item
FOR EACH ROW
BEGIN
    UPDATE EST_Produto
        SET EST_Quantidade = NVL(EST_Quantidade,0) - :NEW.NSI_Qtde,
            EST_Reserva    = NVL(EST_Reserva,0) - :NEW.NSI_Qtde
     WHERE EST_ID_Produto = :NEW.NSI_ID_Prod;
END;
/



--> TRIGGER 07 – Validar estoque insuficiente no Pedido de Venda
CREATE OR REPLACE TRIGGER TRG_VALIDA_ESTOQUE_PEDIDO
BEFORE INSERT OR UPDATE ON VEN_Item_Pedido
FOR EACH ROW
DECLARE
    v_estoque NUMBER;
BEGIN
    SELECT EST_Quantidade
      INTO v_estoque
      FROM EST_Produto
     WHERE EST_ID_Produto = :NEW.PVI_ID_Produto;

    IF v_estoque < :NEW.PVI_Qtde THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Estoque insuficiente para o produto no pedido de venda.');
    END IF;
END;
/



--> TRIGGER 08 – Validar estoque insuficiente na NF de Saída
CREATE OR REPLACE TRIGGER TRG_VALIDA_ESTOQUE_NFS
BEFORE INSERT ON NFS_Item
FOR EACH ROW
DECLARE
    v_estoque NUMBER;
BEGIN
    SELECT EST_Quantidade
      INTO v_estoque
      FROM EST_Produto
     WHERE EST_ID_Produto = :NEW.NSI_ID_Prod;

    IF v_estoque < :NEW.NSI_Qtde THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Estoque insuficiente para emissão da NF de saída.');
    END IF;
END;
/



--> TRIGGER 09 – Atualizar saldo financeiro do Cliente
CREATE OR REPLACE TRIGGER TRG_ATUALIZA_SALDO_CLIENTE
AFTER INSERT ON FIN_Titulo_Rec
FOR EACH ROW
BEGIN
    UPDATE CAD_Cliente
       SET CLI_Saldo_Fin = NVL(CLI_Saldo_Fin,0) + :NEW.FTR_Valor
     WHERE ID_Cliente = (
           SELECT PV.PVE_ID_Cliente
             FROM NFS_Cabecalho N
             JOIN NFS_Item NI        ON NI.NSI_ID_NFS = N.ID_NFS
             JOIN VEN_Item_Pedido VI ON VI.ID_V_Item = NI.NSI_ID_IPDV
             JOIN VEN_Pedido PV      ON PV.ID_P_Venda = VI.PVI_ID_P_Venda
            WHERE N.ID_NFS = :NEW.FTR_ID_NFS
              AND ROWNUM = 1
     );
END;
/



--> TRIGGER 10 – Impedir exclusão de Pedido de Venda com NF
CREATE OR REPLACE TRIGGER TRG_BLOQ_DEL_PEDIDO_VENDA
BEFORE DELETE ON VEN_Pedido
FOR EACH ROW
DECLARE
    v_qtd NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_qtd
      FROM NFS_Item NI
      JOIN VEN_Item_Pedido VI ON VI.ID_V_Item = NI.NSI_ID_IPDV
     WHERE VI.PVI_ID_P_Venda = :OLD.ID_P_Venda;

    IF v_qtd > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Exclusão não permitida: Pedido de venda possui Nota Fiscal vinculada.'
        );
    END IF;
END;
/



--> TRIGGER 11 – Impedir exclusão de Pedido de Compra com NF
CREATE OR REPLACE TRIGGER TRG_BLOQ_DEL_PEDIDO_COMPRA
BEFORE DELETE ON COM_Pedido
FOR EACH ROW
DECLARE
    v_qtd NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_qtd
      FROM NFE_Item NI
      JOIN COM_Item_Pedido CI ON CI.ID_C_Item = NI.NEI_ID_IPDC
     WHERE CI.PCI_ID_P_Compra = :OLD.ID_P_Compra;

    IF v_qtd > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Exclusão não permitida: Pedido de compra possui Nota Fiscal de Entrada vinculada.'
        );
    END IF;
END;
/



--> TRIGGER 12 – Impedir baixa maior que o saldo (Pagar)
CREATE OR REPLACE TRIGGER TRG_VALIDA_BAIXA_PAGAR
BEFORE UPDATE ON FIN_Titulo_Pg
FOR EACH ROW
BEGIN
    IF :NEW.FTP_Saldo < 0 THEN
        RAISE_APPLICATION_ERROR(-20005,
            'Baixa maior que o saldo a pagar.');
    END IF;
END;
/



--> TRIGGER 13 – Impedir baixa maior que o saldo (Receber)
CREATE OR REPLACE TRIGGER TRG_VALIDA_BAIXA_RECEBER
BEFORE UPDATE ON FIN_Titulo_Rec
FOR EACH ROW
BEGIN
    IF :NEW.FTR_Saldo < 0 THEN
        RAISE_APPLICATION_ERROR(-20006,
            'Baixa maior que o saldo a receber.');
    END IF;
END;
/



--> TRIGGER 14 – Atualizar reserva de estoque no Pedido de Venda
CREATE OR REPLACE TRIGGER TRG_RESERVA_ESTOQUE_PEDIDO
AFTER INSERT OR DELETE ON VEN_Item_Pedido
FOR EACH ROW
BEGIN
    -- Inserção: reserva estoque
    IF INSERTING THEN
        UPDATE EST_Produto
           SET EST_Reserva = NVL(EST_Reserva, 0) + :NEW.PVI_Qtde
         WHERE EST_ID_Produto = :NEW.PVI_ID_Produto;
    END IF;

    -- Exclusão: devolve reserva
    IF DELETING THEN
        UPDATE EST_Produto
           SET EST_Reserva = NVL(EST_Reserva, 0) - :OLD.PVI_Qtde
         WHERE EST_ID_Produto = :OLD.PVI_ID_Produto;
    END IF;
END;
/



--> TRIGGER 15 - Impedir geração duplicada de títulos a pagar */
CREATE OR REPLACE TRIGGER TRG_BLOQ_DUP_TITULO_PG
BEFORE INSERT ON FIN_Titulo_Pg
FOR EACH ROW
DECLARE
    v_qtd NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_qtd
    FROM FIN_Titulo_Pg
    WHERE FTP_ID_NFE = :NEW.FTP_ID_NFE;

    IF v_qtd > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20020,
            'Já existem títulos a pagar gerados para esta Nota Fiscal de Entrada.'
        );
    END IF;
END;
/


--> TRIGGER 16 - Impedir geração duplicada de títulos a receber */
CREATE OR REPLACE TRIGGER TRG_BLOQ_DUP_TITULO_REC
BEFORE INSERT ON FIN_Titulo_Rec
FOR EACH ROW
DECLARE
    v_qtd NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_qtd
    FROM FIN_Titulo_Rec
    WHERE FTR_ID_NFS = :NEW.FTR_ID_NFS;

    IF v_qtd > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20021,
            'Já existem títulos a receber gerados para esta Nota Fiscal de Saída.'
        );
    END IF;
END;
/
