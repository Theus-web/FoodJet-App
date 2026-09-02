const { pool } = require("../config/database");

class DashboardService {

  // =====================================================
  // OBTER DASHBOARD
  // =====================================================

  static async obterDashboard(restauranteId) {

    const restauranteIdNormalizado =
      String(restauranteId);


    // ===================================================
    // PEDIDOS
    // ===================================================

    const pedidosResult =
      await pool.query(
        `
        SELECT
          id,
          restaurante_id,
          status,
          total,
          criado_em,
          dados
        FROM pedidos
        WHERE restaurante_id = $1
        `,
        [
          restauranteIdNormalizado
        ]
      );


    const pedidosRestaurante =
      pedidosResult.rows.map(row => {

        let dados = {};

        if (row.dados) {

          try {

            dados =
              typeof row.dados === "string"
                ? JSON.parse(row.dados)
                : row.dados;

          } catch {

            dados = {};

          }
        }


        return {

          ...dados,

          id:
            row.id,

          restauranteId:
            row.restaurante_id,

          status:
            row.status ||
            dados.status,

          total:
            Number(
              row.total ||
              dados.total ||
              0
            ),

          createdAt:
            dados.createdAt ||
            dados.criadoEm ||
            (
              row.criado_em
                ? new Date(
                    row.criado_em
                  ).toISOString()
                : null
            )

        };
      });


    // ===================================================
    // PRODUTOS
    // ===================================================

    const produtosResult =
      await pool.query(
        `
        SELECT
          id,
          restaurante_id,
          nome,
          descricao,
          preco,
          categoria,
          imagem,
          disponivel,
          destaque,
          criado_em,
          atualizado_em,
          dados
        FROM produtos
        WHERE restaurante_id = $1
        `,
        [
          restauranteIdNormalizado
        ]
      );


    const produtosRestaurante =
      produtosResult.rows.map(row => {

        let dados = {};

        if (row.dados) {

          try {

            dados =
              typeof row.dados === "string"
                ? JSON.parse(row.dados)
                : row.dados;

          } catch {

            dados = {};

          }
        }


        return {

          ...dados,

          id:
            row.id,

          restauranteId:
            row.restaurante_id,

          nome:
            row.nome ??
            dados.nome,

          descricao:
            row.descricao ??
            dados.descricao,

          preco:
            Number(
              row.preco ??
              dados.preco ??
              0
            ),

          categoria:
            row.categoria ??
            dados.categoria,

          imagem:
            row.imagem ??
            dados.imagem,

          disponivel:
            row.disponivel ??
            dados.disponivel,

          destaque:
            row.destaque ??
            dados.destaque

        };
      });


    // ===================================================
    // DATA DE HOJE
    // ===================================================

    const hoje =
      new Date()
        .toISOString()
        .substring(0, 10);


    // ===================================================
    // PEDIDOS DE HOJE
    // ===================================================

    const pedidosHoje =
      pedidosRestaurante.filter(
        pedido => {

          if (!pedido.createdAt) {
            return false;
          }

          return (
            String(
              pedido.createdAt
            ).substring(0, 10)
            === hoje
          );

        }
      );


    // ===================================================
    // VENDAS DE HOJE
    // ===================================================

    const vendasHoje =
      pedidosHoje

        .filter(
          pedido =>
            pedido.status ===
            "CONCLUIDO"
        )

        .reduce(
          (total, pedido) =>
            total +
            Number(
              pedido.total || 0
            ),
          0
        );


    // ===================================================
    // PEDIDOS PENDENTES
    // ===================================================

    const pendentes =
      pedidosRestaurante.filter(
        pedido =>
          pedido.status ===
          "AGUARDANDO"
      ).length;


    // ===================================================
    // PEDIDOS PREPARANDO
    // ===================================================

    const preparando =
      pedidosRestaurante.filter(
        pedido =>
          pedido.status ===
          "PREPARANDO"
      ).length;


    // ===================================================
    // PEDIDOS EM ENTREGA
    // ===================================================

    const entrega =
      pedidosRestaurante.filter(
        pedido =>
          pedido.status ===
          "SAIU_PARA_ENTREGA"
      ).length;


    // ===================================================
    // PEDIDOS CONCLUÍDOS
    // ===================================================

    const concluidos =
      pedidosRestaurante.filter(
        pedido =>
          pedido.status ===
          "CONCLUIDO"
      ).length;


    // ===================================================
    // TICKET MÉDIO
    // ===================================================

    const ticketMedio =
      concluidos > 0
        ? vendasHoje / concluidos
        : 0;


    // ===================================================
    // AVALIAÇÕES
    // ===================================================

    let avaliacoesRestaurante = [];


    try {

      const tabelaAvaliacoes =
        await pool.query(
          `
          SELECT
            *
          FROM avaliacoes
          WHERE restaurante_id = $1
          `,
          [
            restauranteIdNormalizado
          ]
        );


      avaliacoesRestaurante =
        tabelaAvaliacoes.rows.map(
          row => {

            let dados = {};

            if (row.dados) {

              try {

                dados =
                  typeof row.dados === "string"
                    ? JSON.parse(row.dados)
                    : row.dados;

              } catch {

                dados = {};

              }
            }


            return {
              ...dados,
              ...row
            };

          }
        );


    } catch (erroAvaliacoes) {

      // =================================================
      // A TABELA PODE AINDA NÃO EXISTIR
      // =================================================

      if (
        erroAvaliacoes.code !==
        "42P01"
      ) {

        console.error(
          "ERRO AO BUSCAR AVALIAÇÕES:",
          erroAvaliacoes
        );

      }

      avaliacoesRestaurante = [];

    }


    // ===================================================
    // CALCULAR AVALIAÇÃO
    // ===================================================

    const avaliacao =
      avaliacoesRestaurante.length > 0

        ? avaliacoesRestaurante.reduce(
            (soma, item) =>
              soma +
              Number(
                item.nota || 0
              ),
            0
          ) /
          avaliacoesRestaurante.length

        : 5;


    // ===================================================
    // ÚLTIMOS PEDIDOS
    // ===================================================

    const ultimosPedidos =
      [...pedidosRestaurante]
        .sort(
          (a, b) =>
            Number(b.id || 0) -
            Number(a.id || 0)
        )
        .slice(0, 5);


    // ===================================================
    // RETORNO
    // ===================================================

    return {

      pedidosHoje:
        pedidosHoje.length,

      vendasHoje,

      produtos:
        produtosRestaurante.length,

      avaliacao:
        Number(
          avaliacao.toFixed(1)
        ),

      pendentes,

      preparando,

      entrega,

      concluidos,

      ticketMedio:
        Number(
          ticketMedio.toFixed(2)
        ),

      ultimosPedidos

    };

  }

}


module.exports =
  DashboardService;