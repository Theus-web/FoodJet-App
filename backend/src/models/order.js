
const { pool } = require("../config/database");

// ======================================================
// CONFIGURAÇÃO
// ======================================================

const HORAS_HISTORICO_PEDIDOS = 24;

const INTERVALO_LIMPEZA_MS =
    60 * 60 * 1000;


// ======================================================
// STATUS QUE PODEM SER APAGADOS
// ======================================================

const STATUS_FINAIS_PARA_LIMPEZA = [
    "ENTREGUE",
    "RECUSADO",
    "CANCELADO",
    "CANCELADA",
    "CANCELLED",
];


// ======================================================
// GARANTIR CONEXÃO
// ======================================================

async function prepararBanco() {

    await pool.query("SELECT 1");

}


// ======================================================
// LIMPAR PEDIDOS ANTIGOS
// ======================================================

async function limparPedidosAntigos() {

    try {

        await prepararBanco();

        const resultado =
            await pool.query(
                `
                DELETE FROM pedidos
                WHERE
                    UPPER(
                        COALESCE(
                            status,
                            dados->>'status',
                            ''
                        )
                    ) = ANY($1::text[])

                    AND
                    COALESCE(
                        criado_em,
                        CASE
                            WHEN dados->>'criadoEm'
                                ~ '^\\d{4}-\\d{2}-\\d{2}T'
                            THEN
                                (dados->>'criadoEm')::timestamptz
                            ELSE
                                NULL
                        END
                    )
                    <
                    NOW() -
                    ($2 * INTERVAL '1 hour')

                    AND
                    COALESCE(
                        (
                            COALESCE(
                                suporte,
                                dados->'suporte',
                                '{}'::jsonb
                            )->>'aberto'
                        )::boolean,
                        false
                    ) = false

                RETURNING id
                `,
                [
                    STATUS_FINAIS_PARA_LIMPEZA,
                    HORAS_HISTORICO_PEDIDOS,
                ]
            );

        const quantidade =
            resultado.rows.length;

        if (quantidade > 0) {

            console.log(
                "========================================"
            );

            console.log(
                "🧹 LIMPEZA AUTOMÁTICA DE PEDIDOS"
            );

            console.log(
                "⏱️ LIMITE:",
                `${HORAS_HISTORICO_PEDIDOS} horas`
            );

            console.log(
                "🗑️ PEDIDOS REMOVIDOS:",
                quantidade
            );

            console.log(
                "📦 IDS:",
                resultado.rows
                    .map(row => row.id)
                    .join(", ")
            );

            console.log(
                "💳 PAGAMENTOS ASAAS:",
                "PRESERVADOS"
            );

            console.log(
                "========================================"
            );

        } else {

            console.log(
                "🧹 LIMPEZA AUTOMÁTICA: nenhum pedido antigo para remover."
            );

        }

        return quantidade;

    } catch (erro) {

        console.error(
            "❌ ERRO NA LIMPEZA AUTOMÁTICA DE PEDIDOS:",
            erro.message
        );

        return 0;

    }

}


// ======================================================
// INICIAR LIMPEZA AUTOMÁTICA
// ======================================================

setTimeout(
    () => {

        limparPedidosAntigos();

        setInterval(
            () => {

                limparPedidosAntigos();

            },
            INTERVALO_LIMPEZA_MS
        );

    },
    5000
);


// ======================================================
// GERAR ID DO PEDIDO
// ======================================================

async function gerarIdPedido() {

    const resultado = await pool.query(
        `
        SELECT nextval(
            pg_get_serial_sequence(
                'pedidos',
                'id'
            )
        ) AS id
        `
    );

    if (
        !resultado.rows.length ||
        resultado.rows[0].id === null
    ) {

        throw new Error(
            "Não foi possível gerar o ID do pedido."
        );

    }

    return Number(
        resultado.rows[0].id
    );
}


// ======================================================
// ENCONTRAR PAGAMENTO ASAAS PENDENTE
// ======================================================

async function encontrarPagamentoAsaasPendente(
    externalReference
) {

    const referencia =
        String(
            externalReference || ""
        ).trim();

    if (!referencia) {
        return null;
    }

    const resultado =
        await pool.query(
            `
            SELECT
                id,
                pagamento_id,
                pedido_id,
                external_reference,
                status,
                valor,
                dados,
                criado_em,
                atualizado_em
            FROM pagamentos_asaas
            WHERE external_reference = $1
            ORDER BY atualizado_em DESC NULLS LAST,
                     criado_em DESC
            LIMIT 1
            `,
            [
                referencia
            ]
        );

    if (
        resultado.rows.length === 0
    ) {

        return null;

    }

    const row =
        resultado.rows[0];

    let dados =
        row.dados;

    if (
        typeof dados === "string"
    ) {

        try {

            dados =
                JSON.parse(dados);

        } catch {

            dados = {};

        }

    }

    if (
        !dados ||
        typeof dados !== "object"
    ) {

        dados = {};

    }

    const statusAsaas =
        row.status ||
        dados.statusAsaas ||
        dados.status ||
        "";

    let statusPagamento =
        dados.statusPagamento ||
        "";

    const statusNormalizado =
        String(
            statusAsaas
        )
            .trim()
            .toUpperCase();

    if (
        statusNormalizado === "RECEIVED" ||
        statusNormalizado === "CONFIRMED"
    ) {

        statusPagamento =
            "approved";

    } else if (
        statusNormalizado === "PENDING" ||
        statusNormalizado === "AWAITING_RISK_ANALYSIS" ||
        statusNormalizado === "AWAITING_CASH_IN"
    ) {

        statusPagamento =
            "pending";

    } else if (
        statusNormalizado === "OVERDUE" ||
        statusNormalizado === "REFUNDED" ||
        statusNormalizado === "REFUND_REQUESTED" ||
        statusNormalizado === "CHARGEBACK_REQUESTED" ||
        statusNormalizado === "CHARGEBACK_DISPUTE" ||
        statusNormalizado === "DUNNING_REQUESTED"
    ) {

        statusPagamento =
            "rejected";

    } else if (!statusPagamento) {

        statusPagamento =
            "pending";

    }

    const evento =
        dados.evento ||
        dados.event ||
        dados.eventType ||
        "";

    const atualizadoEm =
        row.atualizado_em
            ? new Date(
                row.atualizado_em
            ).toISOString()
            : (
                dados.atualizadoEm ||
                new Date().toISOString()
            );

    return {

        id:
            row.id,

        pagamentoId:
            row.pagamento_id ||
            dados.pagamentoId ||
            dados.paymentId ||
            "",

        paymentId:
            row.pagamento_id ||
            dados.paymentId ||
            dados.pagamentoId ||
            "",

        pedidoId:
            row.pedido_id ||
            dados.pedidoId ||
            "",

        externalReference:
            row.external_reference ||
            dados.externalReference ||
            "",

        statusAsaas,

        statusPagamento,

        valor:
            Number(
                row.valor
            ) ||
            Number(
                dados.valor
            ) ||
            0,

        evento,

        atualizadoEm,

        dados

    };

}


// ======================================================
// MARCAR PAGAMENTO ASAAS COMO CONCILIADO
// ======================================================

async function marcarPagamentoAsaasConciliado(
    pagamentoAsaas,
    pedido
) {

    if (
        !pagamentoAsaas ||
        !pagamentoAsaas.id ||
        !pedido
    ) {

        return;

    }

    const dadosAtuais =
        pagamentoAsaas.dados &&
        typeof pagamentoAsaas.dados === "object"
            ? pagamentoAsaas.dados
            : {};

    const dadosAtualizados = {

        ...dadosAtuais,

        conciliado:
            true,

        conciliadoEm:
            new Date().toISOString(),

        pedidoId:
            pedido.id,

        pedidoRestauranteId:
            pedido.restauranteId ||
            null,

    };

    await pool.query(
        `
        UPDATE pagamentos_asaas
        SET
            dados = $1,
            atualizado_em = $2
        WHERE id = $3
        `,
        [
            dadosAtualizados,
            new Date(),
            pagamentoAsaas.id,
        ]
    );

    console.log(
        "🔗 PAGAMENTO ASAAS CONCILIADO COM PEDIDO:",
        pedido.id
    );

}


// ======================================================
// CRIAR PEDIDO
// ======================================================

async function criar(pedido) {

    await prepararBanco();

    if (
        !pedido ||
        typeof pedido !== "object"
    ) {

        throw new Error(
            "Dados do pedido inválidos."
        );

    }

    if (
        pedido.clienteId === undefined ||
        pedido.clienteId === null ||
        String(
            pedido.clienteId
        ).trim() === ""
    ) {

        throw new Error(
            "Cliente não identificado."
        );

    }

    if (
        pedido.restauranteId === undefined ||
        pedido.restauranteId === null ||
        String(
            pedido.restauranteId
        ).trim() === ""
    ) {

        throw new Error(
            "Restaurante não identificado."
        );

    }


    // ==================================================
    // ID
    // ==================================================

    const id =
        await gerarIdPedido();


    // ==================================================
    // DADOS BÁSICOS
    // ==================================================

    const itens =
        Array.isArray(
            pedido.itens
        )
            ? pedido.itens
            : [];

    const endereco =
        pedido.endereco &&
        typeof pedido.endereco === "object"
            ? pedido.endereco
            : {};


    const subtotal =
        Number(
            pedido.subtotal
        ) || 0;


    const taxaServico =
        Number(
            pedido.taxaServico
        ) || 0;


    const taxaEntrega =
        Number(
            pedido.taxaEntrega
        ) || 0;


    let total =
        Number(
            pedido.total
        );

    if (
        !Number.isFinite(total) ||
        total <= 0
    ) {

        total =
            subtotal +
            taxaServico +
            taxaEntrega;

    }


    const pagamento =
        String(
            pedido.pagamento ||
            "PIX"
        )
            .trim()
            .toUpperCase();


    const precisaTroco =
        pagamento === "DINHEIRO"
            ? Boolean(
                pedido.precisaTroco
            )
            : false;


    const trocoPara =
        precisaTroco
            ? Number(
                pedido.trocoPara
            ) || 0
            : null;


    const valorTroco =
        precisaTroco &&
        trocoPara !== null
            ? Math.max(
                0,
                trocoPara - total
            )
            : 0;


    const externalReference =
        String(
            pedido.externalReference ||
            pedido.referenciaPagamento ||
            id
        ).trim();


    const criadoEm =
        pedido.criadoEm ||
        new Date().toISOString();


    // ==================================================
    // PEDIDO BASE
    // ==================================================

    const novoPedido = {

        id,

        clienteId:
            String(
                pedido.clienteId
            ),

        restauranteId:
            String(
                pedido.restauranteId
            ),

        itens,

        endereco,

        pagamento,

        pagamentoStatus:
            pagamento === "PIX"
                ? "PENDENTE"
                : "AGUARDANDO",

        statusPagamento:
            "pending",

        pagamentoAprovado:
            false,

        subtotal,

        taxaServico,

        taxaEntrega,

        total,

        precisaTroco,

        trocoPara,

        valorTroco,

        externalReference,

        referenciaPagamento:
            externalReference,

        status:
            "AGUARDANDO_RESTAURANTE",

        suporte: {

            aberto:
                false,

            status:
                "FECHADO",

            mensagens:
                []

        },

        criadoEm,

        atualizadoEm:
            criadoEm

    };


    // ==================================================
    // PRESERVAR DADOS EXTRAS
    // ==================================================

    for (
        const [chave, valor]
        of Object.entries(pedido)
    ) {

        if (
            novoPedido[chave] === undefined
        ) {

            novoPedido[chave] =
                valor;

        }

    }


    // ==================================================
    // RECONCILIAR ASAAS
    // ==================================================

    const pagamentoAsaas =
        await encontrarPagamentoAsaasPendente(
            novoPedido.externalReference
        );


    if (pagamentoAsaas) {

        console.log(
            "========================================"
        );

        console.log(
            "🔄 RECONCILIANDO PAGAMENTO ASAAS"
        );

        console.log(
            "REFERÊNCIA:",
            novoPedido.externalReference
        );

        console.log(
            "PAGAMENTO ASAAS:",
            pagamentoAsaas.pagamentoId
        );

        console.log(
            "STATUS ASAAS:",
            pagamentoAsaas.statusAsaas
        );

        console.log(
            "STATUS FOODJET:",
            pagamentoAsaas.statusPagamento
        );


        novoPedido.pagamentoId =
            pagamentoAsaas.pagamentoId ||
            "";

        novoPedido.asaasPaymentId =
            pagamentoAsaas.pagamentoId ||
            "";

        novoPedido.externalReference =
            pagamentoAsaas.externalReference ||
            novoPedido.externalReference;

        novoPedido.referenciaPagamento =
            pagamentoAsaas.externalReference ||
            novoPedido.referenciaPagamento;

        novoPedido.statusPagamento =
            pagamentoAsaas.statusPagamento ||
            "pending";

        novoPedido.statusPagamentoAsaas =
            pagamentoAsaas.statusAsaas ||
            "";

        novoPedido.asaasEvento =
            pagamentoAsaas.evento ||
            "";

        novoPedido.asaasAtualizadoEm =
            pagamentoAsaas.atualizadoEm ||
            new Date().toISOString();

        novoPedido.pagamentoAtualizadoEm =
            pagamentoAsaas.atualizadoEm ||
            new Date().toISOString();

        novoPedido.valorPagamento =
            Number(
                pagamentoAsaas.valor
            ) || 0;


        if (
            pagamentoAsaas.statusPagamento ===
            "approved"
        ) {

            novoPedido.statusPagamento =
                "approved";

            novoPedido.pagamentoAprovado =
                true;

            novoPedido.pagamentoAprovadoEm =
                new Date().toISOString();

            novoPedido.status =
                "AGUARDANDO_RESTAURANTE";

            novoPedido.pagamentoStatus =
                "PAGO";

        }

    }


    // ==================================================
    // VALORES DAS COLUNAS POSTGRESQL
    // ==================================================

    const clienteId =
        String(
            novoPedido.clienteId
        );

    const restauranteId =
        String(
            novoPedido.restauranteId
        );

    const pagamentoStatus =
        novoPedido.pagamentoStatus ||
        null;

    const statusPagamento =
        novoPedido.statusPagamento ||
        null;

    const pagamentoAprovado =
        Boolean(
            novoPedido.pagamentoAprovado
        );

    const externalReferenceFinal =
        novoPedido.externalReference ||
        null;

    const referenciaPagamentoFinal =
        novoPedido.referenciaPagamento ||
        null;

    const statusFinal =
        novoPedido.status ||
        null;

    const suporte =
        novoPedido.suporte &&
        typeof novoPedido.suporte === "object"
            ? novoPedido.suporte
            : {
                aberto: false,
                status: "FECHADO",
                mensagens: [],
            };


    // ==================================================
    // SALVAR NO POSTGRESQL
    // ==================================================

    const resultado =
        await pool.query(
            `
            INSERT INTO pedidos (
                id,
                cliente_id,
                restaurante_id,
                itens,
                endereco,
                pagamento,
                pagamento_status,
                status_pagamento,
                pagamento_aprovado,
                subtotal,
                taxa_servico,
                taxa_entrega,
                total,
                precisa_troco,
                troco_para,
                valor_troco,
                external_reference,
                referencia_pagamento,
                status,
                suporte,
                criado_em,
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
                $8,
                $9,
                $10,
                $11,
                $12,
                $13,
                $14,
                $15,
                $16,
                $17,
                $18,
                $19,
                $20,
                $21,
                $22,
                $23
            )
            RETURNING *
            `,
            [
                id,
                clienteId,
                restauranteId,
                itens,
                endereco,
                pagamento,
                pagamentoStatus,
                statusPagamento,
                pagamentoAprovado,
                subtotal,
                taxaServico,
                taxaEntrega,
                total,
                precisaTroco,
                trocoPara,
                valorTroco,
                externalReferenceFinal,
                referenciaPagamentoFinal,
                statusFinal,
                suporte,
                criadoEm,
                criadoEm,
                novoPedido,
            ]
        );


    const pedidoSalvo =
        montarPedido(
            resultado.rows[0]
        );


    // ==================================================
    // MARCAR PAGAMENTO COMO CONCILIADO
    // ==================================================

    if (pagamentoAsaas) {

        await marcarPagamentoAsaasConciliado(
            pagamentoAsaas,
            pedidoSalvo
        );

    }


    // ==================================================
    // LOG
    // ==================================================

    console.log(
        "========================================"
    );

    console.log(
        "✅ PEDIDO CRIADO NO POSTGRESQL"
    );

    console.log(
        "ID:",
        pedidoSalvo.id
    );

    console.log(
        "CLIENTE:",
        pedidoSalvo.clienteId
    );

    console.log(
        "RESTAURANTE:",
        pedidoSalvo.restauranteId
    );

    console.log(
        "ITENS:",
        Array.isArray(
            pedidoSalvo.itens
        )
            ? pedidoSalvo.itens.length
            : 0
    );

    console.log(
        "PAGAMENTO:",
        pedidoSalvo.pagamento
    );

    console.log(
        "PAGAMENTO ID:",
        pedidoSalvo.pagamentoId ||
        "NÃO DEFINIDO"
    );

    console.log(
        "STATUS PAGAMENTO:",
        pedidoSalvo.statusPagamento
    );

    console.log(
        "PAGAMENTO APROVADO:",
        pedidoSalvo.pagamentoAprovado
    );

    console.log(
        "SUBTOTAL:",
        pedidoSalvo.subtotal
    );

    console.log(
        "TAXA SERVIÇO:",
        pedidoSalvo.taxaServico
    );

    console.log(
        "TAXA ENTREGA:",
        pedidoSalvo.taxaEntrega
    );

    console.log(
        "TOTAL:",
        pedidoSalvo.total
    );

    console.log(
        "STATUS PEDIDO:",
        pedidoSalvo.status
    );

    console.log(
        "REFERÊNCIA:",
        pedidoSalvo.externalReference
    );

    console.log(
        "========================================"
    );

    return pedidoSalvo;
}


// ======================================================
// LISTAR TODOS OS PEDIDOS
// ======================================================

async function listar() {

    const resultado =
        await pool.query(
            `
            SELECT
                *
            FROM pedidos
            ORDER BY id ASC
            `
        );

    return resultado.rows.map(
        montarPedido
    );
}


// ======================================================
// BUSCAR PEDIDO PELO ID
// ======================================================

async function buscarPorId(id) {

    if (
        id === undefined ||
        id === null ||
        String(id).trim() === ""
    ) {

        return null;

    }

    const numeroId =
        Number(id);

    if (
        !Number.isSafeInteger(
            numeroId
        )
    ) {

        return null;

    }

    const resultado =
        await pool.query(
            `
            SELECT
                *
            FROM pedidos
            WHERE id = $1
            LIMIT 1
            `,
            [
                numeroId
            ]
        );

    if (
        resultado.rows.length === 0
    ) {

        return null;

    }

    return montarPedido(
        resultado.rows[0]
    );
}


// ======================================================
// ATUALIZAR PEDIDO
// ======================================================

async function atualizarDadosPedido(
    id,
    alteracoes
) {

    const pedido =
        await buscarPorId(id);

    if (!pedido) {

        return null;

    }

    const pedidoAtualizado = {

        ...pedido,

        ...alteracoes,

        id:
            pedido.id,

        atualizadoEm:
            new Date().toISOString(),

    };


    // ==================================================
    // NORMALIZAR CAMPOS
    // ==================================================

    const clienteId =
        pedidoAtualizado.clienteId !== undefined &&
        pedidoAtualizado.clienteId !== null
            ? String(
                pedidoAtualizado.clienteId
            )
            : null;


    const restauranteId =
        pedidoAtualizado.restauranteId !== undefined &&
        pedidoAtualizado.restauranteId !== null
            ? String(
                pedidoAtualizado.restauranteId
            )
            : null;


    const itens =
        Array.isArray(
            pedidoAtualizado.itens
        )
            ? pedidoAtualizado.itens
            : [];


    const endereco =
        pedidoAtualizado.endereco &&
        typeof pedidoAtualizado.endereco === "object"
            ? pedidoAtualizado.endereco
            : {};


    const pagamento =
        pedidoAtualizado.pagamento ||
        null;


    const pagamentoStatus =
        pedidoAtualizado.pagamentoStatus ||
        null;


    const statusPagamento =
        pedidoAtualizado.statusPagamento ||
        null;


    const pagamentoAprovado =
        pedidoAtualizado.pagamentoAprovado !== undefined
            ? Boolean(
                pedidoAtualizado.pagamentoAprovado
            )
            : false;


    const subtotal =
        Number(
            pedidoAtualizado.subtotal
        ) || 0;


    const taxaServico =
        Number(
            pedidoAtualizado.taxaServico
        ) || 0;


    const taxaEntrega =
        Number(
            pedidoAtualizado.taxaEntrega
        ) || 0;


    const total =
        Number(
            pedidoAtualizado.total
        ) || 0;


    const precisaTroco =
        pagamento === "DINHEIRO"
            ? Boolean(
                pedidoAtualizado.precisaTroco
            )
            : false;


    const trocoPara =
        precisaTroco
            ? Number(
                pedidoAtualizado.trocoPara
            ) || 0
            : null;


    const valorTroco =
        precisaTroco
            ? Math.max(
                0,
                trocoPara - total
            )
            : 0;


    const externalReference =
        pedidoAtualizado.externalReference ||
        null;


    const referenciaPagamento =
        pedidoAtualizado.referenciaPagamento ||
        null;


    const status =
        pedidoAtualizado.status ||
        null;


    const suporte =
        pedidoAtualizado.suporte &&
        typeof pedidoAtualizado.suporte === "object"
            ? pedidoAtualizado.suporte
            : {
                aberto: false,
                status: "FECHADO",
                mensagens: [],
            };


    // ==================================================
    // ATUALIZAR POSTGRESQL
    // ==================================================

    const resultado =
        await pool.query(
            `
            UPDATE pedidos
            SET
                cliente_id = $1,
                restaurante_id = $2,
                itens = $3,
                endereco = $4,
                pagamento = $5,
                pagamento_status = $6,
                status_pagamento = $7,
                pagamento_aprovado = $8,
                subtotal = $9,
                taxa_servico = $10,
                taxa_entrega = $11,
                total = $12,
                precisa_troco = $13,
                troco_para = $14,
                valor_troco = $15,
                external_reference = $16,
                referencia_pagamento = $17,
                status = $18,
                suporte = $19,
                atualizado_em = $20,
                dados = $21
            WHERE id = $22
            RETURNING *
            `,
            [
                clienteId,
                restauranteId,
                itens,
                endereco,
                pagamento,
                pagamentoStatus,
                statusPagamento,
                pagamentoAprovado,
                subtotal,
                taxaServico,
                taxaEntrega,
                total,
                precisaTroco,
                trocoPara,
                valorTroco,
                externalReference,
                referenciaPagamento,
                status,
                suporte,
                pedidoAtualizado.atualizadoEm,
                pedidoAtualizado,
                Number(id),
            ]
        );


    if (
        resultado.rows.length === 0
    ) {

        return null;

    }


    return montarPedido(
        resultado.rows[0]
    );
}


// ======================================================
// ATUALIZAR STATUS
// ======================================================

async function atualizarStatus(
    id,
    novoStatus
) {

    const pedido =
        await buscarPorId(id);

    if (!pedido) {

        return null;

    }

    return atualizarDadosPedido(
        id,
        {
            status:
                novoStatus,
        }
    );
}


// ======================================================
// ACEITAR PEDIDO PELO RESTAURANTE
// ======================================================

async function aceitarPedidoRestaurante(
    id
) {

    const pedido =
        await buscarPorId(id);

    if (!pedido) {

        return null;

    }

    if (
        pedido.status !==
        "AGUARDANDO_RESTAURANTE"
    ) {

        return null;

    }

    return atualizarDadosPedido(
        id,
        {
            status:
                "ACEITO",

            aceitoRestauranteEm:
                new Date().toISOString(),
        }
    );
}


// ======================================================
// RECUSAR PEDIDO PELO RESTAURANTE
// ======================================================

async function recusarPedidoRestaurante(
    id,
    motivo
) {

    const pedido =
        await buscarPorId(id);

    if (!pedido) {

        return null;

    }

    if (
        pedido.status !==
        "AGUARDANDO_RESTAURANTE"
    ) {

        return null;

    }

    return atualizarDadosPedido(
        id,
        {
            status:
                "RECUSADO",

            motivoRecusa:
                motivo ||
                "Pedido recusado pelo restaurante",

            recusadoEm:
                new Date().toISOString(),
        }
    );
}


// ======================================================
// ENTREGADOR ACEITA PEDIDO
// ======================================================

async function aceitarEntrega(
    id,
    entregadorId
) {

    const pedido =
        await buscarPorId(id);

    if (!pedido) {

        return null;

    }

    if (
        pedido.status !==
        "PRONTO"
    ) {

        return null;

    }

    return atualizarDadosPedido(
        id,
        {
            entregadorId:
                String(
                    entregadorId
                ),

            status:
                "EM_ENTREGA",

            aceitoEm:
                new Date().toISOString(),
        }
    );
}


// ======================================================
// PEDIDOS DO RESTAURANTE
// ======================================================

async function listarPorRestaurante(
    restauranteId
) {

    if (
        restauranteId === undefined ||
        restauranteId === null ||
        String(restauranteId).trim() === ""
    ) {

        return [];

    }

    await limparPedidosAntigos();


    const resultado =
        await pool.query(
            `
            SELECT
                *
            FROM pedidos
            WHERE restaurante_id = $1
            ORDER BY id DESC
            `,
            [
                String(
                    restauranteId
                )
            ]
        );

    return resultado.rows.map(
        montarPedido
    );
}


// ======================================================
// PEDIDOS DO CLIENTE
// ======================================================

async function listarPorCliente(
    clienteId
) {

    if (
        clienteId === undefined ||
        clienteId === null ||
        String(clienteId).trim() === ""
    ) {

        return [];

    }

    const resultado =
        await pool.query(
            `
            SELECT
                *
            FROM pedidos
            WHERE cliente_id = $1
            ORDER BY id DESC
            `,
            [
                String(
                    clienteId
                )
            ]
        );

    return resultado.rows.map(
        montarPedido
    );
}


// ======================================================
// PEDIDOS DISPONÍVEIS PARA ENTREGA
// ======================================================

async function listarDisponiveisEntrega() {

    const resultado =
        await pool.query(
            `
            SELECT
                *
            FROM pedidos
            WHERE status = 'PRONTO'
            ORDER BY id ASC
            `
        );

    return resultado.rows.map(
        montarPedido
    );
}


// ======================================================
// FINALIZAR ENTREGA
// ======================================================

async function finalizarEntrega(
    id
) {

    const pedido =
        await buscarPorId(id);

    if (!pedido) {

        return null;

    }

    if (
        pedido.status !==
        "EM_ENTREGA"
    ) {

        return null;

    }

    return atualizarDadosPedido(
        id,
        {
            status:
                "ENTREGUE",

            entregueEm:
                new Date().toISOString(),
        }
    );
}


// ======================================================
// ABRIR SUPORTE
// ======================================================

async function abrirSuporte(
    pedidoId,
    autorId,
    autorTipo,
    mensagem,
    motivo
) {

    const pedido =
        await buscarPorId(
            pedidoId
        );

    if (!pedido) {

        return null;

    }

    const suporteAtual =
        pedido.suporte || {

            aberto:
                false,

            status:
                "FECHADO",

            mensagens:
                []

        };


    if (
        !Array.isArray(
            suporteAtual.mensagens
        )
    ) {

        suporteAtual.mensagens = [];

    }


    const momento =
        new Date().toISOString();


    const mensagemSuporte = {

        id:
            Date.now(),

        autorId,

        autorTipo,

        mensagem,

        motivo:
            motivo ||
            "Problema com pedido",

        criadoEm:
            momento,

    };


    suporteAtual.mensagens.push(
        mensagemSuporte
    );


    suporteAtual.aberto =
        true;

    suporteAtual.status =
        "AGUARDANDO_ADMIN";

    suporteAtual.abertoEm =
        momento;


    return atualizarDadosPedido(
        pedidoId,
        {
            suporte:
                suporteAtual
        }
    );
}


// ======================================================
// LISTAR SUPORTES
// ======================================================

async function listarSuportes() {

    const resultado =
        await pool.query(
            `
            SELECT
                *
            FROM pedidos
            WHERE
                COALESCE(
                    (
                        suporte->>'aberto'
                    )::boolean,
                    false
                ) = true
            ORDER BY id DESC
            `
        );

    return resultado.rows.map(
        montarPedido
    );
}


// ======================================================
// RESPONDER SUPORTE
// ======================================================

async function responderSuporte(
    pedidoId,
    adminId,
    mensagem
) {

    const pedido =
        await buscarPorId(
            pedidoId
        );

    if (!pedido) {

        return null;

    }

    if (!pedido.suporte) {

        return null;

    }


    const suporte = {

        ...pedido.suporte,

    };


    if (
        !Array.isArray(
            suporte.mensagens
        )
    ) {

        suporte.mensagens = [];

    }


    const momento =
        new Date().toISOString();


    suporte.mensagens.push({

        id:
            Date.now(),

        autorId:
            adminId,

        autorTipo:
            "ADMIN",

        mensagem,

        criadoEm:
            momento,

    });


    suporte.status =
        "RESPONDIDO_ADMIN";

    suporte.ultimaRespostaEm =
        momento;


    return atualizarDadosPedido(
        pedidoId,
        {
            suporte
        }
    );
}


// ======================================================
// FECHAR SUPORTE
// ======================================================

async function fecharSuporte(
    pedidoId
) {

    const pedido =
        await buscarPorId(
            pedidoId
        );

    if (!pedido) {

        return null;

    }

    if (!pedido.suporte) {

        return null;

    }


    const suporte = {

        ...pedido.suporte,

        aberto:
            false,

        status:
            "FECHADO",

        fechadoEm:
            new Date().toISOString(),

    };


    return atualizarDadosPedido(
        pedidoId,
        {
            suporte
        }
    );
}


// ======================================================
// MONTAR PEDIDO
// ======================================================

function montarPedido(row) {

    if (!row) {

        return null;

    }


    let dados =
        row.dados;


    if (
        typeof dados === "string"
    ) {

        try {

            dados =
                JSON.parse(dados);

        } catch {

            dados = {};

        }

    }


    if (
        !dados ||
        typeof dados !== "object"
    ) {

        dados = {};

    }


    // ==================================================
    // COLUNAS POSTGRESQL TÊM PRIORIDADE
    // ==================================================

    const pedido = {

        ...dados,

        id:
            row.id !== undefined &&
            row.id !== null
                ? Number(
                    row.id
                )
                : dados.id,

        clienteId:
            row.cliente_id ??
            dados.clienteId,

        restauranteId:
            row.restaurante_id ??
            dados.restauranteId,

        itens:
            row.itens ??
            dados.itens ??
            [],

        endereco:
            row.endereco ??
            dados.endereco ??
            {},

        pagamento:
            row.pagamento ??
            dados.pagamento,

        pagamentoStatus:
            row.pagamento_status ??
            dados.pagamentoStatus,

        statusPagamento:
            row.status_pagamento ??
            dados.statusPagamento,

        pagamentoAprovado:
            row.pagamento_aprovado ??
            dados.pagamentoAprovado ??
            false,

        subtotal:
            row.subtotal !== null &&
            row.subtotal !== undefined
                ? Number(
                    row.subtotal
                )
                : Number(
                    dados.subtotal
                ) || 0,

        taxaServico:
            row.taxa_servico !== null &&
            row.taxa_servico !== undefined
                ? Number(
                    row.taxa_servico
                )
                : Number(
                    dados.taxaServico
                ) || 0,

        taxaEntrega:
            row.taxa_entrega !== null &&
            row.taxa_entrega !== undefined
                ? Number(
                    row.taxa_entrega
                )
                : Number(
                    dados.taxaEntrega
                ) || 0,

        total:
            row.total !== null &&
            row.total !== undefined
                ? Number(
                    row.total
                )
                : Number(
                    dados.total
                ) || 0,

        precisaTroco:
            row.precisa_troco ??
            dados.precisaTroco ??
            false,

        trocoPara:
            row.troco_para !== null &&
            row.troco_para !== undefined
                ? Number(
                    row.troco_para
                )
                : (
                    dados.trocoPara !== undefined &&
                    dados.trocoPara !== null
                        ? Number(
                            dados.trocoPara
                        )
                        : null
                ),

        valorTroco:
            row.valor_troco !== null &&
            row.valor_troco !== undefined
                ? Number(
                    row.valor_troco
                )
                : Number(
                    dados.valorTroco
                ) || 0,

        externalReference:
            row.external_reference ??
            dados.externalReference,

        referenciaPagamento:
            row.referencia_pagamento ??
            dados.referenciaPagamento,

        status:
            row.status ??
            dados.status,

        suporte:
            row.suporte ??
            dados.suporte ??
            {
                aberto: false,
                status: "FECHADO",
                mensagens: [],
            },

        criadoEm:
            row.criado_em
                ? new Date(
                    row.criado_em
                ).toISOString()
                : dados.criadoEm,

        atualizadoEm:
            row.atualizado_em
                ? new Date(
                    row.atualizado_em
                ).toISOString()
                : dados.atualizadoEm,

    };


    return pedido;
}


// ======================================================
// EXPORTAR
// ======================================================

module.exports = {

    prepararBanco,

    criar,

    listar,

    buscarPorId,

    atualizarDadosPedido,

    atualizarStatus,

    aceitarPedidoRestaurante,

    recusarPedidoRestaurante,

    aceitarEntrega,

    listarPorRestaurante,

    listarPorCliente,

    listarDisponiveisEntrega,

    finalizarEntrega,

    abrirSuporte,

    listarSuportes,

    responderSuporte,

    fecharSuporte,

    limparPedidosAntigos,

};

