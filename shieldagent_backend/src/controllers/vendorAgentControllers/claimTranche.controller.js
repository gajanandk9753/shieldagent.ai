const Transaction = require("../../models/agenticModels/transaction.model");

async function claimTranche(req, res) {
    try {
        if (req.agentRole !== "vendor-agent") {
            return res.status(403).json({ message: "Forbidden", success: false });
        }

        const transactionId = req.params.id;
        const { milestone } = req.body;
        const vendor = req.agent;

        const transaction = await Transaction.findById(transactionId);

        if (!transaction || transaction.vendorId.toString() !== vendor._id.toString()) {
            return res.status(404).json({ message: "Transaction not found or unauthorized", success: false });
        }

        if (transaction.escrowMode !== "ADAPTIVE") {
            return res.status(400).json({ message: "Transaction is not in adaptive escrow mode", success: false });
        }

        const targetTrancheIndex = transaction.tranches.findIndex(t => t.milestone === milestone);
        
        if (targetTrancheIndex === -1) {
            return res.status(400).json({ message: "Invalid milestone", success: false });
        }

        const targetTranche = transaction.tranches[targetTrancheIndex];

        if (targetTranche.status === "RELEASED") {
            return res.status(400).json({ message: "Tranche already released", success: false });
        }

        if (targetTrancheIndex > 0 && transaction.tranches[targetTrancheIndex - 1].status !== "RELEASED") {
            return res.status(403).json({ message: "Previous tranches must be cleared first", success: false });
        }

        transaction.tranches[targetTrancheIndex].status = "RELEASED";

        if (milestone === "FINAL_DELIVERY") {
            transaction.state = "BALANCE_RELEASED";
        } else {
            const nextMilestone = transaction.tranches[targetTrancheIndex + 1].milestone;
            transaction.state = `AWAITING_${nextMilestone}`;
        }

        await transaction.save();

        return res.status(200).json({
            message: `${milestone} tranche released successfully`,
            success: true,
            releasedAmount: targetTranche.amount,
            newState: transaction.state,
            tranches: transaction.tranches
        });

    } catch (error) {
        return res.status(500).json({ message: "Internal Server Error", success: false });
    }
}

module.exports = { claimTranche };