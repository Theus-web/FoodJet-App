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
// CONFIGURAÇÃO MULTER
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

router.post(
    "/",
    productController.create
);

router.get(
    "/",
    productController.list
);

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

router.delete(
    "/:id",
    productController.remove
);

router.get(
    "/restaurante/:id",
    productController.restaurantProducts
);

router.put(
    "/:id/destaque",
    productController.updateHighlight
);

router.get(
    "/categoria/:categoria",
    productController.categoryProducts
);

router.get(
    "/buscar/:texto",
    productController.searchProducts
);

// ============================================================
// IMAGEM DO PRODUTO
// ============================================================

router.post(
    "/:id/imagem",
    upload.single("imagem"),
    productController.uploadImage
);

module.exports = router;