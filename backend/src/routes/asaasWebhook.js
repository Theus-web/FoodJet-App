
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

        case "PENDING":
        case "AWAITING_RISK_ANALYSIS":
        case "AWAITING_PAYMENT":
            return "pending";

        case "RECEIVED":
        case "CONFIRMED":
            return "approved";

        case "OVERDUE":
            return "overdue";

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
// PAGAMENTO APROVADO?
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
// PAGAMENTO CANCELADO?
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
// PARSE JSONB
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
// LOCALIZAR PEDIDO
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
    // 3. ORDER ID
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
    // 4. REFERÊNCIA FOODJET NUMÉRICA
    // --------------------------------------------------------

    if (referencia) {

        const numeroReferencia =
            referencia
                .replace(
                    /^FOODJET-/i,
                    ""
                )
                .trim();

        if (
            numeroReferencia &&
            /^\d+$/.test(numeroReferencia)
        ) {

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
// BUSCAR CHECKOUT PENDENTE
// ============================================================
//
// O cartão usa uma referência:
//
// FOODJET-CHK-...
//
// Essa referência não é o ID do pedido.
//
// O snapshot original está salvo em:
//
// pagamentos_asaas.dados.checkout
//
// ============================================================

async function buscarCheckoutPendente(
    referencia,
    pagamentoId
) {

    let resultado;

    // --------------------------------------------------------
    // 1. Tentar pelo PAYMENT ID
    // --------------------------------------------------------

    if (pagamentoId) {

        resultado =
            await pool.query(
                `
                SELECT
                    id,
                    pagamento_id,
                    pedido_id,
                    external_reference,
                    status,
                    valor,
                    dados
                FROM pagamentos_asaas
                WHERE pagamento_id = $1
                ORDER BY criado_em DESC
                LIMIT 1
                `,
                [
                    pagamentoId,
                ]
            );

        if (
            resultado.rows.length > 0
        ) {

            const registro =
                resultado.rows[0];

            const dados =
                parseDados(
                    registro.dados
                );

            const checkout =
                dados.checkout ||
                null;

            if (checkout) {

                return {
                    registro,
                    checkout,
                };
            }
        }
    }

    // --------------------------------------------------------
    // 2. Tentar pela referência
    // --------------------------------------------------------

    if (referencia) {

        resultado =
            await pool.query(
                `
                SELECT
                    id,
                    pagamento_id,
                    pedido_id,
                    external_reference,
                    status,
                    valor,
                    dados
                FROM pagamentos_asaas
                WHERE external_reference = $1
                ORDER BY criado_em DESC
                LIMIT 1
                `,
                [
                    referencia,
                ]
            );

        if (
            resultado.rows.length > 0
        ) {

            const registro =
                resultado.rows[0];

            const dados =
                parseDados(
                    registro.dados
                );

            const checkout =
                dados.checkout ||
                null;

            if (checkout) {

                return {
                    registro,
                    checkout,
                };
            }
        }
    }

    return null;
}

// ============================================================
// VALIDAR CHECKOUT
// ============================================================

function validarCheckout(
    checkout
) {

    if (!checkout) {

        throw new Error(
            "Checkout não encontrado."
        );
    }

    if (
        !checkout.clienteId
    ) {

        throw new Error(
            "Checkout sem clienteId."
        );
    }

    if (
        !checkout.restauranteId
    ) {

        throw new Error(
            "Checkout sem restauranteId."
        );
    }

    if (
        !Array.isArray(
            checkout.itens
        ) ||
        checkout.itens.length === 0
    ) {

        throw new Error(
            "Checkout sem itens."
        );
    }

    if (
        checkout.total === undefined ||
        checkout.total === null
    ) {

        throw new Error(
            "Checkout sem valor total."
        );
    }

    return true;
}

// ============================================================
// CRIAR PEDIDO A PARTIR DO CHECKOUT
// ============================================================
//
// IMPORTANTE:
//
// Esta função só é chamada quando o pagamento estiver
// RECEIVED ou CONFIRMED.
//
// Portanto:
//
// pagamento aprovado
//        ↓
// criar pedido
//
// ============================================================

async function criarPedidoDoCheckout(
    checkout,
    payment,
    evento
) {

    validarCheckout(
        checkout
    );

    const pagamentoId =
        normalizarId(
            payment?.id
        );

    const referencia =
        normalizarId(
            payment?.externalReference
        );

    const total =
        Number(
            checkout.total
        );

    const subtotal =
        Number(
            checkout.subtotal ?? 0
        );

    const taxaServico =
        Number(
            checkout.taxaServico ?? 0
        );

    const taxaEntrega =
        Number(
            checkout.taxaEntrega ?? 0
        );

    if (
        !Number.isFinite(total) ||
        total <= 0
    ) {

        throw new Error(
            "Valor total do checkout inválido."
        );
    }

    // --------------------------------------------------------
    // SEGURANÇA CONTRA DUPLICAÇÃO
    // --------------------------------------------------------
    //
    // Antes de criar um novo pedido, verificamos novamente
    // pelo pagamento Asaas e pela referência.
    //
    // Isso é importante porque o Asaas pode reenviar o
    // mesmo webhook.
    // --------------------------------------------------------

    const pedidoExistente =
        await localizarPedido({
            id:
                pagamentoId,

            externalReference:
                referencia,
        });

    if (
        pedidoExistente?.pedido
    ) {

        console.log(
            "♻️ PEDIDO JÁ EXISTE. NÃO SERÁ DUPLICADO."
        );

        console.log(
            "🆔 PEDIDO:",
            pedidoExistente.pedido.id
        );

        return pedidoExistente.pedido;
    }

    // --------------------------------------------------------
    // CRIAR PEDIDO
    // --------------------------------------------------------

    const pedidoCriado =
        await Order.criar({

            clienteId:
                String(
                    checkout.clienteId
                ),

            restauranteId:
                String(
                    checkout.restauranteId
                ),

            itens:
                checkout.itens,

            endereco:
                checkout.endereco ||
                null,

            pagamento:
                String(
                    checkout.pagamento ||
                    "CREDITO"
                ).toUpperCase(),

            subtotal:
                Number(
                    subtotal.toFixed(2)
                ),

            taxaServico:
                Number(
                    taxaServico.toFixed(2)
                ),

            taxaEntrega:
                Number(
                    taxaEntrega.toFixed(2)
                ),

            total:
                Number(
                    total.toFixed(2)
                ),

            precisaTroco:
                false,

            trocoPara:
                null,

            valorTroco:
                0,

            status:
                "AGUARDANDO_RESTAURANTE",

            pagamentoStatus:
                "APROVADO",

            statusPagamento:
                "approved",

            pagamentoAprovado:
                true,

            pagamentoId:
                pagamentoId,

            paymentId:
                pagamentoId,

            asaasPaymentId:
                pagamentoId,

            externalReference:
                referencia,

            referenciaPagamento:
                referencia,

            statusPagamentoAsaas:
                normalizarId(
                    payment?.status
                ).toUpperCase(),

            asaasEvento:
                evento,

            asaasAtualizadoEm:
                agora(),

            pagamentoAprovadoEm:
                agora(),
        });

    if (
        !pedidoCriado ||
        pedidoCriado.id === undefined ||
        pedidoCriado.id === null
    ) {

        throw new Error(
            "Order.criar() não retornou o pedido criado."
        );
    }

    console.log(
        "========================================"
    );

    console.log(
        "🎉 PEDIDO CRIADO APÓS PAGAMENTO APROVADO"
    );

    console.log(
        "🆔 PEDIDO:",
        pedidoCriado.id
    );

    console.log(
        "💳 ASAAS:",
        pagamentoId
    );

    console.log(
        "🔖 REFERÊNCIA:",
        referencia
    );

    console.log(
        "💰 TOTAL:",
        total
    );

    console.log(
        "========================================"
    );

    return pedidoCriado;
}

// ============================================================
// VINCULAR PEDIDO AO PAGAMENTO ASAAS
// ============================================================

async function vincularPedidoAoPagamento(
    pagamentoId,
    referencia,
    pedidoId,
    checkout,
    payment,
    evento
) {

    if (!pagamentoId) {

        throw new Error(
            "Pagamento Asaas não informado."
        );
    }

    if (
        pedidoId === undefined ||
        pedidoId === null
    ) {

        throw new Error(
            "Pedido não informado para vinculação."
        );
    }

    const dadosAtuais = {

        tipo:
            "CHECKOUT_CARTAO",

        checkout:
            checkout || null,

        pagamentoId,

        paymentId:
            pagamentoId,

        externalReference:
            referencia,

        pedidoId:
            String(pedidoId),

        statusAsaas:
            normalizarId(
                payment?.status
            ).toUpperCase(),

        statusPagamento:
            normalizarStatusAsaas(
                payment?.status
            ),

        evento,

        valor:
            Number(
                payment?.value || 0
            ),

        atualizadoEm:
            agora(),

        asaas:
            payment,
    };

    await pool.query(
        `
        UPDATE pagamentos_asaas
        SET
            pedido_id = $1,
            pagamento_id = $2,
            external_reference = $3,
            status = $4,
            valor = $5,
            dados = $6,
            atualizado_em = NOW()
        WHERE pagamento_id = $2
        `,
        [
            String(
                pedidoId
            ),

            pagamentoId,

            referencia || null,

            normalizarId(
                payment?.status
            ).toUpperCase() ||
                "PENDING",

            Number(
                payment?.value || 0
            ),

            dadosAtuais,
        ]
    );

    // --------------------------------------------------------
    // Caso o registro ainda não exista
    // --------------------------------------------------------

    const verificacao =
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

    if (
        verificacao.rows.length === 0
    ) {

        await pool.query(
            `
            INSERT INTO pagamentos_asaas (
                id,
                pagamento_id,
                pedido_id,
                external_reference,
                status,
                valor,
                dados,
                criado_em,
                atualizado_em
            )
            VALUES (
                $1,
                $2,
                $3,
                $4,
                $5,
                $6,
                $7,
                NOW(),
                NOW()
            )
            `,
            [

                pagamentoId,

                pagamentoId,

                String(
                    pedidoId
                ),

                referencia || null,

                normalizarId(
                    payment?.status
                ).toUpperCase() ||
                    "PENDING",

                Number(
                    payment?.value || 0
                ),

                dadosAtuais,
            ]
        );
    }

    console.log(
        "🔗 PAGAMENTO VINCULADO AO PEDIDO:"
    );

    console.log(
        "💳 ASAAS:",
        pagamentoId
    );

    console.log(
        "🆔 PEDIDO:",
        pedidoId
    );
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

    const pedidoAtualizado = {

        ...pedido,
    };

    pedidoAtualizado.pagamentoId =
        pagamentoId ||
        pedidoAtualizado.pagamentoId ||
        "";

    pedidoAtualizado.paymentId =
        pagamentoId ||
        pedidoAtualizado.paymentId ||
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
    // CANCELADO
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

    return await Order.atualizarDadosPedido(
        pedidoAtualizado.id,
        pedidoAtualizado
    );
}

// ============================================================
// SALVAR / ATUALIZAR PAGAMENTO ASAAS
// ============================================================

async function salvarPagamentoPendente(
    payment,
    evento,
    pedidoId = null,
    checkout = null
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

    // --------------------------------------------------------
    // Preservar checkout existente
    // --------------------------------------------------------

    let checkoutFinal =
        checkout || null;

    if (!checkoutFinal) {

        const existenteCheckout =
            await pool.query(
                `
                SELECT dados
                FROM pagamentos_asaas
                WHERE pagamento_id = $1
                LIMIT 1
                `,
                [
                    pagamentoId,
                ]
            );

        if (
            existenteCheckout.rows.length > 0
        ) {

            const dados =
                parseDados(
                    existenteCheckout.rows[0].dados
                );

            checkoutFinal =
                dados.checkout ||
                null;
        }
    }

    const dadosPagamento = {

        tipo:
            checkoutFinal
                ? "CHECKOUT_CARTAO"
                : "ASAAS_PAYMENT",

        checkout:
            checkoutFinal,

        pagamentoId,

        paymentId:
            pagamentoId,

        externalReference:
            referencia,

        statusAsaas,

        statusPagamento,

        evento,

        valor,

        pedidoId:
            pedidoId
                ? String(pedidoId)
                : null,

        atualizadoEm:
            agora(),

        payment,
    };

    // --------------------------------------------------------
    // EXISTENTE
    // --------------------------------------------------------

    const existente =
        await pool.query(
            `
            SELECT
                id,
                pedido_id,
                dados
            FROM pagamentos_asaas
            WHERE pagamento_id = $1
            LIMIT 1
            `,
            [
                pagamentoId,
            ]
        );

    if (
        existente.rows.length > 0
    ) {

        const registro =
            existente.rows[0];

        const dadosAntigos =
            parseDados(
                registro.dados
            );

        const checkoutPreservado =
            checkoutFinal ||
            dadosAntigos.checkout ||
            null;

        dadosPagamento.checkout =
            checkoutPreservado;

        await pool.query(
            `
            UPDATE pagamentos_asaas
            SET
                pedido_id = COALESCE($1, pedido_id),
                external_reference = COALESCE($2, external_reference),
                status = $3,
                valor = $4,
                dados = $5,
                atualizado_em = NOW()
            WHERE id = $6
            `,
            [

                pedidoId
                    ? String(pedidoId)
                    : null,

                referencia || null,

                statusAsaas || null,

                valor,

                dadosPagamento,

                registro.id,
            ]
        );

        console.log(
            "🔄 PAGAMENTO ASAAS ATUALIZADO NO POSTGRESQL:",
            pagamentoId
        );

        console.log(
            "📊 STATUS:",
            statusAsaas
        );

        console.log(
            "🔖 REFERÊNCIA:",
            referencia
        );

        if (pedidoId) {

            console.log(
                "🆔 PEDIDO VINCULADO:",
                pedidoId
            );
        }

        return registro.id;
    }

    // --------------------------------------------------------
    // NOVO
    // --------------------------------------------------------

    const inserido =
        await pool.query(
            `
            INSERT INTO pagamentos_asaas (
                id,
                pagamento_id,
                pedido_id,
                external_reference,
                status,
                valor,
                dados,
                criado_em,
                atualizado_em
            )
            VALUES (
                $1,
                $2,
                $3,
                $4,
                $5,
                $6,
                $7,
                NOW(),
                NOW()
            )
            RETURNING id
            `,
            [

                pagamentoId,

                pagamentoId,

                pedidoId
                    ? String(pedidoId)
                    : null,

                referencia || null,

                statusAsaas || null,

                valor,

                dadosPagamento,
            ]
        );

    console.log(
        "💾 PAGAMENTO ASAAS SALVO NO POSTGRESQL:",
        pagamentoId
    );

    console.log(
        "📊 STATUS:",
        statusAsaas
    );

    console.log(
        "🔖 REFERÊNCIA:",
        referencia
    );

    return (
        inserido.rows[0]?.id ||
        null
    );
}

// ============================================================
// SOCKET
// ============================================================

function emitirAtualizacao(
    pedido,
    evento
) {

    if (!global.io) {

        console.warn(
            "⚠️ Socket.IO não disponível."
        );

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
    // TOKEN
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
        // PRIMEIRO:
        // SALVAR/ATUALIZAR O PAGAMENTO
        // ====================================================

        await salvarPagamentoPendente(
            payment,
            evento,
            null,
            null
        );

        // ====================================================
        // LOCALIZAR PEDIDO EXISTENTE
        // ====================================================

        let resultado =
            await localizarPedido(
                payment
            );

        let pedido =
            resultado.pedido;

        // ====================================================
        // SE PEDIDO JÁ EXISTE
        // ====================================================

        if (pedido) {

            console.log(
                "📦 PEDIDO JÁ EXISTE:",
                pedido.id
            );

            pedido =
                await atualizarPedido(
                    pedido,
                    payment,
                    evento
                );

            await salvarPagamentoPendente(
                payment,
                evento,
                pedido.id,
                null
            );

            emitirAtualizacao(
                pedido,
                evento
            );

            console.log(
                "========================================"
            );

            console.log(
                "✅ WEBHOOK PROCESSADO"
            );

            console.log(
                "🆔 PEDIDO:",
                pedido.id
            );

            console.log(
                "🆔 ASAAS:",
                payment.id
            );

            console.log(
                "📊 STATUS:",
                payment.status
            );

            console.log(
                "========================================"
            );

            return res.status(200).json({

                sucesso: true,

                processado: true,

                pedidoEncontrado: true,

                pedidoCriadoAgora: false,

                pagamentoId:
                    payment.id,

                pedidoId:
                    pedido.id,

                statusPagamento:
                    pedido.statusPagamento,

                statusPedido:
                    pedido.status,
            });
        }

        // ====================================================
        // PEDIDO NÃO EXISTE
        // ====================================================

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

        // ====================================================
        // PAGAMENTO AINDA NÃO APROVADO
        // ====================================================

        if (
            !pagamentoAprovado(
                payment.status
            )
        ) {

            console.log(
                "⏳ PAGAMENTO AINDA NÃO APROVADO."
            );

            console.log(
                "💾 Checkout/pagamento permanecerá pendente."
            );

            console.log(
                "========================================"
            );

            return res.status(200).json({

                sucesso: true,

                processado: false,

                pagamentoRegistrado: true,

                pedidoEncontrado: false,

                pedidoCriado: false,

                pagamentoAprovado: false,

                pagamentoId:
                    payment.id,

                externalReference:
                    payment.externalReference ||
                    "",
            });
        }

        // ====================================================
        // PAGAMENTO APROVADO
        // ====================================================

        console.log(
            "========================================"
        );

        console.log(
            "💰 PAGAMENTO APROVADO"
        );

        console.log(
            "📦 INICIANDO CRIAÇÃO DO PEDIDO"
        );

        console.log(
            "========================================"
        );

        // ====================================================
        // RECUPERAR CHECKOUT
        // ====================================================

        const checkoutResultado =
            await buscarCheckoutPendente(
                normalizarId(
                    payment.externalReference
                ),
                normalizarId(
                    payment.id
                )
            );

        if (
            !checkoutResultado
        ) {

            console.error(
                "❌ CHECKOUT NÃO ENCONTRADO."
            );

            console.error(
                "🔖 REFERÊNCIA:",
                payment.externalReference
            );

            console.error(
                "🆔 PAYMENT:",
                payment.id
            );

            // ------------------------------------------------
            // Mantemos o pagamento registrado.
            // Não criamos pedido sem os dados do checkout.
            // ------------------------------------------------

            await salvarPagamentoPendente(
                payment,
                evento,
                null,
                null
            );

            return res.status(200).json({

                sucesso: true,

                processado: false,

                pagamentoRegistrado: true,

                pedidoEncontrado: false,

                pedidoCriado: false,

                erro:
                    "Pagamento aprovado, mas checkout não encontrado para criação do pedido.",
            });
        }

        const checkout =
            checkoutResultado.checkout;

        console.log(
            "✅ CHECKOUT ENCONTRADO"
        );

        console.log(
            "👤 CLIENTE:",
            checkout.clienteId
        );

        console.log(
            "🍽️ RESTAURANTE:",
            checkout.restauranteId
        );

        console.log(
            "📦 ITENS:",
            Array.isArray(
                checkout.itens
            )
                ? checkout.itens.length
                : 0
        );

        console.log(
            "💰 TOTAL:",
            checkout.total
        );

        // ====================================================
        // CRIAR PEDIDO
        // ====================================================

        pedido =
            await criarPedidoDoCheckout(
                checkout,
                payment,
                evento
            );

        // ====================================================
        // VINCULAR PAGAMENTO AO PEDIDO
        // ====================================================

        await vincularPedidoAoPagamento(
            normalizarId(
                payment.id
            ),
            normalizarId(
                payment.externalReference
            ),
            pedido.id,
            checkout,
            payment,
            evento
        );

        // ====================================================
        // GARANTIR DADOS FINAIS NO PEDIDO
        // ====================================================

        pedido =
            await atualizarPedido(
                pedido,
                payment,
                evento
            );

        // ====================================================
        // SALVAR PAGAMENTO FINAL
        // ====================================================

        await salvarPagamentoPendente(
            payment,
            evento,
            pedido.id,
            checkout
        );

        // ====================================================
        // SOCKET
        // ====================================================

        emitirAtualizacao(
            pedido,
            evento
        );

        // ====================================================
        // FINAL
        // ====================================================

        console.log(
            "========================================"
        );

        console.log(
            "🎉 WEBHOOK CONCLUÍDO COM SUCESSO"
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
            payment.id
        );

        console.log(
            "🔖 REFERÊNCIA:",
            payment.externalReference
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

        return res.status(200).json({

            sucesso: true,

            processado: true,

            pedidoEncontrado: false,

            pedidoCriadoAgora: true,

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
            "MENSAGEM:",
            error?.message
        );

        console.error(
            "STACK:",
            error?.stack
        );

        console.error(
            "========================================"
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao processar webhook.",

            detalhes:
                error?.message ||
                "Erro desconhecido.",
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

