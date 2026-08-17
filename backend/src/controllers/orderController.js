const Order = require("../models/order");
const Restaurant = require("../models/restaurant");

// ======================================================
// FUNÇÃO AUXILIAR
// NORMALIZAR ID
// ======================================================

function normalizarId(id) {
    if (id === undefined || id === null) {
        return "";
    }

    return String(id).trim();
}

// ======================================================
// FUNÇÃO AUXILIAR
// SALVAR PEDIDOS
// ======================================================

async function salvarPedidos(pedidos) {

    const { db } =
        require("../config/database");

    // Garantir que a estrutura exista
    if (!db.data) {
        db.data = {};
    }

    db.data.pedidos =
        Array.isArray(pedidos)
            ? pedidos
            : [];

    await db.write();
}


// ======================================================
// CRIAR PEDIDO
// POST /api/orders
// ======================================================

exports.create = async (req, res) => {

    try {

        // ==================================================
        // DADOS RECEBIDOS
        // ==================================================

        const restauranteId =
            normalizarId(
                req.body.restauranteId
            );

        const clienteId =
            normalizarId(
                req.body.clienteId
            );

        const itens =
            Array.isArray(req.body.itens)
                ? req.body.itens
                : [];


        // ==================================================
        // VALIDAR RESTAURANTE
        // ==================================================

        if (!restauranteId) {

            return res.status(400).json({

                sucesso: false,

                restauranteOffline: false,

                erro:
                    "restauranteId é obrigatório"

            });
        }


        // ==================================================
        // BUSCAR RESTAURANTE
        // ==================================================

        const restaurante =
            await Restaurant.buscarPorId(
                restauranteId
            );


        if (!restaurante) {

            console.log(
                "❌ RESTAURANTE NÃO ENCONTRADO:",
                restauranteId
            );

            return res.status(404).json({

                sucesso: false,

                restauranteOffline: false,

                erro:
                    "Restaurante não encontrado"

            });
        }


        // ==================================================
        // NORMALIZAR STATUS
        // ==================================================

        const status =
            String(
                restaurante.status || ""
            )
                .trim()
                .toUpperCase();


        // ==================================================
        // NORMALIZAR ONLINE
        // ==================================================

        const online =
            restaurante.online === true ||
            String(
                restaurante.online
            ).trim().toLowerCase() === "true";


        // ==================================================
        // NORMALIZAR ABERTO
        // ==================================================

        const aberto =
            restaurante.aberto === true ||
            String(
                restaurante.aberto
            ).trim().toLowerCase() === "true";


        // ==================================================
        // LOG
        // ==================================================

        console.log(
            "=========================================="
        );

        console.log(
            "🔎 VERIFICAÇÃO DO RESTAURANTE"
        );

        console.log(
            "🏪 ID:",
            restauranteId
        );

        console.log(
            "🏪 NOME:",
            restaurante.nome
        );

        console.log(
            "📌 STATUS:",
            status
        );

        console.log(
            "🟢 ONLINE:",
            online
        );

        console.log(
            "🚪 ABERTO:",
            aberto
        );

        console.log(
            "=========================================="
        );


        // ==================================================
        // VERIFICAR SE ESTÁ DISPONÍVEL
        // ==================================================

        const restauranteDisponivel =
            status === "ABERTO" &&
            online === true &&
            aberto === true;


        if (!restauranteDisponivel) {

            console.log(
                "🔴 PEDIDO BLOQUEADO"
            );

            return res.status(409).json({

                sucesso: false,

                restauranteOffline: true,

                erro:
                    "O restaurante está offline e não está aceitando pedidos.",

                mensagem:
                    "Este restaurante está fechado no momento. Tente novamente mais tarde.",

                restaurante: {

                    id:
                        restaurante.id,

                    nome:
                        restaurante.nome,

                    status:
                        status || "FECHADO",

                    online:
                        online,

                    aberto:
                        aberto

                }

            });
        }


        // ==================================================
        // VALIDAR ITENS
        // ==================================================

        if (itens.length === 0) {

            return res.status(400).json({

                sucesso: false,

                restauranteOffline: false,

                erro:
                    "O pedido precisa ter pelo menos um produto."

            });
        }


        // ==================================================
        // CRIAR PEDIDO
        // ==================================================

        const pedido = {

            id:
                Date.now(),

            clienteId:
                clienteId,

            restauranteId:
                restauranteId,

            itens:
                itens,

            endereco:
                req.body.endereco || {},

            pagamento:
                req.body.pagamento || "PIX",

            subtotal:
                Number(
                    req.body.subtotal
                ) || 0,

            taxaEntrega:
                Number(
                    req.body.taxaEntrega
                ) || 0,

            total:
                Number(
                    req.body.total
                ) || 0,

            status:
                "AGUARDANDO_RESTAURANTE",

            criadoEm:
                new Date().toISOString()

        };


        // ==================================================
        // SALVAR
        // ==================================================

        await Order.criar(
            pedido
        );


        // ==================================================
        // WEBSOCKET
        // AVISAR RESTAURANTE
        // ==================================================

        if (global.io) {

            const salaRestaurante =
                `restaurante_${restauranteId}`;


            global.io
                .to(salaRestaurante)
                .emit(
                    "novo_pedido",
                    pedido
                );


            console.log(
                "🔔 NOVO PEDIDO ENVIADO PARA A SALA:",
                salaRestaurante
            );

        } else {

            console.log(
                "⚠️ global.io não está disponível."
            );

        }


        // ==================================================
        // LOG
        // ==================================================

        console.log(
            "=========================================="
        );

        console.log(
            "📦 NOVO PEDIDO CRIADO"
        );

        console.log(
            "🆔 ID:",
            pedido.id
        );

        console.log(
            "🏪 RESTAURANTE:",
            pedido.restauranteId
        );

        console.log(
            "👤 CLIENTE:",
            pedido.clienteId
        );

        console.log(
            "💰 TOTAL:",
            pedido.total
        );

        console.log(
            "📌 STATUS:",
            pedido.status
        );

        console.log(
            "=========================================="
        );


        // ==================================================
        // RESPOSTA
        // ==================================================

        return res.status(201).json({

            sucesso: true,

            restauranteOffline: false,

            mensagem:
                "Pedido criado com sucesso",

            pedido:
                pedido

        });


    } catch (erro) {

        console.error(
            "❌ ERRO AO CRIAR PEDIDO:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            restauranteOffline: false,

            erro:
                "Erro ao criar pedido",

            detalhes:
                erro.message

        });

    }
};


// ======================================================
// LISTAR TODOS OS PEDIDOS
// GET /api/orders
// ======================================================

exports.list = async (req, res) => {

    try {

        const pedidos =
            await Order.listar();

        return res.status(200).json(
            Array.isArray(pedidos)
                ? pedidos
                : []
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO LISTAR PEDIDOS:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao listar pedidos",

            detalhes:
                erro.message

        });

    }
};


// ======================================================
// BUSCAR PEDIDO PELO ID
// GET /api/orders/:id
// ======================================================

exports.getById = async (req, res) => {

    try {

        const id =
            Number(
                req.params.id
            );


        if (!Number.isFinite(id)) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do pedido inválido"

            });
        }


        const pedido =
            await Order.buscarPorId(
                id
            );


        if (!pedido) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado"

            });
        }


        return res.status(200).json(
            pedido
        );


    } catch (erro) {

        console.error(
            "❌ ERRO AO BUSCAR PEDIDO:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro interno ao buscar pedido",

            detalhes:
                erro.message

        });

    }
};


// ======================================================
// ATUALIZAR STATUS DO PEDIDO
// PUT /api/orders/:id/status
// ======================================================

exports.updateStatus = async (req, res) => {

    try {

        const id =
            Number(
                req.params.id
            );

        const novoStatus =
            String(
                req.body.status || ""
            ).trim();


        if (!Number.isFinite(id)) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do pedido inválido"

            });
        }


        if (!novoStatus) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "Status não informado"

            });
        }


        const pedido =
            await Order.buscarPorId(
                id
            );


        if (!pedido) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado"

            });
        }


        // ==================================================
        // ATUALIZAR
        // ==================================================

        pedido.status =
            novoStatus;

        pedido.atualizadoEm =
            new Date().toISOString();


        // ==================================================
        // SALVAR
        // ==================================================

        const pedidos =
            await Order.listar();


        const index =
            pedidos.findIndex(
                item =>
                    Number(item.id) === id
            );


        if (index === -1) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado no banco"

            });
        }


        pedidos[index] =
            pedido;


        await salvarPedidos(
            pedidos
        );


        // ==================================================
        // AVISAR CLIENTE
        // ==================================================

        if (global.io) {

            global.io.emit(
                "status_pedido_atualizado",
                pedido
            );

            console.log(
                "📡 STATUS ENVIADO AO CLIENTE:",
                pedido.id,
                pedido.status
            );
        }


        // ==================================================
        // RESPOSTA
        // ==================================================

        return res.status(200).json({

            sucesso: true,

            mensagem:
                "Status atualizado com sucesso",

            pedido:
                pedido

        });


    } catch (erro) {

        console.error(
            "❌ ERRO AO ATUALIZAR STATUS:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao atualizar status",

            detalhes:
                erro.message

        });

    }
};


// ======================================================
// BUSCAR PEDIDOS DO RESTAURANTE
// GET /api/orders/restaurante/:id
// ======================================================

exports.restaurantOrders = async (req, res) => {

    try {

        // ==================================================
        // IMPORTANTE:
        // NÃO USAR Number() AQUI
        //
        // O FoodJet usa IDs como:
        //
        // rest_1786542500158
        //
        // ==================================================

        const restauranteId =
            normalizarId(
                req.params.id
            );


        if (!restauranteId) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do restaurante não informado"

            });
        }


        console.log(
            "=========================================="
        );

        console.log(
            "🔎 BUSCANDO PEDIDOS DO RESTAURANTE"
        );

        console.log(
            "🏪 RESTAURANTE:",
            restauranteId
        );


        const pedidos =
            await Order.listar();


        const resultado =
            (Array.isArray(pedidos)
                ? pedidos
                : []
            ).filter(
                pedido => {

                    const pedidoRestauranteId =
                        normalizarId(
                            pedido.restauranteId
                        );

                    return (
                        pedidoRestauranteId ===
                        restauranteId
                    );

                }
            );


        console.log(
            "📦 TOTAL DE PEDIDOS:",
            resultado.length
        );

        console.log(
            "=========================================="
        );


        return res.status(200).json(
            resultado
        );


    } catch (erro) {

        console.error(
            "❌ ERRO AO BUSCAR PEDIDOS DO RESTAURANTE:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao buscar pedidos do restaurante",

            detalhes:
                erro.message

        });

    }
};


// ======================================================
// PEDIDOS DISPONÍVEIS PARA ENTREGA
// GET /api/orders/delivery/available
// ======================================================

exports.availableDeliveries = async (req, res) => {

    try {

        const pedidos =
            await Order.listar();


        const disponiveis =
            (Array.isArray(pedidos)
                ? pedidos
                : []
            ).filter(
                pedido =>
                    String(
                        pedido.status || ""
                    ).trim().toUpperCase() ===
                    "PRONTO"
            );


        return res.status(200).json(
            disponiveis
        );


    } catch (erro) {

        console.error(
            "❌ ERRO AO BUSCAR PEDIDOS DISPONÍVEIS:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao buscar pedidos disponíveis",

            detalhes:
                erro.message

        });

    }
};


// ======================================================
// ENTREGADOR ACEITA O PEDIDO
// PUT /api/orders/:id/accept-delivery
// ======================================================

exports.acceptDelivery = async (req, res) => {

    try {

        const id =
            Number(
                req.params.id
            );

        const entregadorId =
            normalizarId(
                req.body.entregadorId
            );


        if (!Number.isFinite(id)) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do pedido inválido"

            });
        }


        if (!entregadorId) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do entregador não informado"

            });
        }


        const pedido =
            await Order.buscarPorId(
                id
            );


        if (!pedido) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado"

            });
        }


        // ==================================================
        // ATUALIZAR
        // ==================================================

        pedido.entregadorId =
            entregadorId;

        pedido.status =
            "EM_ENTREGA";

        pedido.aceitoEm =
            new Date().toISOString();


        const pedidos =
            await Order.listar();


        const index =
            pedidos.findIndex(
                item =>
                    Number(item.id) === id
            );


        if (index !== -1) {

            pedidos[index] =
                pedido;

        }


        await salvarPedidos(
            pedidos
        );


        // ==================================================
        // AVISAR CLIENTE
        // ==================================================

        if (global.io) {

            global.io.emit(
                "status_pedido_atualizado",
                pedido
            );

        }


        return res.status(200).json({

            sucesso: true,

            mensagem:
                "Pedido aceito pelo entregador",

            pedido:
                pedido

        });


    } catch (erro) {

        console.error(
            "❌ ERRO AO ACEITAR PEDIDO:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao aceitar pedido",

            detalhes:
                erro.message

        });

    }
};


// ======================================================
// FINALIZAR ENTREGA
// PUT /api/orders/:id/complete
// ======================================================

exports.completeDelivery = async (req, res) => {

    try {

        const id =
            Number(
                req.params.id
            );


        if (!Number.isFinite(id)) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do pedido inválido"

            });
        }


        const pedido =
            await Order.buscarPorId(
                id
            );


        if (!pedido) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado"

            });
        }


        pedido.status =
            "ENTREGUE";

        pedido.entregueEm =
            new Date().toISOString();


        const pedidos =
            await Order.listar();


        const index =
            pedidos.findIndex(
                item =>
                    Number(item.id) === id
            );


        if (index !== -1) {

            pedidos[index] =
                pedido;

        }


        await salvarPedidos(
            pedidos
        );


        // ==================================================
        // AVISAR CLIENTE
        // ==================================================

        if (global.io) {

            global.io.emit(
                "status_pedido_atualizado",
                pedido
            );

        }


        console.log(
            "✅ PEDIDO ENTREGUE:",
            id
        );


        return res.status(200).json({

            sucesso: true,

            mensagem:
                "Entrega finalizada com sucesso",

            pedido:
                pedido

        });


    } catch (erro) {

        console.error(
            "❌ ERRO AO FINALIZAR ENTREGA:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao finalizar entrega",

            detalhes:
                erro.message

        });

    }
};


// ======================================================
// EXCLUIR PEDIDO
// DELETE /api/orders/:id
// ======================================================

exports.deleteOrder = async (req, res) => {

    try {

        const id =
            Number(
                req.params.id
            );


        if (!Number.isFinite(id)) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do pedido inválido"

            });
        }


        // ==================================================
        // BUSCAR PEDIDO
        // ==================================================

        const pedido =
            await Order.buscarPorId(
                id
            );


        if (!pedido) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Pedido não encontrado"

            });
        }


        // ==================================================
        // LISTAR
        // ==================================================

        const pedidos =
            await Order.listar();


        // ==================================================
        // REMOVER
        // ==================================================

        const pedidosAtualizados =
            pedidos.filter(
                item =>
                    Number(item.id) !== id
            );


        // ==================================================
        // SALVAR
        // ==================================================

        await salvarPedidos(
            pedidosAtualizados
        );


        // ==================================================
        // AVISAR APLICATIVOS
        // ==================================================

        if (global.io) {

            const evento =
                {

                    id:
                        id,

                    restauranteId:
                        pedido.restauranteId,

                    clienteId:
                        pedido.clienteId

                };


            global.io.emit(
                "pedido_excluido",
                evento
            );


            // Também avisa especificamente
            // o restaurante

            const salaRestaurante =
                `restaurante_${pedido.restauranteId}`;


            global.io
                .to(salaRestaurante)
                .emit(
                    "pedido_excluido",
                    evento
                );


            console.log(
                "📡 PEDIDO EXCLUÍDO PELO SOCKET:",
                id
            );

        }


        console.log(
            "=========================================="
        );

        console.log(
            "🗑️ PEDIDO EXCLUÍDO"
        );

        console.log(
            "🆔 ID:",
            id
        );

        console.log(
            "🏪 RESTAURANTE:",
            pedido.restauranteId
        );

        console.log(
            "👤 CLIENTE:",
            pedido.clienteId
        );

        console.log(
            "=========================================="
        );


        return res.status(200).json({

            sucesso: true,

            mensagem:
                "Pedido excluído com sucesso",

            pedidoId:
                id

        });


    } catch (erro) {

        console.error(
            "❌ ERRO AO EXCLUIR PEDIDO:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao excluir pedido",

            detalhes:
                erro.message

        });

    }
};