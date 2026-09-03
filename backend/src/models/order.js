
const { pool } = require("../config/database");

// ======================================================
// CONFIGURAÇÃO
// ======================================================

// Pedidos finalizados/cancelados serão apagados após
// este período.
//
// 24 horas = 1 dia
const HORAS_HISTORICO_PEDIDOS = 24;

// Intervalo para executar a limpeza automática.
//
// 1 hora
const INTERVALO_LIMPEZA_MS =
    60 * 60 * 1000;


// ======================================================
// STATUS QUE PODEM SER APAGADOS
// ======================================================
//
// Somente pedidos que já terminaram ou foram cancelados.
//
// Pedidos em andamento NÃO serão apagados.
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
//
// IMPORTANTE:
//
// Esta função APAGA somente os pedidos da tabela:
//
// pedidos
//
// Ela NÃO apaga:
//
// pagamentos_asaas
//
// Portanto, o histórico de pagamentos do Asaas permanece
// preservado.
//
// Somente pedidos:
//
// - finalizados/cancelados
// - com mais de 24 horas
// - sem suporte aberto
//
// serão removidos.
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
                            dados->>'status',
                            ''
                        )
                    ) = ANY($1::text[])

                    AND
                    dados->>'criadoEm' IS NOT NULL

                    AND
                    dados->>'criadoEm'
                        ~ '^\\d{4}-\\d{2}-\\d{2}T'

                    AND
                    (
                        dados->>'criadoEm'
                    )::timestamptz
                    <
                    NOW() -
                    ($2 * INTERVAL '1 hour')

                    AND
                    COALESCE(
                        (
                            dados->'suporte'
                            ->>'aberto'
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
//
// Executa:
//
// 1. Uma vez quando o backend inicia
// 2. Depois a cada 1 hora
//
// Isso significa que um pedido que completou 24 horas
// será removido na próxima execução da limpeza.
//
// Exemplo:
//
// Pedido criado:
// 10:00
//
// Completa 24h:
// dia seguinte às 10:00
//
// Próxima verificação:
// pode ser 10:05, 10:30, 11:00 etc.
//
// Portanto, a exclusão acontece automaticamente após
// completar 24 horas, com tolerância de até aproximadamente
// 1 hora dependendo do momento da verificação.
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
//
// O PostgreSQL possui uma sequence na coluna pedidos.id.
//
// Isso evita gerar ID manualmente no Node e mantém a
// sequência existente após a migração.
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

        conciliado: true,

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

    const id =
        await gerarIdPedido();

    const itens =
        Array.isArray(pedido.itens)
            ? pedido.itens
            : [];

    const subtotal =
        Number(
            pedido.subtotal
        ) || 0;

    const taxaServico =
        Number(
            pedido.taxaServico
        ) || 0;

    const total =
        Number(
            pedido.total
        ) ||
        subtotal +
        taxaServico;

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

        endereco:
            pedido.endereco || {},

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

            aberto: false,

            status: "FECHADO",

            mensagens: []

        },

        criadoEm:
            pedido.criadoEm ||
            new Date().toISOString()

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
    // NÃO SALVAR TAXA DE ENTREGA
    // ==================================================

    delete novoPedido.taxaEntrega;


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

            console.log(
                "========================================"
            );

            console.log(
                "✅ PIX JÁ ESTAVA PAGO"
            );

            console.log(
                "💳 STATUS:",
                "APPROVED"
            );

            console.log(
                "📦 PEDIDO:",
                novoPedido.id
            );

            console.log(
                "🍽️ STATUS:",
                "AGUARDANDO_RESTAURANTE"
            );

            console.log(
                "========================================"
            );

        } else {

            novoPedido.pagamentoAprovado =
                false;

            console.log(
                "⏳ PAGAMENTO ASAAS AINDA PENDENTE"
            );

        }

    }


    // ==================================================
    // SALVAR NO POSTGRESQL
    // ==================================================

    const resultado =
        await pool.query(
            `
            INSERT INTO pedidos (
                id,
                dados
            )
            VALUES (
                $1,
                $2
            )
            RETURNING
                id,
                dados
            `,
            [
                id,
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
                id,
                dados
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
                id,
                dados
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
// ATUALIZAR PEDIDO NO JSONB
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

    const resultado =
        await pool.query(
            `
            UPDATE pedidos
            SET dados = $1
            WHERE id = $2
            RETURNING
                id,
                dados
            `,
            [
                pedidoAtualizado,
                Number(id)
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
//
// Antes de buscar os pedidos, executamos uma limpeza.
//
// Assim, mesmo que o processo automático ainda não tenha
// rodado naquele momento, pedidos com mais de 24 horas e
// status final não serão devolvidos ao aplicativo.
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


    // ==================================================
    // LIMPEZA AUTOMÁTICA
    // ==================================================

    await limparPedidosAntigos();


    // ==================================================
    // BUSCAR PEDIDOS
    // ==================================================

    const resultado =
        await pool.query(
            `
            SELECT
                id,
                dados
            FROM pedidos
            WHERE dados->>'restauranteId' = $1
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
                id,
                dados
            FROM pedidos
            WHERE dados->>'clienteId' = $1
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
                id,
                dados
            FROM pedidos
            WHERE dados->>'status' = 'PRONTO'
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

            aberto: false,

            status:
                "FECHADO",

            mensagens: []

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
                id,
                dados
            FROM pedidos
            WHERE
                COALESCE(
                    (dados->'suporte'->>'aberto')::boolean,
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

    return {

        ...dados,

        id:
            row.id !== undefined &&
            row.id !== null
                ? Number(
                    row.id
                )
                : dados.id,

    };

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

    // --------------------------------------------------
    // LIMPEZA AUTOMÁTICA
    // --------------------------------------------------

    limparPedidosAntigos,

};

