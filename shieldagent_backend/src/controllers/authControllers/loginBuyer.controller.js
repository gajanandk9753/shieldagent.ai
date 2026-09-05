const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
require("dotenv").config();

const buyerAgentModel = require("../../models/authModels/buyerAgent.model");

async function loginBuyerAgent(req, res) {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                message: "Please fill all required fields",
                success: false
            });
        }

        const agent = await buyerAgentModel.findOne({ email });
        if (!agent) {
            return res.status(400).json({
                message: "Email is not registered yet!",
                success: false
            });
        }

        const isPasswordCorrect = await bcrypt.compare(password, agent.passwordHash);
        if (!isPasswordCorrect) {
            return res.status(400).json({
                message: "Invalid Password",
                success: false
            });
        }

        const token = jwt.sign(
            {
                userId: agent._id,
                email: email
            },
            process.env.JSON_SECRET,
            {
                expiresIn: '30d'
            }
        );

        return res.status(200).json({
            message: "Login successfully",
            success: true,
            token: token,
            agent: {
                _id: agent._id,
                name: agent.name,
                email: agent.email,
                role: agent.role,
                apiKey: agent.apiKey,
                budgetLimit: agent.budgetLimit,
                budgetSpent: agent.budgetSpent,
                status: agent.status
            }
        });

    } catch (error) {
        console.error('Error in logging the buyer agent:', error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = {
    loginBuyerAgent
};