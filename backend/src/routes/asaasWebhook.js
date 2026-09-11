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

    return [
        "OVERDUE",
        "REFUNDED",
        "REFUND_REQUESTED",
        "CHARGEBACK_REQUESTED",
        "CHARGEBACK_DISPUTE",
        "DUNNING_REQUESTED",
        "DUNNING_RECEIVED",
    ].includes(valor);
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

    const recebido =
        String(
            req.headers["asaas-access-token"] || ""
        ).trim();

    const esperado =
        String(
            ASAAS_WEBHOOK_TOKEN
        ).trim();

    if (
        !recebido ||
        !esperado
    ) {
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

        return (
            a.length === b.length &&
            crypto.timingSafeEqual(
                a,
                b
            )
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
            "⚠️ JSON inválido em pagamentos_asaas:",
            error.message
        );

        return {};
    }
}

// ============================================================
// TIPO DO CHECKOUT
// ============================================================

function obterTipoCheckout(checkout) {

    const pagamento =
        normalizarId(
            checkout?.pagamento
        ).toUpperCase();

    if (
        pagamento === "PIX"
    ) {

        return "CHECKOUT_PIX";
    }

    return "CHECKOUT_CARTAO";
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

    return {

        pedido: {

            ...parseDados(
                row.dados
            ),

            id:
                Number(
                    row.id
                ),
        },

        index: -1,

        row,
    };
}

// ============================================================
// LOCALIZAR PEDIDO
// ============================================================

async function localizarPedido(
    payment
) {

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
                    OR dados->>'paymentId' = $1
                ORDER BY id DESC
                LIMIT 1
                `,
                [
                    pagamentoId,
                ]
            );

        if (
            resultado.rows.length
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
            resultado.rows.length
        ) {

            return montarResultadoPedido(
                resultado.rows[0]
            );
        }
    }

    // --------------------------------------------------------
    // 3. ORDER ID
    // --------------------------------------------------------

    if (
        orderId &&
        Number.isSafeInteger(
            Number(orderId)
        )
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
                    Number(orderId),
                ]
            );

        if (
            resultado.rows.length
        ) {

            return montarResultadoPedido(
                resultado.rows[0]
            );
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
// IMPORTANTE:
//
// O checkout é salvo antes do pagamento.
//
// O pedido NÃO existe neste momento.
//
// ============================================================

async function buscarCheckoutPendente(
    referencia,
    pagamentoId
) {

    let resultado;

    // --------------------------------------------------------
    // 1. PAYMENT ID
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
            resultado.rows.length
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
    // 2. EXTERNAL REFERENCE
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
            resultado.rows.length
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
        !checkout.itens.length
    ) {

        throw new Error(
            "Checkout sem itens."
        );
    }

    const total =
        Number(
            checkout.total
        );

    if (
        !Number.isFinite(total) ||
        total <= 0
    ) {

        throw new Error(
            "Valor total do checkout inválido."
        );
    }

    return true;
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

    if (!pagamentoId) {
        return null;
    }

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

    const valor =
        Number(
            payment?.value
        ) || 0;

    // --------------------------------------------------------
    // PROCURAR PAGAMENTO
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

    // --------------------------------------------------------
    // PRESERVAR CHECKOUT
    // --------------------------------------------------------

    let checkoutFinal =
        checkout ||
        null;

    if (
        !checkoutFinal &&
        existente.rows.length
    ) {

        const dadosAntigos =
            parseDados(
                existente.rows[0].dados
            );

        checkoutFinal =
            dadosAntigos.checkout ||
            null;
    }

    // --------------------------------------------------------
    // TIPO CORRETO
    // --------------------------------------------------------

    const tipoCheckout =
        obterTipoCheckout(
            checkoutFinal
        );

    const dadosPagamento = {

        tipo:
            tipoCheckout,

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
            pedidoId !== null &&
            pedidoId !== undefined
                ? String(pedidoId)
                : null,

        atualizadoEm:
            agora(),

        payment,
    };

    // --------------------------------------------------------
    // ATUALIZAR
    // --------------------------------------------------------

    if (
        existente.rows.length
    ) {

        await pool.query(
            `
            UPDATE pagamentos_asaas
            SET
                pedido_id =
                    COALESCE(
                        $1,
                        pedido_id
                    ),

                external_reference =
                    COALESCE(
                        $2,
                        external_reference
                    ),

                status =
                    $3,

                valor =
                    $4,

                dados =
                    $5,

                atualizado_em =
                    NOW()

            WHERE id = $6
            `,
            [

                pedidoId !== null &&
                pedidoId !== undefined
                    ? String(pedidoId)
                    : null,

                referencia ||
                    null,

                statusAsaas ||
                    null,

                valor,

                dadosPagamento,

                existente.rows[0].id,
            ]
        );

        console.log(
            "🔄 PAGAMENTO ASAAS ATUALIZADO:",
            pagamentoId
        );

        console.log(
            "📊 STATUS:",
            statusAsaas
        );

        console.log(
            "💳 TIPO:",
            tipoCheckout
        );

        return (
            existente.rows[0].id
        );
    }

    // --------------------------------------------------------
    // INSERIR
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

                pedidoId !== null &&
                pedidoId !== undefined
                    ? String(pedidoId)
                    : null,

                referencia ||
                    null,

                statusAsaas ||
                    null,

                valor,

                dadosPagamento,
            ]
        );

    console.log(
        "💾 PAGAMENTO ASAAS SALVO:"
    );

    console.log(
        "🆔 ASAAS:",
        pagamentoId
    );

    console.log(
        "📊 STATUS:",
        statusAsaas
    );

    console.log(
        "💳 TIPO:",
        tipoCheckout
    );

    return (
        inserido.rows[0]?.id ||
        null
    );
}

// ============================================================
// CRIAR PEDIDO A PARTIR DO CHECKOUT PIX
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

    // ========================================================
    // TRAVA 1
    // ========================================================

    if (
        !pagamentoAprovado(
            payment?.status
        )
    ) {

        throw new Error(
            "Tentativa bloqueada: pedido PIX só pode ser criado após RECEIVED/CONFIRMED."
        );
    }

    // ========================================================
    // TRAVA 2
    // ========================================================

    const tipoCheckout =
        obterTipoCheckout(
            checkout
        );

    if (
        tipoCheckout !==
        "CHECKOUT_PIX"
    ) {

        throw new Error(
            "O webhook PIX recebeu um checkout que não é PIX."
        );
    }

    // ========================================================
    // TRAVA 3
    // ========================================================
    //
    // Verificar novamente se o pedido já existe.
    //
    // ========================================================

    const existente =
        await localizarPedido({

            id:
                pagamentoId,

            externalReference:
                referencia,
        });

    if (
        existente?.pedido
    ) {

        console.log(
            "♻️ PEDIDO JÁ EXISTE."
        );

        console.log(
            "🆔 PEDIDO:",
            existente.pedido.id
        );

        return (
            existente.pedido
        );
    }

    // ========================================================
    // CRIAR PEDIDO
    // ========================================================

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
                "PIX",

            subtotal:
                Number(
                    Number(
                        checkout.subtotal ||
                        0
                    ).toFixed(2)
                ),

            taxaServico:
                Number(
                    Number(
                        checkout.taxaServico ||
                        0
                    ).toFixed(2)
                ),

            taxaEntrega:
                Number(
                    Number(
                        checkout.taxaEntrega ||
                        0
                    ).toFixed(2)
                ),

            total:
                Number(
                    Number(
                        checkout.total
                    ).toFixed(2)
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
        !pedidoCriado?.id
    ) {

        throw new Error(
            "Order.criar() não retornou o pedido criado."
        );
    }

    console.log(
        "========================================"
    );

    console.log(
        "🎉 PEDIDO PIX CRIADO APÓS PAGAMENTO"
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
        pedidoId === null ||
        pedidoId === undefined
    ) {

        throw new Error(
            "Pedido não informado."
        );
    }

    const dadosAtuais = {

        tipo:
            obterTipoCheckout(
                checkout
            ),

        checkout:
            checkout ||
            null,

        pagamentoId,

        paymentId:
            pagamentoId,

        externalReference:
            referencia,

        pedidoId:
            String(
                pedidoId
            ),

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
                payment?.value ||
                0
            ),

        atualizadoEm:
            agora(),

        asaas:
            payment,
    };

    const atualizado =
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

                referencia ||
                    null,

                normalizarId(
                    payment?.status
                ).toUpperCase() ||
                    "PENDING",

                Number(
                    payment?.value ||
                    0
                ),

                dadosAtuais,
            ]
        );

    // --------------------------------------------------------
    // Se ainda não existe
    // --------------------------------------------------------

    if (
        !atualizado.rowCount
    ) {

        await salvarPagamentoPendente(
            payment,
            evento,
            pedidoId,
            checkout
        );
    }

    console.log(
        "🔗 PAGAMENTO VINCULADO:"
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

    const momento =
        agora();

    const atualizado = {

        ...pedido,

        pagamentoId:
            pagamentoId ||
            pedido.pagamentoId ||
            "",

        paymentId:
            pagamentoId ||
            pedido.paymentId ||
            "",

        asaasPaymentId:
            pagamentoId ||
            pedido.asaasPaymentId ||
            "",

        externalReference:
            referencia ||
            pedido.externalReference ||
            "",

        referenciaPagamento:
            referencia ||
            pedido.referenciaPagamento ||
            "",

        statusPagamento:
            normalizarStatusAsaas(
                statusAsaas
            ),

        statusPagamentoAsaas:
            statusAsaas,

        asaasEvento:
            evento,

        asaasAtualizadoEm:
            momento,

        pagamentoAtualizadoEm:
            momento,
    };

    // --------------------------------------------------------
    // APROVADO
    // --------------------------------------------------------

    if (
        pagamentoAprovado(
            statusAsaas
        )
    ) {

        atualizado.statusPagamento =
            "approved";

        atualizado.pagamentoAprovado =
            true;

        atualizado.pagamentoAprovadoEm =
            atualizado.pagamentoAprovadoEm ||
            momento;

        if (
            !atualizado.status ||
            atualizado.status ===
                "AGUARDANDO_PAGAMENTO"
        ) {

            atualizado.status =
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

        atualizado.pagamentoAprovado =
            false;

        atualizado.pagamentoCanceladoEm =
            atualizado.pagamentoCanceladoEm ||
            momento;

        if (
            atualizado.status ===
                "AGUARDANDO_PAGAMENTO" ||

            atualizado.status ===
                "AGUARDANDO_RESTAURANTE"
        ) {

            atualizado.status =
                "CANCELADO";

            atualizado.canceladoEm =
                atualizado.canceladoEm ||
                momento;
        }
    }

    return await Order.atualizarDadosPedido(
        atualizado.id,
        atualizado
    );
}

// ============================================================
// SOCKET.IO
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

        // ----------------------------------------------------
        // NOVO PEDIDO
        // ----------------------------------------------------
        //
        // Só envia depois do pagamento aprovado.
        //
        // ----------------------------------------------------

        if (
            pedido.statusPagamento ===
                "approved" &&

            pedido.status ===
                "AGUARDANDO_RESTAURANTE"
        ) {

            global.io
                .to(sala)
                .emit(
                    "novo_pedido",
                    pedido
                );

            console.log(
                "📢 NOVO PEDIDO ENVIADO AO RESTAURANTE:",
                pedido.id
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
// PROCESSAR PIX APROVADO
// ============================================================

async function processarPixAprovado(
    payment,
    evento
) {

    console.log(
        "========================================"
    );

    console.log(
        "💠 FOODJET - PIX APROVADO"
    );

    console.log(
        "========================================"
    );

    const pagamentoId =
        normalizarId(
            payment.id
        );

    const referencia =
        normalizarId(
            payment.externalReference
        );

    // ========================================================
    // 1. BUSCAR CHECKOUT
    // ========================================================

    const checkoutResultado =
        await buscarCheckoutPendente(
            referencia,
            pagamentoId
        );

    // ========================================================
    // CHECKOUT NÃO ENCONTRADO
    // ========================================================

    if (
        !checkoutResultado?.checkout
    ) {

        await salvarPagamentoPendente(
            payment,
            evento,
            null,
            null
        );

        console.error(
            "❌ CHECKOUT PIX NÃO ENCONTRADO."
        );

        console.error(
            "💳 ASAAS:",
            pagamentoId
        );

        console.error(
            "🔖 REFERÊNCIA:",
            referencia
        );

        return {

            processado:
                false,

            pagamentoRegistrado:
                true,

            pedidoCriado:
                false,
        };
    }

    const checkout =
        checkoutResultado.checkout;

    // ========================================================
    // TRAVA PIX
    // ========================================================

    if (
        obterTipoCheckout(
            checkout
        ) !==
        "CHECKOUT_PIX"
    ) {

        await salvarPagamentoPendente(
            payment,
            evento,
            null,
            checkout
        );

        throw new Error(
            "Checkout encontrado, mas não está marcado como PIX."
        );
    }

    // ========================================================
    // 2. VERIFICAR SE JÁ EXISTE PEDIDO
    // ========================================================

    const existente =
        await localizarPedido(
            payment
        );

    if (
        existente?.pedido
    ) {

        console.log(
            "♻️ PEDIDO PIX JÁ EXISTE:",
            existente.pedido.id
        );

        const pedido =
            await atualizarPedido(
                existente.pedido,
                payment,
                evento
            );

        await salvarPagamentoPendente(
            payment,
            evento,
            pedido.id,
            checkout
        );

        emitirAtualizacao(
            pedido,
            evento
        );

        return {

            processado:
                true,

            pedidoEncontrado:
                true,

            pedidoCriadoAgora:
                false,

            pedidoId:
                pedido.id,

            pedido,
        };
    }

    // ========================================================
    // 3. CRIAR PEDIDO
    // ========================================================

    console.log(
        "========================================"
    );

    console.log(
        "💰 PIX CONFIRMADO"
    );

    console.log(
        "📦 CRIANDO PEDIDO AGORA"
    );

    console.log(
        "========================================"
    );

    const pedidoCriado =
        await criarPedidoDoCheckout(
            checkout,
            payment,
            evento
        );

    // ========================================================
    // 4. VINCULAR PAGAMENTO
    // ========================================================

    await vincularPedidoAoPagamento(
        pagamentoId,
        referencia,
        pedidoCriado.id,
        checkout,
        payment,
        evento
    );

    // ========================================================
    // 5. ATUALIZAR PEDIDO
    // ========================================================

    const pedido =
        await atualizarPedido(
            pedidoCriado,
            payment,
            evento
        );

    // ========================================================
    // 6. SALVAR PAGAMENTO
    // ========================================================

    await salvarPagamentoPendente(
        payment,
        evento,
        pedido.id,
        checkout
    );

    // ========================================================
    // 7. SOCKET
    // ========================================================

    emitirAtualizacao(
        pedido,
        evento
    );

    console.log(
        "========================================"
    );

    console.log(
        "🎉 PEDIDO PIX CRIADO APÓS PAGAMENTO"
    );

    console.log(
        "🆔 PEDIDO:",
        pedido.id
    );

    console.log(
        "💳 ASAAS:",
        pagamentoId
    );

    console.log(
        "📦 STATUS:",
        pedido.status
    );

    console.log(
        "========================================"
    );

    return {

        processado:
            true,

        pedidoEncontrado:
            false,

        pedidoCriadoAgora:
            true,

        pedidoId:
            pedido.id,

        pedido,
    };
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

        return res.status(401).json({

            sucesso:
                false,

            erro:
                "Token do webhook inválido.",
        });
    }

    // ========================================================
    // BODY
    // ========================================================

    const body =
        req.body ||
        {};

    const evento =
        normalizarId(
            body.event
        );

    const payment =
        body.payment ||
        {};

    console.log(
        "📌 EVENTO:",
        evento
    );

    console.log(
        "🆔 PAYMENT ID:",
        payment.id
    );

    console.log(
        "📊 STATUS:",
        payment.status
    );

    console.log(
        "💳 TIPO:",
        payment.billingType
    );

    console.log(
        "🔖 REFERÊNCIA:",
        payment.externalReference
    );

    // ========================================================
    // VALIDAR
    // ========================================================

    if (
        !evento ||
        !payment.id
    ) {

        return res.status(200).json({

            sucesso:
                true,

            processado:
                false,

            mensagem:
                !evento
                    ? "Evento não informado."
                    : "Pagamento não informado.",
        });
    }

    try {

        const billingType =
            normalizarId(
                payment.billingType
            ).toUpperCase();

        const ehPix =
            billingType ===
            "PIX";

        console.log(
            "💠 É PIX:",
            ehPix
                ? "SIM"
                : "NÃO"
        );

        // ====================================================
        // ====================================================
        // PIX
        // ====================================================
        //
        // PENDING
        // AWAITING_PAYMENT
        // AWAITING_RISK_ANALYSIS
        //
        // NÃO CRIA PEDIDO.
        //
        // RECEIVED
        // CONFIRMED
        //
        // CRIA PEDIDO.
        //
        // ====================================================
        // ====================================================

        if (
            ehPix
        ) {

            // ------------------------------------------------
            // PIX AINDA NÃO PAGO
            // ------------------------------------------------

            if (
                !pagamentoAprovado(
                    payment.status
                )
            ) {

                await salvarPagamentoPendente(
                    payment,
                    evento,
                    null,
                    null
                );

                console.log(
                    "⏳ PIX AINDA NÃO APROVADO."
                );

                console.log(
                    "❌ NENHUM PEDIDO SERÁ CRIADO."
                );

                return res.status(200).json({

                    sucesso:
                        true,

                    processado:
                        false,

                    pagamentoRegistrado:
                        true,

                    pedidoCriado:
                        false,

                    pagamentoAprovado:
                        false,

                    pagamentoId:
                        payment.id,

                    externalReference:
                        payment.externalReference ||
                        "",
                });
            }

            // ------------------------------------------------
            // PIX APROVADO
            // ------------------------------------------------

            const resultado =
                await processarPixAprovado(
                    payment,
                    evento
                );

            return res.status(200).json({

                sucesso:
                    true,

                ...resultado,

                pagamentoId:
                    payment.id,

                statusPagamento:
                    resultado.pedido?.statusPagamento ||
                    "approved",

                statusPedido:
                    resultado.pedido?.status ||
                    null,
            });
        }

        // ====================================================
        // ====================================================
        // CARTÃO / OUTROS
        // ====================================================
        //
        // Não alteramos a regra principal do cartão.
        //
        // ====================================================
        // ====================================================

        const resultadoExistente =
            await localizarPedido(
                payment
            );

        if (
            resultadoExistente?.pedido
        ) {

            const pedido =
                await atualizarPedido(
                    resultadoExistente.pedido,
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

            return res.status(200).json({

                sucesso:
                    true,

                processado:
                    true,

                pedidoEncontrado:
                    true,

                pedidoCriadoAgora:
                    false,

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

        // ----------------------------------------------------
        // NÃO APROVADO
        // ----------------------------------------------------

        if (
            !pagamentoAprovado(
                payment.status
            )
        ) {

            await salvarPagamentoPendente(
                payment,
                evento,
                null,
                null
            );

            return res.status(200).json({

                sucesso:
                    true,

                processado:
                    false,

                pagamentoRegistrado:
                    true,

                pedidoEncontrado:
                    false,

                pedidoCriado:
                    false,

                pagamentoAprovado:
                    false,

                pagamentoId:
                    payment.id,

                externalReference:
                    payment.externalReference ||
                    "",
            });
        }

        // ----------------------------------------------------
        // PAGAMENTO APROVADO
        // ----------------------------------------------------

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
            !checkoutResultado?.checkout
        ) {

            await salvarPagamentoPendente(
                payment,
                evento,
                null,
                null
            );

            return res.status(200).json({

                sucesso:
                    true,

                processado:
                    false,

                pagamentoRegistrado:
                    true,

                pedidoCriado:
                    false,

                pagamentoAprovado:
                    true,

                pagamentoId:
                    payment.id,

                externalReference:
                    payment.externalReference ||
                    "",
            });
        }

        const checkout =
            checkoutResultado.checkout;

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
                        checkout.subtotal ||
                        0
                    ),

                taxaServico:
                    Number(
                        checkout.taxaServico ||
                        0
                    ),

                taxaEntrega:
                    Number(
                        checkout.taxaEntrega ||
                        0
                    ),

                total:
                    Number(
                        checkout.total
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
                    payment.id,

                paymentId:
                    payment.id,

                asaasPaymentId:
                    payment.id,

                externalReference:
                    normalizarId(
                        payment.externalReference
                    ),

                referenciaPagamento:
                    normalizarId(
                        payment.externalReference
                    ),

                statusPagamentoAsaas:
                    normalizarId(
                        payment.status
                    ).toUpperCase(),

                asaasEvento:
                    evento,

                asaasAtualizadoEm:
                    agora(),

                pagamentoAprovadoEm:
                    agora(),
            });

        await vincularPedidoAoPagamento(
            normalizarId(
                payment.id
            ),

            normalizarId(
                payment.externalReference
            ),

            pedidoCriado.id,

            checkout,

            payment,

            evento
        );

        const pedido =
            await atualizarPedido(
                pedidoCriado,
                payment,
                evento
            );

        await salvarPagamentoPendente(
            payment,
            evento,
            pedido.id,
            checkout
        );

        emitirAtualizacao(
            pedido,
            evento
        );

        return res.status(200).json({

            sucesso:
                true,

            processado:
                true,

            pedidoEncontrado:
                false,

            pedidoCriadoAgora:
                true,

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

            sucesso:
                false,

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

function registrarWebhook(
    app
) {

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
        "🔔 ROTA /api/asaas/webhook REGISTRADA"
    );
}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {

    webhook,

    registrarWebhook,
};