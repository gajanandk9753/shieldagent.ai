const vendorAgentModel = require("../models/authModels/vendorAgent.model")
const buyerAgentModel = require("../models/authModels/buyerAgent.model");

async function apiKeyMiddleware(req,res,next){
    const apiKey = req.headers["x-api-key"];
    if(!apiKey){
        return res.status(401).json({
            message : "No API Key provided",
            success : false
        });
    }

    try{
        let agent = await buyerAgentModel.findOne({apiKey});
        let role = "buyer-agent";

        if(!agent){
            agent = await vendorAgentModel.findOne({apiKey});
            role = "vendor-agent";
        }

        if(!agent){
            return res.status(401).json({
                message: "Invalid API key",
                success: false
            });
        }

        if(agent.status == "SUSPENDED"){
            return res.status(423).json({
                message : "Agent is suspended",
                success : false
            });
        }

        req.agent = agent;
        req.agentRole = role;
        next();
    }catch(error){
        console.error("Error in apiKeyMiddleware:", error);

        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = {
    apiKeyMiddleware
};