const crypto = require("crypto");

const {
    pool,
} = require("../config/database");

const Order = require("../models/order");

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const ASAAS_WEBHOOK_TOKEN =
    process.env.ASAAS_WEBHOOK_TOKEN;

// ============================================================
// NORMALIZAR ID
// ============================================================

function normalizarId(valor) {

    if (
        valor === undefined ||
        valor === null
    ) {
        return "";
    }

    return String(valor).trim();

}

// ============================================================
// DATA
// ============================================================

function agora() {

    return new Date().toISOString();

}

// ============================================================
// NORMALIZAR STATUS ASAAS
// ============================================================

function normalizarStatusAsaas(status) {

    const valor =
        normalizarId(status).toUpperCase();

    switch (valor) {

        // ----------------------------------------------------
        // PAGAMENTO AGUARDANDO
        // ----------------------------------------------------

        case "PENDING":
        case "AWAITING_RISK_ANALYSIS":
        case "AWAITING_PAYMENT":
            return "pending";

        // ----------------------------------------------------
        // PAGAMENTO RECEBIDO / CONFIRMADO
        // ----------------------------------------------------

        case "RECEIVED":
        case "CONFIRMED":
            return "approved";

        // ----------------------------------------------------
        // VENCIDO
        // ----------------------------------------------------

        case "OVERDUE":
            return "overdue";

        // ----------------------------------------------------
        // CANCELADO
        // ----------------------------------------------------

        case "REFUNDED":
        case "REFUND_REQUESTED":
        case "CHARGEBACK_REQUESTED":
        case "CHARGEBACK_DISPUTE":
        case "DUNNING_REQUESTED":
        case "DUNNING_RECEIVED":
            return "cancelled";

        default:
            return valor.toLowerCase();

    }

}

// ============================================================
// EVENTO É PAGAMENTO APROVADO?
// ============================================================

function pagamentoAprovado(status) {

    const valor =
        normalizarId(status).toUpperCase();

    return (
        valor === "RECEIVED" ||
        valor === "CONFIRMED"
    );

}

// ============================================================
// EVENTO É CANCELAMENTO?
// ============================================================

function pagamentoCancelado(status) {

    const valor =
        normalizarId(status).toUpperCase();

    return (
        valor === "OVERDUE" ||
        valor === "REFUNDED" ||
        valor === "REFUND_REQUESTED" ||
        valor === "CHARGEBACK_REQUESTED" ||
        valor === "CHARGEBACK_DISPUTE" ||
        valor === "DUNNING_REQUESTED" ||
        valor === "DUNNING_RECEIVED"
    );

}

// ============================================================
// VALIDAR TOKEN DO WEBHOOK
// ============================================================

function validarTokenWebhook(req) {

    if (!ASAAS_WEBHOOK_TOKEN) {

        console.error(
            "❌ ASAAS_WEBHOOK_TOKEN não configurado."
        );

        return false;

    }

    const tokenRecebido =
        req.headers["asaas-access-token"];

    if (!tokenRecebido) {

        console.error(
            "❌ Token do webhook não enviado."
        );

        return false;

    }

    const recebido =
        String(tokenRecebido).trim();

    const esperado =
        String(
            ASAAS_WEBHOOK_TOKEN
        ).trim();

    if (!recebido || !esperado) {

        return false;

    }

    try {

        const a =
            Buffer.from(
                recebido,
                "utf8"
            );

        const b =
            Buffer.from(
                esperado,
                "utf8"
            );

        if (a.length !== b.length) {

            return false;

        }

        return crypto.timingSafeEqual(
            a,
            b
        );

    } catch (error) {

        console.error(
            "❌ Erro validando token Asaas:",
            error.message
        );

        return false;

    }

}

// ============================================================
// PARSE DADOS JSONB
// ============================================================

function parseDados(valor) {

    if (!valor) {

        return {};

    }

    if (
        typeof valor === "object"
    ) {

        return valor;

    }

    try {

        return JSON.parse(valor);

    } catch (error) {

        console.error(
            "⚠️ Não foi possível interpretar dados JSON:",
            error.message
        );

        return {};

    }

}

// ============================================================
// LOCALIZAR PEDIDO NO POSTGRESQL
// ============================================================
//
// Procuramos na mesma ordem da implementação antiga:
//
// 1. pagamentoId
// 2. referenciaPagamento
// 3. externalReference
// 4. pedidoReferencia
// 5. pagamentoReferencia
// 6. orderId
// 7. referência FOODJET-123
//
// ============================================================

async function localizarPedido(payment) {

    const pagamentoId =
        normalizarId(
            payment?.id
        );

    const referencia =
        normalizarId(
            payment?.externalReference
        );

    const orderId =
        normalizarId(
            payment?.orderId
        );

    // --------------------------------------------------------
    // 1. PAYMENT ID ASAAS
    // --------------------------------------------------------

    if (pagamentoId) {

        const resultado =
            await pool.query(
                `
                SELECT
                    id,
                    dados
                FROM pedidos
                WHERE
                    dados->>'pagamentoId' = $1
                    OR dados->>'asaasPaymentId' = $1
                ORDER BY id DESC
                LIMIT 1
                `,
                [
                    pagamentoId,
                ]
            );

        if (
            resultado.rows.length > 0
        ) {

            return montarResultadoPedido(
                resultado.rows[0]
            );

        }

    }

    // --------------------------------------------------------
    // 2. EXTERNAL REFERENCE
    // --------------------------------------------------------

    if (referencia) {

        const resultado =
            await pool.query(
                `
                SELECT
                    id,
                    dados
                FROM pedidos
                WHERE
                    dados->>'referenciaPagamento' = $1
                    OR dados->>'externalReference' = $1
                    OR dados->>'pedidoReferencia' = $1
                    OR dados->>'pagamentoReferencia' = $1
                ORDER BY id DESC
                LIMIT 1
                `,
                [
                    referencia,
                ]
            );

        if (
            resultado.rows.length > 0
        ) {

            return montarResultadoPedido(
                resultado.rows[0]
            );

        }

    }

    // --------------------------------------------------------
    // 3. ID DO PEDIDO
    // --------------------------------------------------------

    if (orderId) {

        const numero =
            Number(orderId);

        if (
            Number.isSafeInteger(numero)
        ) {

            const resultado =
                await pool.query(
                    `
                    SELECT
                        id,
                        dados
                    FROM pedidos
                    WHERE id = $1
                    LIMIT 1
                    `,
                    [
                        numero,
                    ]
                );

            if (
                resultado.rows.length > 0
            ) {

                return montarResultadoPedido(
                    resultado.rows[0]
                );

            }

        }

    }

    // --------------------------------------------------------
    // 4. REFERÊNCIA FOODJET
    //
    // Exemplo:
    //
    // FOODJET-1787794040158
    //
    // --------------------------------------------------------

    if (referencia) {

        const numeroReferencia =
            referencia
                .replace(
                    /^FOODJET-/i,
                    ""
                )
                .trim();

        if (numeroReferencia) {

            const resultado =
                await pool.query(
                    `
                    SELECT
                        id,
                        dados
                    FROM pedidos
                    WHERE
                        CAST(id AS TEXT) = $1
                        OR dados->>'referenciaPagamento' = $1
                        OR dados->>'pedidoReferencia' = $1
                    ORDER BY id DESC
                    LIMIT 1
                    `,
                    [
                        numeroReferencia,
                    ]
                );

            if (
                resultado.rows.length > 0
            ) {

                return montarResultadoPedido(
                    resultado.rows[0]
                );

            }

        }

    }

    return {

        pedido: null,

        index: -1,

        row: null,

    };

}

// ============================================================
// MONTAR RESULTADO DO PEDIDO
// ============================================================

function montarResultadoPedido(row) {

    if (!row) {

        return {

            pedido: null,

            index: -1,

            row: null,

        };

    }

    const dados =
        parseDados(
            row.dados
        );

    return {

        pedido: {

            ...dados,

            id:
                Number(row.id),

        },

        index: -1,

        row,

    };

}

// ============================================================
// ATUALIZAR PEDIDO
// ============================================================

async function atualizarPedido(
    pedido,
    payment,
    evento
) {

    const pagamentoId =
        normalizarId(
            payment?.id
        );

    const referencia =
        normalizarId(
            payment?.externalReference
        );

    const statusAsaas =
        normalizarId(
            payment?.status
        ).toUpperCase();

    const statusPagamento =
        normalizarStatusAsaas(
            statusAsaas
        );

    const momento =
        agora();

    // --------------------------------------------------------
    // COPIAR PEDIDO
    // --------------------------------------------------------

    const pedidoAtualizado = {

        ...pedido,

    };

    // --------------------------------------------------------
    // DADOS DO PAGAMENTO
    // --------------------------------------------------------

    pedidoAtualizado.pagamentoId =
        pagamentoId ||
        pedidoAtualizado.pagamentoId ||
        "";

    pedidoAtualizado.externalReference =
        referencia ||
        pedidoAtualizado.externalReference ||
        pedidoAtualizado.referenciaPagamento ||
        "";

    pedidoAtualizado.referenciaPagamento =
        referencia ||
        pedidoAtualizado.referenciaPagamento ||
        "";

    pedidoAtualizado.statusPagamento =
        statusPagamento;

    pedidoAtualizado.statusPagamentoAsaas =
        statusAsaas;

    pedidoAtualizado.asaasPaymentId =
        pagamentoId ||
        pedidoAtualizado.asaasPaymentId ||
        "";

    pedidoAtualizado.asaasEvento =
        evento;

    pedidoAtualizado.asaasAtualizadoEm =
        momento;

    pedidoAtualizado.pagamentoAtualizadoEm =
        momento;

    // --------------------------------------------------------
    // VALOR
    // --------------------------------------------------------

    if (
        payment?.value !== undefined &&
        payment?.value !== null
    ) {

        const valor =
            Number(
                payment.value
            );

        if (
            Number.isFinite(valor)
        ) {

            pedidoAtualizado.valorPagamento =
                valor;

        }

    }

    // --------------------------------------------------------
    // APROVADO
    // --------------------------------------------------------

    if (
        pagamentoAprovado(
            statusAsaas
        )
    ) {

        pedidoAtualizado.statusPagamento =
            "approved";

        pedidoAtualizado.pagamentoAprovado =
            true;

        pedidoAtualizado.pagamentoAprovadoEm =
            pedidoAtualizado.pagamentoAprovadoEm ||
            momento;

        // ----------------------------------------------------
        // NÃO colocamos diretamente em preparo.
        //
        // O restaurante ainda precisa aceitar.
        // ----------------------------------------------------

        if (
            !pedidoAtualizado.status ||
            pedidoAtualizado.status ===
                "AGUARDANDO_PAGAMENTO"
        ) {

            pedidoAtualizado.status =
                "AGUARDANDO_RESTAURANTE";

        }

    }

    // --------------------------------------------------------
    // CANCELADO / VENCIDO
    // --------------------------------------------------------

    if (
        pagamentoCancelado(
            statusAsaas
        )
    ) {

        pedidoAtualizado.pagamentoAprovado =
            false;

        pedidoAtualizado.pagamentoCanceladoEm =
            pedidoAtualizado.pagamentoCanceladoEm ||
            momento;

        if (
            pedidoAtualizado.status ===
                "AGUARDANDO_PAGAMENTO" ||
            pedidoAtualizado.status ===
                "AGUARDANDO_RESTAURANTE"
        ) {

            pedidoAtualizado.status =
                "CANCELADO";

            pedidoAtualizado.canceladoEm =
                pedidoAtualizado.canceladoEm ||
                momento;

        }

    }

    // --------------------------------------------------------
    // ATUALIZAR NO POSTGRESQL
    // --------------------------------------------------------

    const atualizado =
        await Order.atualizarDadosPedido(
            pedidoAtualizado.id,
            pedidoAtualizado
        );

    return atualizado;

}

// ============================================================
// SALVAR PAGAMENTO ASAAS
// ============================================================
//
// Substitui:
//
// db.data.pagamentosAsaas
//
// Agora o pagamento fica no PostgreSQL.
//
// Isso permite que o webhook chegue antes do pedido sem
// depender de foodjet.json.
//
// ============================================================

async function salvarPagamentoPendente(
    payment,
    evento
) {

    const pagamentoId =
        normalizarId(
            payment?.id
        );

    const referencia =
        normalizarId(
            payment?.externalReference
        );

    if (!pagamentoId) {

        return null;

    }

    const statusAsaas =
        normalizarId(
            payment?.status
        ).toUpperCase();

    const statusPagamento =
        normalizarStatusAsaas(
            statusAsaas
        );

    const valor =
        Number(
            payment?.value
        ) || 0;

    const dadosPagamento = {

        pagamentoId,

        paymentId:
            pagamentoId,

        externalReference:
            referencia,

        statusAsaas,

        statusPagamento,

        valor,

        evento,

        atualizadoEm:
            agora(),

        payment,

    };

    // --------------------------------------------------------
    // VERIFICAR SE JÁ EXISTE
    // --------------------------------------------------------

    const existente =
        await pool.query(
            `
            SELECT id
            FROM pagamentos_asaas
            WHERE pagamento_id = $1
            LIMIT 1
            `,
            [
                pagamentoId,
            ]
        );

    // --------------------------------------------------------
    // ATUALIZAR EXISTENTE
    // --------------------------------------------------------

    if (
        existente.rows.length > 0
    ) {

        const id =
            existente.rows[0].id;

        await pool.query(
            `
            UPDATE pagamentos_asaas
            SET
                external_reference = $1,
                status_asaas = $2,
                status_pagamento = $3,
                evento = $4,
                valor = $5,
                atualizado_em = $6,
                dados = $7
            WHERE id = $8
            `,
            [
                referencia || null,
                statusAsaas || null,
                statusPagamento || null,
                evento || null,
                valor,
                new Date(),
                dadosPagamento,
                id,
            ]
        );

        console.log(
            "🔄 PAGAMENTO ASAAS ATUALIZADO NO POSTGRESQL:",
            pagamentoId
        );

        return id;

    }

    // --------------------------------------------------------
    // INSERIR NOVO
    // --------------------------------------------------------

    const inserido =
        await pool.query(
            `
            INSERT INTO pagamentos_asaas (
                pagamento_id,
                external_reference,
                status_asaas,
                status_pagamento,
                evento,
                valor,
                atualizado_em,
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
                $8
            )
            RETURNING id
            `,
            [
                pagamentoId,
                referencia || null,
                statusAsaas || null,
                statusPagamento || null,
                evento || null,
                valor,
                new Date(),
                dadosPagamento,
            ]
        );

    console.log(
        "💾 PAGAMENTO ASAAS SALVO NO POSTGRESQL:",
        pagamentoId
    );

    return inserido.rows[0]?.id || null;

}

// ============================================================
// SOCKET
// ============================================================

function emitirAtualizacao(
    pedido,
    evento
) {

    if (!global.io) {

        return;

    }

    // --------------------------------------------------------
    // RESTAURANTE
    // --------------------------------------------------------

    if (
        pedido?.restauranteId
    ) {

        const sala =
            `restaurante_${pedido.restauranteId}`;

        global.io
            .to(sala)
            .emit(
                "status_pagamento_atualizado",
                {
                    pedido,
                    evento,
                }
            );

        global.io
            .to(sala)
            .emit(
                "status_pedido_atualizado",
                pedido
            );

        // ----------------------------------------------------
        // SE PAGAMENTO APROVADO
        // ----------------------------------------------------

        if (
            pedido.statusPagamento ===
            "approved"
        ) {

            global.io
                .to(sala)
                .emit(
                    "novo_pedido",
                    pedido
                );

        }

        console.log(
            "🔔 SOCKET RESTAURANTE:",
            sala
        );

    }

    // --------------------------------------------------------
    // EVENTO GLOBAL
    // --------------------------------------------------------

    global.io.emit(
        "pagamento_atualizado",
        {
            pedido,
            evento,
        }
    );

}

// ============================================================
// WEBHOOK ASAAS
// POST /api/asaas/webhook
// ============================================================

async function webhook(
    req,
    res
) {

    console.log("");

    console.log(
        "========================================"
    );

    console.log(
        "🔔 FOODJET - ASAAS WEBHOOK"
    );

    console.log(
        "========================================"
    );

    // ========================================================
    // VALIDAR TOKEN
    // ========================================================

    if (
        !validarTokenWebhook(req)
    ) {

        console.error(
            "❌ WEBHOOK ASAAS RECUSADO"
        );

        console.log(
            "========================================"
        );

        return res.status(401).json({

            sucesso: false,

            erro:
                "Token do webhook inválido.",

        });

    }

    // ========================================================
    // PAYLOAD
    // ========================================================

    const body =
        req.body || {};

    const evento =
        normalizarId(
            body.event
        );

    const payment =
        body.payment || {};

    console.log(
        "📌 EVENTO:",
        evento
    );

    console.log(
        "🆔 PAYMENT ID:",
        payment?.id
    );

    console.log(
        "📊 STATUS ASAAS:",
        payment?.status
    );

    console.log(
        "💰 VALOR:",
        payment?.value
    );

    console.log(
        "🔖 REFERÊNCIA:",
        payment?.externalReference
    );

    // ========================================================
    // VALIDAR EVENTO
    // ========================================================

    if (!evento) {

        console.warn(
            "⚠️ Webhook recebido sem evento."
        );

        return res.status(200).json({

            sucesso: true,

            processado: false,

            mensagem:
                "Evento não informado.",

        });

    }

    // ========================================================
    // VALIDAR PAYMENT
    // ========================================================

    if (
        !payment ||
        !payment.id
    ) {

        console.warn(
            "⚠️ Webhook sem payment.id."
        );

        return res.status(200).json({

            sucesso: true,

            processado: false,

            mensagem:
                "Pagamento não informado.",

        });

    }

    try {

        // ====================================================
        // LOCALIZAR PEDIDO NO POSTGRESQL
        // ====================================================

        const resultado =
            await localizarPedido(
                payment
            );

        let pedido =
            resultado.pedido;

        // ====================================================
        // PEDIDO NÃO EXISTE AINDA
        // ====================================================

        if (!pedido) {

            console.warn(
                "⚠️ PEDIDO AINDA NÃO EXISTE NO POSTGRESQL."
            );

            console.warn(
                "🔖 REFERÊNCIA:",
                payment.externalReference
            );

            console.warn(
                "🆔 PAYMENT:",
                payment.id
            );

            // ------------------------------------------------
            // SALVAR WEBHOOK PARA CONCILIAÇÃO POSTERIOR
            // ------------------------------------------------

            await salvarPagamentoPendente(
                payment,
                evento
            );

            console.log(
                "💾 PAGAMENTO SALVO EM pagamentos_asaas."
            );

            console.log(
                "========================================"
            );

            /*
             * Retornamos 200 porque o webhook foi recebido
             * e persistido corretamente.
             */

            return res.status(200).json({

                sucesso: true,

                processado: false,

                pagamentoRegistrado: true,

                pedidoEncontrado: false,

                pagamentoId:
                    payment.id,

                externalReference:
                    payment.externalReference ||
                    "",

            });

        }

        // ====================================================
        // ATUALIZAR PEDIDO
        // ====================================================

        pedido =
            await atualizarPedido(
                pedido,
                payment,
                evento
            );

        // ====================================================
        // ATUALIZAR REGISTRO ASAAS
        //
        // Mesmo quando o pedido já existe, mantemos o evento
        // registrado em pagamentos_asaas.
        // ====================================================

        await salvarPagamentoPendente(
            payment,
            evento
        );

        console.log(
            "========================================"
        );

        console.log(
            "✅ WEBHOOK PROCESSADO"
        );

        console.log(
            "========================================"
        );

        console.log(
            "🆔 PEDIDO:",
            pedido.id
        );

        console.log(
            "🆔 ASAAS:",
            pedido.pagamentoId
        );

        console.log(
            "🔖 REFERÊNCIA:",
            pedido.externalReference
        );

        console.log(
            "📊 STATUS ASAAS:",
            payment.status
        );

        console.log(
            "💳 STATUS PAGAMENTO:",
            pedido.statusPagamento
        );

        console.log(
            "📦 STATUS PEDIDO:",
            pedido.status
        );

        console.log(
            "========================================"
        );

        // ====================================================
        // SOCKET
        // ====================================================

        emitirAtualizacao(
            pedido,
            evento
        );

        // ====================================================
        // RESPOSTA
        // ====================================================

        return res.status(200).json({

            sucesso: true,

            processado: true,

            pedidoEncontrado: true,

            pagamentoId:
                payment.id,

            pedidoId:
                pedido.id,

            statusPagamento:
                pedido.statusPagamento,

            statusPedido:
                pedido.status,

        });

    } catch (error) {

        console.error(
            "========================================"
        );

        console.error(
            "❌ ERRO PROCESSANDO WEBHOOK ASAAS"
        );

        console.error(
            "========================================"
        );

        console.error(
            error
        );

        console.error(
            "========================================"
        );

        /*
         * Retornamos 500 para permitir que o Asaas tente
         * entregar novamente quando ocorrer uma falha real
         * de processamento/persistência.
         */

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao processar webhook.",

            detalhes:
                error.message,

        });

    }

}

// ============================================================
// REGISTRAR ROTA
// ============================================================

function registrarWebhook(app) {

    if (!app) {

        throw new Error(
            "Express app não informado."
        );

    }

    app.post(
        "/api/asaas/webhook",
        webhook
    );

    console.log(
        "========================================"
    );

    console.log(
        "🔔 ROTA /api/asaas/webhook REGISTRADA"
    );

    console.log(
        "========================================"
    );

}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {

    webhook,

    registrarWebhook,

};