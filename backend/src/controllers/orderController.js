
const Order = require("../models/order");

const {
    estornarPagamento,
    consultarPagamento,
} = require("../services/asaasService");

const {
    pool,
} = require("../config/database");


// ======================================================
// OBTER USUÁRIO AUTENTICADO
// ======================================================

function obterUsuarioAutenticado(req) {
    const usuario = req.usuario || req.user || null;

    if (!usuario) return null;

    const id =
        usuario.id ||
        usuario.usuarioId ||
        usuario.userId ||
        usuario._id ||
        null;

    if (!id) return null;

    return {
        ...usuario,
        id: String(id).trim(),
    };
}


// ======================================================
// PROCESSAR ESTORNO DO PEDIDO
// ======================================================
//
// Retorna:
// {
//     encontrado: true/false,
//     estornado: true/false,
//     statusAsaas: "..."
// }
//
// Se houver erro no estorno, lança erro.
// Isso permite que o pedido NÃO seja cancelado/recusado
// quando o dinheiro não puder ser estornado.
//

async function processarEstornoPedido(pedidoAtual) {

    if (!pedidoAtual || !pedidoAtual.id) {
        throw new Error(
            "Pedido inválido para processamento do estorno."
        );
    }

    console.log("");
    console.log("========================================");
    console.log("💸 FOODJET - PROCESSAR ESTORNO");
    console.log("========================================");
    console.log(
        "🆔 PEDIDO:",
        pedidoAtual.id
    );


    // ==================================================
    // BUSCAR PAGAMENTO ASAAS NO POSTGRESQL
    // ==================================================

    let pagamentoAsaas = null;

    try {

        const resultado =
            await pool.query(
                `
                SELECT
                    payment_id,
                    external_reference,
                    status_asaas
                FROM pagamentos_asaas
                WHERE external_reference = $1
                ORDER BY created_at DESC
                LIMIT 1
                `,
                [
                    String(pedidoAtual.id),
                ]
            );

        pagamentoAsaas =
            resultado.rows[0] || null;

    } catch (erroBanco) {

        console.error(
            "❌ ERRO AO BUSCAR PAGAMENTO ASAAS:",
            erroBanco.message
        );

        throw new Error(
            "Não foi possível verificar o pagamento do pedido: " +
            erroBanco.message
        );
    }


    // ==================================================
    // NÃO EXISTE PAGAMENTO ASAAS
    // ==================================================

    if (!pagamentoAsaas) {

        console.log(
            "ℹ️ NENHUM PAGAMENTO ASAAS ENCONTRADO."
        );

        console.log(
            "ℹ️ NENHUM ESTORNO NECESSÁRIO."
        );

        console.log(
            "========================================"
        );

        return {
            encontrado: false,
            estornado: false,
            statusAsaas: null,
        };
    }


    const pagamentoId =
        pagamentoAsaas.payment_id;


    console.log(
        "🆔 ASAAS:",
        pagamentoId
    );

    console.log(
        "📊 STATUS NO BANCO:",
        pagamentoAsaas.status_asaas
    );


    // ==================================================
    // PAGAMENTO SEM ID
    // ==================================================

    if (!pagamentoId) {

        console.log(
            "⚠️ PAGAMENTO ASAAS ENCONTRADO, MAS SEM payment_id."
        );

        console.log(
            "ℹ️ NENHUM ESTORNO REALIZADO."
        );

        console.log(
            "========================================"
        );

        return {
            encontrado: true,
            estornado: false,
            statusAsaas: null,
        };
    }


    // ==================================================
    // JÁ MARCADO COMO ESTORNADO
    // ==================================================

    const statusBanco =
        String(
            pagamentoAsaas.status_asaas || ""
        )
            .trim()
            .toUpperCase();


    if (statusBanco === "REFUNDED") {

        console.log(
            "ℹ️ PAGAMENTO JÁ ESTORNADO NO BANCO."
        );

        console.log(
            "🆔 ASAAS:",
            pagamentoId
        );

        console.log(
            "========================================"
        );

        return {
            encontrado: true,
            estornado: true,
            statusAsaas: "REFUNDED",
        };
    }


    // ==================================================
    // CONSULTAR ASAAS DIRETAMENTE
    // ==================================================

    console.log(
        "🔎 CONSULTANDO STATUS ATUAL NO ASAAS..."
    );


    let pagamentoAtualizado;

    try {

        pagamentoAtualizado =
            await consultarPagamento(
                pagamentoId
            );

    } catch (erroConsulta) {

        console.error(
            "❌ ERRO AO CONSULTAR PAGAMENTO NO ASAAS:",
            erroConsulta.message
        );

        throw new Error(
            "Não foi possível consultar o pagamento no Asaas: " +
            erroConsulta.message
        );
    }


    const statusAsaas =
        String(
            pagamentoAtualizado?.status || ""
        )
            .trim()
            .toUpperCase();


    console.log(
        "📊 STATUS ATUAL ASAAS:",
        statusAsaas
    );


    // ==================================================
    // PAGAMENTOS QUE PODEM SER ESTORNADOS
    // ==================================================

    const pagamentoPago = [
        "RECEIVED",
        "CONFIRMED",
        "RECEIVED_IN_CASH",
    ].includes(
        statusAsaas
    );


    // ==================================================
    // PAGAMENTO NÃO FOI PAGO
    // ==================================================

    if (!pagamentoPago) {

        console.log(
            "ℹ️ PAGAMENTO AINDA NÃO ESTÁ PAGO."
        );

        console.log(
            "📊 STATUS ASAAS:",
            statusAsaas
        );

        console.log(
            "ℹ️ NENHUM ESTORNO NECESSÁRIO."
        );

        console.log(
            "========================================"
        );

        return {
            encontrado: true,
            estornado: false,
            statusAsaas,
        };
    }


    // ==================================================
    // PAGAMENTO PAGO → SOLICITAR ESTORNO
    // ==================================================

    console.log(
        "💳 PAGAMENTO CONFIRMADO."
    );

    console.log(
        "💸 SOLICITANDO ESTORNO AO ASAAS..."
    );


    try {

        await estornarPagamento(
            pagamentoId
        );

    } catch (erroEstorno) {

        console.error("");
        console.error(
            "========================================"
        );
        console.error(
            "❌ ERRO AO PROCESSAR ESTORNO"
        );
        console.error(
            "========================================"
        );

        console.error(
            "🆔 PEDIDO:",
            pedidoAtual.id
        );

        console.error(
            "🆔 ASAAS:",
            pagamentoId
        );

        console.error(
            "📊 STATUS ASAAS:",
            statusAsaas
        );

        console.error(
            "❌ ERRO:",
            erroEstorno.message
        );

        console.error(
            "========================================"
        );

        throw new Error(
            erroEstorno.message ||
            "Não foi possível estornar o pagamento."
        );
    }


    // ==================================================
    // REGISTRAR ESTORNO NO POSTGRESQL
    // ==================================================

    try {

        await pool.query(
            `
            UPDATE pagamentos_asaas
            SET status_asaas = 'REFUNDED'
            WHERE payment_id = $1
            `,
            [
                pagamentoId,
            ]
        );

    } catch (erroBanco) {

        console.error(
            "❌ ESTORNO FOI SOLICITADO, MAS NÃO FOI POSSÍVEL ATUALIZAR O BANCO:",
            erroBanco.message
        );

        throw new Error(
            "O estorno foi solicitado ao Asaas, mas não foi possível atualizar o registro do pagamento no banco: " +
            erroBanco.message
        );
    }


    console.log(
        "✅ ESTORNO SOLICITADO COM SUCESSO."
    );

    console.log(
        "✅ PAGAMENTO MARCADO COMO REFUNDED."
    );

    console.log(
        "========================================"
    );


    return {
        encontrado: true,
        estornado: true,
        statusAsaas,
    };
}


// ======================================================
// CRIAR PEDIDO
// ======================================================

async function create(req, res) {
    try {

        console.log("");
        console.log("========================================");
        console.log("📦 CONTROLLER - CRIAR PEDIDO");
        console.log("========================================");

        const usuario =
            obterUsuarioAutenticado(req);

        if (!usuario) {

            return res.status(401).json({
                sucesso: false,
                erro:
                    "Cliente não identificado. Faça login novamente.",
            });
        }

        const body =
            req.body || {};


        if (!body.restauranteId) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "Restaurante não identificado.",
            });
        }


        if (
            !Array.isArray(body.itens) ||
            body.itens.length === 0
        ) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "O pedido precisa possuir pelo menos um item.",
            });
        }


        const pedido =
            await Order.criar({

                clienteId:
                    usuario.id,

                restauranteId:
                    String(
                        body.restauranteId
                    ).trim(),

                itens:
                    body.itens,

                endereco:
                    body.endereco || {},

                pagamento:
                    String(
                        body.pagamento || "PIX"
                    ).toUpperCase(),

                subtotal:
                    Number(
                        body.subtotal
                    ) || 0,

                taxaServico:
                    Number(
                        body.taxaServico
                    ) || 0,

                taxaEntrega:
                    Number(
                        body.taxaEntrega
                    ) || 0,

                total:
                    Number(
                        body.total
                    ) || 0,

                precisaTroco:
                    Boolean(
                        body.precisaTroco
                    ),

                trocoPara:
                    body.trocoPara !== undefined &&
                    body.trocoPara !== null
                        ? Number(
                            body.trocoPara
                        )
                        : null,

                valorTroco:
                    Number(
                        body.valorTroco
                    ) || 0,
            });


        console.log("========================================");
        console.log(
            "✅ PEDIDO CRIADO PELO CONTROLLER"
        );
        console.log(
            "ID:",
            pedido.id
        );
        console.log(
            "CLIENTE:",
            pedido.clienteId
        );
        console.log(
            "RESTAURANTE:",
            pedido.restauranteId
        );
        console.log(
            "STATUS:",
            pedido.status
        );
        console.log("========================================");


        return res.status(201).json({

            sucesso: true,

            mensagem:
                "Pedido criado com sucesso.",

            pedido,

            pedidoId:
                pedido.id,
        });

    } catch (error) {

        console.error(
            "❌ ERRO CONTROLLER CRIAR PEDIDO:",
            error
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao criar pedido",

            detalhes:
                error.message,
        });
    }
}


// ======================================================
// LISTAR PEDIDOS
// ======================================================

async function list(req, res) {

    try {

        const pedidos =
            await Order.listar();

        return res.json({

            sucesso: true,

            pedidos,
        });

    } catch (error) {

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao listar pedidos",

            detalhes:
                error.message,
        });
    }
}


// ======================================================
// BUSCAR PEDIDO
// ======================================================

async function getById(req, res) {

    try {

        const pedido =
            await Order.buscarPorId(
                req.params.id
            );

        if (!pedido) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado.",
            });
        }

        return res.json({

            sucesso: true,

            pedido,
        });

    } catch (error) {

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao buscar pedido",

            detalhes:
                error.message,
        });
    }
}


// ======================================================
// ATUALIZAR STATUS
// ======================================================

async function updateStatus(req, res) {

    try {

        const { status } =
            req.body;


        if (!status) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "Status não informado.",
            });
        }


        // ==================================================
        // BUSCAR PEDIDO ANTES DA ALTERAÇÃO
        // ==================================================

        const pedidoAtual =
            await Order.buscarPorId(
                req.params.id
            );


        if (!pedidoAtual) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado.",
            });
        }


        // ==================================================
        // NORMALIZAR STATUS
        // ==================================================

        const statusNormalizado =
            String(status)
                .trim()
                .toUpperCase();


        // ==================================================
        // IDENTIFICAR CANCELAMENTO
        // ==================================================

        const statusCancelamento = [

            "CANCELADO",

            "CANCELADA",

            "CANCELLED",

        ];


        const vaiCancelar =
            statusCancelamento.includes(
                statusNormalizado
            );


        // ==================================================
        // PROCESSAR ESTORNO
        // ==================================================

        if (vaiCancelar) {

            console.log("");
            console.log(
                "========================================"
            );
            console.log(
                "❌ FOODJET - CANCELAMENTO"
            );
            console.log(
                "========================================"
            );

            console.log(
                "🆔 PEDIDO:",
                pedidoAtual.id
            );

            console.log(
                "📊 STATUS ATUAL:",
                pedidoAtual.status
            );


            try {

                await processarEstornoPedido(
                    pedidoAtual
                );

            } catch (erroEstorno) {

                console.error(
                    "❌ CANCELAMENTO BLOQUEADO POR FALHA NO ESTORNO:",
                    erroEstorno.message
                );


                return res.status(500).json({

                    sucesso: false,

                    erro:
                        "Não foi possível estornar o pagamento. O pedido não foi cancelado.",

                    detalhes:
                        erroEstorno.message,
                });
            }


            console.log(
                "========================================"
            );
        }


        // ==================================================
        // ATUALIZAR STATUS DO PEDIDO
        // ==================================================

        const pedido =
            await Order.atualizarStatus(

                req.params.id,

                status
            );


        if (!pedido) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado.",
            });
        }


        // ==================================================
        // RESPOSTA
        // ==================================================

        return res.json({

            sucesso: true,

            pedido,
        });


    } catch (error) {

        console.error(
            "❌ ERRO AO ATUALIZAR STATUS:",
            error
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao atualizar status",

            detalhes:
                error.message,
        });
    }
}


// ======================================================
// PEDIDOS DO RESTAURANTE
// ======================================================

async function restaurantOrders(req, res) {

    try {

        const pedidos =
            await Order.listarPorRestaurante(
                req.params.id
            );

        return res.json({

            sucesso: true,

            pedidos,
        });

    } catch (error) {

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao buscar pedidos do restaurante",

            detalhes:
                error.message,
        });
    }
}


// ======================================================
// PEDIDOS DO CLIENTE
// ======================================================

async function clientOrders(req, res) {

    try {

        const pedidos =
            await Order.listarPorCliente(
                req.params.id
            );

        return res.json({

            sucesso: true,

            pedidos,
        });

    } catch (error) {

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao buscar pedidos do cliente",

            detalhes:
                error.message,
        });
    }
}


// ======================================================
// PEDIDOS DISPONÍVEIS PARA ENTREGA
// ======================================================

async function availableDeliveries(req, res) {

    try {

        const pedidos =
            await Order.listarDisponiveisEntrega();

        return res.json({

            sucesso: true,

            pedidos,
        });

    } catch (error) {

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao buscar pedidos disponíveis",

            detalhes:
                error.message,
        });
    }
}


// ======================================================
// RESTAURANTE ACEITA PEDIDO
// ======================================================

async function acceptRestaurant(req, res) {

    try {

        const pedido =
            await Order.aceitarPedidoRestaurante(
                req.params.id
            );


        if (!pedido) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado ou não está aguardando o restaurante.",
            });
        }


        return res.json({

            sucesso: true,

            mensagem:
                "Pedido aceito pelo restaurante.",

            pedido,
        });

    } catch (error) {

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao aceitar pedido",

            detalhes:
                error.message,
        });
    }
}


// ======================================================
// RESTAURANTE RECUSA PEDIDO
// ======================================================

async function rejectRestaurant(req, res) {

    try {

        console.log("");
        console.log(
            "========================================"
        );
        console.log(
            "🚫 FOODJET - RESTAURANTE RECUSANDO PEDIDO"
        );
        console.log(
            "========================================"
        );


        // ==================================================
        // BUSCAR PEDIDO ANTES DA RECUSA
        // ==================================================

        const pedidoAtual =
            await Order.buscarPorId(
                req.params.id
            );


        if (!pedidoAtual) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado.",
            });
        }


        console.log(
            "🆔 PEDIDO:",
            pedidoAtual.id
        );

        console.log(
            "📊 STATUS ATUAL:",
            pedidoAtual.status
        );


        // ==================================================
        // PROCESSAR ESTORNO
        // ==================================================

        try {

            await processarEstornoPedido(
                pedidoAtual
            );

        } catch (erroEstorno) {

            console.error(
                "❌ RECUSA BLOQUEADA POR FALHA NO ESTORNO:",
                erroEstorno.message
            );


            return res.status(500).json({

                sucesso: false,

                erro:
                    "Não foi possível estornar o pagamento. O pedido não foi recusado.",

                detalhes:
                    erroEstorno.message,
            });
        }


        // ==================================================
        // RECUSAR PEDIDO NO BANCO
        // ==================================================

        const pedido =
            await Order.recusarPedidoRestaurante(

                req.params.id,

                req.body?.motivo
            );


        if (!pedido) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado ou não está aguardando o restaurante.",
            });
        }


        console.log(
            "✅ PEDIDO RECUSADO PELO RESTAURANTE."
        );


        return res.json({

            sucesso: true,

            mensagem:
                "Pedido recusado. Pagamento estornado quando aplicável.",

            pedido,
        });


    } catch (error) {

        console.error(
            "❌ ERRO AO RECUSAR PEDIDO:",
            error
        );


        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao recusar pedido",

            detalhes:
                error.message,
        });
    }
}


// ======================================================
// ENTREGADOR ACEITA ENTREGA
// ======================================================

async function acceptDelivery(req, res) {

    try {

        const pedido =
            await Order.aceitarEntrega(

                req.params.id,

                req.body.entregadorId
            );


        if (!pedido) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado ou não está disponível para entrega.",
            });
        }


        return res.json({

            sucesso: true,

            mensagem:
                "Entrega aceita.",

            pedido,
        });

    } catch (error) {

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao aceitar entrega",

            detalhes:
                error.message,
        });
    }
}


// ======================================================
// FINALIZAR ENTREGA
// ======================================================

async function completeDelivery(req, res) {

    try {

        const pedido =
            await Order.finalizarEntrega(
                req.params.id
            );


        if (!pedido) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado ou não está em entrega.",
            });
        }


        return res.json({

            sucesso: true,

            mensagem:
                "Entrega finalizada.",

            pedido,
        });

    } catch (error) {

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao finalizar entrega",

            detalhes:
                error.message,
        });
    }
}


// ======================================================
// ABRIR SUPORTE
// ======================================================

async function openSupport(req, res) {

    try {

        const usuario =
            obterUsuarioAutenticado(req);


        if (!usuario) {

            return res.status(401).json({

                sucesso: false,

                erro:
                    "Usuário não identificado.",
            });
        }


        const pedido =
            await Order.abrirSuporte(

                req.params.id,

                usuario.id,

                usuario.tipo || "CLIENTE",

                req.body.mensagem,

                req.body.motivo
            );


        if (!pedido) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado.",
            });
        }


        return res.json({

            sucesso: true,

            mensagem:
                "Suporte aberto.",

            pedido,
        });

    } catch (error) {

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao abrir suporte",

            detalhes:
                error.message,
        });
    }
}


// ======================================================
// EXPORTAÇÕES
// ======================================================

module.exports = {

    create,

    list,

    getById,

    updateStatus,

    restaurantOrders,

    clientOrders,

    availableDeliveries,

    acceptRestaurant,

    rejectRestaurant,

    acceptDelivery,

    completeDelivery,

    openSupport,

};

