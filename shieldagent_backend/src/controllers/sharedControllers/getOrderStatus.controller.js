const Transaction = require("../../models/agenticModels/transaction.model");

async function getOrderStatus(req,res){
    try{
        const transactionId = req.params.id;
        const agent = req.agent;
        const role = req.agentRole;

        const transaction = await Transaction.findById(transactionId);

        if (!transaction) {
            return res.status(404).json({ 
                message: "Transaction not found", 
                success: false 
            });
        }

        const isBuyer = role === "buyer-agent" && transaction.buyerId.toString() === agent._id.toString();
        const isVendor = role === "vendor-agent" && transaction.vendorId.toString() === agent._id.toString();

        if (!isBuyer && !isVendor) {
            return res.status(403).json({ 
                message: "Unauthorized: You are not a party to this transaction", 
                success: false 
            });
        }

        return res.status(200).json({
            message: "Order status retrieved successfully",
            success: true,
            transactionId: transaction._id,
            state: transaction.state,
            advanceAmount: transaction.advanceAmount,
            balanceAmount: transaction.balanceAmount,
            razorpayOrderId: transaction.razorpayOrderId,
            lastUpdated: transaction.updatedAt
        });
    }catch(error){
        console.error("Error in getOrderStatus:", error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = {getOrderStatus};