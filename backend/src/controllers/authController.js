
const bcrypt = require("bcryptjs");

const User = require("../models/user");
const Restaurant = require("../models/restaurant");
const Token = require("../services/tokenService");
const Email = require("../services/emailService");

// ============================================================
// CADASTRO
// CLIENTE OU RESTAURANTE
// ============================================================

exports.register = async (req, res) => {
    try {
        const {
            nome,
            email,
            telefone,
            cnpj,
            categoria,
            responsavel,
            cpf,
            senha,
            cep,
            rua,
            numero,
            complemento,
            bairro,
            cidade,
            estado,
            banco,
            agencia,
            conta,
            pix,
            tipo
        } = req.body;

        // ====================================================
        // NORMALIZAÇÃO DO TIPO
        // ====================================================

        const tipoNormalizado = String(tipo || "CLIENTE")
            .trim()
            .toUpperCase();

        // ====================================================
        // VALIDAÇÕES BÁSICAS
        // ====================================================

        if (!nome || !email || !senha) {
            return res.status(400).json({
                erro: "Nome, email e senha são obrigatórios"
            });
        }

        if (String(nome).trim().length < 3) {
            return res.status(400).json({
                erro: "O nome deve ter pelo menos 3 caracteres"
            });
        }

        if (String(senha).length < 6) {
            return res.status(400).json({
                erro: "A senha deve ter pelo menos 6 caracteres"
            });
        }

        const emailNormalizado = String(email)
            .trim()
            .toLowerCase();

        // ====================================================
        // VALIDAÇÃO SIMPLES DO EMAIL
        // ====================================================

        const emailValido = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(
            emailNormalizado
        );

        if (!emailValido) {
            return res.status(400).json({
                erro: "Informe um email válido"
            });
        }

        // ====================================================
        // VERIFICAR EMAIL EXISTENTE
        // ====================================================

        const usuarioExistente =
            await User.buscarPorEmail(emailNormalizado);

        if (usuarioExistente) {
            return res.status(409).json({
                erro: "Este email já está cadastrado"
            });
        }

        // ====================================================
        // CLIENTE
        // ====================================================

        if (tipoNormalizado === "CLIENTE") {

            const agora = Date.now();

            const usuarioId = `user_${agora}`;

            const senhaHash = await bcrypt.hash(
                String(senha),
                10
            );

            const usuario = {
                id: usuarioId,

                nome: String(nome).trim(),

                email: emailNormalizado,

                telefone: telefone
                    ? String(telefone).trim()
                    : "",

                cpf: cpf
                    ? String(cpf).trim()
                    : "",

                senha: senhaHash,

                tipo: "CLIENTE",

                restauranteId: null,

                endereco: null,

                criadoEm: new Date().toISOString(),

                atualizadoEm: new Date().toISOString()
            };

            // =================================================
            // SALVAR CLIENTE
            // =================================================

            await User.criar(usuario);

            console.log("");
            console.log(
                "=========================================="
            );
            console.log(
                "👤 FOODJET - CLIENTE CADASTRADO"
            );
            console.log(
                "=========================================="
            );
            console.log(
                "🆔 ID:",
                usuario.id
            );
            console.log(
                "👤 NOME:",
                usuario.nome
            );
            console.log(
                "📧 EMAIL:",
                usuario.email
            );
            console.log(
                "👤 TIPO:",
                usuario.tipo
            );
            console.log(
                "=========================================="
            );

            return res.status(201).json({
                sucesso: true,

                mensagem: "Conta criada com sucesso",

                usuario: {
                    id: usuario.id,

                    nome: usuario.nome,

                    email: usuario.email,

                    telefone: usuario.telefone,

                    cpf: usuario.cpf,

                    tipo: usuario.tipo,

                    restauranteId: null
                }
            });
        }

        // ====================================================
        // RESTAURANTE
        // ====================================================

        if (tipoNormalizado === "RESTAURANTE") {

            // =================================================
            // VALIDAÇÕES ESPECÍFICAS DO RESTAURANTE
            // =================================================

            if (!telefone) {
                return res.status(400).json({
                    erro: "Telefone é obrigatório"
                });
            }

            if (!cnpj) {
                return res.status(400).json({
                    erro: "CNPJ é obrigatório"
                });
            }

            if (!responsavel || !cpf) {
                return res.status(400).json({
                    erro: "Responsável e CPF são obrigatórios"
                });
            }

            if (
                !cep ||
                !rua ||
                !numero ||
                !bairro ||
                !cidade ||
                !estado
            ) {
                return res.status(400).json({
                    erro: "O endereço completo é obrigatório"
                });
            }

            if (
                !banco ||
                !agencia ||
                !conta ||
                !pix
            ) {
                return res.status(400).json({
                    erro:
                        "Os dados de recebimento são obrigatórios"
                });
            }

            // =================================================
            // NORMALIZAR CNPJ
            // =================================================

            const cnpjNormalizado = String(cnpj)
                .replace(/\D/g, "");

            if (!cnpjNormalizado) {
                return res.status(400).json({
                    erro: "CNPJ inválido"
                });
            }

            // =================================================
            // VERIFICAR CNPJ
            // =================================================

            const restaurantes =
                await Restaurant.listar();

            const cnpjExistente =
                restaurantes.find(
                    (restaurante) =>
                        String(restaurante.cnpj || "")
                            .replace(/\D/g, "") ===
                        cnpjNormalizado
                );

            if (cnpjExistente) {
                return res.status(409).json({
                    erro: "Este CNPJ já está cadastrado"
                });
            }

            // =================================================
            // IDS
            // =================================================

            const agora = Date.now();

            const restauranteId =
                `rest_${agora}`;

            const usuarioId =
                `user_${agora}`;

            // =================================================
            // HASH DA SENHA
            // =================================================

            const senhaHash =
                await bcrypt.hash(
                    String(senha),
                    10
                );

            // =================================================
            // RESTAURANTE
            // =================================================

            const restaurante = {
                id: restauranteId,

                nome: String(nome).trim(),

                cnpj: String(cnpj).trim(),

                categoria: categoria
                    ? String(categoria).trim()
                    : "Restaurante",

                email: emailNormalizado,

                telefone: String(telefone).trim(),

                responsavel:
                    String(responsavel).trim(),

                cpf: String(cpf).trim(),

                endereco: {
                    cep: String(cep).trim(),

                    rua: String(rua).trim(),

                    numero: String(numero).trim(),

                    complemento: complemento
                        ? String(complemento).trim()
                        : "",

                    bairro:
                        String(bairro).trim(),

                    cidade:
                        String(cidade).trim(),

                    estado:
                        String(estado).trim()
                },

                pagamento: {
                    banco:
                        String(banco).trim(),

                    agencia:
                        String(agencia).trim(),

                    conta:
                        String(conta).trim(),

                    pix:
                        String(pix).trim()
                },

                status: "FECHADO",

                online: false,

                aberto: false,

                criadoEm:
                    new Date().toISOString(),

                atualizadoEm:
                    new Date().toISOString()
            };

            // =================================================
            // SALVAR RESTAURANTE
            // =================================================

            await Restaurant.criar(
                restaurante
            );

            // =================================================
            // USUÁRIO DO RESTAURANTE
            // =================================================

            const usuario = {
                id: usuarioId,

                nome:
                    String(responsavel).trim(),

                email:
                    emailNormalizado,

                telefone:
                    String(telefone).trim(),

                cpf:
                    String(cpf).trim(),

                senha:
                    senhaHash,

                tipo:
                    "RESTAURANTE",

                restauranteId:
                    restauranteId,

                criadoEm:
                    new Date().toISOString(),

                atualizadoEm:
                    new Date().toISOString()
            };

            // =================================================
            // SALVAR USUÁRIO
            // =================================================

            await User.criar(usuario);

            console.log("");
            console.log(
                "=========================================="
            );
            console.log(
                "🏪 FOODJET - RESTAURANTE CADASTRADO"
            );
            console.log(
                "=========================================="
            );
            console.log(
                "🆔 USUÁRIO:",
                usuario.id
            );
            console.log(
                "🏪 RESTAURANTE:",
                restaurante.id
            );
            console.log(
                "📧 EMAIL:",
                usuario.email
            );
            console.log(
                "=========================================="
            );

            // =================================================
            // RESPOSTA
            // =================================================

            return res.status(201).json({
                sucesso: true,

                mensagem:
                    "Restaurante criado com sucesso",

                usuario: {
                    id:
                        usuario.id,

                    nome:
                        usuario.nome,

                    email:
                        usuario.email,

                    telefone:
                        usuario.telefone,

                    tipo:
                        usuario.tipo,

                    restauranteId:
                        usuario.restauranteId
                },

                restaurante: {
                    id:
                        restaurante.id,

                    nome:
                        restaurante.nome,

                    cnpj:
                        restaurante.cnpj,

                    categoria:
                        restaurante.categoria,

                    status:
                        restaurante.status,

                    online:
                        restaurante.online
                }
            });
        }

        // ====================================================
        // TIPO INVÁLIDO
        // ====================================================

        return res.status(400).json({
            erro:
                "Tipo de usuário inválido. Use CLIENTE ou RESTAURANTE."
        });

    } catch (error) {

        console.error(
            "ERRO NO CADASTRO:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro interno ao cadastrar usuário",

            detalhe:
                error.message
        });
    }
};

// ============================================================
// LOGIN
// ============================================================

exports.login = async (req, res) => {
    try {
        const {
            email,
            senha
        } = req.body;

        if (!email || !senha) {
            return res.status(400).json({
                erro:
                    "Email e senha são obrigatórios"
            });
        }

        const emailNormalizado =
            String(email)
                .trim()
                .toLowerCase();

        const usuario =
            await User.buscarPorEmail(
                emailNormalizado
            );

        if (!usuario) {
            return res.status(401).json({
                erro:
                    "Email ou senha incorretos"
            });
        }

        const senhaValida =
            await bcrypt.compare(
                String(senha),
                usuario.senha
            );

        if (!senhaValida) {
            return res.status(401).json({
                erro:
                    "Email ou senha incorretos"
            });
        }

        // ====================================================
        // RESTAURANTE
        // ====================================================

        let restaurante = null;

        const tipoUsuario =
            String(usuario.tipo || "")
                .trim()
                .toUpperCase();

        if (tipoUsuario === "RESTAURANTE") {

            if (!usuario.restauranteId) {
                return res.status(403).json({
                    erro:
                        "Esta conta de restaurante não possui restaurante vinculado."
                });
            }

            restaurante =
                await Restaurant.buscarPorId(
                    usuario.restauranteId
                );

            if (!restaurante) {
                return res.status(403).json({
                    erro:
                        "O restaurante vinculado a esta conta não existe mais. Cadastre o restaurante novamente."
                });
            }
        }

        // ====================================================
        // TOKEN
        // ====================================================

        const token =
            Token.criarToken({
                id:
                    usuario.id,

                nome:
                    usuario.nome,

                email:
                    usuario.email,

                tipo:
                    usuario.tipo,

                restauranteId:
                    usuario.restauranteId
            });

        // ====================================================
        // RESPOSTA
        // ====================================================

        console.log("");
        console.log(
            "=========================================="
        );
        console.log(
            "🔐 FOODJET - LOGIN"
        );
        console.log(
            "=========================================="
        );
        console.log(
            "👤 USUÁRIO:",
            usuario.nome
        );
        console.log(
            "📧 EMAIL:",
            usuario.email
        );
        console.log(
            "👤 TIPO:",
            usuario.tipo
        );
        console.log(
            "🆔 ID:",
            usuario.id
        );
        console.log(
            "=========================================="
        );

        return res.status(200).json({
            sucesso: true,

            mensagem:
                "Login realizado com sucesso",

            token,

            usuario: {
                id:
                    usuario.id,

                nome:
                    usuario.nome,

                email:
                    usuario.email,

                telefone:
                    usuario.telefone,

                cpf:
                    usuario.cpf,

                tipo:
                    usuario.tipo,

                restauranteId:
                    usuario.restauranteId
            },

            restaurante:
                restaurante
                    ? {
                        id:
                            restaurante.id,

                        nome:
                            restaurante.nome,

                        categoria:
                            restaurante.categoria,

                        status:
                            restaurante.status,

                        online:
                            restaurante.online,

                        aberto:
                            restaurante.aberto
                    }
                    : null
        });

    } catch (error) {

        console.error(
            "ERRO NO LOGIN:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro interno no login",

            detalhe:
                error.message
        });
    }
};

// ============================================================
// VALIDAR CÓDIGO DE RECUPERAÇÃO
// ============================================================

exports.validarCodigoRecuperacao = async (
    req,
    res
) => {
    try {

        const {
            email,
            codigo
        } = req.body;

        if (!email || !codigo) {
            return res.status(400).json({
                erro:
                    "Email e código são obrigatórios"
            });
        }

        const usuario =
            await User.buscarPorCodigoRecuperacao(
                email,
                codigo
            );

        if (!usuario) {
            return res.status(400).json({
                erro:
                    "Código inválido ou expirado"
            });
        }

        return res.status(200).json({
            sucesso: true,

            mensagem:
                "Código validado com sucesso",

            usuarioId:
                usuario.id
        });

    } catch (error) {

        console.error(
            "ERRO AO VALIDAR CÓDIGO:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro interno ao validar código"
        });
    }
};

// ============================================================
// REDEFINIR SENHA
// ============================================================

exports.redefinirSenha = async (
    req,
    res
) => {
    try {

        const {
            email,
            codigo,
            novaSenha
        } = req.body;

        if (
            !email ||
            !codigo ||
            !novaSenha
        ) {
            return res.status(400).json({
                erro:
                    "Email, código e nova senha são obrigatórios"
            });
        }

        if (String(novaSenha).length < 6) {
            return res.status(400).json({
                erro:
                    "A nova senha deve ter pelo menos 6 caracteres"
            });
        }

        const usuario =
            await User.buscarPorCodigoRecuperacao(
                email,
                codigo
            );

        if (!usuario) {
            return res.status(400).json({
                erro:
                    "Código inválido ou expirado"
            });
        }

        const novaSenhaHash =
            await bcrypt.hash(
                String(novaSenha),
                10
            );

        await User.atualizarSenha(
            usuario.id,
            novaSenhaHash
        );

        await User.limparCodigoRecuperacao(
            usuario.id
        );

        return res.status(200).json({
            sucesso: true,

            mensagem:
                "Senha redefinida com sucesso"
        });

    } catch (error) {

        console.error(
            "ERRO AO REDEFINIR SENHA:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro interno ao redefinir senha"
        });
    }
};

// ============================================================
// ALTERAR SENHA LOGADO
// ============================================================

exports.alterarSenha = async (
    req,
    res
) => {
    try {

        const {
            senhaAtual,
            novaSenha
        } = req.body;

        if (!senhaAtual || !novaSenha) {
            return res.status(400).json({
                erro:
                    "Senha atual e nova senha são obrigatórias"
            });
        }

        if (String(novaSenha).length < 6) {
            return res.status(400).json({
                erro:
                    "A nova senha deve ter pelo menos 6 caracteres"
            });
        }

        const usuarioId =
            req.usuario?.id;

        if (!usuarioId) {
            return res.status(401).json({
                erro:
                    "Usuário não autenticado"
            });
        }

        const usuario =
            await User.buscarPorId(
                usuarioId
            );

        if (!usuario) {
            return res.status(404).json({
                erro:
                    "Usuário não encontrado"
            });
        }

        const senhaValida =
            await bcrypt.compare(
                String(senhaAtual),
                usuario.senha
            );

        if (!senhaValida) {
            return res.status(400).json({
                erro:
                    "Senha atual incorreta"
            });
        }

        const novaSenhaHash =
            await bcrypt.hash(
                String(novaSenha),
                10
            );

        await User.atualizarSenha(
            usuario.id,
            novaSenhaHash
        );

        return res.status(200).json({
            sucesso: true,

            mensagem:
                "Senha alterada com sucesso"
        });

    } catch (error) {

        console.error(
            "ERRO AO ALTERAR SENHA:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro interno ao alterar senha"
        });
    }
};

// ============================================================
// BUSCAR PERFIL
// ============================================================

exports.perfil = async (
    req,
    res
) => {
    try {

        const usuarioId =
            req.usuario?.id;

        if (!usuarioId) {
            return res.status(401).json({
                erro:
                    "Usuário não autenticado"
            });
        }

        const usuario =
            await User.buscarPorId(
                usuarioId
            );

        if (!usuario) {
            return res.status(404).json({
                erro:
                    "Usuário não encontrado"
            });
        }

        const usuarioSeguro = {
            id:
                usuario.id,

            nome:
                usuario.nome,

            email:
                usuario.email,

            telefone:
                usuario.telefone,

            cpf:
                usuario.cpf,

            tipo:
                usuario.tipo,

            restauranteId:
                usuario.restauranteId,

            endereco:
                usuario.endereco || null,

            criadoEm:
                usuario.criadoEm,

            atualizadoEm:
                usuario.atualizadoEm
        };

        return res.status(200).json({
            sucesso: true,

            usuario:
                usuarioSeguro
        });

    } catch (error) {

        console.error(
            "ERRO AO BUSCAR PERFIL:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro interno ao buscar perfil"
        });
    }
};

// ============================================================
// ATUALIZAR PERFIL
// ============================================================

exports.atualizarPerfil = async (
    req,
    res
) => {
    try {

        const usuarioId =
            req.usuario?.id;

        if (!usuarioId) {
            return res.status(401).json({
                erro:
                    "Usuário não autenticado"
            });
        }

        const {
            nome,
            telefone,
            email,
            cpf
        } = req.body;

        if (email) {

            const emailNormalizado =
                String(email)
                    .trim()
                    .toLowerCase();

            const usuarioExistente =
                await User.buscarPorEmail(
                    emailNormalizado
                );

            if (
                usuarioExistente &&
                String(usuarioExistente.id) !==
                    String(usuarioId)
            ) {
                return res.status(409).json({
                    erro:
                        "Este email já está cadastrado"
                });
            }
        }

        const usuarioAtualizado =
            await User.atualizarPerfil(
                usuarioId,
                {
                    nome,
                    telefone,
                    email,
                    cpf
                }
            );

        if (!usuarioAtualizado) {
            return res.status(404).json({
                erro:
                    "Usuário não encontrado"
            });
        }

        return res.status(200).json({
            sucesso: true,

            mensagem:
                "Perfil atualizado com sucesso",

            usuario: {
                id:
                    usuarioAtualizado.id,

                nome:
                    usuarioAtualizado.nome,

                email:
                    usuarioAtualizado.email,

                telefone:
                    usuarioAtualizado.telefone,

                cpf:
                    usuarioAtualizado.cpf,

                tipo:
                    usuarioAtualizado.tipo,

                restauranteId:
                    usuarioAtualizado.restauranteId
            }
        });

    } catch (error) {

        console.error(
            "ERRO AO ATUALIZAR PERFIL:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro interno ao atualizar perfil"
        });
    }
};

// ============================================================
// ATUALIZAR ENDEREÇO
// ============================================================

exports.atualizarEndereco = async (
    req,
    res
) => {
    try {

        const usuarioId =
            req.usuario?.id;

        if (!usuarioId) {
            return res.status(401).json({
                erro:
                    "Usuário não autenticado"
            });
        }

        const endereco = {
            cep:
                req.body.cep,

            rua:
                req.body.rua,

            numero:
                req.body.numero,

            bairro:
                req.body.bairro,

            complemento:
                req.body.complemento,

            cidade:
                req.body.cidade,

            estado:
                req.body.estado
        };

        const usuarioAtualizado =
            await User.atualizarEndereco(
                usuarioId,
                endereco
            );

        if (!usuarioAtualizado) {
            return res.status(404).json({
                erro:
                    "Usuário não encontrado"
            });
        }

        return res.status(200).json({
            sucesso: true,

            mensagem:
                "Endereço atualizado com sucesso",

            endereco:
                usuarioAtualizado.endereco
        });

    } catch (error) {

        console.error(
            "ERRO AO ATUALIZAR ENDEREÇO:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro interno ao atualizar endereço"
        });
    }
};

// ============================================================
// SOLICITAR RECUPERAÇÃO DE SENHA
// ============================================================

exports.solicitarRecuperacao = async (
    req,
    res
) => {
    try {

        console.log("");
        console.log(
            "=========================================="
        );
        console.log(
            "🔐 ROTA DE RECUPERAÇÃO CHAMADA"
        );
        console.log(
            "=========================================="
        );

        const email =
            String(req.body.email || "")
                .trim()
                .toLowerCase();

        console.log(
            "📧 Email recebido:",
            email
        );

        if (!email) {
            return res.status(400).json({
                erro:
                    "Informe seu email"
            });
        }

        console.log(
            "🔎 Procurando usuário..."
        );

        const usuario =
            await User.buscarPorEmail(
                email
            );

        if (!usuario) {

            console.log(
                "❌ Usuário não encontrado:",
                email
            );

            return res.status(404).json({
                erro:
                    "Email não encontrado"
            });
        }

        console.log(
            "✅ Usuário encontrado:",
            usuario.id
        );

        // ====================================================
        // GERAR CÓDIGO
        // ====================================================

        const codigo =
            Math.floor(
                100000 +
                Math.random() * 900000
            ).toString();

        console.log(
            "🔐 Código de recuperação:",
            codigo
        );

        // ====================================================
        // EXPIRAÇÃO - 10 MINUTOS
        // ====================================================

        const expiracao =
            Date.now() +
            (10 * 60 * 1000);

        await User.salvarCodigoRecuperacao(
            usuario.id,
            codigo,
            expiracao
        );

        console.log(
            "💾 Código salvo no usuário"
        );

        // ====================================================
        // ENVIAR EMAIL
        // ====================================================

        console.log(
            "📨 Iniciando envio do email..."
        );

        await Email.enviarCodigoRecuperacao(
            email,
            codigo
        );

        console.log(
            "✅ Email enviado com sucesso!"
        );

        console.log(
            "=========================================="
        );

        return res.status(200).json({
            sucesso: true,

            mensagem:
                "Código de recuperação enviado para seu email"
        });

    } catch (error) {

        console.error("");

        console.error(
            "❌❌❌ ERRO AO ENVIAR EMAIL ❌❌❌"
        );

        console.error(error);

        console.error(
            "Mensagem:",
            error.message
        );

        console.error(
            "=========================================="
        );

        return res.status(500).json({
            erro:
                "Não foi possível enviar o email de recuperação",

            detalhe:
                error.message
        });
    }
};

// ============================================================
// EXCLUIR CONTA DO CLIENTE
// ============================================================

exports.excluirConta = async (
    req,
    res
) => {
    try {

        console.log("");

        console.log(
            "=========================================="
        );

        console.log(
            "🗑️ FOODJET - EXCLUSÃO DE CONTA"
        );

        console.log(
            "=========================================="
        );

        const usuarioId =
            req.usuario?.id;

        console.log(
            "🆔 ID recebido:",
            usuarioId
        );

        if (!usuarioId) {
            return res.status(401).json({
                erro:
                    "Usuário não autenticado"
            });
        }

        const usuario =
            await User.buscarPorId(
                usuarioId
            );

        if (!usuario) {
            return res.status(404).json({
                erro:
                    "Usuário não encontrado"
            });
        }

        console.log(
            "👤 Usuário encontrado:",
            usuario.email
        );

        const tipoUsuario =
            String(usuario.tipo || "")
                .trim()
                .toUpperCase();

        console.log(
            "👤 Tipo:",
            tipoUsuario
        );

        if (tipoUsuario !== "CLIENTE") {
            return res.status(403).json({
                erro:
                    "Somente clientes podem excluir a conta."
            });
        }

        const excluido =
            await User.excluir(
                usuarioId
            );

        if (!excluido) {
            return res.status(500).json({
                erro:
                    "Não foi possível excluir a conta."
            });
        }

        console.log(
            "✅ CONTA EXCLUÍDA:",
            usuario.email
        );

        console.log(
            "=========================================="
        );

        return res.status(200).json({
            sucesso: true,

            mensagem:
                "Conta excluída com sucesso"
        });

    } catch (error) {

        console.error("");

        console.error(
            "❌ ERRO AO EXCLUIR CONTA"
        );

        console.error(error);

        console.error(
            "=========================================="
        );

        return res.status(500).json({
            erro:
                "Erro interno ao excluir conta",

            detalhe:
                error.message
        });
    }
};

