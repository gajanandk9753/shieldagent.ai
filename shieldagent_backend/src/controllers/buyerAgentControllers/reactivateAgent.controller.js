const buyerAgentModel = require("../../models/authModels/buyerAgent.model");

async function reactivateAgent(req, res) {
    try {
        const agentId = req.params.id;
        const userId = req.user.userId;

        if (agentId !== userId) {
            return res.status(403).json({
                message: "Unauthorized: You can only reactivate your own agent",
                success: false
            });
        }

        const agent = await buyerAgentModel.findById(agentId);

        if (!agent) {
            return res.status(404).json({ message: "Agent not found", success: false });
        }

        if (agent.status === "ACTIVE") {
            return res.status(400).json({ message: "Agent is already active", success: false });
        }
        
        agent.status = "ACTIVE";
        agent.flagHistory = [];
        
        await agent.save();

        return res.status(200).json({
            message: "Agent reactivated successfully. Flag counter cleared.",
            success: true,
            status: agent.status
        });

    } catch (error) {
        console.error("Error in reactivateAgent:", error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = { reactivateAgent };