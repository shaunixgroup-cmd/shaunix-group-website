const QRCode = require("qrcode");

const link = "https://wa.me/919821186889?text=Hi%20Shaunix%20group,%20I%20am%20interested%20in%20your%20services.%20Please%20provide%20more%20information.";

QRCode.toFile(
    "shaunix-qr.png",
    link,
    {
        width: 106,              // ✅ 106x106 pixels
        margin: 0,               // ✅ No extra margin (pure QR)
        errorCorrectionLevel: "H"
    },
    function (err) {
        if (err) throw err;
        console.log("✅ QR Code generated!");
        console.log("📐 Size: 106x106 px @ 300 ppi");
        console.log("📏 Print size: 0.353 inches");
    }
);