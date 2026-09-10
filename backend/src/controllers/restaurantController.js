
const Restaurant = require("../models/restaurant");
const multer = require("multer");
const cloudinary = require("cloudinary").v2;

// ============================================================
// CLOUDINARY
// ============================================================

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

// ============================================================
// VALIDAR CONFIGURAÇÃO CLOUDINARY
// ============================================================

function validarCloudinary() {
    const faltando = [];

    if (!process.env.CLOUDINARY_CLOUD_NAME) {
        faltando.push("CLOUDINARY_CLOUD_NAME");
    }

    if (!process.env.CLOUDINARY_API_KEY) {
        faltando.push("CLOUDINARY_API_KEY");
    }

    if (!process.env.CLOUDINARY_API_SECRET) {
        faltando.push("CLOUDINARY_API_SECRET");
    }

    if (faltando.length > 0) {
        throw new Error(
            `Cloudinary não configurado. Variáveis ausentes: ${faltando.join(", ")}`
        );
    }
}

// ============================================================
// NORMALIZAR URL
// ============================================================

function normalizarImagem(valor) {
    if (!valor) {
        return null;
    }

    const texto = String(valor).trim();

    if (!texto) {
        return null;
    }

    if (
        texto.startsWith("https://") ||
        texto.startsWith("http://") ||
        texto.startsWith("data:image/")
    ) {
        return texto;
    }

    // Caminho antigo
    if (texto.startsWith("/")) {
        return texto;
    }

    return `/${texto}`;
}

// ============================================================
// MULTER - MEMÓRIA
// ============================================================

const storage = multer.memoryStorage();

// ============================================================
// FILTRO DE IMAGEM
// ============================================================

function filtroImagem(req, file, cb) {
    const tiposPermitidos = [
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp",
        "image/pjpeg",
        "image/x-png",
    ];

    const mimetype = String(file.mimetype || "")
        .toLowerCase()
        .trim();

    const nomeArquivo = String(file.originalname || "")
        .toLowerCase()
        .trim();

    const extensaoPermitida =
        nomeArquivo.endsWith(".jpg") ||
        nomeArquivo.endsWith(".jpeg") ||
        nomeArquivo.endsWith(".png") ||
        nomeArquivo.endsWith(".webp");

    console.log("========================================");
    console.log("🔎 FOODJET - VALIDANDO IMAGEM");
    console.log("📁 Arquivo:", file.originalname);
    console.log("📦 MIME:", file.mimetype);
    console.log("📎 Extensão válida:", extensaoPermitida);
    console.log("========================================");

    // MIME conhecido
    if (tiposPermitidos.includes(mimetype)) {
        cb(null, true);
        return;
    }

    // Flutter Web/navegador pode não informar MIME
    if (!mimetype && extensaoPermitida) {
        console.log("⚠️ MIME vazio, aceitando pela extensão.");
        cb(null, true);
        return;
    }

    // Alguns navegadores enviam octet-stream
    if (
        mimetype === "application/octet-stream" &&
        extensaoPermitida
    ) {
        console.log(
            "⚠️ application/octet-stream, aceitando pela extensão."
        );

        cb(null, true);
        return;
    }

    cb(
        new Error(
            `Formato de imagem não permitido. MIME recebido: ${
                file.mimetype || "vazio"
            }. Use JPG, JPEG, PNG ou WEBP.`
        )
    );
}

// ============================================================
// MULTER LOGO
// ============================================================

const uploadLogo = multer({
    storage,
    fileFilter: filtroImagem,
    limits: {
        fileSize: 5 * 1024 * 1024,
    },
});

// ============================================================
// MULTER CAPA
// ============================================================

const uploadCapa = multer({
    storage,
    fileFilter: filtroImagem,
    limits: {
        fileSize: 10 * 1024 * 1024,
    },
});

// ============================================================
// TRATAMENTO DE ERRO DO MULTER
// ============================================================

function tratarErroUpload(error, res, tipo) {
    if (!error) {
        return false;
    }

    console.error("========================================");
    console.error(`❌ ERRO NO UPLOAD DA ${tipo.toUpperCase()}`);
    console.error("Tipo:", error.name);
    console.error("Mensagem:", error.message);
    console.error("Código:", error.code || "N/A");
    console.error("========================================");

    if (error instanceof multer.MulterError) {
        let mensagem = error.message;

        if (error.code === "LIMIT_FILE_SIZE") {
            mensagem =
                tipo === "logo"
                    ? "A logo não pode ultrapassar 5 MB."
                    : "A capa não pode ultrapassar 10 MB.";
        }

        res.status(400).json({
            sucesso: false,
            mensagem,
            erro: "MULTER_ERROR",
            codigo: error.code,
        });

        return true;
    }

    res.status(400).json({
        sucesso: false,
        mensagem: error.message || "Erro ao processar imagem.",
        erro: "UPLOAD_ERROR",
    });

    return true;
}

// ============================================================
// UPLOAD BUFFER PARA CLOUDINARY
// ============================================================

function enviarBufferCloudinary(buffer, pasta, publicId) {
    return new Promise((resolve, reject) => {
        validarCloudinary();

        if (!buffer || !Buffer.isBuffer(buffer)) {
            reject(
                new Error(
                    "Buffer da imagem inválido ou vazio."
                )
            );

            return;
        }

        const stream =
            cloudinary.uploader.upload_stream(
                {
                    folder: pasta,
                    public_id: publicId,
                    resource_type: "image",
                    overwrite: true,
                    invalidate: true,
                },
                (error, resultado) => {
                    if (error) {
                        reject(error);
                        return;
                    }

                    resolve(resultado);
                }
            );

        stream.end(buffer);
    });
}

// ============================================================
// UPLOAD BASE64 PARA CLOUDINARY
// ============================================================

async function enviarBase64Cloudinary(
    base64,
    pasta,
    publicId
) {
    validarCloudinary();

    if (!base64) {
        return null;
    }

    if (
        typeof base64 !== "string" ||
        !base64.startsWith("data:image/")
    ) {
        return base64;
    }

    const resultado =
        await cloudinary.uploader.upload(
            base64,
            {
                folder: pasta,
                public_id: publicId,
                resource_type: "image",
                overwrite: true,
                invalidate: true,
            }
        );

    return resultado.secure_url;
}

// ============================================================
// OBTER PUBLIC ID CLOUDINARY
// ============================================================

function obterPublicIdCloudinary(url) {
    if (!url || typeof url !== "string") {
        return null;
    }

    if (
        !url.includes("res.cloudinary.com") ||
        !url.includes("/image/upload/")
    ) {
        return null;
    }

    try {
        const urlObj = new URL(url);
        const caminho = urlObj.pathname;

        const marcador = "/image/upload/";
        const posicao = caminho.indexOf(marcador);

        if (posicao === -1) {
            return null;
        }

        let publicId =
            caminho.substring(
                posicao + marcador.length
            );

        const partes = publicId.split("/");

        // Remove transformações Cloudinary
        if (partes.length > 0) {
            const primeiro = partes[0] || "";

            if (
                primeiro.includes(",") ||
                primeiro.includes("w_") ||
                primeiro.includes("h_") ||
                primeiro.includes("c_") ||
                primeiro.includes("q_") ||
                primeiro.includes("f_")
            ) {
                partes.shift();

                publicId = partes.join("/");
            }
        }

        // Remove extensão
        publicId = publicId.replace(
            /\.[^/.]+$/,
            ""
        );

        return publicId || null;
    } catch (error) {
        console.log(
            "⚠️ Não foi possível obter public_id:",
            error.message
        );

        return null;
    }
}

// ============================================================
// REMOVER IMAGEM DO CLOUDINARY
// ============================================================

async function removerImagemCloudinary(url) {
    if (!url) {
        return;
    }

    const publicId =
        obterPublicIdCloudinary(url);

    if (!publicId) {
        return;
    }

    try {
        validarCloudinary();

        await cloudinary.uploader.destroy(
            publicId,
            {
                resource_type: "image",
                invalidate: true,
            }
        );

        console.log(
            "🗑️ IMAGEM REMOVIDA DO CLOUDINARY:",
            publicId
        );
    } catch (error) {
        console.log(
            "⚠️ Erro ao remover imagem do Cloudinary:",
            error.message
        );
    }
}

// ============================================================
// EMITIR EVENTOS
// ============================================================

function emitirAtualizacaoRestaurante(
    req,
    restaurante
) {
    try {
        const io = req.app.get("io");

        if (!io || !restaurante) {
            return;
        }

        const restauranteId =
            String(restaurante.id);

        io.to(
            `restaurante_${restauranteId}`
        ).emit(
            "restaurante_atualizado",
            restaurante
        );

        io.emit(
            "restaurante_atualizado",
            restaurante
        );
    } catch (error) {
        console.log(
            "⚠️ Erro ao emitir atualização:",
            error.message
        );
    }
}

// ============================================================
// CRIAR RESTAURANTE
// ============================================================

exports.create = async (req, res) => {
    try {
        const body = req.body || {};

        const id =
            body.id
                ? String(body.id)
                : `rest_${Date.now()}`;

        let imagem =
            body.imagem ||
            body.logo ||
            body.foto ||
            null;

        let capa =
            body.capa ||
            body.banner ||
            null;

        // ====================================================
        // LOGO BASE64
        // ====================================================

        if (
            imagem &&
            typeof imagem === "string" &&
            imagem.startsWith("data:image/")
        ) {
            imagem =
                await enviarBase64Cloudinary(
                    imagem,
                    "foodjet/restaurantes/logos",
                    `logo_${id}`
                );
        }

        // ====================================================
        // CAPA BASE64
        // ====================================================

        if (
            capa &&
            typeof capa === "string" &&
            capa.startsWith("data:image/")
        ) {
            capa =
                await enviarBase64Cloudinary(
                    capa,
                    "foodjet/restaurantes/capas",
                    `capa_${id}`
                );
        }

        const restaurante =
            await Restaurant.criar({
                ...body,
                id,
                imagem,
                capa,
            });

        console.log(
            "============================================"
        );

        console.log(
            "🏪 RESTAURANTE CRIADO"
        );

        console.log(
            "ID:",
            restaurante.id
        );

        console.log(
            "LOGO:",
            restaurante.imagem
        );

        console.log(
            "CAPA:",
            restaurante.capa
        );

        console.log(
            "============================================"
        );

        res.status(201).json({
            sucesso: true,
            restaurante,
        });
    } catch (error) {
        console.error(
            "❌ ERRO AO CRIAR RESTAURANTE:",
            error
        );

        res.status(500).json({
            sucesso: false,
            mensagem:
                "Erro ao criar restaurante.",
            detalhes:
                error.message,
        });
    }
};

// ============================================================
// LISTAR RESTAURANTES
// ============================================================

exports.list = async (req, res) => {
    try {
        const restaurantes =
            await Restaurant.listar();

        const resultado =
            restaurantes.map(
                (restaurante) => ({
                    ...restaurante,

                    imagem:
                        normalizarImagem(
                            restaurante.imagem
                        ),

                    logo:
                        normalizarImagem(
                            restaurante.imagem
                        ),

                    capa:
                        normalizarImagem(
                            restaurante.capa
                        ),
                })
            );

        res.json({
            sucesso: true,
            restaurantes: resultado,
        });
    } catch (error) {
        console.error(
            "❌ ERRO AO LISTAR RESTAURANTES:",
            error
        );

        res.status(500).json({
            sucesso: false,
            mensagem:
                "Erro ao listar restaurantes.",
            detalhes:
                error.message,
        });
    }
};

// ============================================================
// BUSCAR RESTAURANTE POR ID
// ============================================================

exports.getById = async (req, res) => {
    try {
        const id = req.params.id;

        if (!id) {
            return res.status(400).json({
                sucesso: false,
                mensagem:
                    "ID do restaurante é obrigatório.",
            });
        }

        const restaurante =
            await Restaurant.buscarPorId(id);

        if (!restaurante) {
            return res.status(404).json({
                sucesso: false,
                mensagem:
                    "Restaurante não encontrado.",
            });
        }

        const resultado = {
            ...restaurante,

            imagem:
                normalizarImagem(
                    restaurante.imagem
                ),

            logo:
                normalizarImagem(
                    restaurante.imagem
                ),

            capa:
                normalizarImagem(
                    restaurante.capa
                ),
        };

        res.json({
            sucesso: true,
            restaurante: resultado,
        });
    } catch (error) {
        console.error(
            "❌ ERRO AO BUSCAR RESTAURANTE:",
            error
        );

        res.status(500).json({
            sucesso: false,
            mensagem:
                "Erro ao buscar restaurante.",
            detalhes:
                error.message,
        });
    }
};

// ============================================================
// ATUALIZAR RESTAURANTE
// ============================================================

exports.update = async (req, res) => {
    try {
        const id = req.params.id;

        if (!id) {
            return res.status(400).json({
                sucesso: false,
                mensagem:
                    "ID do restaurante é obrigatório.",
            });
        }

        const restauranteAtual =
            await Restaurant.buscarPorId(id);

        if (!restauranteAtual) {
            return res.status(404).json({
                sucesso: false,
                mensagem:
                    "Restaurante não encontrado.",
            });
        }

        const dados =
            req.body || {};

        const dadosAtualizados = {
            ...dados,
        };

        // ====================================================
        // LOGO BASE64
        // ====================================================

        let imagem =
            dadosAtualizados.imagem ||
            dadosAtualizados.logo ||
            null;

        if (
            imagem &&
            typeof imagem === "string" &&
            imagem.startsWith("data:image/")
        ) {
            const novaImagem =
                await enviarBase64Cloudinary(
                    imagem,
                    "foodjet/restaurantes/logos",
                    `logo_${id}`
                );

            dadosAtualizados.imagem =
                novaImagem;
        } else if (
            dadosAtualizados.logo &&
            !dadosAtualizados.imagem
        ) {
            dadosAtualizados.imagem =
                dadosAtualizados.logo;
        }

        // ====================================================
        // CAPA BASE64
        // ====================================================

        let capa =
            dadosAtualizados.capa ||
            dadosAtualizados.banner ||
            null;

        if (
            capa &&
            typeof capa === "string" &&
            capa.startsWith("data:image/")
        ) {
            const novaCapa =
                await enviarBase64Cloudinary(
                    capa,
                    "foodjet/restaurantes/capas",
                    `capa_${id}`
                );

            dadosAtualizados.capa =
                novaCapa;
        } else if (
            dadosAtualizados.banner &&
            !dadosAtualizados.capa
        ) {
            dadosAtualizados.capa =
                dadosAtualizados.banner;
        }

        const restaurante =
            await Restaurant.atualizar(
                id,
                dadosAtualizados
            );

        if (!restaurante) {
            return res.status(404).json({
                sucesso: false,
                mensagem:
                    "Restaurante não encontrado.",
            });
        }

        const resultado = {
            ...restaurante,

            imagem:
                normalizarImagem(
                    restaurante.imagem
                ),

            logo:
                normalizarImagem(
                    restaurante.imagem
                ),

            capa:
                normalizarImagem(
                    restaurante.capa
                ),
        };

        emitirAtualizacaoRestaurante(
            req,
            resultado
        );

        res.json({
            sucesso: true,
            mensagem:
                "Restaurante atualizado com sucesso.",
            restaurante: resultado,
        });
    } catch (error) {
        console.error(
            "❌ ERRO AO ATUALIZAR RESTAURANTE:",
            error
        );

        res.status(500).json({
            sucesso: false,
            mensagem:
                "Erro ao atualizar restaurante.",
            detalhes:
                error.message,
        });
    }
};

// ============================================================
// ATUALIZAR STATUS
// ============================================================

exports.updateStatus = async (req, res) => {
    try {
        const id = req.params.id;
        const status =
            req.body?.status;

        if (!id) {
            return res.status(400).json({
                sucesso: false,
                mensagem:
                    "ID do restaurante é obrigatório.",
            });
        }

        if (!status) {
            return res.status(400).json({
                sucesso: false,
                mensagem:
                    "Status é obrigatório.",
            });
        }

        const restaurante =
            await Restaurant.atualizarStatus(
                id,
                status
            );

        if (!restaurante) {
            return res.status(404).json({
                sucesso: false,
                mensagem:
                    "Restaurante não encontrado.",
            });
        }

        const resultado = {
            ...restaurante,

            imagem:
                normalizarImagem(
                    restaurante.imagem
                ),

            logo:
                normalizarImagem(
                    restaurante.imagem
                ),

            capa:
                normalizarImagem(
                    restaurante.capa
                ),
        };

        emitirAtualizacaoRestaurante(
            req,
            resultado
        );

        res.json({
            sucesso: true,
            mensagem:
                "Status atualizado com sucesso.",
            restaurante: resultado,
        });
    } catch (error) {
        console.error(
            "❌ ERRO AO ATUALIZAR STATUS:",
            error
        );

        res.status(500).json({
            sucesso: false,
            mensagem:
                "Erro ao atualizar status.",
            detalhes:
                error.message,
        });
    }
};

// ============================================================
// UPLOAD DA LOGO
// ============================================================

exports.uploadLogo = [
    function (req, res, next) {
        uploadLogo.single("logo")(
            req,
            res,
            function (error) {
                if (error) {
                    tratarErroUpload(
                        error,
                        res,
                        "logo"
                    );
                    return;
                }

                next();
            }
        );
    },

    async (req, res) => {
        try {
            validarCloudinary();

            const id =
                req.params.id;

            if (!id) {
                return res.status(400).json({
                    sucesso: false,
                    mensagem:
                        "ID do restaurante é obrigatório.",
                });
            }

            if (!req.file) {
                return res.status(400).json({
                    sucesso: false,
                    mensagem:
                        "Nenhuma logo foi enviada.",
                });
            }

            const restaurante =
                await Restaurant.buscarPorId(id);

            if (!restaurante) {
                return res.status(404).json({
                    sucesso: false,
                    mensagem:
                        "Restaurante não encontrado.",
                });
            }

            console.log(
                "========================================"
            );

            console.log(
                "☁️ FOODJET - ENVIANDO LOGO PARA CLOUDINARY"
            );

            console.log(
                "🏪 Restaurante:",
                id
            );

            console.log(
                "📁 Arquivo:",
                req.file.originalname
            );

            console.log(
                "📦 MIME:",
                req.file.mimetype
            );

            console.log(
                "📦 Tamanho:",
                req.file.size
            );

            console.log(
                "========================================"
            );

            const resultadoCloudinary =
                await enviarBufferCloudinary(
                    req.file.buffer,
                    "foodjet/restaurantes/logos",
                    `logo_${id}`
                );

            const logoUrl =
                resultadoCloudinary.secure_url;

            if (!logoUrl) {
                throw new Error(
                    "Cloudinary não retornou a URL da logo."
                );
            }

            console.log(
                "☁️ URL CLOUDINARY:",
                logoUrl
            );

            // =================================================
            // SALVAR NO POSTGRESQL
            // =================================================

            const atualizado =
                await Restaurant.atualizar(
                    id,
                    {
                        imagem: logoUrl,
                    }
                );

            if (!atualizado) {
                return res.status(404).json({
                    sucesso: false,
                    mensagem:
                        "Restaurante não encontrado.",
                });
            }

            const resposta = {
                ...atualizado,

                imagem: logoUrl,

                logo: logoUrl,

                capa:
                    normalizarImagem(
                        atualizado.capa
                    ),
            };

            emitirAtualizacaoRestaurante(
                req,
                resposta
            );

            console.log(
                "========================================"
            );

            console.log(
                "✅ LOGO SALVA NO CLOUDINARY"
            );

            console.log(
                logoUrl
            );

            console.log(
                "========================================"
            );

            res.json({
                sucesso: true,
                mensagem:
                    "Logo atualizada com sucesso.",
                logo: logoUrl,
                imagem: logoUrl,
                restaurante: resposta,
            });
        } catch (error) {
            console.error(
                "❌ ERRO AO ENVIAR LOGO:",
                error
            );

            res.status(500).json({
                sucesso: false,
                mensagem:
                    "Erro ao enviar logo.",
                detalhes:
                    error.message,
            });
        }
    },
];

// ============================================================
// REMOVER LOGO
// ============================================================

exports.deleteLogo = async (req, res) => {
    try {
        validarCloudinary();

        const id =
            req.params.id;

        const restaurante =
            await Restaurant.buscarPorId(id);

        if (!restaurante) {
            return res.status(404).json({
                sucesso: false,
                mensagem:
                    "Restaurante não encontrado.",
            });
        }

        const imagemAntiga =
            restaurante.imagem ||
            restaurante.logo ||
            null;

        const atualizado =
            await Restaurant.atualizar(
                id,
                {
                    imagem: null,
                }
            );

        if (imagemAntiga) {
            await removerImagemCloudinary(
                imagemAntiga
            );
        }

        const resposta = {
            ...atualizado,

            imagem: null,

            logo: null,

            capa:
                normalizarImagem(
                    atualizado.capa
                ),
        };

        emitirAtualizacaoRestaurante(
            req,
            resposta
        );

        res.json({
            sucesso: true,
            mensagem:
                "Logo removida com sucesso.",
            restaurante:
                resposta,
        });
    } catch (error) {
        console.error(
            "❌ ERRO AO REMOVER LOGO:",
            error
        );

        res.status(500).json({
            sucesso: false,
            mensagem:
                "Erro ao remover logo.",
            detalhes:
                error.message,
        });
    }
};

// ============================================================
// UPLOAD DA CAPA
// ============================================================

exports.uploadCapa = [
    function (req, res, next) {
        uploadCapa.single("capa")(
            req,
            res,
            function (error) {
                if (error) {
                    tratarErroUpload(
                        error,
                        res,
                        "capa"
                    );
                    return;
                }

                next();
            }
        );
    },

    async (req, res) => {
        try {
            validarCloudinary();

            const id =
                req.params.id;

            if (!id) {
                return res.status(400).json({
                    sucesso: false,
                    mensagem:
                        "ID do restaurante é obrigatório.",
                });
            }

            if (!req.file) {
                return res.status(400).json({
                    sucesso: false,
                    mensagem:
                        "Nenhuma capa foi enviada.",
                });
            }

            const restaurante =
                await Restaurant.buscarPorId(id);

            if (!restaurante) {
                return res.status(404).json({
                    sucesso: false,
                    mensagem:
                        "Restaurante não encontrado.",
                });
            }

            console.log(
                "========================================"
            );

            console.log(
                "☁️ FOODJET - ENVIANDO CAPA PARA CLOUDINARY"
            );

            console.log(
                "🏪 Restaurante:",
                id
            );

            console.log(
                "📁 Arquivo:",
                req.file.originalname
            );

            console.log(
                "📦 MIME:",
                req.file.mimetype
            );

            console.log(
                "📦 Tamanho:",
                req.file.size
            );

            console.log(
                "========================================"
            );

            const resultadoCloudinary =
                await enviarBufferCloudinary(
                    req.file.buffer,
                    "foodjet/restaurantes/capas",
                    `capa_${id}`
                );

            const capaUrl =
                resultadoCloudinary.secure_url;

            if (!capaUrl) {
                throw new Error(
                    "Cloudinary não retornou a URL da capa."
                );
            }

            console.log(
                "☁️ URL CLOUDINARY:",
                capaUrl
            );

            // =================================================
            // SALVAR NO POSTGRESQL
            // =================================================

            const atualizado =
                await Restaurant.atualizar(
                    id,
                    {
                        capa: capaUrl,
                    }
                );

            if (!atualizado) {
                return res.status(404).json({
                    sucesso: false,
                    mensagem:
                        "Restaurante não encontrado.",
                });
            }

            const resposta = {
                ...atualizado,

                imagem:
                    normalizarImagem(
                        atualizado.imagem
                    ),

                logo:
                    normalizarImagem(
                        atualizado.imagem
                    ),

                capa: capaUrl,
            };

            emitirAtualizacaoRestaurante(
                req,
                resposta
            );

            console.log(
                "========================================"
            );

            console.log(
                "✅ CAPA SALVA NO CLOUDINARY"
            );

            console.log(
                capaUrl
            );

            console.log(
                "========================================"
            );

            res.json({
                sucesso: true,
                mensagem:
                    "Capa atualizada com sucesso.",
                capa: capaUrl,
                restaurante:
                    resposta,
            });
        } catch (error) {
            console.error(
                "❌ ERRO AO ENVIAR CAPA:",
                error
            );

            res.status(500).json({
                sucesso: false,
                mensagem:
                    "Erro ao enviar capa.",
                detalhes:
                    error.message,
            });
        }
    },
];

// ============================================================
// REMOVER CAPA
// ============================================================

exports.deleteCapa = async (req, res) => {
    try {
        validarCloudinary();

        const id =
            req.params.id;

        const restaurante =
            await Restaurant.buscarPorId(id);

        if (!restaurante) {
            return res.status(404).json({
                sucesso: false,
                mensagem:
                    "Restaurante não encontrado.",
            });
        }

        const capaAntiga =
            restaurante.capa ||
            null;

        const atualizado =
            await Restaurant.atualizar(
                id,
                {
                    capa: null,
                }
            );

        if (capaAntiga) {
            await removerImagemCloudinary(
                capaAntiga
            );
        }

        const resposta = {
            ...atualizado,

            imagem:
                normalizarImagem(
                    atualizado.imagem
                ),

            logo:
                normalizarImagem(
                    atualizado.imagem
                ),

            capa: null,
        };

        emitirAtualizacaoRestaurante(
            req,
            resposta
        );

        res.json({
            sucesso: true,
            mensagem:
                "Capa removida com sucesso.",
            restaurante:
                resposta,
        });
    } catch (error) {
        console.error(
            "❌ ERRO AO REMOVER CAPA:",
            error
        );

        res.status(500).json({
            sucesso: false,
            mensagem:
                "Erro ao remover capa.",
            detalhes:
                error.message,
        });
    }
};

// ============================================================
// EXCLUIR RESTAURANTE
// ============================================================

exports.delete = async (req, res) => {
    try {
        const id =
            req.params.id;

        if (!id) {
            return res.status(400).json({
                sucesso: false,
                mensagem:
                    "ID do restaurante é obrigatório.",
            });
        }

        const restaurante =
            await Restaurant.buscarPorId(id);

        if (!restaurante) {
            return res.status(404).json({
                sucesso: false,
                mensagem:
                    "Restaurante não encontrado.",
            });
        }

        const imagem =
            restaurante.imagem ||
            null;

        const capa =
            restaurante.capa ||
            null;

        const resultado =
            await Restaurant.excluir(id);

        // ====================================================
        // REMOVER IMAGENS DO CLOUDINARY
        // ====================================================

        if (imagem) {
            await removerImagemCloudinary(
                imagem
            );
        }

        if (capa) {
            await removerImagemCloudinary(
                capa
            );
        }

        res.json({
            sucesso: true,
            mensagem:
                "Restaurante excluído com sucesso.",
            ...resultado,
        });
    } catch (error) {
        console.error(
            "❌ ERRO AO EXCLUIR RESTAURANTE:",
            error
        );

        res.status(500).json({
            sucesso: false,
            mensagem:
                "Erro ao excluir restaurante.",
            detalhes:
                error.message,
        });
    }
};

// ============================================================
// EXPORTAR MIDDLEWARES
// ============================================================

exports.uploadLogoMiddleware =
    uploadLogo;

exports.uploadCapaMiddleware =
    uploadCapa;

