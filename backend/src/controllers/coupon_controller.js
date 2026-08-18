const Coupon = require("../models/coupon");

// ======================================================
// CRIAR CUPOM
// POST /api/coupons
// ======================================================

exports.criar = async (req, res) => {

    try {

        const {
            restauranteId,
            codigo,
            descricao,
            tipo,
            valor,
            valorMinimo,
            limiteUso
        } = req.body;

        if (!restauranteId) {
            return res.status(400).json({
                erro: "Restaurante não informado."
            });
        }

        if (!codigo) {
            return res.status(400).json({
                erro: "Código do cupom é obrigatório."
            });
        }

        if (!valor || Number(valor) <= 0) {
            return res.status(400).json({
                erro: "Valor do cupom inválido."
            });
        }

        const existente =
            await Coupon.buscarPorCodigo(codigo);

        if (existente) {
            return res.status(409).json({
                erro: "Este código de cupom já existe."
            });
        }

        const cupom =
            await Coupon.criar({
                restauranteId,
                codigo,
                descricao,
                tipo,
                valor,
                valorMinimo,
                limiteUso
            });

        return res.status(201).json({
            sucesso: true,
            cupom
        });

    } catch (error) {

        console.error(
            "❌ Erro ao criar cupom:",
            error
        );

        return res.status(500).json({
            erro: "Erro ao criar cupom."
        });
    }
};


// ======================================================
// LISTAR CUPONS DO RESTAURANTE
// GET /api/coupons/restaurante/:restauranteId
// ======================================================

exports.listar = async (req, res) => {

    try {

        const {
            restauranteId
        } = req.params;

        const cupons =
            await Coupon.listar(
                restauranteId
            );

        return res.json({
            sucesso: true,
            cupons
        });

    } catch (error) {

        console.error(
            "❌ Erro ao listar cupons:",
            error
        );

        return res.status(500).json({
            erro: "Erro ao listar cupons."
        });
    }
};


// ======================================================
// VALIDAR CUPOM
// POST /api/coupons/validar
// ======================================================

exports.validar = async (req, res) => {

    try {

        const {
            codigo,
            restauranteId,
            valorPedido
        } = req.body;

        if (!codigo) {
            return res.status(400).json({
                erro: "Informe o código do cupom."
            });
        }

        const cupom =
            await Coupon.buscarPorCodigo(
                codigo
            );

        if (!cupom) {
            return res.status(404).json({
                erro: "Cupom não encontrado."
            });
        }

        if (
            restauranteId &&
            cupom.restauranteId.toString() !==
            restauranteId.toString()
        ) {
            return res.status(400).json({
                erro: "Cupom não pertence a este restaurante."
            });
        }

        if (!cupom.ativo) {
            return res.status(400).json({
                erro: "Este cupom está desativado."
            });
        }

        if (
            cupom.limiteUso > 0 &&
            cupom.usos >= cupom.limiteUso
        ) {
            return res.status(400).json({
                erro: "Este cupom atingiu o limite de uso."
            });
        }

        const total =
            Number(valorPedido) || 0;

        if (
            cupom.valorMinimo > 0 &&
            total < cupom.valorMinimo
        ) {
            return res.status(400).json({
                erro:
                    `Pedido mínimo de R$ ${cupom.valorMinimo.toFixed(2)}`
            });
        }

        let desconto = 0;

        if (
            cupom.tipo === "PORCENTAGEM"
        ) {

            desconto =
                total *
                (Number(cupom.valor) / 100);

        } else {

            desconto =
                Number(cupom.valor);
        }

        if (desconto > total) {
            desconto = total;
        }

        const valorFinal =
            total - desconto;

        return res.json({

            sucesso: true,

            cupom,

            desconto: Number(
                desconto.toFixed(2)
            ),

            valorOriginal: Number(
                total.toFixed(2)
            ),

            valorFinal: Number(
                valorFinal.toFixed(2)
            )
        });

    } catch (error) {

        console.error(
            "❌ Erro ao validar cupom:",
            error
        );

        return res.status(500).json({
            erro: "Erro ao validar cupom."
        });
    }
};


// ======================================================
// ATUALIZAR CUPOM
// PUT /api/coupons/:id
// ======================================================

exports.atualizar = async (req, res) => {

    try {

        const {
            id
        } = req.params;

        const cupom =
            await Coupon.atualizar(
                id,
                req.body
            );

        if (!cupom) {
            return res.status(404).json({
                erro: "Cupom não encontrado."
            });
        }

        return res.json({
            sucesso: true,
            cupom
        });

    } catch (error) {

        console.error(
            "❌ Erro ao atualizar cupom:",
            error
        );

        return res.status(500).json({
            erro: "Erro ao atualizar cupom."
        });
    }
};


// ======================================================
// ATIVAR / DESATIVAR
// PATCH /api/coupons/:id/status
// ======================================================

exports.alterarStatus = async (req, res) => {

    try {

        const {
            id
        } = req.params;

        const {
            ativo
        } = req.body;

        const cupom =
            await Coupon.atualizar(
                id,
                {
                    ativo:
                        ativo === true
                }
            );

        if (!cupom) {
            return res.status(404).json({
                erro: "Cupom não encontrado."
            });
        }

        return res.json({
            sucesso: true,
            cupom
        });

    } catch (error) {

        console.error(
            "❌ Erro ao alterar status:",
            error
        );

        return res.status(500).json({
            erro: "Erro ao alterar status do cupom."
        });
    }
};


// ======================================================
// EXCLUIR CUPOM
// DELETE /api/coupons/:id
// ======================================================

exports.excluir = async (req, res) => {

    try {

        const {
            id
        } = req.params;

        const excluido =
            await Coupon.excluir(id);

        if (!excluido) {
            return res.status(404).json({
                erro: "Cupom não encontrado."
            });
        }

        return res.json({
            sucesso: true,
            mensagem: "Cupom excluído com sucesso."
        });

    } catch (error) {

        console.error(
            "❌ Erro ao excluir cupom:",
            error
        );

        return res.status(500).json({
            erro: "Erro ao excluir cupom."
        });
    }
};