const express = require("express");

const router = express.Router();

const Order = require("../models/order");

// =====================================================
// CRIAR PEDIDO DE TESTE FINANCEIRO
// POST /api/teste-financeiro/:restauranteId
// =====================================================

router.post("/:restauranteId", async (req, res) => {
    try {
        const { restauranteId } = req.params;

        if (!restauranteId) {
            return res.status(400).json({
                sucesso: false,
                erro: "restauranteId é obrigatório.",
            });
        }

        // =====================================================
        // CRIAR PEDIDO NO POSTGRESQL
        // =====================================================

        const agora = new Date().toISOString();

        const pedido = await Order.criar({
            restauranteId,

            clienteId: "cliente_teste",

            clienteNome: "Cliente Teste",

            status: "CONCLUIDO",

            total: 100,

            subtotal: 100,

            taxaEntrega: 0,

            taxaServico: 0,

            itens: [
                {
                    nome: "Pedido de teste",
                    quantidade: 1,
                    preco: 100,
                },
            ],

            endereco: {
                rua: "Endereço de teste",
                numero: "100",
                bairro: "Centro",
                cidade: "Ipatinga",
                estado: "MG",
            },

            pagamento: {
                metodo: "PIX",
                status: "PAGO",
            },

            data: agora,

            criadoEm: agora,

            finalizadoEm: agora,

            testeFinanceiro: true,
        });

        // =====================================================
        // LOGS
        // =====================================================

        console.log("");
        console.log("🧪 PEDIDO FINANCEIRO DE TESTE CRIADO");
        console.log("🏪 Restaurante:", restauranteId);
        console.log("📦 Pedido:", pedido.id);
        console.log("💰 Valor: R$ 100,00");
        console.log("");

        // =====================================================
        // RESPOSTA
        // =====================================================

        return res.status(201).json({
            sucesso: true,

            mensagem:
                "Pedido de teste criado com sucesso.",

            pedido,
        });

    } catch (erro) {

        console.error("");
        console.error("❌ ERRO TESTE FINANCEIRO:");
        console.error(erro);
        console.error("");

        return res.status(500).json({
            sucesso: false,

            erro:
                "Erro ao criar pedido de teste.",

            detalhe:
                erro.message,
        });
    }
});

module.exports = router;