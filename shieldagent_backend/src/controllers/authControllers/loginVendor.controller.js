const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
require("dotenv").config();

const vendorAgentModel = require("../../models/authModels/vendorAgent.model");

async function loginVendorAgent(req, res) {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                message: "Please fill all required fields",
                success: false
            });
        }

        const agent = await vendorAgentModel.findOne({ email });
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
                companyName: agent.companyName,
                email: agent.email,
                role: agent.role,
                apiKey: agent.apiKey,
                reputationScore: agent.reputationScore,
                status: agent.status
            }
        });

    } catch (error) {
        console.error('Error in logging the vendor agent:', error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = {
    loginVendorAgent
};