const Transaction = require("../../models/agenticModels/transaction.model");
const AuditLog = require("../../models/agenticModels/auditLog.model");

async function reportLogisticsUpdate(req, res) {
    try {
        if (req.agentRole !== "vendor-agent") {
            return res.status(403).json({ message: "Forbidden", success: false });
        }

        const transactionId = req.params.id;
        const { delayInDays } = req.body;
        const vendor = req.agent;

        const transaction = await Transaction.findById(transactionId);

        if (!transaction) return res.status(404).json({ message: "Transaction not found", success: false });
        if (transaction.vendorId.toString() !== vendor._id.toString()) return res.status(403).json({ message: "Unauthorized", success: false });

        if (transaction.state !== "ADVANCE_RELEASED") {
            return res.status(400).json({ message: "Cannot adapt escrow in current state.", success: false });
        }

        if (delayInDays > 2 && transaction.escrowMode === "STANDARD") {
            transaction.escrowMode = "ADAPTIVE";
            transaction.logisticsFlags += 1;
            
            const remainingBalance = transaction.balanceAmount;
            
            const dispatchAmount = Math.round(remainingBalance * 0.30);
            const transitAmount = Math.round(remainingBalance * 0.30);
            const deliveryAmount = remainingBalance - dispatchAmount - transitAmount;

            transaction.tranches = [
                { milestone: "DISPATCH_PROOF", amount: dispatchAmount, status: "PENDING" },
                { milestone: "TRANSIT_SCAN", amount: transitAmount, status: "PENDING" },
                { milestone: "FINAL_DELIVERY", amount: deliveryAmount, status: "PENDING" }
            ];

            transaction.balanceAmount = 0; 
            transaction.state = "AWAITING_DISPATCH_PROOF";

            await transaction.save();

            const auditEntry = new AuditLog({
                transactionId: transaction._id,
                decision: "ESCROW_RESTRUCTURED",
                reason: `Vendor reported ${delayInDays} day delay. Remaining balance restructured into 3-stage milestone payout.`,
                riskScore: 65,
                actor: "system"
            });
            await auditEntry.save();

            return res.status(200).json({
                message: "Risk detected. Escrow restructured to Adaptive Multi-Stage.",
                success: true,
                escrowMode: transaction.escrowMode,
                state: transaction.state,
                tranches: transaction.tranches
            });
        }

        return res.status(200).json({
            message: "Logistics updated. Standard escrow maintained.",
            success: true,
            state: transaction.state
        });

    } catch (error) {
        return res.status(500).json({ message: "Internal Server Error", success: false });
    }
}

module.exports = { reportLogisticsUpdate };