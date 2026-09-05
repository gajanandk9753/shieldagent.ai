const Transaction = require("../../models/agenticModels/transaction.model");

async function getVendorOrders(req, res) {
    try {
        if (req.agentRole !== "vendor-agent") {
            return res.status(403).json({ message: "Forbidden", success: false });
        }
        
        // Fetch all transactions for this vendor, newest first
        const orders = await Transaction.find({ vendorId: req.agent._id })
            .populate("buyerId", "companyName")
            .sort({ createdAt: -1 });

        return res.status(200).json({
            success: true,
            count: orders.length,
            orders: orders
        });
    } catch (error) {
        console.error("Error fetching vendor orders:", error);
        return res.status(500).json({ message: "Internal Server Error", success: false });
    }
}

module.exports = { getVendorOrders };