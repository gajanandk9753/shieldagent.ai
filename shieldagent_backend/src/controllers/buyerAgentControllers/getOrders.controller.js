const Transaction = require("../../models/agenticModels/transaction.model");

async function getOrders(req, res) {
    try {
        const agentId = req.agent ? req.agent._id : req.user.userId;

        const transactions = await Transaction.find({ buyerId: agentId })
            .populate("vendorId", "companyName")
            .sort({ createdAt: -1 });

        return res.status(200).json({
            success: true,
            count: transactions.length,
            transactions: transactions
        });
    } catch (error) {
        console.error("Error in getOrders:", error);
        return res.status(500).json({ message: "Internal Server Error", success: false });
    }
}

module.exports = { getOrders };