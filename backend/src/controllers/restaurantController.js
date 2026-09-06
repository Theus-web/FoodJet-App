const Restaurant = require("../models/restaurant");
const fs = require("fs");
const path = require("path");
const multer = require("multer");

// ==================================================
// UPLOAD DE CAPA
// ==================================================

const pastaCapas = path.join(
    process.cwd(),
    "uploads",
    "capas"
);

if (!fs.existsSync(pastaCapas)) {
    fs.mkdirSync(
        pastaCapas,
        {
            recursive: true
        }
    );
}

// ==================================================
// CONFIGURAÇÃO DO MULTER
// ==================================================

const storageCapa = multer.diskStorage({

    destination: (req, file, cb) => {

        cb(
            null,
            pastaCapas
        );

    },

    filename: (req, file, cb) => {

        const restauranteId =
            String(
                req.params.id || "restaurante"
            )
                .replace(
                    /[^a-zA-Z0-9_-]/g,
                    ""
                );

        let extensao =
            path.extname(
                String(
                    file.originalname || ""
                )
            ).toLowerCase();

        // ==================================================
        // NORMALIZAR EXTENSÃO
        // ==================================================

        if (
            extensao === ".jpeg"
        ) {
            extensao = ".jpg";
        }

        if (
            ![
                ".jpg",
                ".png",
                ".webp"
            ].includes(
                extensao
            )
        ) {
            extensao = ".jpg";
        }

        const nomeArquivo =
            `capa_${restauranteId}_${Date.now()}${extensao}`;

        console.log(
            "📁 Nome final da capa:",
            nomeArquivo
        );

        cb(
            null,
            nomeArquivo
        );

    }

});

// ==================================================
// FILTRO DE IMAGEM
// ==================================================

const uploadCapa =
    multer({

        storage: storageCapa,

        limits: {

            fileSize:
                5 * 1024 * 1024

        },

        fileFilter: (
            req,
            file,
            cb
        ) => {

            // ==================================================
            // TIPOS ACEITOS
            // ==================================================

            const tiposPermitidos = [

                "image/jpeg",

                "image/jpg",

                "image/png",

                "image/webp",

                // Alguns navegadores podem enviar PNG assim
                "image/x-png"

            ];

            const extensoesPermitidas = [

                ".jpg",

                ".jpeg",

                ".png",

                ".webp"

            ];

            // ==================================================
            // NORMALIZAR DADOS RECEBIDOS
            // ==================================================

            const mime =
                String(
                    file.mimetype || ""
                )
                    .trim()
                    .toLowerCase();

            const nomeArquivo =
                String(
                    file.originalname || ""
                )
                    .trim()
                    .toLowerCase();

            const extensao =
                path.extname(
                    nomeArquivo
                );

            const mimePermitido =
                tiposPermitidos.includes(
                    mime
                );

            const extensaoPermitida =
                extensoesPermitidas.includes(
                    extensao
                );

            // ==================================================
            // LOG
            // ==================================================

            console.log("");

            console.log(
                "========================================"
            );

            console.log(
                "🖼️ FOODJET - VALIDANDO CAPA"
            );

            console.log(
                "📁 Nome original:",
                file.originalname
            );

            console.log(
                "📦 MIME recebido:",
                file.mimetype
            );

            console.log(
                "📎 Extensão:",
                extensao
            );

            console.log(
                "========================================"
            );

            // ==================================================
            // ACEITAR
            // ==================================================

            if (
                mimePermitido ||
                extensaoPermitida
            ) {

                console.log(
                    "✅ FORMATO DA CAPA ACEITO"
                );

                cb(
                    null,
                    true
                );

                return;

            }

            // ==================================================
            // RECUSAR
            // ==================================================

            console.log(
                "❌ FORMATO DA CAPA RECUSADO"
            );

            cb(
                new Error(
                    "Formato de imagem não permitido. Use JPG, PNG ou WEBP."
                )
            );

        }

    });

// ==================================================
// FUNÇÃO AUXILIAR
// REMOVER ARQUIVO DE CAPA
// ==================================================

function removerArquivoCapa(
    capa
) {

    if (
        !capa ||
        typeof capa !== "string"
    ) {

        return;

    }

    if (
        !capa.startsWith(
            "/uploads/capas/"
        )
    ) {

        return;

    }

    const nomeArquivo =
        path.basename(
            capa
        );

    const arquivo =
        path.join(
            pastaCapas,
            nomeArquivo
        );

    try {

        if (
            fs.existsSync(
                arquivo
            )
        ) {

            fs.unlinkSync(
                arquivo
            );

            console.log(
                "🗑️ Arquivo de capa removido:",
                nomeArquivo
            );

        }

    } catch (error) {

        console.warn(
            "⚠️ Não foi possível remover arquivo da capa:",
            error.message
        );

    }

}

// ==================================================
// UPLOAD DA CAPA
// POST /api/restaurants/:id/capa
// ==================================================

exports.uploadCapa = [

    // ==================================================
    // MULTER COM TRATAMENTO DE ERRO
    // ==================================================

    (req, res, next) => {

        uploadCapa.single(
            "capa"
        )(
            req,
            res,
            (error) => {

                // ==================================================
                // SEM ERRO
                // ==================================================

                if (!error) {

                    console.log(
                        "✅ MULTER FINALIZADO"
                    );

                    return next();

                }

                console.error(
                    "========================================"
                );

                console.error(
                    "❌ ERRO DO MULTER"
                );

                console.error(
                    error
                );

                console.error(
                    "========================================"
                );

                // ==================================================
                // LIMITE DE TAMANHO
                // ==================================================

                if (
                    error.code ===
                    "LIMIT_FILE_SIZE"
                ) {

                    return res.status(400).json({

                        sucesso: false,

                        erro:
                            "A imagem da capa deve ter no máximo 5 MB."

                    });

                }

                // ==================================================
                // FORMATO INVÁLIDO
                // ==================================================

                if (
                    error.message &&
                    error.message.includes(
                        "Formato de imagem não permitido"
                    )
                ) {

                    return res.status(400).json({

                        sucesso: false,

                        erro:
                            error.message

                    });

                }

                // ==================================================
                // OUTRO ERRO DO MULTER
                // ==================================================

                return res.status(400).json({

                    sucesso: false,

                    erro:
                        error.message ||
                        "Erro ao processar a imagem da capa."

                });

            }
        );

    },

    // ==================================================
    // CONTROLLER
    // ==================================================

    async (
        req,
        res
    ) => {

        let capaUrl = null;

        try {

            const { id } =
                req.params;

            console.log(
                "========================================"
            );

            console.log(
                "🖼️ FOODJET - UPLOAD DE CAPA"
            );

            console.log(
                "RESTAURANTE:",
                id
            );

            console.log(
                "ARQUIVO:",
                req.file?.filename
            );

            console.log(
                "========================================"
            );

            // ==================================================
            // VALIDAR ID
            // ==================================================

            if (
                !id ||
                String(id).trim() === ""
            ) {

                if (
                    req.file
                ) {

                    removerArquivoCapa(
                        `/uploads/capas/${req.file.filename}`
                    );

                }

                return res.status(400).json({

                    sucesso: false,

                    erro:
                        "ID do restaurante é obrigatório"

                });

            }

            // ==================================================
            // VALIDAR ARQUIVO
            // ==================================================

            if (
                !req.file
            ) {

                return res.status(400).json({

                    sucesso: false,

                    erro:
                        "Nenhuma imagem de capa foi enviada"

                });

            }

            // ==================================================
            // BUSCAR RESTAURANTE
            // ==================================================

            console.log(
                "🔎 Buscando restaurante..."
            );

            const restaurante =
                await Restaurant.buscarPorId(
                    id
                );

            console.log(
                "✅ Restaurante encontrado:",
                !!restaurante
            );

            if (
                !restaurante
            ) {

                removerArquivoCapa(
                    `/uploads/capas/${req.file.filename}`
                );

                return res.status(404).json({

                    sucesso: false,

                    erro:
                        "Restaurante não encontrado"

                });

            }

            // ==================================================
            // CAPA ANTIGA
            // ==================================================

            const capaAntiga =
                restaurante.capa;

            // ==================================================
            // URL DA NOVA CAPA
            // ==================================================

            capaUrl =
                `/uploads/capas/${req.file.filename}`;

            console.log(
                "📁 Caminho da nova capa:",
                capaUrl
            );

            // ==================================================
            // SALVAR NO POSTGRESQL
            // ==================================================

            console.log(
                "💾 Salvando capa no PostgreSQL..."
            );

            const restauranteAtualizado =
                await Restaurant.atualizar(

                    id,

                    {
                        capa:
                            capaUrl
                    }

                );

            console.log(
                "✅ PostgreSQL atualizado"
            );

            if (
                !restauranteAtualizado
            ) {

                removerArquivoCapa(
                    capaUrl
                );

                return res.status(404).json({

                    sucesso: false,

                    erro:
                        "Restaurante não encontrado"

                });

            }

            // ==================================================
            // REMOVER CAPA ANTIGA
            // ==================================================

            if (
                capaAntiga &&
                capaAntiga !== capaUrl
            ) {

                console.log(
                    "🗑️ Removendo capa antiga..."
                );

                removerArquivoCapa(
                    capaAntiga
                );

            }

            // ==================================================
            // PREPARAR RESPOSTA
            // ==================================================

            const resposta = {

                sucesso: true,

                mensagem:
                    "Capa do restaurante enviada com sucesso",

                capa:
                    capaUrl,

                restaurante:
                    restauranteAtualizado

            };

            // ==================================================
            // RESPONDER AO FLUTTER PRIMEIRO
            // ==================================================

            console.log(
                "📤 Enviando resposta para o Flutter..."
            );

            res.status(200).json(
                resposta
            );

            console.log(
                "✅ RESPOSTA HTTP ENVIADA AO FLUTTER"
            );

            // ==================================================
            // WEBSOCKET
            //
            // A resposta HTTP já foi enviada.
            // Qualquer problema no Socket.IO não deve
            // impedir o upload.
            // ==================================================

            try {

                if (
                    global.io
                ) {

                    console.log(
                        "📡 Enviando atualização pelo WebSocket..."
                    );

                    global.io.emit(
                        "restaurante_atualizado",
                        restauranteAtualizado
                    );

                    console.log(
                        "📡 RESTAURANTE ATUALIZADO ENVIADO AOS CLIENTES"
                    );

                    console.log(
                        "📡 NOVA CAPA ENVIADA AOS CLIENTES"
                    );

                }

            } catch (socketError) {

                console.error(
                    "⚠️ Erro no WebSocket após resposta HTTP:",
                    socketError.message
                );

            }

            return;

        } catch (error) {

            console.error(
                "========================================"
            );

            console.error(
                "❌ ERRO AO ENVIAR CAPA"
            );

            console.error(
                error
            );

            console.error(
                "========================================"
            );

            // ==================================================
            // APAGAR ARQUIVO SE HOUVE ERRO
            // ==================================================

            if (
                req.file &&
                capaUrl
            ) {

                removerArquivoCapa(
                    capaUrl
                );

            } else if (
                req.file
            ) {

                removerArquivoCapa(
                    `/uploads/capas/${req.file.filename}`
                );

            }

            // ==================================================
            // LIMITE DE TAMANHO
            // ==================================================

            if (
                error.code ===
                "LIMIT_FILE_SIZE"
            ) {

                return res.status(400).json({

                    sucesso: false,

                    erro:
                        "A imagem da capa deve ter no máximo 5 MB."

                });

            }

            // ==================================================
            // FORMATO INVÁLIDO
            // ==================================================

            if (
                error.message &&
                error.message.includes(
                    "Formato de imagem não permitido"
                )
            ) {

                return res.status(400).json({

                    sucesso: false,

                    erro:
                        error.message

                });

            }

            // ==================================================
            // RESPOSTA DE ERRO
            // ==================================================

            if (
                !res.headersSent
            ) {

                return res.status(500).json({

                    sucesso: false,

                    erro:
                        error.message ||
                        "Erro ao enviar capa"

                });

            }

        }

    }

];

// ==================================================
// REMOVER CAPA
// DELETE /api/restaurants/:id/capa
// ==================================================

exports.deleteCapa = async (
    req,
    res
) => {

    try {

        const { id } =
            req.params;

        console.log(
            "========================================"
        );

        console.log(
            "🗑️ FOODJET - REMOVER CAPA"
        );

        console.log(
            "RESTAURANTE:",
            id
        );

        console.log(
            "========================================"
        );

        // ==================================================
        // VALIDAR ID
        // ==================================================

        if (
            !id ||
            String(id).trim() === ""
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do restaurante é obrigatório"

            });

        }

        // ==================================================
        // BUSCAR RESTAURANTE
        // ==================================================

        const restaurante =
            await Restaurant.buscarPorId(
                id
            );

        if (
            !restaurante
        ) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Restaurante não encontrado"

            });

        }

        // ==================================================
        // GUARDAR CAPA ANTIGA
        // ==================================================

        const capaAntiga =
            restaurante.capa;

        // ==================================================
        // REMOVER CAPA DO BANCO
        // ==================================================

        const restauranteAtualizado =
            await Restaurant.atualizar(

                id,

                {
                    capa: null
                }

            );

        if (
            !restauranteAtualizado
        ) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Restaurante não encontrado"

            });

        }

        // ==================================================
        // REMOVER ARQUIVO DO SERVIDOR
        // ==================================================

        if (
            capaAntiga
        ) {

            removerArquivoCapa(
                capaAntiga
            );

        }

        // ==================================================
        // AVISAR CLIENTES
        // ==================================================

        if (
            global.io
        ) {

            global.io.emit(
                "restaurante_atualizado",
                restauranteAtualizado
            );

            console.log(
                "📡 REMOÇÃO DA CAPA ENVIADA AOS CLIENTES"
            );

        }

        // ==================================================
        // RESPOSTA
        // ==================================================

        return res.status(200).json({

            sucesso: true,

            mensagem:
                "Capa removida com sucesso",

            capa: null,

            restaurante:
                restauranteAtualizado

        });

    } catch (error) {

        console.error(
            "========================================"
        );

        console.error(
            "❌ ERRO AO REMOVER CAPA"
        );

        console.error(
            error
        );

        console.error(
            "========================================"
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao remover capa",

            detalhe:
                error.message

        });

    }

};

// ==================================================
// CRIAR RESTAURANTE
// ==================================================

exports.create = async (
    req,
    res
) => {

    try {

        const restaurante = {

            id:
                Date.now(),

            nome:
                req.body.nome || "",

            categoria:
                req.body.categoria || "",

            descricao:
                req.body.descricao || "",

            telefone:
                req.body.telefone || "",

            endereco:
                req.body.endereco || "",

            taxaEntrega:
                Number(
                    req.body.taxaEntrega
                ) || 0,

            tempoEntrega:
                req.body.tempoEntrega || "",

            capa:
                req.body.capa || null,

            status:
                "ABERTO",

            online:
                true,

            aberto:
                true,

            aceitarAutomatico:
                req.body.aceitarAutomatico !== false,

            criadoEm:
                new Date().toISOString()

        };

        await Restaurant.criar(
            restaurante
        );

        return res.status(201).json({

            sucesso: true,

            mensagem:
                "Restaurante cadastrado com sucesso",

            restaurante

        });

    } catch (error) {

        console.error(
            "ERRO CREATE RESTAURANTE:",
            error
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao cadastrar restaurante",

            detalhe:
                error.message

        });

    }

};

// ==================================================
// LISTAR RESTAURANTES
// ==================================================

exports.list = async (
    req,
    res
) => {

    try {

        let lista =
            await Restaurant.listar();

        if (
            !Array.isArray(lista)
        ) {

            lista = [];

        }

        // ==================================================
        // PROMOÇÕES
        // ==================================================

        let promocoes = [];

        try {

            const Promotion =
                require(
                    "../models/promotion"
                );

            promocoes =
                await Promotion.listar();

            if (
                !Array.isArray(
                    promocoes
                )
            ) {

                promocoes = [];

            }

        } catch (error) {

            console.log(
                "ℹ️ Sem promoções carregadas:",
                error.message
            );

            promocoes = [];

        }

        const agora =
            new Date();

        lista =
            lista.map(
                (
                    restaurante
                ) => {

                    let prioridade = 0;

                    let destaque = false;

                    let tipoDestaque = null;

                    let promocao = null;

                    const promocaoEncontrada =
                        promocoes.find(
                            (p) =>
                                String(
                                    p.restauranteId
                                ) ===
                                String(
                                    restaurante.id
                                ) &&
                                p.ativa === true
                        );

                    if (
                        promocaoEncontrada
                    ) {

                        let valida = true;

                        if (
                            promocaoEncontrada.expiraEm
                        ) {

                            const validade =
                                new Date(
                                    promocaoEncontrada.expiraEm
                                );

                            if (
                                Number.isNaN(
                                    validade.getTime()
                                )
                            ) {

                                valida = false;

                            } else if (
                                validade <= agora
                            ) {

                                valida = false;

                            }

                        }

                        if (
                            valida
                        ) {

                            promocao =
                                promocaoEncontrada;

                            destaque = true;

                            tipoDestaque =
                                promocaoEncontrada.tipo;

                            if (
                                tipoDestaque ===
                                "TOP1"
                            ) {

                                prioridade = 3;

                            } else if (
                                tipoDestaque ===
                                "DESTAQUE"
                            ) {

                                prioridade = 2;

                            } else if (
                                tipoDestaque ===
                                "IMPULSO"
                            ) {

                                prioridade = 1;

                            }

                        }

                    }

                    return {

                        ...restaurante,

                        promocao,

                        destaque,

                        tipoDestaque,

                        prioridade,

                        selo:
                            destaque
                                ? "Patrocinado FoodJet"
                                : null

                    };

                }
            );

        // ==================================================
        // ORDENAR
        // ==================================================

        lista.sort(
            (a, b) =>
                b.prioridade -
                a.prioridade
        );

        return res.json(
            lista
        );

    } catch (error) {

        console.error(
            "ERRO LISTAR RESTAURANTES:",
            error
        );

        return res.status(500).json({

            erro:
                "Erro ao listar restaurantes",

            detalhe:
                error.message

        });

    }

};

// ==================================================
// BUSCAR RESTAURANTE POR ID
// GET /api/restaurants/:id
// ==================================================

exports.getById = async (
    req,
    res
) => {

    try {

        const { id } =
            req.params;

        if (
            !id ||
            String(id).trim() === ""
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do restaurante é obrigatório"

            });

        }

        const restaurante =
            await Restaurant.buscarPorId(
                id
            );

        if (
            !restaurante
        ) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Restaurante não encontrado"

            });

        }

        return res.json(
            restaurante
        );

    } catch (error) {

        console.error(
            "ERRO AO BUSCAR RESTAURANTE:",
            error
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao buscar restaurante",

            detalhe:
                error.message

        });

    }

};

// ==================================================
// ATUALIZAR RESTAURANTE
// PUT /api/restaurants/:id
// ==================================================

exports.update = async (
    req,
    res
) => {

    try {

        const { id } =
            req.params;

        if (
            !id ||
            String(id).trim() === ""
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do restaurante é obrigatório"

            });

        }

        console.log(
            "========================================"
        );

        console.log(
            "⚙️ ATUALIZANDO RESTAURANTE"
        );

        console.log(
            "ID:",
            id
        );

        console.log(
            "DADOS:",
            req.body
        );

        console.log(
            "========================================"
        );

        const restaurante =
            await Restaurant.atualizar(
                id,
                req.body
            );

        if (
            !restaurante
        ) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Restaurante não encontrado"

            });

        }

        if (
            global.io
        ) {

            global.io.emit(
                "restaurante_atualizado",
                restaurante
            );

            console.log(
                "📡 RESTAURANTE ATUALIZADO ENVIADO AOS CLIENTES"
            );

        }

        return res.json({

            sucesso: true,

            mensagem:
                "Restaurante atualizado com sucesso",

            restaurante

        });

    } catch (error) {

        console.error(
            "ERRO AO ATUALIZAR RESTAURANTE:",
            error
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao atualizar restaurante",

            detalhe:
                error.message

        });

    }

};

// ==================================================
// EXCLUIR RESTAURANTE
// DELETE /api/restaurants/:id
// ==================================================

exports.delete = async (
    req,
    res
) => {

    try {

        const { id } =
            req.params;

        console.log(
            "========================================"
        );

        console.log(
            "🗑️ EXCLUSÃO COMPLETA DE CONTA"
        );

        console.log(
            "RESTAURANTE ID:",
            id
        );

        console.log(
            "========================================"
        );

        if (
            !id ||
            String(id).trim() === ""
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do restaurante é obrigatório"

            });

        }

        // ==================================================
        // BUSCAR RESTAURANTE
        // ==================================================

        const restaurante =
            await Restaurant.buscarPorId(
                id
            );

        if (
            !restaurante
        ) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Restaurante não encontrado"

            });

        }

        // ==================================================
        // GUARDAR CAPA
        // ==================================================

        const capa =
            restaurante.capa;

        // ==================================================
        // EXCLUIR DADOS
        // ==================================================

        const resultado =
            await Restaurant.excluir(
                id
            );

        if (
            !resultado ||
            resultado.sucesso !== true
        ) {

            return res.status(500).json({

                sucesso: false,

                erro:
                    "Não foi possível excluir a conta do restaurante"

            });

        }

        // ==================================================
        // REMOVER CAPA DO SERVIDOR
        // ==================================================

        if (
            capa
        ) {

            removerArquivoCapa(
                capa
            );

        }

        console.log(
            "✅ EXCLUSÃO CONCLUÍDA"
        );

        console.log(
            "Restaurante:",
            resultado.removidos?.restaurante
        );

        console.log(
            "Produtos:",
            resultado.removidos?.produtos
        );

        console.log(
            "Pedidos:",
            resultado.removidos?.pedidos
        );

        console.log(
            "Pagamentos:",
            resultado.removidos?.pagamentos
        );

        console.log(
            "Outros:",
            resultado.removidos?.outros
        );

        console.log(
            "========================================"
        );

        // ==================================================
        // WEBSOCKET
        // ==================================================

        if (
            global.io
        ) {

            global.io.emit(
                "restaurante_excluido",
                {
                    restauranteId:
                        String(id)
                }
            );

            console.log(
                "📡 EXCLUSÃO ENVIADA AOS CLIENTES"
            );

        }

        return res.status(200).json({

            sucesso: true,

            mensagem:
                "Conta e dados vinculados ao restaurante foram excluídos com sucesso",

            restauranteId:
                String(id),

            removidos:
                resultado.removidos

        });

    } catch (error) {

        console.error(
            "========================================"
        );

        console.error(
            "❌ ERRO AO EXCLUIR RESTAURANTE"
        );

        console.error(
            error
        );

        console.error(
            "========================================"
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro interno ao excluir a conta do restaurante",

            detalhe:
                error.message

        });

    }

};

// ==================================================
// ONLINE / OFFLINE
// PUT /api/restaurants/:id/status
// ==================================================

exports.updateStatus = async (
    req,
    res
) => {

    try {

        const { id } =
            req.params;

        if (
            !id ||
            String(id).trim() === ""
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do restaurante é obrigatório"

            });

        }

        console.log(
            "========================================"
        );

        console.log(
            "🔄 ALTERANDO STATUS DO RESTAURANTE"
        );

        console.log(
            "ID:",
            id
        );

        console.log(
            "DADOS:",
            req.body
        );

        console.log(
            "========================================"
        );

        const dados = {};

        // ==================================================
        // ONLINE
        // ==================================================

        if (
            req.body.online !== undefined
        ) {

            dados.online =
                req.body.online === true ||
                req.body.online === "true";

        }

        // ==================================================
        // ABERTO
        // ==================================================

        if (
            req.body.aberto !== undefined
        ) {

            dados.aberto =
                req.body.aberto === true ||
                req.body.aberto === "true";

        }

        // ==================================================
        // STATUS
        // ==================================================

        if (
            req.body.status !== undefined
        ) {

            dados.status =
                req.body.status;

        }

        // ==================================================
        // NADA INFORMADO
        // ==================================================

        if (
            Object.keys(
                dados
            ).length === 0
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "Nenhum status foi informado"

            });

        }

        const restaurante =
            await Restaurant.atualizar(
                id,
                dados
            );

        if (
            !restaurante
        ) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Restaurante não encontrado"

            });

        }

        // ==================================================
        // WEBSOCKET
        // ==================================================

        if (
            global.io
        ) {

            global.io.emit(
                "restaurante_atualizado",
                restaurante
            );

            console.log(
                "📡 STATUS ENVIADO AOS CLIENTES"
            );

        }

        return res.json({

            sucesso: true,

            mensagem:
                "Status do restaurante atualizado com sucesso",

            restaurante

        });

    } catch (error) {

        console.error(
            "========================================"
        );

        console.error(
            "❌ ERRO AO ALTERAR STATUS"
        );

        console.error(
            error
        );

        console.error(
            "========================================"
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao alterar status do restaurante",

            detalhe:
                error.message

        });

    }

};

// ============================================================
// PROMOÇÕES
// ============================================================

let promocoes = [];

// ============================================================
// CARREGAR PROMOÇÕES
// ============================================================

async function carregarPromocoes() {

    try {

        const Promotion =
            require(
                "../models/promotion"
            );

        promocoes =
            await Promotion.listar();

        if (
            !Array.isArray(
                promocoes
            )
        ) {

            promocoes = [];

        }

        console.log(
            `✅ ${promocoes.length} promoções carregadas`
        );

        return promocoes;

    } catch (error) {

        console.log(
            "ℹ️ Sem promoções carregadas:",
            error.message
        );

        promocoes = [];

        return promocoes;

    }

}