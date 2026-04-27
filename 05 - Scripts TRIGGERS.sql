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
    v_disponivel NUMBER;
BEGIN
    SELECT NVL(EST_Quantidade,0) - NVL(EST_Reserva,0)
      INTO v_disponivel
      FROM EST_Produto
     WHERE EST_ID_Produto = :NEW.PVI_ID_Produto;

    IF :NEW.PVI_Qtde > v_disponivel THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Estoque insuficiente considerando reservas existentes.'
        );
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
            -20030,
            'Produto não encontrado no estoque.'
        );
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
AFTER INSERT OR UPDATE OR DELETE ON VEN_Item_Pedido
FOR EACH ROW
BEGIN
    -- Inserção: reserva estoque
    IF INSERTING THEN
        UPDATE EST_Produto
           SET EST_Reserva = NVL(EST_Reserva, 0) + :NEW.PVI_Qtde
         WHERE EST_ID_Produto = :NEW.PVI_ID_Produto;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20031,
                'Falha ao reservar estoque: produto inexistente.'
            );
        END IF;
    END IF;

    -- Atualização: ajusta diferença da reserva
    IF UPDATING THEN
        UPDATE EST_Produto
           SET EST_Reserva = NVL(EST_Reserva, 0)
                            - NVL(:OLD.PVI_Qtde, 0)
                            + NVL(:NEW.PVI_Qtde, 0)
         WHERE EST_ID_Produto = :NEW.PVI_ID_Produto;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20032,
                'Falha ao atualizar reserva de estoque.'
            );
        END IF;
    END IF;

    -- Exclusão: devolve reserva
    IF DELETING THEN
        UPDATE EST_Produto
           SET EST_Reserva = NVL(EST_Reserva, 0) - :OLD.PVI_Qtde
         WHERE EST_ID_Produto = :OLD.PVI_ID_Produto;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20033,
                'Falha ao liberar reserva de estoque.'
            );
        END IF;
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


--> TRIGGER 17 - Recalcula valor total do pedido de venda
CREATE OR REPLACE TRIGGER TRG_RECALC_TOTAL_PEDIDO_VENDA
AFTER INSERT OR UPDATE OR DELETE ON VEN_Item_Pedido
FOR EACH ROW
DECLARE
    v_total     NUMBER;
    v_id_pedido VEN_Pedido.ID_P_Venda%TYPE;
BEGIN
    -- Identifica o pedido afetado
    IF INSERTING OR UPDATING THEN
        v_id_pedido := :NEW.PVI_ID_P_Venda;
    ELSE
        v_id_pedido := :OLD.PVI_ID_P_Venda;
    END IF;

    -- Recalcula o valor total do pedido
    SELECT NVL(SUM(PVI_Qtde * PVI_V_Unit), 0)
      INTO v_total
      FROM VEN_Item_Pedido
     WHERE PVI_ID_P_Venda = v_id_pedido;

    -- Atualiza o cabeçalho
    UPDATE VEN_Pedido
       SET PVE_Valor = v_total
     WHERE ID_P_Venda = v_id_pedido;
END;
/
 


--> TRIGGER 18 - Recalcula valor total do pedido de compra
CREATE OR REPLACE TRIGGER TRG_RECALC_TOTAL_PEDIDO_COMPRA
AFTER INSERT OR UPDATE OR DELETE ON COM_Item_Pedido
FOR EACH ROW
DECLARE
    v_total     NUMBER;
    v_id_pedido COM_Pedido.ID_P_Compra%TYPE;
BEGIN
    -- Identifica o pedido afetado
    IF INSERTING OR UPDATING THEN
        v_id_pedido := :NEW.PCI_ID_P_Compra;
    ELSE
        v_id_pedido := :OLD.PCI_ID_P_Compra;
    END IF;

    -- Recalcula o valor total do pedido
    SELECT NVL(SUM(PCI_Qtde * PCI_V_Unit), 0)
      INTO v_total
      FROM COM_Item_Pedido
     WHERE PCI_ID_P_Compra = v_id_pedido;

    -- Atualiza o cabeçalho
    UPDATE COM_Pedido
       SET PCO_Valor = v_total
     WHERE ID_P_Compra = v_id_pedido;
END;
/
 


--> TRIGGER 19 - Recalcula valor total da NF de Entrada
CREATE OR REPLACE TRIGGER TRG_RECALC_TOTAL_NFE
AFTER INSERT OR UPDATE OR DELETE ON NFE_Item
FOR EACH ROW
DECLARE
    v_total NUMBER;
    v_id_nfe NFE_Cabecalho.ID_NFE%TYPE;
BEGIN
    -- Identifica a NF afetada
    IF INSERTING OR UPDATING THEN
        v_id_nfe := :NEW.NEI_ID_NFE;
    ELSE
        v_id_nfe := :OLD.NEI_ID_NFE;
    END IF;

    -- Recalcula o valor total da NF
    SELECT NVL(SUM(NEI_Valor), 0)
      INTO v_total
      FROM NFE_Item
     WHERE NEI_ID_NFE = v_id_nfe;

    -- Atualiza o cabeçalho
    UPDATE NFE_Cabecalho
       SET NFE_Valor_Total = v_total
     WHERE ID_NFE = v_id_nfe;
END;
/
 


--> TRIGGER 20 - Recalcula valor total da NF de Saída
CREATE OR REPLACE TRIGGER TRG_RECALC_TOTAL_NFS
AFTER INSERT OR UPDATE OR DELETE ON NFS_Item
FOR EACH ROW
DECLARE
    v_total NUMBER;
    v_id_nfs NFS_Cabecalho.ID_NFS%TYPE;
BEGIN
    -- Identifica a NF afetada
    IF INSERTING OR UPDATING THEN
        v_id_nfs := :NEW.NSI_ID_NFS;
    ELSE
        v_id_nfs := :OLD.NSI_ID_NFS;
    END IF;

    -- Recalcula o valor total da NF
    SELECT NVL(SUM(NSI_Valor), 0)
      INTO v_total
      FROM NFS_Item
     WHERE NSI_ID_NFS = v_id_nfs;

    -- Atualiza o cabeçalho
    UPDATE NFS_Cabecalho
       SET NFS_Valor_Total = v_total
     WHERE ID_NFS = v_id_nfs;
END;
/
