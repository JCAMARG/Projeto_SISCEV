/* --- VIEWs --- */

--> Cadastros
	-- Pessoas
	CREATE OR REPLACE VIEW VW_Pessoas AS
	SELECT ID_Pessoa, PES_Tipo, PES_Nome, PES_Email, PES_Telefone
	FROM CAD_Pessoa;

	-- Clientes
	CREATE OR REPLACE VIEW VW_Clientes AS
	SELECT C.ID_Cliente, P.PES_Nome, C.CLI_Saldo_Fin
	FROM CAD_Cliente C
	JOIN CAD_Pessoa P ON P.ID_Pessoa = C.CLI_ID_Pessoa;

	-- Fornecedores
	CREATE OR REPLACE VIEW VW_Fornecedores AS
	SELECT F.ID_Fornecedor, P.PES_Nome, F.FOR_Saldo_Fin
	FROM CAD_Fornecedor F
	JOIN CAD_Pessoa P ON P.ID_Pessoa = F.FOR_ID_Pessoa;

	-- Vendedores
	CREATE OR REPLACE VIEW VW_Vendedores AS
	SELECT V.ID_Vendedor, P.PES_Nome, V.VEN_Vendas
	FROM CAD_Vendedor V
	JOIN CAD_Pessoa P ON P.ID_Pessoa = V.VEN_ID_Pessoa;

	-- Produtos
	CREATE OR REPLACE VIEW VW_Produtos AS
	SELECT ID_Produto, PRO_Descricao, PRO_Preco_Com, PRO_Preco_Ven
	FROM CAD_Produto;
	

--> Compras
	-- Pedido de Compra (Cabeçalho)
	CREATE OR REPLACE VIEW VW_Pedidos_Compra AS
	SELECT P.ID_P_Compra, F.ID_Fornecedor, PCO_Emissao, PCO_Valor, PCO_Num_Parc, PCO_Pagamento
	FROM COM_Pedido P
	JOIN CAD_Fornecedor F ON F.ID_Fornecedor = P.PCO_ID_Fornecedor;

	-- Itens de Compra
	CREATE OR REPLACE VIEW VW_Itens_Compra AS
	SELECT I.ID_C_Item, I.PCI_ID_P_Compra, P.PRO_Descricao,
		   I.PCI_Qtde, I.PCI_V_Unit
	FROM COM_Item_Pedido I
	JOIN CAD_Produto P ON P.ID_Produto = I.PCI_ID_Produto;

	-- NF Entrada
	CREATE OR REPLACE VIEW VW_NF_Entrada AS
	SELECT ID_NFE, NFE_Numero, NFE_Serie, NFE_Emissao, NFE_Valor_Total
	FROM NFE_Cabecalho;

	-- Financeiro a Pagar
	CREATE OR REPLACE VIEW VW_Titulos_Pagar AS
	SELECT ID_Titulo_Pg, FTP_ID_NFE, FTP_Parcela, FTP_Valor, FTP_Saldo
	FROM FIN_Titulo_Pg;
	
	-- Pedido de compra Completo
	CREATE OR REPLACE VIEW VW_Compra_Completa AS
	SELECT
		PC.ID_P_Compra,
		PC.PCO_Emissao,
		PC.PCO_Valor,
		F.ID_Fornecedor,
		PESS.PES_Nome AS Fornecedor,
		IP.ID_C_Item,
		PROD.PRO_Descricao,
		IP.PCI_Qtde,
		IP.PCI_V_Unit,
		(IP.PCI_Qtde * IP.PCI_V_Unit) AS Subtotal_Item
	FROM COM_Pedido PC
	JOIN CAD_Fornecedor F       ON F.ID_Fornecedor = PC.PCO_ID_Fornecedor
	JOIN CAD_Pessoa PESS        ON PESS.ID_Pessoa = F.FOR_ID_Pessoa
	JOIN COM_Item_Pedido IP     ON IP.PCI_ID_P_Compra = PC.ID_P_Compra
	JOIN CAD_Produto PROD       ON PROD.ID_Produto = IP.PCI_ID_Produto;
	
	-- NF Entrada completa
	CREATE OR REPLACE VIEW VW_NFE_Completa AS
	SELECT
		N.ID_NFE,
		N.NFE_Numero,
		N.NFE_Serie,
		N.NFE_Emissao,
		N.NFE_Valor_Total,
		I.ID_NFE_Item,
		PROD.PRO_Descricao,
		I.NEI_Qtde,
		I.NEI_Valor,
		TP.ID_Titulo_Pg,
		TP.FTP_Parcela,
		TP.FTP_Valor,
		TP.FTP_Saldo
	FROM NFE_Cabecalho N
	JOIN NFE_Item I          ON I.NEI_ID_NFE = N.ID_NFE
	JOIN CAD_Produto PROD    ON PROD.ID_Produto = I.NEI_ID_Prod
	LEFT JOIN FIN_Titulo_Pg TP ON TP.FTP_ID_NFE = N.ID_NFE;
	

--> Vendas
	-- Pedido de Venda
	CREATE OR REPLACE VIEW VW_Pedidos_Venda AS
	SELECT V.ID_P_Venda, C.ID_Cliente, V.PVE_Emissao, V.PVE_Valor, PVE_Num_Parc, PVE_Pagamento
	FROM VEN_Pedido V
	JOIN CAD_Cliente C ON C.ID_Cliente = V.PVE_ID_Cliente;

	-- Itens de Venda
	CREATE OR REPLACE VIEW VW_Itens_Venda AS
	SELECT I.ID_V_Item, I.PVI_ID_P_Venda, P.PRO_Descricao,
		   I.PVI_Qtde, I.PVI_V_Unit
	FROM VEN_Item_Pedido I
	JOIN CAD_Produto P ON P.ID_Produto = I.PVI_ID_Produto;

	-- NF Saída
	CREATE OR REPLACE VIEW VW_NF_Saida AS
	SELECT ID_NFS, NFS_Numero, NFS_Serie, NFS_Emissao, NFS_Valor_Total
	FROM NFS_Cabecalho;

	-- Financeiro a Receber
	CREATE OR REPLACE VIEW VW_Titulos_Receber AS
	SELECT ID_Titulo_Rec, FTR_ID_NFS, FTR_Parcela, FTR_Valor, FTR_Saldo
	FROM FIN_Titulo_Rec;
	
	-- Pedido de venda Completo
	CREATE OR REPLACE VIEW VW_Venda_Completa AS
	SELECT
		PV.ID_P_Venda,
		PV.PVE_Emissao,
		PV.PVE_Valor,
		CLI.ID_Cliente,
		PCLI.PES_Nome AS Cliente,
		VEN.ID_Vendedor,
		PVEN.PES_Nome AS Vendedor,
		IV.ID_V_Item,
		PROD.PRO_Descricao,
		IV.PVI_Qtde,
		IV.PVI_V_Unit,
		(IV.PVI_Qtde * IV.PVI_V_Unit) AS Subtotal_Item
	FROM VEN_Pedido PV
	JOIN CAD_Cliente CLI       ON CLI.ID_Cliente = PV.PVE_ID_Cliente
	JOIN CAD_Pessoa PCLI       ON PCLI.ID_Pessoa = CLI.CLI_ID_Pessoa
	JOIN CAD_Vendedor VEN      ON VEN.ID_Vendedor = PV.PVE_ID_Vendedor
	JOIN CAD_Pessoa PVEN       ON PVEN.ID_Pessoa = VEN.VEN_ID_Pessoa
	JOIN VEN_Item_Pedido IV    ON IV.PVI_ID_P_Venda = PV.ID_P_Venda
	JOIN CAD_Produto PROD      ON PROD.ID_Produto = IV.PVI_ID_Produto;
	
	-- NF Saida completa
	CREATE OR REPLACE VIEW VW_NFS_Completa AS
	SELECT
		N.ID_NFS,
		N.NFS_Numero,
		N.NFS_Serie,
		N.NFS_Emissao,
		N.NFS_Valor_Total,
		I.ID_NFS_Item,
		PROD.PRO_Descricao,
		I.NSI_Qtde,
		I.NSI_Valor,
		TR.ID_Titulo_Rec,
		TR.FTR_Parcela,
		TR.FTR_Valor,
		TR.FTR_Saldo
	FROM NFS_Cabecalho N
	JOIN NFS_Item I           ON I.NSI_ID_NFS = N.ID_NFS
	JOIN CAD_Produto PROD     ON PROD.ID_Produto = I.NSI_ID_Prod
	LEFT JOIN FIN_Titulo_Rec TR ON TR.FTR_ID_NFS = N.ID_NFS;


--> Gestão
	-- Estoque Atual
	CREATE OR REPLACE VIEW VW_Estoque_Atual AS
	SELECT E.EST_ID_Local, P.PRO_Descricao, E.EST_Quantidade, E.EST_Reserva
	FROM EST_Produto E
	JOIN CAD_Produto P ON P.ID_Produto = E.EST_ID_Produto;

	-- Faturamento Total
	CREATE OR REPLACE VIEW VW_Faturamento AS
	SELECT SUM(NFS_Valor_Total) AS TOTAL_FATURADO
	FROM NFS_Cabecalho;
	
	-- Resultado Financeiro
	CREATE OR REPLACE VIEW VW_Resultado_Financeiro AS
	SELECT
		R.Total_Receber_Gerado,
		R.Total_Recebido,
		R.Total_Receber_Em_Aberto,
		P.Total_Pagar_Gerado,
		P.Total_Pago,
		P.Total_Pagar_Em_Aberto
	FROM
		( SELECT
			  SUM(NVL(FTR_Valor,0))                      AS Total_Receber_Gerado,
			  SUM(NVL(FTR_Valor,0) - NVL(FTR_Saldo,0)) AS Total_Recebido,
			  SUM(NVL(FTR_Saldo,0))                     AS Total_Receber_Em_Aberto
		  FROM FIN_Titulo_Rec
		) R
	CROSS JOIN
		( SELECT
			  SUM(NVL(FTP_Valor,0))                      AS Total_Pagar_Gerado,
			  SUM(NVL(FTP_Valor,0) - NVL(FTP_Saldo,0)) AS Total_Pago,
			  SUM(NVL(FTP_Saldo,0))                     AS Total_Pagar_Em_Aberto
		  FROM FIN_Titulo_Pg
		) P;
	
	-- Fluxo de caixa mes a mes
	CREATE OR REPLACE VIEW VW_Fluxo_Caixa_Mensal AS
	SELECT
		Ano_Mes,
		Total_Entradas,
		Total_Saidas,
		Saldo_Mensal,
		SUM(Saldo_Mensal) OVER (ORDER BY Ano_Mes) AS Saldo_Acumulado
	FROM (
		SELECT
			TO_CHAR(FBX_Data, 'YYYY-MM') AS Ano_Mes,

			SUM(CASE WHEN FBX_ID_RC IS NOT NULL THEN NVL(FBX_Valor,0) ELSE 0 END) AS Total_Entradas,
			SUM(CASE WHEN FBX_ID_PG IS NOT NULL THEN NVL(FBX_Valor,0) ELSE 0 END) AS Total_Saidas,

			SUM(
				CASE 
					WHEN FBX_ID_RC IS NOT NULL THEN  NVL(FBX_Valor,0)
					WHEN FBX_ID_PG IS NOT NULL THEN -NVL(FBX_Valor,0)
					ELSE 0
				END
			) AS Saldo_Mensal
		FROM FIN_Baixa
		GROUP BY TO_CHAR(FBX_Data, 'YYYY-MM')
	);
