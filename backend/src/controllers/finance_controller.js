const { db } = require("../database/db");

// =====================================================
// FUNÇÕES AUXILIARES
// =====================================================

function garantirEstrutura() {
    if (!db.data) {
        db.data = {};
    }

    db.data.pedidos ||= [];
    db.data.repasses ||= [];
    db.data.restaurantes ||= [];
    db.data.usuarios ||= [];
}

// =====================================================
// CALCULAR SALDO DO RESTAURANTE
// =====================================================

function calcularSaldo(restauranteId) {
    garantirEstrutura();

    const pedidos = db.data.pedidos.filter(
        pedido =>
            String(pedido.restauranteId) ===
            String(restauranteId)
    );

    const concluidos = pedidos.filter(
        pedido =>
            pedido.status === "CONCLUIDO" ||
            pedido.status === "FINALIZADO"
    );

    const faturamento = concluidos.reduce(
        (total, pedido) =>
            total + Number(pedido.total || 0),
        0
    );

    const movimentacoes = db.data.repasses.filter(
        repasse =>
            String(repasse.restauranteId) ===
            String(restauranteId)
    );

    const pagos = movimentacoes
        .filter(
            repasse =>
                repasse.status === "PAGO" ||
                repasse.status === "PROCESSANDO" ||
                repasse.status === "PENDENTE"
        )
        .reduce(
            (total, repasse) =>
                total + Number(repasse.valor || 0),
            0
        );

    const saldoDisponivel =
        faturamento - pagos;

    return {
        faturamento,
        saldoDisponivel,
        pedidosConcluidos: concluidos.length
    };
}

// =====================================================
// RESUMO FINANCEIRO
// GET /api/finance/:restauranteId
// =====================================================

exports.resumo = async (req, res) => {

    try {

        const { restauranteId } = req.params;

        await db.read();

        garantirEstrutura();

        const pedidos =
            db.data.pedidos.filter(
                pedido =>
                    String(pedido.restauranteId) ===
                    String(restauranteId)
            );

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
                    total + Number(pedido.total || 0),
                0
            );

        // =================================================
        // REPASSES PAGOS
        // =================================================

        const repassesPagos =
            db.data.repasses.filter(
                repasse =>
                    String(repasse.restauranteId) ===
                    String(restauranteId) &&
                    repasse.status === "PAGO"
            );

        const totalRepassado =
            repassesPagos.reduce(
                (total, repasse) =>
                    total + Number(repasse.valor || 0),
                0
            );

        // =================================================
        // SAQUES PROCESSANDO
        // =================================================

        const saquesProcessando =
            db.data.repasses.filter(
                repasse =>
                    String(repasse.restauranteId) ===
                    String(restauranteId) &&
                    repasse.status === "PROCESSANDO"
            );

        const totalProcessando =
            saquesProcessando.reduce(
                (total, repasse) =>
                    total + Number(repasse.valor || 0),
                0
            );

        // =================================================
        // SAQUES PENDENTES
        // Compatibilidade com registros antigos
        // =================================================

        const saquesPendentes =
            db.data.repasses.filter(
                repasse =>
                    String(repasse.restauranteId) ===
                    String(restauranteId) &&
                    repasse.status === "PENDENTE"
            );

        const totalPendente =
            saquesPendentes.reduce(
                (total, repasse) =>
                    total + Number(repasse.valor || 0),
                0
            );

        // =================================================
        // SAQUES COM ERRO
        // =================================================

        const saquesComErro =
            db.data.repasses.filter(
                repasse =>
                    String(repasse.restauranteId) ===
                    String(restauranteId) &&
                    repasse.status === "ERRO"
            );

        const totalErro =
            saquesComErro.reduce(
                (total, repasse) =>
                    total + Number(repasse.valor || 0),
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
            db.data.repasses
                .filter(
                    repasse =>
                        String(
                            repasse.restauranteId
                        ) ===
                        String(restauranteId)
                )
                .sort(
                    (a, b) =>
                        new Date(b.data) -
                        new Date(a.data)
                );

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

        const { restauranteId } =
            req.params;

        const {
            valor,
            metodo,
            chave
        } = req.body;

        await db.read();

        garantirEstrutura();

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
            calcularSaldo(
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
        // CRIAR SAQUE AUTOMÁTICO
        // =================================================

        const agora =
            new Date();

        const repasse = {

            id:
                `saque_${Date.now()}`,

            restauranteId:
                restauranteId,

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
        // SALVAR
        // =================================================

        db.data.repasses.push(
            repasse
        );

        await db.write();

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

        const { saqueId } =
            req.params;

        await db.read();

        garantirEstrutura();

        const repasse =
            db.data.repasses.find(
                item =>
                    String(item.id) ===
                    String(saqueId)
            );

        if (!repasse) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Saque não encontrado."

            });
        }

        if (
            repasse.status ===
            "PAGO"
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "Este saque já foi pago."

            });
        }

        repasse.status =
            "PAGO";

        repasse.atualizadoEm =
            new Date().toISOString();

        repasse.mensagem =
            "Pagamento realizado com sucesso.";

        await db.write();

        return res.json({

            sucesso: true,

            mensagem:
                "Saque marcado como pago.",

            repasse

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
// =====================================================

exports.marcarComoErro = async (req, res) => {

    try {

        const { saqueId } =
            req.params;

        const {
            motivo
        } = req.body;

        await db.read();

        garantirEstrutura();

        const repasse =
            db.data.repasses.find(
                item =>
                    String(item.id) ===
                    String(saqueId)
            );

        if (!repasse) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Saque não encontrado."

            });
        }

        repasse.status =
            "ERRO";

        repasse.atualizadoEm =
            new Date().toISOString();

        repasse.mensagem =
            motivo ||
            "Não foi possível processar o pagamento.";

        await db.write();

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