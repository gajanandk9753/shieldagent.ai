const Transaction = require("../../models/agenticModels/transaction.model");

async function confirmAdvance(req, res){
    try{
        if (req.agentRole !== "vendor-agent") {
            return res.status(403).json({
                message: "Forbidden: Only vendor agents can confirm advances",
                success: false
            });
        }

        const transactionId = req.params.id;
        const vendor = req.agent;

        const transaction = await Transaction.findById(transactionId);

        if(!transaction){
            return res.status(404).json({ message: "Transaction not found", success: false });
        }

        if (transaction.vendorId.toString() !== vendor._id.toString()) {
            return res.status(403).json({ message: "Unauthorized: This is not your transaction", success: false });
        }

        if(transaction.state !== "ADVANCE_LOCKED"){
            return res.status(400).json({
                message : "Cannot release advance.",
                success : false
            });
        }

        // re-check
        if(vendor.reputationScore < 50){
            transaction.state = "FROZEN";
            await transaction.save();

            return res.status(403).json({
                message: "Advance frozen due to low vendor reputation score",
                success: false,
                state: transaction.state
            });
        }

        // call razorpay to release money

        transaction.state = "ADVANCE_RELEASED";
        await transaction.save();

        return res.status(200).json({
            message : "Advance release successfully",
            success : true,
            transactionId : transaction._id,
            state : transaction.state,
            releasedAmount : transaction.advanceAmount
        });

    }catch(error){
        console.error("Error in confirmAdvance:", error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = { confirmAdvance }