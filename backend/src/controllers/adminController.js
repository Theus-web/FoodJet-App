const { pool } = require("../config/database");

// ======================================================
// DASHBOARD ADMINISTRATIVO
// ======================================================

exports.dashboard = async (req, res) => {

    try {

        const [
            usuarios,
            restaurantes,
            produtos,
            pedidos,
            entregadores
        ] = await Promise.all([

            pool.query(
                `SELECT COUNT(*)::int AS total FROM usuarios`
            ),

            pool.query(
                `SELECT COUNT(*)::int AS total FROM restaurantes`
            ),

            pool.query(
                `SELECT COUNT(*)::int AS total FROM produtos`
            ),

            pool.query(
                `SELECT COUNT(*)::int AS total FROM pedidos`
            ),

            pool.query(
                `SELECT COUNT(*)::int AS total FROM entregadores`
            )
        ]);

        res.json({
            sistema: "FoodJet",

            usuarios:
                usuarios.rows[0].total,

            restaurantes:
                restaurantes.rows[0].total,

            produtos:
                produtos.rows[0].total,

            pedidos:
                pedidos.rows[0].total,

            entregadores:
                entregadores.rows[0].total
        });

    } catch (error) {

        console.error(
            "❌ Erro no dashboard administrativo:",
            error
        );

        res.status(500).json({
            sucesso: false,
            erro:
                "Erro ao carregar dashboard administrativo."
        });
    }
};

// ======================================================
// LISTAR USUÁRIOS
// ======================================================

exports.users = async (req, res) => {

    try {

        const resultado =
            await pool.query(`
                SELECT
                    id,
                    nome,
                    email,
                    tipo
                FROM usuarios
                ORDER BY criado_em DESC
            `);

        const usuarios =
            resultado.rows.map(usuario => ({
                id: usuario.id,
                nome: usuario.nome,
                email: usuario.email,
                tipo: usuario.tipo
            }));

        res.json(usuarios);

    } catch (error) {

        console.error(
            "❌ Erro ao listar usuários:",
            error
        );

        res.status(500).json({
            sucesso: false,
            erro:
                "Erro ao listar usuários."
        });
    }
};

// ======================================================
// LISTAR RESTAURANTES
// ======================================================

exports.restaurants = async (req, res) => {

    try {

        const resultado =
            await pool.query(`
                SELECT
                    id,
                    nome,
                    cnpj,
                    categoria,
                    endereco,
                    pagamento,
                    imagem,
                    status,
                    online,
                    aberto,
                    criado_em,
                    atualizado_em,
                    dados
                FROM restaurantes
                ORDER BY criado_em DESC
            `);

        const restaurantes =
            resultado.rows.map(row => {

                const dados =
                    row.dados &&
                    typeof row.dados === "object"
                        ? row.dados
                        : {};

                return {
                    ...dados,

                    id: row.id,
                    nome: row.nome,
                    cnpj: row.cnpj,
                    categoria: row.categoria,

                    endereco:
                        row.endereco,

                    pagamento:
                        row.pagamento,

                    imagem:
                        row.imagem,

                    status:
                        row.status,

                    online:
                        row.online,

                    aberto:
                        row.aberto,

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
                            : dados.atualizadoEm
                };

            });

        res.json(restaurantes);

    } catch (error) {

        console.error(
            "❌ Erro ao listar restaurantes:",
            error
        );

        res.status(500).json({
            sucesso: false,
            erro:
                "Erro ao listar restaurantes."
        });
    }
};