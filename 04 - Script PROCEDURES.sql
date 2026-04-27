/* --- Stored Procedures --- */


--> PACKAGE: PKG_COMPRAS

CREATE OR REPLACE PACKAGE PKG_COMPRAS AS

	PROCEDURE PR_Criar_Pedido_Compra (
		p_id_pedido     IN VARCHAR2,
		p_id_fornecedor IN VARCHAR2,
		p_emissao       IN DATE,
		p_valor         IN NUMBER,
		p_pagamento     IN VARCHAR2,
		p_parcelas      IN NUMBER
	);

	PROCEDURE PR_Inserir_Item_Compra (
		p_id_item     IN VARCHAR2,
		p_id_pedido   IN VARCHAR2,
		p_id_produto  IN VARCHAR2,
		p_qtde        IN NUMBER,
		p_valor_unit  IN NUMBER,
		p_entrega     IN DATE
	);

END PKG_COMPRAS;
/

CREATE OR REPLACE PACKAGE BODY PKG_COMPRAS AS
	
	--> PROCEDURE PR_01 - Criar Pedido de Compra (Cabeçalho)
	PROCEDURE PR_Criar_Pedido_Compra (
		p_id_pedido     IN VARCHAR2,
		p_id_fornecedor IN VARCHAR2,
		p_emissao       IN DATE,
		p_valor         IN NUMBER,
		p_pagamento     IN VARCHAR2,
		p_parcelas      IN NUMBER
	) IS
	BEGIN
		INSERT INTO COM_Pedido (
			ID_P_Compra,
			PCO_ID_Fornecedor,
			PCO_Emissao,
			PCO_Valor,
			PCO_Pagamento,
			PCO_Num_Parc
		) VALUES (
			p_id_pedido,
			p_id_fornecedor,
			p_emissao,
			0,
			p_pagamento,
			p_parcelas
		);
	END PR_Criar_Pedido_Compra;

	--> PROCEDURE PR_02 - Inserir Item no Pedido de Compra
	PROCEDURE PR_Inserir_Item_Compra (
		p_id_item     IN VARCHAR2,
		p_id_pedido   IN VARCHAR2,
		p_id_produto  IN VARCHAR2,
		p_qtde        IN NUMBER,
		p_valor_unit  IN NUMBER,
		p_entrega     IN DATE
	) IS
	BEGIN
		INSERT INTO COM_Item_Pedido (
			ID_C_Item,
			PCI_ID_P_Compra,
			PCI_ID_Produto,
			PCI_Qtde,
			PCI_V_Unit,
			PCI_Data_Entrega
		) VALUES (
			p_id_item,
			p_id_pedido,
			p_id_produto,
			p_qtde,
			p_valor_unit,
			p_entrega
		);
	END PR_Inserir_Item_Compra;

END PKG_COMPRAS;
/



--> PACKAGE: PKG_VENDAS
CREATE OR REPLACE PACKAGE PKG_VENDAS AS

    PROCEDURE PR_Criar_Pedido_Venda (
        p_id_venda     IN VARCHAR2,
        p_id_cliente   IN VARCHAR2,
        p_id_vendedor  IN VARCHAR2,
        p_emissao      IN DATE,
        p_valor        IN NUMBER,
        p_pagamento    IN VARCHAR2,
        p_parcelas     IN NUMBER
    );

    PROCEDURE PR_Inserir_Item_Venda (
        p_id_item     IN VARCHAR2,
        p_id_venda    IN VARCHAR2,
        p_id_produto  IN VARCHAR2,
        p_qtde        IN NUMBER,
        p_valor_unit  IN NUMBER
    );

END PKG_VENDAS;
/

CREATE OR REPLACE PACKAGE BODY PKG_VENDAS AS

	--> PROCEDURE PR_03 - Criar Pedido de Venda (Cabeçalho)
    PROCEDURE PR_Criar_Pedido_Venda (
        p_id_venda     IN VARCHAR2,
        p_id_cliente   IN VARCHAR2,
        p_id_vendedor  IN VARCHAR2,
        p_emissao      IN DATE,
        p_valor        IN NUMBER,
        p_pagamento    IN VARCHAR2,
        p_parcelas     IN NUMBER
    ) IS
    BEGIN
        INSERT INTO VEN_Pedido (
            ID_P_Venda,
            PVE_ID_Cliente,
            PVE_ID_Vendedor,
            PVE_Emissao,
            PVE_Valor,
            PVE_Pagamento,
            PVE_Num_Parc
        ) VALUES (
            p_id_venda,
            p_id_cliente,
            p_id_vendedor,
            p_emissao,
            0,
            p_pagamento,
            p_parcelas
        );
    END PR_Criar_Pedido_Venda;

	--> PROCEDURE PR_04 - Inserir Item no Pedido de Venda
    PROCEDURE PR_Inserir_Item_Venda (
        p_id_item     IN VARCHAR2,
        p_id_venda    IN VARCHAR2,
        p_id_produto  IN VARCHAR2,
        p_qtde        IN NUMBER,
        p_valor_unit  IN NUMBER
    ) IS
    BEGIN
        INSERT INTO VEN_Item_Pedido (
            ID_V_Item,
            PVI_ID_P_Venda,
            PVI_ID_Produto,
            PVI_Qtde,
            PVI_V_Unit
        ) VALUES (
            p_id_item,
            p_id_venda,
            p_id_produto,
            p_qtde,
            p_valor_unit
        );
    END PR_Inserir_Item_Venda;

END PKG_VENDAS;
/



--> PACKAGE: PKG_FINANCEIRO
CREATE OR REPLACE PACKAGE PKG_FINANCEIRO AS

    PROCEDURE PR_Gerar_Titulos_Pagar (
	    p_id_nfe IN VARCHAR2
	);

    PROCEDURE PR_Gerar_Titulos_Receber (
        p_id_nfs IN VARCHAR2
    );

END PKG_FINANCEIRO;
/

CREATE OR REPLACE PACKAGE BODY PKG_FINANCEIRO AS
	
	--> PROCEDURE PR_05 - Gerar Títulos a Pagar (NFE)
	PROCEDURE PR_Gerar_Titulos_Pagar (
	    p_id_nfe IN VARCHAR2
	) IS
	    v_qtd_existente NUMBER;
	    v_valor_total   NUMBER;
	    v_parcelas      NUMBER;
	    v_data_base     DATE;
	    v_valor_parcela NUMBER;
	BEGIN
	    -- Validação de duplicidade (ANTES de gerar)
	    SELECT COUNT(*)
	      INTO v_qtd_existente
	      FROM FIN_Titulo_Pg
	     WHERE FTP_ID_NFE = p_id_nfe;
	
	    IF v_qtd_existente > 0 THEN
	        RAISE_APPLICATION_ERROR(
	            -20020,
	            'Já existem títulos a pagar gerados para esta Nota Fiscal de Entrada.'
	        );
	    END IF;
	
	    -- Dados da NF / pedidos
	    SELECT
	        n.NFE_Valor_Total,
	        MAX(p.PCO_Num_Parc),
	        n.NFE_Emissao
	    INTO
	        v_valor_total,
	        v_parcelas,
	        v_data_base
	    FROM NFE_Cabecalho n
	    JOIN NFE_Item ni       ON ni.NEI_ID_NFE = n.ID_NFE
	    JOIN COM_Item_Pedido c ON c.ID_C_Item = ni.NEI_ID_IPDC
	    JOIN COM_Pedido p      ON p.ID_P_Compra = c.PCI_ID_P_Compra
	    WHERE n.ID_NFE = p_id_nfe
	    GROUP BY n.NFE_Valor_Total, n.NFE_Emissao;
	
	    v_valor_parcela := v_valor_total / v_parcelas;
	
	    -- Geração das parcelas
	    FOR i IN 1 .. v_parcelas LOOP
	        INSERT INTO FIN_Titulo_Pg (
	            ID_Titulo_Pg,
	            FTP_ID_NFE,
	            FTP_Parcela,
	            FTP_Valor,
	            FTP_Vencimento,
	            FTP_Saldo
	        ) VALUES (
	            'TP' || p_id_nfe || LPAD(i,2,'0'),
	            p_id_nfe,
	            i,
	            v_valor_parcela,
	            ADD_MONTHS(v_data_base, i),
	            v_valor_parcela
	        );
	    END LOOP;
	END;

	--> PROCEDURE PR_06 - Gerar Títulos a Receber (NFS)
    PROCEDURE PR_Gerar_Titulos_Receber (
	    p_id_nfs IN VARCHAR2
	) IS
    	v_qtd_existente NUMBER;
	    v_valor_total    NUMBER;
	    v_parcelas       NUMBER;
	    v_data_base      DATE;
	    v_valor_parcela  NUMBER;
	BEGIN
		-- Validação de duplicidade (ANTES de gerar)
	    SELECT COUNT(*)
	      INTO v_qtd_existente
	      FROM FIN_Titulo_Rec
	     WHERE FTR_ID_NFS = p_id_nfs;
	
	    IF v_qtd_existente > 0 THEN
	        RAISE_APPLICATION_ERROR(
	            -20020,
	            'Já existem títulos a receber gerados para esta Nota Fiscal de saida.'
	        );
	    END IF;

	    /* 1. Buscar dados da NF e pedidos vinculados via itens */
	    SELECT
	        n.NFS_Valor_Total,
	        MAX(p.PVE_Num_Parc),
	        n.NFS_Vencimento
	    INTO
	        v_valor_total,
	        v_parcelas,
	        v_data_base
	    FROM NFS_Cabecalho n
	    JOIN NFS_Item ni
	        ON ni.NSI_ID_NFS = n.ID_NFS
	    JOIN VEN_Item_Pedido ip
	        ON ip.ID_V_Item = ni.NSI_ID_IPDV
	    JOIN VEN_Pedido p
	        ON p.ID_P_Venda = ip.PVI_ID_P_Venda
	    WHERE n.ID_NFS = p_id_nfs
	    GROUP BY
	        n.NFS_Valor_Total,
	        n.NFS_Vencimento;
	
	    /* 2. Calcular valor da parcela */
	    v_valor_parcela := v_valor_total / v_parcelas;
	
	    /* 3. Gerar títulos */
	    FOR i IN 1 .. v_parcelas LOOP
	        INSERT INTO FIN_Titulo_Rec (
	            ID_Titulo_Rec,
	            FTR_ID_NFS,
	            FTR_Parcela,
	            FTR_Valor,
	            FTR_Vencimento,
	            FTR_Saldo
	        ) VALUES (
	            'TR' || SUBSTR(p_id_nfs, -3) || LPAD(i,2,'0'),
	            p_id_nfs,
	            i,
	            v_valor_parcela,
	            ADD_MONTHS(v_data_base, i - 1),
	            v_valor_parcela
	        );
	    END LOOP;
	END PR_Gerar_Titulos_Receber;

END PKG_FINANCEIRO;
/
