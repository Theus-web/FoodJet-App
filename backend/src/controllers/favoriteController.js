const { pool } = require("../config/database");
// ======================================================
// LISTAR FAVORITOS DO USUÁRIO
// ======================================================
exports.listar = async (req, res) => {
  try {
    const usuarioId = req.usuario?.id || req.params.usuarioId;

    const resultado = await pool.query(
      `
      SELECT *
      FROM favoritos
      WHERE usuario_id = $1
      ORDER BY nome ASC
      `,
      [usuarioId]
    );

    const favoritos = resultado.rows.map((item) => ({
      ...(item.dados || {}),
      id: item.id,
      usuarioId: item.usuario_id,
      restauranteId: item.restaurante_id,
      nome: item.nome,
      descricao: item.descricao,
      avaliacao: item.avaliacao,
      logo: item.logo,
      imagem: item.logo,
    }));

    return res.json(favoritos);
  } catch (error) {
    console.error("❌ Erro ao listar favoritos:", error);
    return res.status(500).json({
      erro: "Erro ao listar favoritos.",
    });
  }
};

// ======================================================
// SALVAR FAVORITO
// ======================================================
exports.salvar = async (req, res) => {
  try {
    const usuarioId = req.usuario?.id || req.body.usuarioId;

    const favorito = req.body;

    const restauranteId =
      favorito.restauranteId ||
      favorito.restaurante_id ||
      favorito.idRestaurante;

    if (!usuarioId || !restauranteId) {
      return res.status(400).json({
        erro: "Usuário ou restaurante não informado.",
      });
    }

    favorito.id =
      favorito.id ||
      `fav_${usuarioId}_${restauranteId}`;

    await pool.query(
      `
      INSERT INTO favoritos (
          id,
          usuario_id,
          restaurante_id,
          nome,
          descricao,
          avaliacao,
          logo,
          dados
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
      ON CONFLICT (usuario_id, restaurante_id)
      DO UPDATE SET
          nome = EXCLUDED.nome,
          descricao = EXCLUDED.descricao,
          avaliacao = EXCLUDED.avaliacao,
          logo = EXCLUDED.logo,
          dados = EXCLUDED.dados
      `,
      [
        favorito.id,
        usuarioId,
        restauranteId,
        favorito.nome || "",
        favorito.descricao || "",
        favorito.avaliacao || "0",
        favorito.logo || favorito.imagem || null,
        favorito,
      ]
    );

    return res.json({
      sucesso: true,
      mensagem: "Favorito salvo com sucesso.",
    });
  } catch (error) {
    console.error("❌ Erro ao salvar favorito:", error);
    return res.status(500).json({
      erro: "Erro ao salvar favorito.",
      detalhe: error.message,
    });
  }
};

// ======================================================
// REMOVER FAVORITO
// ======================================================
exports.remover = async (req, res) => {
  try {
    const usuarioId = req.usuario?.id || req.body.usuarioId;

    const restauranteId =
      req.params.restauranteId ||
      req.body.restauranteId;

    await pool.query(
      `
      DELETE FROM favoritos
      WHERE usuario_id = $1
      AND restaurante_id = $2
      `,
      [usuarioId, restauranteId]
    );

    return res.json({
      sucesso: true,
      mensagem: "Favorito removido.",
    });
  } catch (error) {
    console.error("❌ Erro ao remover favorito:", error);
    return res.status(500).json({
      erro: "Erro ao remover favorito.",
    });
  }
};

// ======================================================
// VERIFICAR SE É FAVORITO
// ======================================================
exports.verificar = async (req, res) => {
  try {
    const usuarioId = req.usuario?.id || req.params.usuarioId;
    const restauranteId = req.params.restauranteId;

    const resultado = await pool.query(
      `
      SELECT 1
      FROM favoritos
      WHERE usuario_id = $1
      AND restaurante_id = $2
      LIMIT 1
      `,
      [usuarioId, restauranteId]
    );

    return res.json({
      favorito: resultado.rows.length > 0,
    });
  } catch (error) {
    console.error("❌ Erro ao verificar favorito:", error);
    return res.status(500).json({
      erro: "Erro ao verificar favorito.",
    });
  }
};