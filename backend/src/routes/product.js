const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

const router = express.Router();

const productController =
    require("../controllers/productController");

console.log(
    "✅ ROTA PRODUTOS CARREGADA"
);

// ============================================================
// PASTA DE UPLOAD
// ============================================================

const pastaUploads =
    path.join(
        process.cwd(),
        "uploads",
        "products"
    );

if (!fs.existsSync(pastaUploads)) {
    fs.mkdirSync(
        pastaUploads,
        {
            recursive: true
        }
    );
}

// ============================================================
// MULTER
// ============================================================

const storage =
    multer.diskStorage({
        destination: (
            req,
            file,
            cb
        ) => {
            cb(
                null,
                pastaUploads
            );
        },

        filename: (
            req,
            file,
            cb
        ) => {
            const extensao =
                path.extname(
                    file.originalname
                ).toLowerCase();

            const nome =
                `produto-${req.params.id}-${Date.now()}${extensao}`;

            cb(
                null,
                nome
            );
        }
    });

const upload =
    multer({
        storage,

        limits: {
            fileSize:
                5 * 1024 * 1024
        },

        fileFilter: (
            req,
            file,
            cb
        ) => {
            const permitidos = [
                ".jpg",
                ".jpeg",
                ".png",
                ".webp"
            ];

            const extensao =
                path.extname(
                    file.originalname
                ).toLowerCase();

            if (
                permitidos.includes(
                    extensao
                )
            ) {
                cb(
                    null,
                    true
                );
            } else {
                cb(
                    new Error(
                        "Formato de imagem não permitido."
                    )
                );
            }
        }
    });

// ============================================================
// PRODUTOS
// ============================================================

// CRIAR
router.post(
    "/",
    productController.create
);

// LISTAR TODOS
router.get(
    "/",
    productController.list
);

// ============================================================
// ROTAS ESPECÍFICAS
// ============================================================

// PRODUTOS DO RESTAURANTE
// IMPORTANTE: fica ANTES de /:id
router.get(
    "/restaurante/:id",
    productController.restaurantProducts
);

// PRODUTOS POR CATEGORIA
router.get(
    "/categoria/:categoria",
    productController.categoryProducts
);

// PESQUISAR
router.get(
    "/buscar/:texto",
    productController.searchProducts
);

// ============================================================
// ROTAS POR ID
// ============================================================

router.get(
    "/:id",
    productController.getById
);

router.put(
    "/:id",
    productController.update
);

router.put(
    "/:id/disponibilidade",
    productController.updateAvailability
);

router.put(
    "/:id/destaque",
    productController.updateHighlight
);

router.delete(
    "/:id",
    productController.remove
);

// ============================================================
// IMAGEM
// ============================================================

router.post(
    "/:id/imagem",
    upload.single("imagem"),
    productController.uploadImage
);

module.exports = router;