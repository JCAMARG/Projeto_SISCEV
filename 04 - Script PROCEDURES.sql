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
			p_valor,
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
            p_valor,
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
        p_id_nfe      IN VARCHAR2,
        p_parcelas    IN NUMBER,
        p_valor_total IN NUMBER,
        p_data_base   IN DATE
    );

    PROCEDURE PR_Gerar_Titulos_Receber (
        p_id_nfs      IN VARCHAR2,
        p_parcelas    IN NUMBER,
        p_valor_total IN NUMBER,
        p_data_base   IN DATE
    );

END PKG_FINANCEIRO;
/

CREATE OR REPLACE PACKAGE BODY PKG_FINANCEIRO AS

	--> PROCEDURE PR_05 - Gerar Títulos a Pagar (NFE)
    PROCEDURE PR_Gerar_Titulos_Pagar (
        p_id_nfe      IN VARCHAR2,
        p_parcelas    IN NUMBER,
        p_valor_total IN NUMBER,
        p_data_base   IN DATE
    ) IS
        v_valor_parcela NUMBER;
    BEGIN
        v_valor_parcela := p_valor_total / p_parcelas;

        FOR i IN 1..p_parcelas LOOP
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
                ADD_MONTHS(p_data_base, i),
                v_valor_parcela
            );
        END LOOP;
    END PR_Gerar_Titulos_Pagar;

	--> PROCEDURE PR_06 - Gerar Títulos a Receber (NFS)
    PROCEDURE PR_Gerar_Titulos_Receber (
        p_id_nfs      IN VARCHAR2,
        p_parcelas    IN NUMBER,
        p_valor_total IN NUMBER,
        p_data_base   IN DATE
    ) IS
        v_valor_parcela NUMBER;
    BEGIN
        v_valor_parcela := p_valor_total / p_parcelas;

        FOR i IN 1..p_parcelas LOOP
            INSERT INTO FIN_Titulo_Rec (
                ID_Titulo_Rec,
                FTR_ID_NFS,
                FTR_Parcela,
                FTR_Valor,
                FTR_Vencimento,
                FTR_Saldo
            ) VALUES (
                'TR' || p_id_nfs || LPAD(i,2,'0'),
                p_id_nfs,
                i,
                v_valor_parcela,
                ADD_MONTHS(p_data_base, i),
                v_valor_parcela
            );
        END LOOP;
    END PR_Gerar_Titulos_Receber;

END PKG_FINANCEIRO;
/
