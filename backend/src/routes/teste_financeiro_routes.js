const express = require("express");

const router = express.Router();

const { db } = require("../database/db");

// =====================================================
// CRIAR PEDIDO DE TESTE FINANCEIRO
// POST /api/teste-financeiro/:restauranteId
// =====================================================

router.post("/:restauranteId", async (req, res) => {

    try {

        const { restauranteId } = req.params;

        await db.read();

        if (!db.data) {
            db.data = {};
        }

        db.data.pedidos ||= [];

        const pedido = {

            id: `pedido_teste_${Date.now()}`,

            restauranteId,

            clienteId: "cliente_teste",

            clienteNome: "Cliente Teste",

            status: "CONCLUIDO",

            total: 100,

            subtotal: 100,

            taxaEntrega: 0,

            itens: [
                {
                    nome: "Pedido de teste",
                    quantidade: 1,
                    preco: 100
                }
            ],

            endereco: {
                rua: "Endereço de teste",
                numero: "100",
                bairro: "Centro",
                cidade: "Ipatinga",
                estado: "MG"
            },

            pagamento: {
                metodo: "PIX",
                status: "PAGO"
            },

            data: new Date().toISOString(),

            criadoEm: new Date().toISOString(),

            finalizadoEm: new Date().toISOString(),

            testeFinanceiro: true
        };

        db.data.pedidos.push(pedido);

        await db.write();

        console.log(
            "🧪 PEDIDO FINANCEIRO DE TESTE CRIADO"
        );

        console.log(
            "🏪 Restaurante:",
            restauranteId
        );

        console.log(
            "💰 Valor: R$ 100,00"
        );

        return res.status(201).json({

            sucesso: true,

            mensagem:
                "Pedido de teste criado com sucesso.",

            pedido

        });

    } catch (erro) {

        console.error(
            "ERRO TESTE FINANCEIRO:",
            erro
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao criar pedido de teste.",

            detalhe:
                erro.message

        });

    }

});

module.exports = router;