const { db } = require("../config/database");

const Coupon = {

    async criar(cupom) {

        const novoCupom = {
            id: Date.now().toString(),
            restauranteId: cupom.restauranteId,
            codigo: cupom.codigo.toUpperCase(),
            descricao: cupom.descricao || "",
            tipo: cupom.tipo || "PORCENTAGEM",
            valor: Number(cupom.valor) || 0,
            valorMinimo: Number(cupom.valorMinimo) || 0,
            limiteUso: Number(cupom.limiteUso) || 0,
            usos: 0,
            ativo: cupom.ativo !== false,
            criadoEm: new Date().toISOString()
        };

        if (!db.data.cupons) {
            db.data.cupons = [];
        }

        db.data.cupons.push(novoCupom);

        await db.write();

        return novoCupom;
    },

    async listar(restauranteId) {

        if (!db.data.cupons) {
            db.data.cupons = [];
            await db.write();
        }

        return db.data.cupons.filter(
            cupom =>
                cupom.restauranteId.toString() ===
                restauranteId.toString()
        );
    },

    async buscarPorCodigo(codigo) {

        if (!db.data.cupons) {
            return null;
        }

        return db.data.cupons.find(
            cupom =>
                cupom.codigo.toUpperCase() ===
                codigo.toUpperCase()
        );
    },

    async buscarPorId(id) {

        if (!db.data.cupons) {
            return null;
        }

        return db.data.cupons.find(
            cupom =>
                cupom.id.toString() ===
                id.toString()
        );
    },

    async atualizar(id, dados) {

        if (!db.data.cupons) {
            return null;
        }

        const indice = db.data.cupons.findIndex(
            cupom =>
                cupom.id.toString() ===
                id.toString()
        );

        if (indice === -1) {
            return null;
        }

        db.data.cupons[indice] = {
            ...db.data.cupons[indice],
            ...dados,
            codigo: dados.codigo
                ? dados.codigo.toUpperCase()
                : db.data.cupons[indice].codigo
        };

        await db.write();

        return db.data.cupons[indice];
    },

    async excluir(id) {

        if (!db.data.cupons) {
            return false;
        }

        const tamanhoAntes =
            db.data.cupons.length;

        db.data.cupons =
            db.data.cupons.filter(
                cupom =>
                    cupom.id.toString() !==
                    id.toString()
            );

        if (
            db.data.cupons.length ===
            tamanhoAntes
        ) {
            return false;
        }

        await db.write();

        return true;
    },

    async registrarUso(id) {

        const cupom =
            await this.buscarPorId(id);

        if (!cupom) {
            return null;
        }

        cupom.usos =
            Number(cupom.usos || 0) + 1;

        await db.write();

        return cupom;
    }
};

module.exports = Coupon;