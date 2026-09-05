const buyerAgentModel = require("../../models/authModels/buyerAgent.model");

async function getRiskStatus(req, res){
    try{
        let agentId;
        if(req.agent && req.agentRole == "buyer-agent"){
            agentId = req.agent._id;
        }else if(req.user && req.user.userId){
            agentId = req.user.userId;
        }else{
            return res.status(403).json({ 
                message: "Unauthorized: Invalid role or missing authentication", 
                success: false 
            });
        }

        const buyer = await buyerAgentModel.findById(agentId);

        if (!buyer) {
            return res.status(404).json({ message: "Buyer agent not found", success: false });
        }

        const oneHourAgo = new Date( Date.now() - 60 * 60 * 1000);
        const recentFlags = buyer.flagHistory.filter(flag => flag.at >= oneHourAgo);

        let windowResetsAt = null;
        if (recentFlags.length > 0) {
            const sortedFlags = recentFlags.sort((a, b) => a.at - b.at);
            const oldestRecentFlag = sortedFlags[0];
            
            windowResetsAt = new Date(oldestRecentFlag.at.getTime() + 60 * 60 * 1000);
        }

        return res.status(200).json({
            message: "Risk status retrieved successfully",
            success: true,
            status: buyer.status,
            flagCountInWindow: recentFlags.length,
            windowResetsAt: windowResetsAt
        });
    }catch (error) {
        console.error("Error in getRiskStatus:", error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = { getRiskStatus };