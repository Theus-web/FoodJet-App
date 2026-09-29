
const { pool } = require("../config/database");

// ============================================================
// MODELO DE CARTEIRA DO ENTREGADOR
// ============================================================

const Wallet = {};

// ============================================================
// BUSCAR CARTEIRA
// ============================================================

Wallet.buscar = async (entregadorId) => {
    const result = await pool.query(
        `
        SELECT
            id,
            entregador_id,
            saldo,
            limite_negativo,
            dinheiro_em_maos,
            total_comissoes,
            total_recebido_clientes,
            total_devido_restaurante,
            total_devido_foodjet,
            criado_em,
            atualizado_em,
            dados
        FROM carteiras_entregadores
        WHERE entregador_id = $1
        LIMIT 1
        `,
        [String(entregadorId)]
    );

    return result.rows[0] || null;
};

// ============================================================
// CRIAR CARTEIRA
// ============================================================

Wallet.criar = async (entregadorId) => {
    const result = await pool.query(
        `
        INSERT INTO carteiras_entregadores (
            entregador_id,
            saldo,
            limite_negativo,
            dinheiro_em_maos,
            total_comissoes,
            total_recebido_clientes,
            total_devido_restaurante,
            total_devido_foodjet
        )
        VALUES (
            $1,
            0,
            200,
            0,
            0,
            0,
            0,
            0
        )
        ON CONFLICT (entregador_id)
        DO NOTHING
        RETURNING *
        `,
        [String(entregadorId)]
    );

    if (!result.rows[0]) {
        return Wallet.buscar(entregadorId);
    }

    return result.rows[0];
};

// ============================================================
// GARANTIR QUE A CARTEIRA EXISTE
// ============================================================

Wallet.garantir = async (entregadorId) => {
    let carteira = await Wallet.buscar(entregadorId);

    if (!carteira) {
        carteira = await Wallet.criar(entregadorId);
    }

    return carteira;
};

// ============================================================
// RESUMO FINANCEIRO DO ENTREGADOR
//
// Usado pela Home do aplicativo.
// ============================================================

Wallet.resumo = async (entregadorId) => {
    const id = String(entregadorId);

    const carteira = await Wallet.garantir(id);

    const hoje = await pool.query(
        `
        SELECT
            COALESCE(SUM(valor_entregador), 0) AS ganhos_hoje,

            COUNT(*) FILTER (
                WHERE valor_entregador > 0
            ) AS entregas_hoje,

            COALESCE(SUM(valor), 0) AS recebido_hoje

        FROM movimentacoes_carteira
        WHERE entregador_id = $1
          AND criado_em >= CURRENT_DATE
          AND criado_em < CURRENT_DATE + INTERVAL '1 day'
          AND tipo = 'ENTREGA_FINALIZADA'
        `,
        [id]
    );

    const total = await pool.query(
        `
        SELECT
            COALESCE(SUM(valor_entregador), 0) AS ganhos_totais,

            COUNT(*) FILTER (
                WHERE valor_entregador > 0
            ) AS entregas_totais,

            COALESCE(SUM(valor), 0) AS recebido_total

        FROM movimentacoes_carteira
        WHERE entregador_id = $1
          AND tipo = 'ENTREGA_FINALIZADA'
        `,
        [id]
    );

    const ganhosHoje =
        Number(hoje.rows[0]?.ganhos_hoje) || 0;

    const entregasHoje =
        Number(hoje.rows[0]?.entregas_hoje) || 0;

    const recebidoHoje =
        Number(hoje.rows[0]?.recebido_hoje) || 0;

    const ganhosTotais =
        Number(total.rows[0]?.ganhos_totais) || 0;

    const entregasTotais =
        Number(total.rows[0]?.entregas_totais) || 0;

    const recebidoTotal =
        Number(total.rows[0]?.recebido_total) || 0;

    return {
        carteira,

        ganhosHoje,

        entregasHoje,

        recebidoHoje,

        ganhosTotais,

        entregasTotais,

        recebidoTotal,

        saldo: Number(carteira.saldo) || 0,

        dinheiroEmMaos:
            Number(carteira.dinheiro_em_maos) || 0,

        totalComissoes:
            Number(carteira.total_comissoes) || 0,

        totalRecebidoClientes:
            Number(carteira.total_recebido_clientes) || 0,

        totalDevidoRestaurante:
            Number(carteira.total_devido_restaurante) || 0,

        totalDevidoFoodjet:
            Number(carteira.total_devido_foodjet) || 0,

        limiteNegativo:
            Number(carteira.limite_negativo) || 0,
    };
};

// ============================================================
// ÚLTIMAS MOVIMENTAÇÕES
// ============================================================

Wallet.extrato = async (
    entregadorId,
    limite = 50
) => {

    const result = await pool.query(
        `
        SELECT
            id,
            carteira_id,
            entregador_id,
            pedido_id,
            tipo,
            descricao,
            forma_pagamento,
            valor,
            saldo_anterior,
            saldo_posterior,
            valor_restaurante,
            valor_foodjet,
            valor_entregador,
            dinheiro_em_maos_anterior,
            dinheiro_em_maos_posterior,
            referencia,
            dados,
            criado_em
        FROM movimentacoes_carteira
        WHERE entregador_id = $1
        ORDER BY criado_em DESC
        LIMIT $2
        `,
        [
            String(entregadorId),
            Math.max(1, Number(limite) || 50),
        ]
    );

    return result.rows;
};

// ============================================================
// REGISTRAR MOVIMENTAÇÃO FINANCEIRA
// ============================================================

Wallet.registrarMovimentacao = async ({
    entregadorId,
    pedidoId = null,
    tipo,
    descricao = null,
    formaPagamento = null,
    valor,
    valorRestaurante = 0,
    valorFoodjet = 0,
    valorEntregador = 0,
    alteracaoDinheiroEmMaos = 0,
    referencia = null,
    dados = {},
}) => {

    const client = await pool.connect();

    try {

        await client.query("BEGIN");

        // ====================================================
        // GARANTIR CARTEIRA
        // ====================================================

        await client.query(
            `
            INSERT INTO carteiras_entregadores (
                entregador_id,
                saldo,
                limite_negativo,
                dinheiro_em_maos,
                total_comissoes,
                total_recebido_clientes,
                total_devido_restaurante,
                total_devido_foodjet
            )
            VALUES ($1, 0, 200, 0, 0, 0, 0, 0)
            ON CONFLICT (entregador_id)
            DO NOTHING
            `,
            [String(entregadorId)]
        );

        // ====================================================
        // BLOQUEAR CARTEIRA
        // ====================================================

        const carteiraResult = await client.query(
            `
            SELECT *
            FROM carteiras_entregadores
            WHERE entregador_id = $1
            FOR UPDATE
            `,
            [String(entregadorId)]
        );

        if (!carteiraResult.rows[0]) {
            throw new Error(
                "Carteira do entregador não encontrada."
            );
        }

        const carteira = carteiraResult.rows[0];

        // ====================================================
        // VERIFICAR DUPLICIDADE
        // ====================================================

        if (referencia) {

            const duplicada = await client.query(
                `
                SELECT id
                FROM movimentacoes_carteira
                WHERE entregador_id = $1
                  AND referencia = $2
                LIMIT 1
                `,
                [
                    String(entregadorId),
                    String(referencia),
                ]
            );

            if (duplicada.rows[0]) {

                await client.query("ROLLBACK");

                return {
                    duplicada: true,
                    movimentacaoId:
                        duplicada.rows[0].id,
                    carteira,
                };
            }
        }

        // ====================================================
        // NORMALIZAR
        // ====================================================

        const valorNumerico =
            Number(valor) || 0;

        const restaurante =
            Number(valorRestaurante) || 0;

        const foodjet =
            Number(valorFoodjet) || 0;

        const entregador =
            Number(valorEntregador) || 0;

        const dinheiroAlteracao =
            Number(alteracaoDinheiroEmMaos) || 0;

        const dinheiroAnterior =
            Number(carteira.dinheiro_em_maos) || 0;

        const saldoAnterior =
            Number(carteira.saldo) || 0;

        // ====================================================
        // NOVO SALDO
        //
        // Exemplo:
        //
        // cliente paga R$100
        // entregador ganha R$10
        //
        // saldo:
        //
        // 0 - 100 + 10 = -90
        // ====================================================

        const novoSaldo =
            saldoAnterior
            - valorNumerico
            + entregador;

        const novoDinheiroEmMaos =
            dinheiroAnterior
            + dinheiroAlteracao;

        // ====================================================
        // LIMITE NEGATIVO
        // ====================================================

        const limiteNegativo =
            Number(carteira.limite_negativo) || 0;

        if (
            novoSaldo <
            -Math.abs(limiteNegativo)
        ) {
            throw new Error(
                `Limite negativo da carteira excedido. ` +
                `Saldo permitido: -R$ ${Math.abs(
                    limiteNegativo
                ).toFixed(2)}`
            );
        }

        // ====================================================
        // ATUALIZAR CARTEIRA
        // ====================================================

        const carteiraAtualizada =
            await client.query(
                `
                UPDATE carteiras_entregadores
                SET
                    saldo = $1,
                    dinheiro_em_maos = $2,

                    total_comissoes =
                        total_comissoes + $3,

                    total_recebido_clientes =
                        total_recebido_clientes + $4,

                    total_devido_restaurante =
                        total_devido_restaurante + $5,

                    total_devido_foodjet =
                        total_devido_foodjet + $6,

                    atualizado_em = NOW()

                WHERE id = $7

                RETURNING *
                `,
                [
                    novoSaldo,
                    novoDinheiroEmMaos,
                    entregador,
                    valorNumerico,
                    restaurante,
                    foodjet,
                    carteira.id,
                ]
            );

        // ====================================================
        // REGISTRAR EXTRATO
        // ====================================================

        const movimentacao =
            await client.query(
                `
                INSERT INTO movimentacoes_carteira (
                    carteira_id,
                    entregador_id,
                    pedido_id,
                    tipo,
                    descricao,
                    forma_pagamento,
                    valor,
                    saldo_anterior,
                    saldo_posterior,
                    valor_restaurante,
                    valor_foodjet,
                    valor_entregador,
                    dinheiro_em_maos_anterior,
                    dinheiro_em_maos_posterior,
                    referencia,
                    dados
                )
                VALUES (
                    $1,
                    $2,
                    $3,
                    $4,
                    $5,
                    $6,
                    $7,
                    $8,
                    $9,
                    $10,
                    $11,
                    $12,
                    $13,
                    $14,
                    $15,
                    $16
                )
                RETURNING *
                `,
                [
                    carteira.id,
                    String(entregadorId),
                    pedidoId,
                    tipo,
                    descricao,
                    formaPagamento,
                    valorNumerico,
                    saldoAnterior,
                    novoSaldo,
                    restaurante,
                    foodjet,
                    entregador,
                    dinheiroAnterior,
                    novoDinheiroEmMaos,
                    referencia,
                    dados,
                ]
            );

        await client.query("COMMIT");

        return {
            duplicada: false,
            carteira:
                carteiraAtualizada.rows[0],
            movimentacao:
                movimentacao.rows[0],
        };

    } catch (error) {

        try {
            await client.query("ROLLBACK");
        } catch (_) {}

        throw error;

    } finally {

        client.release();
    }
};

// ============================================================
// BUSCAR MOVIMENTAÇÃO DE UM PEDIDO
// ============================================================

Wallet.buscarPorPedido = async (
    entregadorId,
    pedidoId
) => {

    const result = await pool.query(
        `
        SELECT *
        FROM movimentacoes_carteira
        WHERE entregador_id = $1
          AND pedido_id = $2
        ORDER BY criado_em DESC
        `,
        [
            String(entregadorId),
            pedidoId,
        ]
    );

    return result.rows;
};

// ============================================================
// EXPORTAR
// ============================================================

module.exports = Wallet;

