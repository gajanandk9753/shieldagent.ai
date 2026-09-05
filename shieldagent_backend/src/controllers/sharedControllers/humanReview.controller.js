const Transaction = require("../../models/agenticModels/transaction.model");
const AuditLog = require("../../models/agenticModels/auditLog.model");

async function getFrozenOrders(req,res){
    try{
        const userId = req.user.userId;

        const transactions = await Transaction.find({
            $or : [
                { buyerId : userId},
                { vendorId : userId}
            ],
            state : "FROZEN"
        }).populate("vendorId", "companyName reputationScore")
          .populate("buyerId", " name budgetLimit");


        return res.status(200).json({
            message: "Frozen orders retrieved successfully",
            success: true,
            count: transactions.length,
            transactions: transactions
        });
    }catch(error){
        console.error("Error in getFrozenOrders:", error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

async function resolveOrder(req,res){
    try{
        const transactionId = req.params.id;
        const userId = req.user.userId;
        const { decision } = req.body;

        if( !decision || !["APPROVE", "REJECT"].includes(decision.toUpperCase())){
            return res.status(400).json({ 
                message: "Decision must be APPROVE or REJECT", 
                success: false 
            });
        }

        const transaction = await Transaction.findById(transactionId);

        if (!transaction) {
            return res.status(404).json({ 
                message: "Transaction not found", 
                success: false 
            });
        }

        if (transaction.buyerId.toString() !== userId && transaction.vendorId.toString() !== userId) {
            return res.status(403).json({ 
                message: "Unauthorized: You are not a party to this transaction", 
                success: false 
            });
        }

        if (transaction.state !== "FROZEN") {
            return res.status(400).json({ 
                message: "Order is not frozen", 
                success: false 
            });
        }

        if (decision.toUpperCase() === "APPROVE") {
            transaction.state = "ADVANCE_RELEASED";
        } else {
            transaction.state = "CANCELLED";
        }

        await transaction.save();

        const auditEntry = new AuditLog({
            transactionId: transaction._id,
            decision: decision.toUpperCase(),
            reason: `Human reviewer resolved frozen order. Outcome: ${transaction.state}`,
            riskScore: 0,
            actor: "human"
        });

        await auditEntry.save();

        return res.status(200).json({
            message: `Order successfully resolved and marked as ${transaction.state}`,
            success: true,
            state: transaction.state
        });
    }catch(error){
        console.error("Error in resolveOrder:", error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = { getFrozenOrders, resolveOrder}