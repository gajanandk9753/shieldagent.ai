const crypto = require("crypto");
require("dotenv").config();

async function razorpayWebhook(req, res) {
    try {
        const secret = process.env.RAZORPAY_WEBHOOK_SECRET; 
        const signature = req.headers["x-razorpay-signature"];
        const body = JSON.stringify(req.body);
        
        const expectedSignature = crypto
            .createHmac("sha256", secret)
            .update(body)
            .digest("hex");

        if (expectedSignature !== signature) {
            return res.status(400).json({ message: "Invalid signature", success: false });
        }

        const event = req.body.event;
        console.log("Razorpay Webhook received:", event);
        return res.status(200).send("OK");
    } catch (error) {
        console.error("Error in webhook processing:", error);
        return res.status(500).send("Internal Server Error");
    }
}

module.exports = { razorpayWebhook };