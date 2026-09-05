const Transaction = require("../../models/agenticModels/transaction.model");
const AuditLog = require("../../models/agenticModels/auditLog.model");

async function reportPriceChange(req,res){
    try{
        if (req.agentRole !== "vendor-agent") {
            return res.status(403).json({
                message: "Forbidden: Only vendor agents can report price changes",
                success: false
            });
        }

        const transactionId = req.params.id;
        const { newAmount } = req.body;
        const vendor = req.agent;

        if (newAmount === undefined) {
            return res.status(400).json({ message: "newAmount is required", success: false });
        }

        const transaction = await Transaction.findById(transactionId);

        if (!transaction) {
            return res.status(404).json({ message: "Transaction not found", success: false });
        }

        if (transaction.vendorId.toString() !== vendor._id.toString()) {
            return res.status(403).json({ message: "Unauthorized", success: false });
        }

        if (transaction.state === "FROZEN" || transaction.state === "BALANCE_RELEASED" || transaction.state === "CANCELLED") {
            return res.status(400).json({ 
                message: `Cannot change price in current state: ${transaction.state}`, 
                success: false 
            });
        }

        const currentTotal = transaction.advanceAmount + transaction.balanceAmount;
        const priceDelta = Number(newAmount) - currentTotal;
        const priceDeltaPct = (priceDelta / currentTotal) * 100;

        const FREEZE_THRESHOLD = 20;

        if(priceDeltaPct > FREEZE_THRESHOLD){
            transaction.state = "FROZEN";
            await transaction.save();

            const auditEntry = new AuditLog({
                transactionId: transaction._id,
                decision: "FROZEN",
                reason: `priceDeltaPct: ${priceDeltaPct.toFixed(2)} > freezeThreshold: ${FREEZE_THRESHOLD}`,
                riskScore: 78,
                actor: "system"
            });
            await auditEntry.save();

            return res.status(423).json({
                message: "Order FROZEN due to high price jump",
                success: false,
                state: transaction.state,
                audit: {
                    reason: auditEntry.reason,
                    riskScore: auditEntry.riskScore
                }
            });
        }

        transaction.balanceAmount = Number(newAmount) - transaction.advanceAmount;
        await transaction.save();

        return res.status(200).json({
            message: "Price change accepted within safe threshold",
            success: true,
            state: transaction.state,
            newBalanceAmount: transaction.balanceAmount
        });
    }catch(error){
        console.error("Error in reportPriceChange:", error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = { reportPriceChange };