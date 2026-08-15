
const Product = require("../models/product");

// ============================================================
// CRIAR PRODUTO
// ============================================================

exports.create = async (req, res) => {
    try {
        const {
            restauranteId,
            nome,
            descricao,
            preco,
            categoria
        } = req.body;

        if (!restauranteId) {
            return res.status(400).json({
                erro: "restauranteId é obrigatório"
            });
        }

        if (!nome || !nome.toString().trim()) {
            return res.status(400).json({
                erro: "Nome do produto é obrigatório"
            });
        }

        if (
            preco === undefined ||
            preco === null ||
            preco === ""
        ) {
            return res.status(400).json({
                erro: "Preço do produto é obrigatório"
            });
        }

        const produto = {
            id: Date.now(),

            // IMPORTANTE:
            // sempre salvar como String
            restauranteId: restauranteId.toString(),

            nome: nome.toString().trim(),

            descricao: descricao
                ? descricao.toString().trim()
                : "",

            preco: Number(preco),

            categoria: categoria
                ? categoria.toString().trim()
                : "",

            disponivel: true,

            destaque: false,

            imagem: null,

            criadoEm: new Date().toISOString()
        };

        const criado = await Product.criar(produto);

        return res.status(201).json({
            mensagem: "Produto cadastrado com sucesso",
            produto: criado
        });

    } catch (erro) {
        console.error(
            "ERRO AO CRIAR PRODUTO:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao cadastrar produto"
        });
    }
};


// ============================================================
// LISTAR TODOS
// ============================================================

exports.list = async (req, res) => {
    try {
        const produtos = await Product.listar();

        return res.json(produtos);

    } catch (erro) {
        console.error(
            "ERRO AO LISTAR PRODUTOS:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao listar produtos"
        });
    }
};


// ============================================================
// PRODUTOS DO RESTAURANTE
// ============================================================

exports.restaurantProducts = async (req, res) => {
    try {
        const restauranteId =
            req.params.id.toString();

        const produtos =
            await Product.listar();

        const resultado = produtos.filter(
            (produto) => {

                if (!produto.restauranteId) {
                    return false;
                }

                return produto.restauranteId
                    .toString() === restauranteId;
            }
        );

        console.log(
            `PRODUTOS DO RESTAURANTE ${restauranteId}:`,
            resultado.length
        );

        return res.json(resultado);

    } catch (erro) {
        console.error(
            "ERRO AO LISTAR PRODUTOS DO RESTAURANTE:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao listar produtos do restaurante"
        });
    }
};


// ============================================================
// BUSCAR POR ID
// ============================================================

exports.getById = async (req, res) => {
    try {
        const produto =
            await Product.buscarPorId(
                req.params.id
            );

        if (!produto) {
            return res.status(404).json({
                erro: "Produto não encontrado"
            });
        }

        return res.json(produto);

    } catch (erro) {
        console.error(
            "ERRO AO BUSCAR PRODUTO:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao buscar produto"
        });
    }
};


// ============================================================
// EDITAR
// ============================================================

exports.update = async (req, res) => {
    try {
        const id = req.params.id;

        const existente =
            await Product.buscarPorId(id);

        if (!existente) {
            return res.status(404).json({
                erro: "Produto não encontrado"
            });
        }

        const dados = {};

        if (req.body.nome !== undefined) {
            dados.nome =
                req.body.nome
                    .toString()
                    .trim();
        }

        if (req.body.descricao !== undefined) {
            dados.descricao =
                req.body.descricao
                    .toString()
                    .trim();
        }

        if (req.body.preco !== undefined) {
            dados.preco =
                Number(req.body.preco);
        }

        if (req.body.categoria !== undefined) {
            dados.categoria =
                req.body.categoria
                    .toString()
                    .trim();
        }

        const atualizado =
            await Product.atualizar(
                id,
                dados
            );

        return res.json({
            mensagem:
                "Produto atualizado com sucesso",
            produto:
                atualizado
        });

    } catch (erro) {
        console.error(
            "ERRO AO ATUALIZAR PRODUTO:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao atualizar produto"
        });
    }
};


// ============================================================
// DISPONIBILIDADE
// ============================================================

exports.updateAvailability =
async (req, res) => {
    try {
        const id = req.params.id;

        const disponivel =
            req.body.disponivel;

        if (typeof disponivel !== "boolean") {
            return res.status(400).json({
                erro:
                    "disponivel deve ser true ou false"
            });
        }

        const existente =
            await Product.buscarPorId(id);

        if (!existente) {
            return res.status(404).json({
                erro:
                    "Produto não encontrado"
            });
        }

        const atualizado =
            await Product.atualizarDisponibilidade(
                id,
                disponivel
            );

        return res.json({
            mensagem:
                disponivel
                    ? "Produto ativado"
                    : "Produto desativado",

            produto:
                atualizado
        });

    } catch (erro) {
        console.error(
            "ERRO AO ALTERAR DISPONIBILIDADE:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao alterar disponibilidade do produto"
        });
    }
};


// ============================================================
// EXCLUIR
// ============================================================

exports.remove = async (req, res) => {
    try {
        const id = req.params.id;

        const existente =
            await Product.buscarPorId(id);

        if (!existente) {
            return res.status(404).json({
                erro:
                    "Produto não encontrado"
            });
        }

        const removido =
            await Product.excluir(id);

        return res.json({
            mensagem:
                "Produto excluído com sucesso",

            produto:
                removido
        });

    } catch (erro) {
        console.error(
            "ERRO AO EXCLUIR PRODUTO:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao excluir produto"
        });
    }
};


// ============================================================
// UPLOAD DA IMAGEM
// ============================================================

exports.uploadImage = async (req, res) => {
    try {
        const id = req.params.id;

        const produto =
            await Product.buscarPorId(id);

        if (!produto) {
            return res.status(404).json({
                erro:
                    "Produto não encontrado"
            });
        }

        if (!req.file) {
            return res.status(400).json({
                erro:
                    "Nenhuma imagem foi enviada"
            });
        }

        const caminho =
            `/uploads/products/${req.file.filename}`;

        const atualizado =
            await Product.atualizarImagem(
                id,
                caminho
            );

        return res.json({
            mensagem:
                "Imagem do produto atualizada",

            produto:
                atualizado
        });

    } catch (erro) {
        console.error(
            "ERRO AO ENVIAR IMAGEM:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao enviar imagem do produto"
        });
    }
};


// ============================================================
// PRODUTOS POR CATEGORIA
// ============================================================

exports.categoryProducts = async (req, res) => {
    try {
        const categoria =
            req.params.categoria
                .toString()
                .toLowerCase();

        const produtos =
            await Product.listar();

        const resultado =
            produtos.filter(
                (produto) =>
                    produto.categoria &&
                    produto.categoria
                        .toString()
                        .toLowerCase() === categoria
            );

        return res.json(resultado);

    } catch (erro) {
        console.error(erro);

        return res.status(500).json({
            erro: "Erro ao buscar categoria"
        });
    }
};


// ============================================================
// PESQUISA
// ============================================================

exports.searchProducts = async (req, res) => {
    try {
        const texto =
            req.params.texto
                .toString()
                .toLowerCase();

        const produtos =
            await Product.listar();

        const resultado =
            produtos.filter(
                (produto) =>
                    produto.nome &&
                    produto.nome
                        .toString()
                        .toLowerCase()
                        .includes(texto)
            );

        return res.json(resultado);

    } catch (erro) {
        console.error(erro);

        return res.status(500).json({
            erro: "Erro na pesquisa"
        });
    }
};


// ============================================================
// DESTAQUE
// ============================================================

exports.updateHighlight =
async (req, res) => {
    try {
        const destaque =
            req.body.destaque;

        if (typeof destaque !== "boolean") {
            return res.status(400).json({
                erro:
                    "destaque deve ser true ou false"
            });
        }

        const produto =
            await Product.atualizarDestaque(
                req.params.id,
                destaque
            );

        return res.json({
            mensagem:
                "Produto atualizado",
            produto
        });

    } catch (erro) {
        console.error(
            "ERRO AO ALTERAR DESTAQUE:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao alterar destaque"
        });
    }
};

