const crypto = require("crypto");

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const ASAAS_WEBHOOK_TOKEN =
    process.env.ASAAS_WEBHOOK_TOKEN;

// ============================================================
// BANCO
// ============================================================

function obterBanco() {

    const { db } =
        require("../config/database");

    return db;
}

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
        valor === "CHARGEBACK_DISPUTE"
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
// LOCALIZAR PEDIDO
// ============================================================

function localizarPedido(
    pedidos,
    payment
) {

    if (!Array.isArray(pedidos)) {

        return {
            pedido: null,
            index: -1,
        };

    }

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
    // 1. PAGAMENTO ID ASAAS
    // --------------------------------------------------------

    let index =
        pedidos.findIndex(
            pedido =>
                normalizarId(
                    pedido.pagamentoId
                ) === pagamentoId
        );

    if (index !== -1) {

        return {
            pedido:
                pedidos[index],
            index,
        };

    }

    // --------------------------------------------------------
    // 2. EXTERNAL REFERENCE
    // --------------------------------------------------------

    if (referencia) {

        index =
            pedidos.findIndex(
                pedido => {

                    const referencias = [

                        pedido.referenciaPagamento,

                        pedido.externalReference,

                        pedido.pedidoReferencia,

                        pedido.pagamentoReferencia,

                    ]
                    .map(normalizarId)
                    .filter(Boolean);

                    return referencias.includes(
                        referencia
                    );

                }
            );

        if (index !== -1) {

            return {
                pedido:
                    pedidos[index],
                index,
            };

        }

    }

    // --------------------------------------------------------
    // 3. ID DO PEDIDO
    // --------------------------------------------------------

    if (orderId) {

        index =
            pedidos.findIndex(
                pedido =>
                    normalizarId(
                        pedido.id
                    ) === orderId
            );

        if (index !== -1) {

            return {
                pedido:
                    pedidos[index],
                index,
            };

        }

    }

    // --------------------------------------------------------
    // 4. REFERÊNCIA FOODJET
    //
    // Exemplo:
    // FOODJET-1787794040158
    //
    // Alguns pedidos podem guardar apenas a parte numérica.
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

            index =
                pedidos.findIndex(
                    pedido => {

                        const candidatos = [

                            pedido.id,

                            pedido.referenciaPagamento,

                            pedido.pedidoReferencia,

                        ];

                        return candidatos.some(
                            valor =>
                                normalizarId(
                                    valor
                                ) ===
                                numeroReferencia
                        );

                    }
                );

            if (index !== -1) {

                return {
                    pedido:
                        pedidos[index],
                    index,
                };

            }

        }

    }

    return {
        pedido: null,
        index: -1,
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

    const db =
        obterBanco();

    if (!db.data) {

        db.data = {};

    }

    if (
        !Array.isArray(
            db.data.pedidos
        )
    ) {

        db.data.pedidos = [];

    }

    // --------------------------------------------------------
    // DADOS DO PAGAMENTO
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // SALVAR DADOS DO ASAAS
    // --------------------------------------------------------

    pedido.pagamentoId =
        pagamentoId ||
        pedido.pagamentoId ||
        "";

    pedido.externalReference =
        referencia ||
        pedido.externalReference ||
        pedido.referenciaPagamento ||
        "";

    pedido.referenciaPagamento =
        referencia ||
        pedido.referenciaPagamento ||
        "";

    pedido.statusPagamento =
        statusPagamento;

    pedido.statusPagamentoAsaas =
        statusAsaas;

    pedido.asaasPaymentId =
        pagamentoId;

    pedido.asaasEvento =
        evento;

    pedido.asaasAtualizadoEm =
        agora();

    pedido.pagamentoAtualizadoEm =
        agora();

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

            pedido.valorPagamento =
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

        pedido.statusPagamento =
            "approved";

        pedido.pagamentoAprovado =
            true;

        pedido.pagamentoAprovadoEm =
            pedido.pagamentoAprovadoEm ||
            agora();

        /*
         * NÃO alteramos automaticamente
         * pedido.status para EM_PREPARO.
         *
         * O restaurante ainda precisa aceitar.
         *
         * O status correto permanece:
         *
         * AGUARDANDO_RESTAURANTE
         */

        if (
            !pedido.status ||
            pedido.status ===
                "AGUARDANDO_PAGAMENTO"
        ) {

            pedido.status =
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

        pedido.pagamentoAprovado =
            false;

        pedido.pagamentoCanceladoEm =
            pedido.pagamentoCanceladoEm ||
            agora();

        /*
         * Só cancelamos o pedido automaticamente
         * se ele ainda não estiver em andamento.
         */

        if (
            pedido.status ===
                "AGUARDANDO_PAGAMENTO" ||
            pedido.status ===
                "AGUARDANDO_RESTAURANTE"
        ) {

            pedido.status =
                "CANCELADO";

            pedido.canceladoEm =
                pedido.canceladoEm ||
                agora();

        }

    }

    // --------------------------------------------------------
    // GRAVAR
    // --------------------------------------------------------

    const index =
        db.data.pedidos.findIndex(
            item =>
                normalizarId(
                    item.id
                ) ===
                normalizarId(
                    pedido.id
                )
        );

    if (index !== -1) {

        db.data.pedidos[index] =
            pedido;

    } else {

        db.data.pedidos.push(
            pedido
        );

    }

    await db.write();

    return pedido;

}

// ============================================================
// SALVAR PAGAMENTO PENDENTE
//
// Isso é importante porque o seu Flutter atualmente cria
// a cobrança ANTES de criar o pedido.
//
// O webhook pode chegar primeiro.
//
// Guardamos temporariamente os dados dentro de:
//
// db.data.pagamentosAsaas
// ============================================================

async function salvarPagamentoPendente(
    payment,
    evento
) {

    const db =
        obterBanco();

    if (!db.data) {

        db.data = {};

    }

    if (
        !Array.isArray(
            db.data.pagamentosAsaas
        )
    ) {

        db.data.pagamentosAsaas = [];

    }

    const pagamentoId =
        normalizarId(
            payment?.id
        );

    const referencia =
        normalizarId(
            payment?.externalReference
        );

    if (!pagamentoId) {

        return;

    }

    const existente =
        db.data.pagamentosAsaas.find(
            item =>
                normalizarId(
                    item.pagamentoId
                ) ===
                pagamentoId
        );

    const dados = {

        pagamentoId,

        paymentId:
            pagamentoId,

        externalReference:
            referencia,

        statusAsaas:
            normalizarId(
                payment?.status
            ).toUpperCase(),

        statusPagamento:
            normalizarStatusAsaas(
                payment?.status
            ),

        valor:
            Number(
                payment?.value
            ) || 0,

        evento,

        atualizadoEm:
            agora(),

    };

    if (existente) {

        Object.assign(
            existente,
            dados
        );

    } else {

        db.data.pagamentosAsaas.push(
            dados
        );

    }

    await db.write();

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
        // SE PAGAMENTO APROVADO,
        // AVISAR COMO NOVO PEDIDO
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

        const db =
            obterBanco();

        if (!db.data) {

            db.data = {};

        }

        if (
            !Array.isArray(
                db.data.pedidos
            )
        ) {

            db.data.pedidos = [];

        }

        // ====================================================
        // LOCALIZAR PEDIDO
        // ====================================================

        const resultado =
            localizarPedido(
                db.data.pedidos,
                payment
            );

        let pedido =
            resultado.pedido;

        const index =
            resultado.index;

        // ====================================================
        // PEDIDO NÃO EXISTE AINDA
        // ====================================================

        if (!pedido) {

            console.warn(
                "⚠️ PEDIDO AINDA NÃO EXISTE NO BANCO."
            );

            console.warn(
                "🔖 REFERÊNCIA:",
                payment.externalReference
            );

            console.warn(
                "🆔 PAYMENT:",
                payment.id
            );

            await salvarPagamentoPendente(
                payment,
                evento
            );

            console.log(
                "💾 PAGAMENTO SALVO COMO PENDENTE."
            );

            console.log(
                "========================================"
            );

            /*
             * Retornamos 200 para o Asaas.
             *
             * O webhook não deve ficar sendo reenviado
             * indefinidamente somente porque o pedido
             * ainda não foi criado.
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
        // ATUALIZAR
        // ====================================================

        pedido =
            await atualizarPedido(
                pedido,
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
         * Retornamos 500 para permitir que o Asaas
         * tente entregar o webhook novamente.
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