const { pool } = require("../config/database");

// =====================================================
// GARANTIR TABELA DE REPASSES
// =====================================================

async function garantirEstrutura() {

    await pool.query(`
        CREATE TABLE IF NOT EXISTS repasses (
            id TEXT PRIMARY KEY,

            restaurante_id TEXT NOT NULL,

            valor NUMERIC(12,2) NOT NULL DEFAULT 0,

            metodo TEXT DEFAULT 'PIX',

            chave TEXT,

            status TEXT DEFAULT 'PENDENTE',

            automatico BOOLEAN DEFAULT FALSE,

            aprovado_automaticamente BOOLEAN DEFAULT FALSE,

            data TIMESTAMPTZ DEFAULT NOW(),

            atualizado_em TIMESTAMPTZ DEFAULT NOW(),

            mensagem TEXT,

            dados JSONB DEFAULT '{}'::jsonb
        )
    `);

    await pool.query(`
        CREATE INDEX IF NOT EXISTS idx_repasses_restaurante
        ON repasses(restaurante_id)
    `);

    await pool.query(`
        CREATE INDEX IF NOT EXISTS idx_repasses_status
        ON repasses(status)
    `);
}


// =====================================================
// MONTAR REPASSE
// =====================================================

function montarRepasse(row) {

    if (!row) {
        return null;
    }

    let dados = {};

    if (row.dados) {

        try {

            dados =
                typeof row.dados === "string"
                    ? JSON.parse(row.dados)
                    : row.dados;

        } catch {

            dados = {};

        }
    }

    return {
        ...dados,

        id: row.id,

        restauranteId:
            row.restaurante_id !== null &&
            row.restaurante_id !== undefined
                ? String(row.restaurante_id)
                : dados.restauranteId,

        valor:
            Number(row.valor || 0),

        metodo:
            row.metodo || dados.metodo || "PIX",

        chave:
            row.chave || dados.chave,

        status:
            row.status || dados.status || "PENDENTE",

        automatico:
            Boolean(
                row.automatico ??
                dados.automatico ??
                false
            ),

        aprovadoAutomaticamente:
            Boolean(
                row.aprovado_automaticamente ??
                dados.aprovadoAutomaticamente ??
                false
            ),

        data:
            row.data
                ? new Date(row.data).toISOString()
                : dados.data,

        atualizadoEm:
            row.atualizado_em
                ? new Date(row.atualizado_em).toISOString()
                : dados.atualizadoEm,

        mensagem:
            row.mensagem ??
            dados.mensagem
    };
}


// =====================================================
// BUSCAR REPASSES DO RESTAURANTE
// =====================================================

async function buscarRepasses(restauranteId) {

    const resultado = await pool.query(
        `
        SELECT
            id,
            restaurante_id,
            valor,
            metodo,
            chave,
            status,
            automatico,
            aprovado_automaticamente,
            data,
            atualizado_em,
            mensagem,
            dados
        FROM repasses
        WHERE restaurante_id = $1
        ORDER BY data DESC
        `,
        [String(restauranteId)]
    );

    return resultado.rows.map(montarRepasse);
}


// =====================================================
// CALCULAR SALDO DO RESTAURANTE
// =====================================================

async function calcularSaldo(restauranteId) {

    const id = String(restauranteId);

    // -------------------------------------------------
    // PEDIDOS CONCLUÍDOS
    // -------------------------------------------------

    const pedidosResult = await pool.query(
        `
        SELECT
            id,
            total,
            status,
            restaurante_id,
            dados
        FROM pedidos
        WHERE restaurante_id = $1
        `,
        [id]
    );

    const pedidos =
        pedidosResult.rows.map(row => {

            let dados = {};

            if (row.dados) {

                try {

                    dados =
                        typeof row.dados === "string"
                            ? JSON.parse(row.dados)
                            : row.dados;

                } catch {

                    dados = {};

                }
            }

            return {
                ...dados,

                id: row.id,

                restauranteId:
                    row.restaurante_id,

                total:
                    Number(row.total || 0),

                status:
                    row.status || dados.status
            };
        });

    const concluidos =
        pedidos.filter(
            pedido =>
                pedido.status === "CONCLUIDO" ||
                pedido.status === "FINALIZADO"
        );


    // -------------------------------------------------
    // FATURAMENTO
    // -------------------------------------------------

    const faturamento =
        concluidos.reduce(
            (total, pedido) =>
                total +
                Number(pedido.total || 0),
            0
        );


    // -------------------------------------------------
    // REPASSES
    // -------------------------------------------------

    const movimentacoes =
        await buscarRepasses(id);


    const pagos =
        movimentacoes
            .filter(
                repasse =>
                    repasse.status === "PAGO" ||
                    repasse.status === "PROCESSANDO" ||
                    repasse.status === "PENDENTE"
            )
            .reduce(
                (total, repasse) =>
                    total +
                    Number(repasse.valor || 0),
                0
            );


    // -------------------------------------------------
    // SALDO
    // -------------------------------------------------

    const saldoDisponivel =
        faturamento - pagos;


    return {

        faturamento,

        saldoDisponivel,

        pedidosConcluidos:
            concluidos.length
    };
}


// =====================================================
// RESUMO FINANCEIRO
// GET /api/finance/:restauranteId
// =====================================================

exports.resumo = async (req, res) => {

    try {

        const {
            restauranteId
        } = req.params;


        await garantirEstrutura();


        // =================================================
        // PEDIDOS
        // =================================================

        const pedidosResult =
            await pool.query(
                `
                SELECT
                    id,
                    total,
                    status,
                    restaurante_id,
                    dados
                FROM pedidos
                WHERE restaurante_id = $1
                `,
                [String(restauranteId)]
            );


        const pedidos =
            pedidosResult.rows.map(row => {

                let dados = {};

                if (row.dados) {

                    try {

                        dados =
                            typeof row.dados === "string"
                                ? JSON.parse(row.dados)
                                : row.dados;

                    } catch {

                        dados = {};

                    }
                }

                return {

                    ...dados,

                    id: row.id,

                    restauranteId:
                        row.restaurante_id,

                    total:
                        Number(row.total || 0),

                    status:
                        row.status ||
                        dados.status
                };
            });


        // =================================================
        // CONCLUÍDOS
        // =================================================

        const concluidos =
            pedidos.filter(
                pedido =>
                    pedido.status === "CONCLUIDO" ||
                    pedido.status === "FINALIZADO"
            );


        // =================================================
        // FATURAMENTO
        // =================================================

        const faturamentoTotal =
            concluidos.reduce(
                (total, pedido) =>
                    total +
                    Number(pedido.total || 0),
                0
            );


        // =================================================
        // REPASSES
        // =================================================

        const repasses =
            await buscarRepasses(
                restauranteId
            );


        // =================================================
        // REPASSES PAGOS
        // =================================================

        const repassesPagos =
            repasses.filter(
                repasse =>
                    repasse.status === "PAGO"
            );


        const totalRepassado =
            repassesPagos.reduce(
                (total, repasse) =>
                    total +
                    Number(repasse.valor || 0),
                0
            );


        // =================================================
        // SAQUES PROCESSANDO
        // =================================================

        const saquesProcessando =
            repasses.filter(
                repasse =>
                    repasse.status === "PROCESSANDO"
            );


        const totalProcessando =
            saquesProcessando.reduce(
                (total, repasse) =>
                    total +
                    Number(repasse.valor || 0),
                0
            );


        // =================================================
        // SAQUES PENDENTES
        // =================================================

        const saquesPendentes =
            repasses.filter(
                repasse =>
                    repasse.status === "PENDENTE"
            );


        const totalPendente =
            saquesPendentes.reduce(
                (total, repasse) =>
                    total +
                    Number(repasse.valor || 0),
                0
            );


        // =================================================
        // SAQUES COM ERRO
        // =================================================

        const saquesComErro =
            repasses.filter(
                repasse =>
                    repasse.status === "ERRO"
            );


        const totalErro =
            saquesComErro.reduce(
                (total, repasse) =>
                    total +
                    Number(repasse.valor || 0),
                0
            );


        // =================================================
        // SALDO DISPONÍVEL
        // =================================================

        const saldoDisponivel =
            faturamentoTotal -
            totalRepassado -
            totalProcessando -
            totalPendente;


        // =================================================
        // TICKET MÉDIO
        // =================================================

        const pedidosConcluidos =
            concluidos.length;


        const ticketMedio =
            pedidosConcluidos > 0
                ? faturamentoTotal /
                  pedidosConcluidos
                : 0;


        // =================================================
        // HISTÓRICO
        // =================================================

        const historico =
            repasses;


        // =================================================
        // RESPOSTA
        // =================================================

        return res.json({

            sucesso: true,

            faturamentoTotal:
                Number(
                    faturamentoTotal.toFixed(2)
                ),

            totalRepassado:
                Number(
                    totalRepassado.toFixed(2)
                ),

            totalProcessando:
                Number(
                    totalProcessando.toFixed(2)
                ),

            totalPendente:
                Number(
                    totalPendente.toFixed(2)
                ),

            totalErro:
                Number(
                    totalErro.toFixed(2)
                ),

            saldoDisponivel:
                Number(
                    saldoDisponivel.toFixed(2)
                ),

            pedidosConcluidos,

            ticketMedio:
                Number(
                    ticketMedio.toFixed(2)
                ),

            historico

        });

    } catch (erro) {

        console.error(
            "ERRO FINANCEIRO:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao carregar dados financeiros",

            detalhe:
                erro.message

        });
    }
};


// =====================================================
// SOLICITAR SAQUE AUTOMÁTICO
// POST /api/finance/:restauranteId/saque
// =====================================================

exports.solicitarSaque = async (req, res) => {

    try {

        const {
            restauranteId
        } = req.params;


        const {
            valor,
            metodo,
            chave
        } = req.body;


        await garantirEstrutura();


        // =================================================
        // VALIDAR VALOR
        // =================================================

        const valorSaque =
            Number(valor);


        if (
            !Number.isFinite(valorSaque) ||
            valorSaque <= 0
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "Informe um valor válido."

            });
        }


        // =================================================
        // VALOR MÍNIMO
        // =================================================

        if (valorSaque < 5) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "O valor mínimo para saque é R$ 5,00."

            });
        }


        // =================================================
        // VALIDAR MÉTODO
        // =================================================

        const metodoPagamento =
            metodo || "PIX";


        if (
            metodoPagamento !== "PIX"
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "No momento o saque automático está disponível somente via PIX."

            });
        }


        // =================================================
        // VALIDAR CHAVE PIX
        // =================================================

        if (
            !chave ||
            chave.toString().trim() === ""
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "Informe sua chave PIX."

            });
        }


        // =================================================
        // CALCULAR SALDO
        // =================================================

        const financeiro =
            await calcularSaldo(
                restauranteId
            );


        const saldoDisponivel =
            financeiro.saldoDisponivel;


        // =================================================
        // VERIFICAR SALDO
        // =================================================

        if (
            valorSaque >
            saldoDisponivel
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "Saldo insuficiente.",

                saldoDisponivel:
                    Number(
                        saldoDisponivel.toFixed(2)
                    )

            });
        }


        // =================================================
        // CRIAR SAQUE
        // =================================================

        const agora =
            new Date();


        const id =
            `saque_${Date.now()}`;


        const repasse = {

            id,

            restauranteId:
                String(restauranteId),

            valor:
                Number(
                    valorSaque.toFixed(2)
                ),

            metodo:
                "PIX",

            chave:
                chave.toString().trim(),

            status:
                "PROCESSANDO",

            automatico:
                true,

            aprovadoAutomaticamente:
                true,

            data:
                agora.toISOString(),

            atualizadoEm:
                agora.toISOString(),

            mensagem:
                "Saque enviado para processamento automático."

        };


        // =================================================
        // SALVAR POSTGRESQL
        // =================================================

        await pool.query(
            `
            INSERT INTO repasses (
                id,
                restaurante_id,
                valor,
                metodo,
                chave,
                status,
                automatico,
                aprovado_automaticamente,
                data,
                atualizado_em,
                mensagem,
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
                $12::jsonb
            )
            `,
            [
                repasse.id,
                repasse.restauranteId,
                repasse.valor,
                repasse.metodo,
                repasse.chave,
                repasse.status,
                repasse.automatico,
                repasse.aprovadoAutomaticamente,
                repasse.data,
                repasse.atualizadoEm,
                repasse.mensagem,
                JSON.stringify(repasse)
            ]
        );


        console.log(
            "💰 SAQUE AUTOMÁTICO SOLICITADO"
        );

        console.log(
            "🏪 Restaurante:",
            restauranteId
        );

        console.log(
            "💵 Valor:",
            valorSaque
        );

        console.log(
            "💳 PIX:",
            chave
        );

        console.log(
            "⚡ Status: PROCESSANDO"
        );


        // =================================================
        // RESPOSTA
        // =================================================

        return res.status(201).json({

            sucesso: true,

            mensagem:
                "Saque solicitado com sucesso e enviado para processamento automático.",

            repasse,

            saldoAnterior:
                Number(
                    saldoDisponivel.toFixed(2)
                ),

            saldoRestante:
                Number(
                    (
                        saldoDisponivel -
                        valorSaque
                    ).toFixed(2)
                )

        });

    } catch (erro) {

        console.error(
            "ERRO AO SOLICITAR SAQUE AUTOMÁTICO:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao solicitar saque.",

            detalhe:
                erro.message

        });
    }
};


// =====================================================
// MARCAR SAQUE COMO PAGO
// POST /api/finance/saque/:saqueId/pago
// =====================================================

exports.marcarComoPago = async (req, res) => {

    try {

        const {
            saqueId
        } = req.params;


        await garantirEstrutura();


        const resultado =
            await pool.query(
                `
                SELECT
                    id,
                    restaurante_id,
                    valor,
                    metodo,
                    chave,
                    status,
                    automatico,
                    aprovado_automaticamente,
                    data,
                    atualizado_em,
                    mensagem,
                    dados
                FROM repasses
                WHERE id = $1
                LIMIT 1
                `,
                [String(saqueId)]
            );


        if (
            resultado.rows.length === 0
        ) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Saque não encontrado."

            });
        }


        const repasse =
            montarRepasse(
                resultado.rows[0]
            );


        if (
            repasse.status === "PAGO"
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "Este saque já foi pago."

            });
        }


        const atualizadoEm =
            new Date();


        const mensagem =
            "Pagamento realizado com sucesso.";


        const atualizado =
            await pool.query(
                `
                UPDATE repasses

                SET
                    status = 'PAGO',
                    atualizado_em = $1,
                    mensagem = $2,
                    dados =
                        COALESCE(dados, '{}'::jsonb)
                        ||
                        jsonb_build_object(
                            'status',
                            'PAGO',
                            'atualizadoEm',
                            $3::text,
                            'mensagem',
                            $4::text
                        )

                WHERE id = $5

                RETURNING
                    id,
                    restaurante_id,
                    valor,
                    metodo,
                    chave,
                    status,
                    automatico,
                    aprovado_automaticamente,
                    data,
                    atualizado_em,
                    mensagem,
                    dados
                `,
                [
                    atualizadoEm,
                    mensagem,
                    atualizadoEm.toISOString(),
                    mensagem,
                    String(saqueId)
                ]
            );


        const novoRepasse =
            montarRepasse(
                atualizado.rows[0]
            );


        return res.json({

            sucesso: true,

            mensagem:
                "Saque marcado como pago.",

            repasse:
                novoRepasse

        });

    } catch (erro) {

        console.error(
            "ERRO AO FINALIZAR SAQUE:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao finalizar saque.",

            detalhe:
                erro.message

        });
    }
};


// =====================================================
// MARCAR SAQUE COMO ERRO
// POST /api/finance/saque/:saqueId/erro
// =====================================================

exports.marcarComoErro = async (req, res) => {

    try {

        const {
            saqueId
        } = req.params;


        const {
            motivo
        } = req.body;


        await garantirEstrutura();


        const resultado =
            await pool.query(
                `
                SELECT
                    id,
                    restaurante_id,
                    valor,
                    metodo,
                    chave,
                    status,
                    automatico,
                    aprovado_automaticamente,
                    data,
                    atualizado_em,
                    mensagem,
                    dados
                FROM repasses
                WHERE id = $1
                LIMIT 1
                `,
                [String(saqueId)]
            );


        if (
            resultado.rows.length === 0
        ) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Saque não encontrado."

            });
        }


        const atualizadoEm =
            new Date();


        const mensagem =
            motivo ||
            "Não foi possível processar o pagamento.";


        const atualizado =
            await pool.query(
                `
                UPDATE repasses

                SET
                    status = 'ERRO',
                    atualizado_em = $1,
                    mensagem = $2,
                    dados =
                        COALESCE(dados, '{}'::jsonb)
                        ||
                        jsonb_build_object(
                            'status',
                            'ERRO',
                            'atualizadoEm',
                            $3::text,
                            'mensagem',
                            $4::text
                        )

                WHERE id = $5

                RETURNING
                    id,
                    restaurante_id,
                    valor,
                    metodo,
                    chave,
                    status,
                    automatico,
                    aprovado_automaticamente,
                    data,
                    atualizado_em,
                    mensagem,
                    dados
                `,
                [
                    atualizadoEm,
                    mensagem,
                    atualizadoEm.toISOString(),
                    mensagem,
                    String(saqueId)
                ]
            );


        const repasse =
            montarRepasse(
                atualizado.rows[0]
            );


        return res.json({

            sucesso: true,

            mensagem:
                "Saque marcado como erro.",

            repasse

        });

    } catch (erro) {

        console.error(
            "ERRO AO MARCAR SAQUE:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao atualizar saque.",

            detalhe:
                erro.message

        });
    }
};